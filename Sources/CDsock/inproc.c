/*

  Copyright (c) 2017 Maximilian Pudelko

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

dsock_unique_id(inproc_type);

static void *inproc_hquery(struct hvfs *hvfs, const void *type);
static void inproc_hclose(struct hvfs *hvfs);
static int inproc_msendl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t inproc_mrecvl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);

static const uint64_t MSG2BIG = UINT64_MAX;

static size_t iol_size(struct iolist *first) {
    size_t sz = 0;
    while(first) {
        sz += first->iol_len;
        first = first->iol_next;
    }
    return sz;
}

static int iol_deep_copy(struct iolist *dst, struct iolist *src) {
    if(!dst || !src) {errno = EINVAL; return -1;}
    size_t dst_size = iol_size(dst);
    size_t src_size = iol_size(src);
    if(dst_size < src_size) {errno = EINVAL; return -1;}
    size_t remaining = src_size;
    struct iolist *src_it = src;
    size_t src_block_remain = src_it->iol_len;
    struct iolist *dst_it = dst;
    size_t dst_block_remain = dst_it->iol_len;
    while(1) {
        size_t to_copy = MIN(src_block_remain, dst_block_remain);
        memcpy(dst_it->iol_base + dst_it->iol_len - dst_block_remain,
               src_it->iol_base + src_it->iol_len - src_block_remain,
               to_copy);
        dst_block_remain -= to_copy;
        src_block_remain -= to_copy;
        remaining -= to_copy;
        if(remaining == 0)
            break;
        dsock_assert(dst_block_remain == 0 || src_block_remain == 0);
        if(dst_block_remain == 0) {
            dst_it = dst_it->iol_next;
            dst_block_remain = dst_it->iol_len;
        }
        if(src_block_remain == 0) {
            src_it = src_it->iol_next;
            src_block_remain = src_it->iol_len;
        }
    }
    return 0;
}


struct inproc_sock {
    struct hvfs hvfs;
    struct msock_vfs mvfs;
    int data;
    int ack;
};

struct inproc_vec {
    struct iolist *first;
    struct iolist *last;
    size_t len;
};

static void *inproc_hquery(struct hvfs *hvfs, const void *type) {
    struct inproc_sock *obj = (struct inproc_sock*)hvfs;
    if(type == msock_type) return &obj->mvfs;
    if(type == inproc_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

/* Create new inproc socket with the channels data<inproc_vec> and
   ack<uint64_t>. Ownership of the channels is transferred to the socket */
static int inproc_new(int data, int ack) {
    int err, rc;
    if(data < 0 || ack < 0) {err = EBADF; goto error1;}
    /* Create the object. */
    struct inproc_sock *obj = malloc(sizeof(struct inproc_sock));
    if(dsock_slow(!obj)) {err = ENOMEM; goto error1;}
    obj->hvfs.query = inproc_hquery;
    obj->hvfs.close = inproc_hclose;
    obj->mvfs.msendl = inproc_msendl;
    obj->mvfs.mrecvl = inproc_mrecvl;
    obj->data = data;
    obj->ack = ack;
    /* Create the handle. */
    int h = hmake(&obj->hvfs);
    if(dsock_slow(h < 0)) {err = errno; goto error4;}
    return h;
    error4:
    free(obj);
    error1:
    errno = err;
    return -1;
}

static void inproc_destroy(struct inproc_sock *obj) {
    if(dsock_fast(obj->data >= 0)) {
        int rc = chdone(obj->data);
        dsock_assert(rc == 0 || errno == EPIPE);
        rc = hclose(obj->data);
        dsock_assert(rc == 0);
    }
    if(dsock_fast(obj->ack >= 0)) {
        int rc = chdone(obj->ack);
        dsock_assert(rc == 0 || errno == EPIPE);
        rc = hclose(obj->ack);
        dsock_assert(rc == 0);
    }
    free(obj);
}

int inproc_pair(int fds[2]) {
    int err, rc;
    if(!fds) {err = EINVAL; goto error1;}
    /* Setup channels */
    int ch_data1 = chmake(sizeof(struct inproc_vec));
    if(ch_data1 < 0) {err = errno; goto error1;}
    int ch_data2 = hdup(ch_data1);
    if(ch_data2 < 0) {err = errno; goto error2;}
    int ch_ack1 = chmake(sizeof(uint64_t));
    if(ch_ack1 < 0) {err = errno; goto error3;}
    int ch_ack2 = hdup(ch_ack1);
    if(ch_ack2 < 0) {err = errno; goto error4;}
    /* Create sockets */
    int a = inproc_new(ch_data1, ch_ack1);
    if(a < 0) {err = errno; goto error5;}
    int b = inproc_new(ch_data2, ch_ack2);
    if(b < 0) {err = errno; goto error6;}
    /*  */
    fds[0] = a;
    fds[1] = b;
    return 0;
    rc = hclose(b);
    dsock_assert(rc >= 0);
error6:
    rc = hclose(a);
    dsock_assert(rc >= 0);
error5:
    rc = hclose(ch_ack2);
    dsock_assert(rc >= 0);
error4:
    rc = hclose(ch_ack1);
    dsock_assert(rc >= 0);
error3:
    rc = hclose(ch_data2);
    dsock_assert(rc >= 0);
error2:
    rc = hclose(ch_data1);
    dsock_assert(rc >= 0);
error1:
    errno = err;
    return -1;
}

static void inproc_hclose(struct hvfs *hvfs) {
    struct inproc_sock *obj = (struct inproc_sock*)hvfs;
    inproc_destroy(obj);
}

static ssize_t inproc_mrecvl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct inproc_sock *obj = dsock_cont(mvfs, struct inproc_sock, mvfs);
    size_t len;
    int rc = iol_check(first, last, NULL, &len);
    if(dsock_slow(rc < 0)) return -1;
    struct inproc_vec vec;
    rc = chrecv(obj->data, &vec, sizeof(struct inproc_vec), deadline);
    if(rc < 0) return -1;
    if(vec.len > len) {goto msg2big;}
    iol_deep_copy(first, vec.first);
    rc = chsend(obj->ack, &vec.len, 8, deadline);
    if(rc < 0) return -1;
    return vec.len;
msg2big:
    rc = chsend(obj->ack, &MSG2BIG, 8 , deadline);
    if(rc < 0) return -1;
    errno = EMSGSIZE;
    return -1;
}

static int inproc_msendl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct inproc_sock *obj = dsock_cont(mvfs, struct inproc_sock, mvfs);
    size_t len;
    int rc = iol_check(first, last, NULL, &len);
    if(dsock_slow(rc < 0)) return -1;
    struct inproc_vec vec = {first, last, len};     
    rc = chsend(obj->data, &vec, sizeof(struct inproc_vec), deadline);
    if(rc < 0) return -1;
    uint64_t confirmation;
    rc = chrecv(obj->ack, &confirmation, 8, deadline);
    if(rc < 0) return -1;
    if(confirmation == MSG2BIG) {errno = EMSGSIZE; return -1;}
    if(confirmation != len) {errno = EPROTO; return -1;}
    return 0;
}

