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
#include "utils.h"

dsock_unique_id(mthrottler_type);

static void *mthrottler_hquery(struct hvfs *hvfs, const void *type);
static void mthrottler_hclose(struct hvfs *hvfs);
static int mthrottler_msendl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t mthrottler_mrecvl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);

struct mthrottler_sock {
    struct hvfs hvfs;
    struct msock_vfs mvfs;
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

static void *mthrottler_hquery(struct hvfs *hvfs, const void *type) {
    struct mthrottler_sock *obj = (struct mthrottler_sock*)hvfs;
    if(type == msock_type) return &obj->mvfs;
    if(type == mthrottler_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

int mthrottler_attach(int s,
      uint64_t send_throughput, int64_t send_interval,
      uint64_t recv_throughput, int64_t recv_interval) {
    int err;
    if(dsock_slow(send_throughput != 0 && send_interval <= 0 )) {
        err = EINVAL; goto error1;}
    if(dsock_slow(recv_throughput != 0 && recv_interval <= 0 )) {
        err = EINVAL; goto error1;}
    /* Check whether underlying socket is message-based. */
    if(dsock_slow(!hquery(s, msock_type))) {err = errno; goto error1;}
    /* Create the object. */
    struct mthrottler_sock *obj = malloc(sizeof(struct mthrottler_sock));
    if(dsock_slow(!obj)) {err = ENOMEM; goto error1;}
    obj->hvfs.query = mthrottler_hquery;
    obj->hvfs.close = mthrottler_hclose;
    obj->mvfs.msendl = mthrottler_msendl;
    obj->mvfs.mrecvl = mthrottler_mrecvl;
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

int mthrottler_detach(int s) {
    struct mthrottler_sock *obj = hquery(s, mthrottler_type);
    if(dsock_slow(!obj)) return -1;
    int u = obj->s;
    free(obj);
    return u;
}

static int mthrottler_msendl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct mthrottler_sock *obj =
        dsock_cont(mvfs, struct mthrottler_sock, mvfs);
    /* If send-throttling is off forward the call. */
    if(obj->send_full == 0) return msendl(obj->s, first, last, deadline);
    /* If there's no quota wait till it is renewed. */
    if(!obj->send_remaining) {
        int rc = msleep(obj->send_last + obj->send_interval);
        if(dsock_slow(rc < 0)) return -1;
        obj->send_remaining = obj->send_full;
        obj->send_last = now();
    }
    /* Send the message. */ 
    int rc = msendl(obj->s, first, last, deadline);
    if(dsock_slow(rc < 0)) return -1;
    --obj->send_remaining;
    return 0;
}

static ssize_t mthrottler_mrecvl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct mthrottler_sock *obj =
        dsock_cont(mvfs, struct mthrottler_sock, mvfs);
    /* If recv-throttling is off forward the call. */
    if(obj->recv_full == 0) return mrecvl(obj->s, first, last, deadline);
    /* If there's no quota wait till it is renewed. */
    if(!obj->recv_remaining) {
        int rc = msleep(obj->recv_last + obj->recv_interval);
        if(dsock_slow(rc < 0)) return -1;
        obj->recv_remaining = obj->recv_full;
        obj->recv_last = now();
    }
    /* Receive the message. */
    int rc = mrecvl(obj->s, first, last, deadline);
    if(dsock_slow(rc < 0)) return -1;
    --obj->recv_remaining;
    return 0;
}

static void mthrottler_hclose(struct hvfs *hvfs) {
    struct mthrottler_sock *obj = (struct mthrottler_sock*)hvfs;
    if(dsock_fast(obj->s >= 0)) {
        int rc = hclose(obj->s);
        dsock_assert(rc == 0);
    }
    free(obj);
}

