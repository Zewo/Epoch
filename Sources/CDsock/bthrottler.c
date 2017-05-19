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

#include "dsock.h"
#include "iol.h"
#include "utils.h"

dsock_unique_id(bthrottler_type);

static void *bthrottler_hquery(struct hvfs *hvfs, const void *type);
static void bthrottler_hclose(struct hvfs *hvfs);
static int bthrottler_bsendl(struct bsock_vfs *bvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t bthrottler_brecvl(struct bsock_vfs *bvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);

struct bthrottler_sock {
    struct hvfs hvfs;
    struct bsock_vfs bvfs;
    int s;
    size_t send_full;
    size_t send_remaining;
    int64_t send_interval;
    int64_t send_last;
    size_t recv_full;
    size_t recv_remaining;
    int64_t recv_interval;
    int64_t recv_last;
};

static void *bthrottler_hquery(struct hvfs *hvfs, const void *type) {
    struct bthrottler_sock *obj = (struct bthrottler_sock*)hvfs;
    if(type == bsock_type) return &obj->bvfs;
    if(type == bthrottler_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

int bthrottler_attach(int s,
      uint64_t send_throughput, int64_t send_interval,
      uint64_t recv_throughput, int64_t recv_interval) {
    int err;
    if(dsock_slow(send_throughput != 0 && send_interval <= 0 )) {
        err = EINVAL; goto error1;}
    if(dsock_slow(recv_throughput != 0 && recv_interval <= 0 )) {
        err = EINVAL; goto error1;}
    /* Check whether underlying socket is a bytestream. */
    if(dsock_slow(!hquery(s, bsock_type))) {err = errno; goto error1;}
    /* Create the object. */
    struct bthrottler_sock *obj = malloc(sizeof(struct bthrottler_sock));
    if(dsock_slow(!obj)) {err = ENOMEM; goto error1;}
    obj->hvfs.query = bthrottler_hquery;
    obj->hvfs.close = bthrottler_hclose;
    obj->bvfs.bsendl = bthrottler_bsendl;
    obj->bvfs.brecvl = bthrottler_brecvl;
    obj->s = -1;
    obj->send_full = 0;
    if(send_throughput > 0) {
        obj->send_full = send_throughput * send_interval / 1000;
        obj->send_remaining = obj->send_full;
        obj->send_interval = send_interval;
        obj->send_last = now();
    }
    obj->recv_full = 0;
    if(recv_throughput > 0) {
        obj->recv_full = recv_throughput * recv_interval / 1000;
        obj->recv_remaining = obj->recv_full;
        obj->recv_interval = recv_interval;
        obj->recv_last = now();
    }
    /* Create the handle. */
    int h = hmake(&obj->hvfs);
    if(dsock_slow(h < 0)) {err = errno; goto error2;}
    /* Make a private copy of the underlying socket. */
    obj->s = hdup(s);
    if(dsock_slow(obj->s < 0)) {err = errno; goto error3;}
    int rc = hclose(s);
    dsock_assert(rc == 0);
    return h;
error3:
    rc = hclose(h);
    dsock_assert(rc == 0);
error2:
    free(obj);
error1:
    errno = err;
    return -1;
}

int bthrottler_detach(int s) {
    struct bthrottler_sock *obj = hquery(s, bthrottler_type);
    if(dsock_slow(!obj)) return -1;
    int u = obj->s;
    free(obj);
    return u;
}

static int bthrottler_bsendl(struct bsock_vfs *bvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct bthrottler_sock *obj =
        dsock_cont(bvfs, struct bthrottler_sock, bvfs);
    /* If send-throttling is off forward the call. */
    if(obj->send_full == 0) return bsendl(obj->s, first, last, deadline);
    /* Get rid of the corner case. */
    size_t bytes;
    int rc = iol_check(first, last, NULL, &bytes);
    if(dsock_slow(rc < 0)) return -1;
    if(dsock_slow(bytes == 0)) return 0;
    size_t pos = 0;
    while(1) {
        /* If there's capacity send as much data as possible. */
        if(obj->send_remaining) {
            size_t tosend = bytes < obj->send_remaining ?
                bytes : obj->send_remaining;
            struct iol_slice slc;
            iol_slice_init(&slc, first, last, pos, tosend);
            int rc = bsendl(obj->s, &slc.first, slc.last, deadline);
            iol_slice_term(&slc);
            if(dsock_slow(rc < 0)) return -1;
            obj->send_remaining -= tosend;
            pos += tosend;
            bytes -= tosend;
            if(bytes == 0) return 0;
        }
        /* Wait till capacity can be renewed. */
        int rc = msleep(obj->send_last + obj->send_interval);
        if(dsock_slow(rc < 0)) return -1;
        /* Renew the capacity. */
        obj->send_remaining = obj->send_full;
        obj->send_last = now();
    }
}

static ssize_t bthrottler_brecvl(struct bsock_vfs *bvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct bthrottler_sock *obj =
        dsock_cont(bvfs, struct bthrottler_sock, bvfs);
    /* If recv-throttling is off forward the call. */
    if(obj->recv_full == 0) return brecvl(obj->s, first, last, deadline);
    /* Get rid of the corner case. */
    size_t bytes;
    int rc = iol_check(first, last, NULL, &bytes);
    if(dsock_slow(rc < 0)) return -1;
    if(dsock_slow(bytes == 0)) return 0;
    size_t pos = 0;
    while(1) {
        /* If there's capacity receive as much data as possible. */
        if(obj->recv_remaining) {
            size_t torecv = bytes < obj->recv_remaining ?
                bytes : obj->recv_remaining;
            struct iol_slice slc;
            iol_slice_init(&slc, first, last, pos, torecv);
            int rc = brecvl(obj->s, &slc.first, slc.last, deadline);
            iol_slice_term(&slc);
            if(dsock_slow(rc < 0)) return -1;
            obj->recv_remaining -= torecv;
            pos += torecv;
            bytes -= torecv;
            if(bytes == 0) return 0;
        }
        /* Wait till capacity can be renewed. */
        int rc = msleep(obj->recv_last + obj->recv_interval);
        if(dsock_slow(rc < 0)) return -1;
        /* Renew the capacity. */
        obj->recv_remaining = obj->recv_full;
        obj->recv_last = now();
    }
}

static void bthrottler_hclose(struct hvfs *hvfs) {
    struct bthrottler_sock *obj = (struct bthrottler_sock*)hvfs;
    if(dsock_fast(obj->s >= 0)) {
        int rc = hclose(obj->s);
        dsock_assert(rc == 0);
    }
    free(obj);
}

