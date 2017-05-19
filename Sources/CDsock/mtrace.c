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
#include <stdio.h>
#include <stdlib.h>

#include "dsock.h"
#include "utils.h"

dsock_unique_id(mtrace_type);

static void *mtrace_hquery(struct hvfs *hvfs, const void *type);
static void mtrace_hclose(struct hvfs *hvfs);
static int mtrace_msendl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t mtrace_mrecvl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);

struct mtrace_sock {
    struct hvfs hvfs;
    struct msock_vfs mvfs;
    /* Underlying socket. */
    int s;
    /* This socket. */
    int h;
};

static void *mtrace_hquery(struct hvfs *hvfs, const void *type) {
    struct mtrace_sock *obj = (struct mtrace_sock*)hvfs;
    if(type == msock_type) return &obj->mvfs;
    if(type == mtrace_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

int mtrace_attach(int s) {
    /* Check whether underlying socket is message-based. */
    if(dsock_slow(!hquery(s, msock_type))) return -1;
    /* Create the object. */
    struct mtrace_sock *obj = malloc(sizeof(struct mtrace_sock));
    if(dsock_slow(!obj)) {errno = ENOMEM; return -1;}
    obj->hvfs.query = mtrace_hquery;
    obj->hvfs.close = mtrace_hclose;
    obj->mvfs.msendl = mtrace_msendl;
    obj->mvfs.mrecvl = mtrace_mrecvl;
    obj->s = s;
    /* Create the handle. */
    int h = hmake(&obj->hvfs);
    if(dsock_slow(h < 0)) {
        int err = errno;
        free(obj);
        errno = err;
        return -1;
    }
    obj->h = h;
    return h;
}

int mtrace_detach(int s) {
    struct mtrace_sock *obj = hquery(s, mtrace_type);
    if(dsock_slow(!obj)) return -1;
    int u = obj->s;
    free(obj);
    return u;
}

static int mtrace_msendl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct mtrace_sock *obj = dsock_cont(mvfs, struct mtrace_sock, mvfs);
    size_t len = 0;
    fprintf(stderr, "msend(%d, 0x", obj->h);
    struct iolist *it = first;
    while(it) {
        int i;
        for(i = 0; i != it->iol_len; ++i)
            fprintf(stderr, "%02x", (int)((uint8_t*)it->iol_base)[i]);
        len += it->iol_len;
        it = it->iol_next;
    }
    fprintf(stderr, ", %zu)\n", len);
    return msendl(obj->s, first, last, deadline);
}

static ssize_t mtrace_mrecvl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct mtrace_sock *obj = dsock_cont(mvfs, struct mtrace_sock, mvfs);
    ssize_t sz = mrecvl(obj->s, first, last, deadline);
    if(dsock_slow(sz < 0)) return -1;
    fprintf(stderr, "mrecv(%d, 0x", obj->h);
    size_t toprint = sz;
    struct iolist *it = first;
    while(it && toprint) {
        int i;
        for(i = 0; i != it->iol_len && toprint; ++i) {
            fprintf(stderr, "%02x", (int)((uint8_t*)it->iol_base)[i]);
            --toprint;
        }
        it = it->iol_next;
    }
    fprintf(stderr, ", %zu)\n", (size_t)sz);
    return sz;
}

static void mtrace_hclose(struct hvfs *hvfs) {
    struct mtrace_sock *obj = (struct mtrace_sock*)hvfs;
    int rc = hclose(obj->s);
    dsock_assert(rc == 0);
    free(obj);
}

