/*

  Copyright (c) 2017 Martin Sustrik

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"),
  to deal in the Software without restriction, including without limitation
  the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom
  the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.

*/

#include <errno.h>
#include "libdillimpl.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "dsock.h"
#include "iol.h"
#include "utils.h"

dsock_unique_id(nagle_type);

static void *nagle_hquery(struct hvfs *hvfs, const void *type);
static void nagle_hclose(struct hvfs *hvfs);
static int nagle_bsendl(struct bsock_vfs *bvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t nagle_brecvl(struct bsock_vfs *bvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static coroutine void nagle_sender(int s, size_t batch, int64_t interval,
    uint8_t *buf, int sendch, int ackch);

struct nagle_vec {
    struct iolist *first;
    struct iolist *last;
    size_t len;
};

struct nagle_sock {
    struct hvfs hvfs;
    struct bsock_vfs bvfs;
    int s;
    uint8_t *buf;
    int sendch;
    int ackch;
    int sender;
};

static void *nagle_hquery(struct hvfs *hvfs, const void *type) {
    struct nagle_sock *obj = (struct nagle_sock*)hvfs;
    if(type == bsock_type) return &obj->bvfs;
    if(type == nagle_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

int nagle_attach(int s, size_t batch, int64_t interval) {
    int rc;
    int err;
    /* Check whether underlying socket is a bytestream. */
    if(dsock_slow(!hquery(s, bsock_type))) {err = errno; goto error1;}
    /* Create the object. */
    struct nagle_sock *obj = malloc(sizeof(struct nagle_sock));
    if(dsock_slow(!obj)) {err = ENOMEM; goto error1;}
    obj->hvfs.query = nagle_hquery;
    obj->hvfs.close = nagle_hclose;
    obj->bvfs.bsendl = nagle_bsendl;
    obj->bvfs.brecvl = nagle_brecvl;
    obj->s = s;
    obj->buf = malloc(batch);
    if(dsock_slow(!obj->buf)) {errno = ENOMEM; goto error2;}
    obj->sendch = chmake(sizeof(struct nagle_vec));
    if(dsock_slow(obj->sendch < 0)) {err = errno; goto error3;}
    obj->ackch = chmake(sizeof(int));
    if(dsock_slow(obj->ackch < 0)) {err = errno; goto error4;}
    obj->sender = go(nagle_sender(s, batch, interval,
        obj->buf, obj->sendch, obj->ackch));
    if(dsock_slow(obj->sender < 0)) {err = errno; goto error5;}
    /* Create the handle. */
    int h = hmake(&obj->hvfs);
    if(dsock_slow(h < 0)) {err = errno; goto error6;}
    return h;
error6:
    rc = hclose(obj->sender);
    dsock_assert(rc == 0);
error5:
    rc = hclose(obj->ackch);
    dsock_assert(rc == 0);
error4:
    rc = hclose(obj->sendch);
    dsock_assert(rc == 0);
error3:
    free(obj->buf);
error2:
    free(obj);
error1:
    errno = err;
    return -1;
}

int nagle_detach(int s, int64_t deadline) {
    struct nagle_sock *obj = hquery(s, nagle_type);
    if(dsock_slow(!obj)) return -1;
    /* TODO: Flush the data from the buffer! */
    int rc = hclose(obj->sender);
    dsock_assert(rc == 0);
    rc = hclose(obj->ackch);
    dsock_assert(rc == 0);
    rc = hclose(obj->sendch);
    dsock_assert(rc == 0);
    free(obj->buf);
    int u = obj->s;
    free(obj);
    return u;
}

static int nagle_bsendl(struct bsock_vfs *bvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct nagle_sock *obj = dsock_cont(bvfs, struct nagle_sock, bvfs);
    size_t len;
    int rc = iol_check(first, last, NULL, &len);
    if(dsock_slow(rc < 0)) return -1;
    /* Send is done in a worker coroutine. */
    struct nagle_vec vec = {first, last, len};
    rc = chsend(obj->sendch, &vec, sizeof(vec), deadline);
    if(dsock_slow(rc < 0)) return -1;
    /* Wait till worker is done. */
    int err;
    rc = chrecv(obj->ackch, &err, sizeof(err), deadline);
    if(dsock_slow(rc < 0)) return -1;
    if(dsock_slow(rc < 0)) {errno = err; return -1;}
    return 0;
}

static coroutine void nagle_sender(int s, size_t batch, int64_t interval,
      uint8_t *buf, int sendch, int ackch) {
    /* Amount of data in the buffer. */
    size_t len = 0;
    /* Last time at least one byte was sent. */
    int64_t last = now();
    while(1) {
        /* Get data to send from the user coroutine. */
        struct nagle_vec vec;
        int rc = chrecv(sendch, &vec, sizeof(vec),
            interval >= 0 && len ? last + interval : -1);
        if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
        /* Timeout expired. Flush the data in the buffer. */
        if(dsock_slow(rc < 0 && errno == ETIMEDOUT)) {
            rc = bsend(s, buf, len, -1);
            if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
            dsock_assert(rc == 0);
            len = 0;
            last = now();
            continue;
        }
        dsock_assert(rc == 0);
        /* If data fit into the buffer, store them there. */
        if(len + vec.len < batch) {
            iol_copy(vec.first, buf + len);
            len += vec.len;
            int err = 0;
            rc = chsend(ackch, &err, sizeof(err), -1);
            if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
            dsock_assert(rc == 0);
            continue;
        }
        if(len > 0) {
            /* Flush the buffer. */
            rc = bsend(s, buf, len, -1);
            if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
            /* Pass the error to the user. */
            if(dsock_slow(rc < 0)) {
                int err = errno;
                rc = chsend(ackch, &err, sizeof(err), -1);
                if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
                dsock_assert(rc == 0);
                return;
            }
            len = 0;
            last = now();
        }
        /* Once again: If data fit into buffer store them there. */
        if(vec.len < batch) {
            iol_copy(vec.first, buf);
            len = vec.len;
            int err = 0;
            rc = chsend(ackch, &err, sizeof(err), -1);
            if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
            dsock_assert(rc == 0);
            continue;
        }
        /* This is a big chunk of data, no need to Nagle it.
           We'll send it straight away. */
        rc = bsendl(s, vec.first, vec.last, -1);
        if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
        dsock_assert(rc == 0);
        last = now();
        int err = 0;
        rc = chsend(ackch, &err, sizeof(err), -1);
        if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
        dsock_assert(rc == 0);
    }
}

static ssize_t nagle_brecvl(struct bsock_vfs *bvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct nagle_sock *obj = dsock_cont(bvfs, struct nagle_sock, bvfs);
    return brecvl(obj->s, first, last, deadline);
}

static void nagle_hclose(struct hvfs *hvfs) {
    struct nagle_sock *obj = (struct nagle_sock*)hvfs;
    int rc = hclose(obj->sender);
    dsock_assert(rc == 0);
    rc = hclose(obj->ackch);
    dsock_assert(rc == 0);
    rc = hclose(obj->sendch);
    dsock_assert(rc == 0);
    free(obj->buf);
    rc = hclose(obj->s);
    dsock_assert(rc == 0);
    free(obj);
}

