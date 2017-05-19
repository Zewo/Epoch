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
#include <sys/uio.h>

#include "dsock.h"
#include "utils.h"

dsock_unique_id(keepalive_type);

static void *keepalive_hquery(struct hvfs *hvfs, const void *type);
static void keepalive_hclose(struct hvfs *hvfs);
static int keepalive_msendl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t keepalive_mrecvl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static coroutine void keepalive_sender(int s, int64_t send_interval,
    int sendch, int ackch);

struct keepalive_sock {
    struct hvfs hvfs;
    struct msock_vfs mvfs;
    int s;
    int64_t send_interval;
    int64_t recv_interval;
    int sendch;
    int ackch;
    int sender;
    int64_t last_recv;
    int err;
};

struct keepalive_vec {
    struct iolist *first;
    struct iolist *last;
};

static void *keepalive_hquery(struct hvfs *hvfs, const void *type) {
    struct keepalive_sock *obj = (struct keepalive_sock*)hvfs;
    if(type == msock_type) return &obj->mvfs;
    if(type == keepalive_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

int keepalive_attach(int s, int64_t send_interval, int64_t recv_interval) {
    int rc;
    int err;
    /* Check whether underlying socket is message-based. */
    if(dsock_slow(!hquery(s, msock_type))) {err = errno; goto error1;}
    /* Create the object. */
    struct keepalive_sock *obj = malloc(sizeof(struct keepalive_sock));
    if(dsock_slow(!obj)) {err = ENOMEM; goto error1;}
    obj->hvfs.query = keepalive_hquery;
    obj->hvfs.close = keepalive_hclose;
    obj->mvfs.msendl = keepalive_msendl;
    obj->mvfs.mrecvl = keepalive_mrecvl;
    obj->s = s;
    obj->send_interval = send_interval;
    obj->recv_interval = recv_interval;
    obj->sendch = -1;
    obj->ackch = -1;
    obj->sender = -1;
    if(send_interval >= 0) {
        obj->sendch = chmake(sizeof(struct keepalive_vec));
        if(dsock_slow(obj->sendch < 0)) {err = errno; goto error2;}
        obj->ackch = chmake(sizeof(int));
        if(dsock_slow(obj->ackch < 0)) {err = errno; goto error3;}
        obj->sender = go(keepalive_sender(s, send_interval,
            obj->sendch, obj->ackch));
        if(dsock_slow(obj->sender < 0)) {err = errno; goto error4;}
    }
    obj->last_recv = now();
    obj->err = 0;
    /* Create the handle. */
    int h = hmake(&obj->hvfs);
    if(dsock_slow(h < 0)) {err = errno; goto error5;}
    return h;
error5:
    if(obj->sender >= 0) {
        rc = hclose(obj->sender);
        dsock_assert(rc == 0);
    }
error4:
    if(obj->ackch >= 0) {
        rc = hclose(obj->ackch);
        dsock_assert(rc == 0);
    }
error3:
    if(obj->sendch >= 0) {
        rc = hclose(obj->sendch);
        dsock_assert(rc == 0);
    }
error2:
    free(obj);
error1:
    errno = err;
    return -1;
}

static int keepalive_free(struct keepalive_sock *obj) {
    if(obj->send_interval >= 0) {
        int rc = hclose(obj->sender);
        dsock_assert(rc == 0);
        rc = hclose(obj->ackch);
        dsock_assert(rc == 0);
        rc = hclose(obj->sendch);
        dsock_assert(rc == 0);
    }
    int u = obj->s;
    free(obj);
    return u;
}

int keepalive_detach(int s) {
    int err;
    struct keepalive_sock *obj = hquery(s, keepalive_type);
    if(dsock_slow(!obj)) return -1;
    return keepalive_free(obj);
}

static int keepalive_msendl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct keepalive_sock *obj = dsock_cont(mvfs, struct keepalive_sock, mvfs);
    if(dsock_slow(obj->err)) {errno = obj->err; return -1;}
    /* Send is done in a worker coroutine. */
    struct keepalive_vec vec = {first, last};
    int rc = chsend(obj->sendch, &vec, sizeof(vec), deadline);
    if(dsock_slow(rc < 0)) return -1;
    /* Wait till worker is done. */
    int err;
    rc = chrecv(obj->ackch, &err, sizeof(err), deadline);
    if(dsock_slow(rc < 0)) return -1;
    if(dsock_slow(err < 0)) {errno = err; return -1;}
    return 0;
}

static coroutine void keepalive_sender(int s, int64_t send_interval,
      int sendch, int ackch) {
    /* Last time something was sent. */
    int64_t last = now();
    while(1) {
        /* Get data to send from the user coroutine. */
        struct keepalive_vec vec;
        int rc = chrecv(sendch, &vec, sizeof(vec), last + send_interval);
        if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
        if(dsock_slow(rc < 0 && errno == ETIMEDOUT)) {
            /* Send a keepalive. */
            rc = msend(s, "K", 1, -1);
            if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
            /* We'll ignore other errors here, assuming they are temporary.
               Temporary failure to send a keepalive should not cause errors. */
            last = now();
            continue;
        }
        dsock_assert(rc == 0);
        uint8_t c = 'D';
        struct iolist iol = {&c, 1, vec.first, 0};
        rc = msendl(s, &iol, vec.last, -1);
        if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
        /* Pass the error to the user. */
        if(dsock_slow(rc < 0)) {
            int err = errno;
            rc = chsend(ackch, &err, sizeof(err), -1);
            if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
            dsock_assert(rc == 0);
            return;
        }
        last = now();
        int err = 0;
        rc = chsend(ackch, &err, sizeof(err), -1);
        if(dsock_slow(rc < 0 && errno == ECANCELED)) return;
        dsock_assert(rc == 0);
    }
}

static ssize_t keepalive_mrecvl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct keepalive_sock *obj = dsock_cont(mvfs, struct keepalive_sock, mvfs);
    /* If receive mode is off, just forward the call. */
    if(obj->recv_interval < 0) return mrecvl(obj->s, first, last, deadline);
    if(dsock_slow(obj->err)) {errno = obj->err; return -1;}
retry:;
    /* Compute the deadline. Take keepalive interval into consideration. */
    int64_t dd = obj->last_recv + obj->recv_interval;
    int fail_on_deadline = 1;
    if(deadline < dd) {
       dd = deadline;
       fail_on_deadline = 0;
    }
    uint8_t c;
    struct iolist iol = {&c, 1, first, 0};
    ssize_t sz = mrecvl(obj->s, &iol, last, dd);
    if(dsock_slow(fail_on_deadline && sz < 0 && errno == ETIMEDOUT)) {
        obj->err = errno = ECONNRESET; return -1;}
    if(dsock_slow(sz < 0)) return -1;
    obj->last_recv = now();
    if(dsock_slow(sz == 0)) {errno = EPROTO; return -1;}
    switch(c) {
    case 'D':
        return sz - 1;
    case 'K':
        goto retry;
    default:
        errno = EPROTO;
        return -1;
    }
}

static void keepalive_hclose(struct hvfs *hvfs) {
    struct keepalive_sock *obj = (struct keepalive_sock*)hvfs;
    int u = keepalive_free(obj);
    int rc = hclose(u);
    dsock_assert(rc == 0);
}

