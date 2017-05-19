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

#include "lz4/lz4frame.h"

#include "iol.h"
#include "utils.h"

dsock_unique_id(lz4_type);

static void *lz4_hquery(struct hvfs *hvfs, const void *type);
static void lz4_hclose(struct hvfs *hvfs);
static int lz4_msendl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t lz4_mrecvl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);

struct lz4_sock {
    struct hvfs hvfs;
    struct msock_vfs mvfs;
    int s;
    uint8_t *outbuf;
    size_t outlen;
    uint8_t *inbuf;
    size_t inlen;
    LZ4F_decompressionContext_t dctx;
};

static void *lz4_hquery(struct hvfs *hvfs, const void *type) {
    struct lz4_sock *obj = (struct lz4_sock*)hvfs;
    if(type == msock_type) return &obj->mvfs;
    if(type == lz4_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

int lz4_attach(int s) {
    int err;
    /* Check whether underlying socket is message-based. */
    if(dsock_slow(!hquery(s, msock_type))) {err = errno; goto error1;}
    /* Create the object. */
    struct lz4_sock *obj = malloc(sizeof(struct lz4_sock));
    if(dsock_slow(!obj)) {errno = ENOMEM; goto error1;}
    obj->hvfs.query = lz4_hquery;
    obj->hvfs.close = lz4_hclose;
    obj->mvfs.msendl = lz4_msendl;
    obj->mvfs.mrecvl = lz4_mrecvl;
    obj->s = s;
    obj->outbuf = NULL;
    obj->outlen = 0;
    obj->inbuf = NULL;
    obj->inlen = 0;        
    size_t ec = LZ4F_createDecompressionContext(&obj->dctx, LZ4F_VERSION);
    if(dsock_slow(LZ4F_isError(ec))) {err = EFAULT; goto error2;}
    /* Create the handle. */
    int h = hmake(&obj->hvfs);
    if(dsock_slow(h < 0)) {err = errno; goto error3;}
    return h;
error3:
    ec = LZ4F_freeDecompressionContext(obj->dctx);
    dsock_assert(!LZ4F_isError(ec));
error2:
    free(obj);
error1:
    errno = err;
    return -1;
}

int lz4_detach(int s) {
    struct lz4_sock *obj = hquery(s, lz4_type);
    if(dsock_slow(!obj)) return -1;
    size_t ec = LZ4F_freeDecompressionContext(obj->dctx);
    dsock_assert(!LZ4F_isError(ec));
    free(obj->inbuf);
    free(obj->outbuf);
    int u = obj->s;
    free(obj);
    return u;
}

static int lz4_msendl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct lz4_sock *obj = dsock_cont(mvfs, struct lz4_sock, mvfs);
    size_t len;
    int rc = iol_check(first, last, NULL, &len);
    if(dsock_slow(rc < 0)) return -1;
    /* Adjust the buffer size as needed. */
    size_t maxlen = LZ4F_compressFrameBound(len, NULL);
    if(obj->outlen < maxlen) {
        uint8_t *newbuf = realloc(obj->outbuf, maxlen);
        if(dsock_slow(!newbuf)) {errno = ENOMEM; return -1;}
        obj->outbuf = newbuf;
        obj->outlen = maxlen;
    }
    /* Compress the data. */
    /* TODO: Avoid the extra allocations and copies. */
    uint8_t *buf = malloc(len);
    if(dsock_slow(!buf)) {errno = ENOMEM; return -1;}
    uint8_t *pos = buf;
    struct iolist *it;
    for(it = first; it; it = it->iol_next) {
        memcpy(pos, it->iol_base, it->iol_len);
        pos += it->iol_len;
    }
    LZ4F_preferences_t prefs = {0};
    prefs.frameInfo.contentSize = len;
    size_t dstlen = LZ4F_compressFrame(obj->outbuf, obj->outlen,
        buf, len, &prefs);
    dsock_assert(!LZ4F_isError(dstlen));
    dsock_assert(dstlen <= obj->outlen);
    free(buf);
    /* Send the compressed frame. */
    return msend(obj->s, obj->outbuf, dstlen, deadline);
}

static ssize_t lz4_mrecvl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct lz4_sock *obj = dsock_cont(mvfs, struct lz4_sock, mvfs);
    size_t len;
    int rc = iol_check(first, last, NULL, &len);
    if(dsock_slow(rc < 0)) return -1;
    /* Adjust the buffer size as needed. */
    size_t maxlen = LZ4F_compressFrameBound(len, NULL);
    if(obj->inlen < maxlen) {
        uint8_t *newbuf = realloc(obj->inbuf, maxlen);
        if(dsock_slow(!newbuf)) {errno = ENOMEM; return -1;}
        obj->inbuf = newbuf;
        obj->inlen = maxlen;
    }
    /* Get the compressed message. */
    ssize_t sz = mrecv(obj->s, obj->inbuf, obj->inlen, deadline);
    if(dsock_slow(sz < 0)) return -1;
    /* Extract size of the uncompressed message from LZ4 frame header. */
    LZ4F_frameInfo_t info;
    size_t infolen = sz;
    size_t ec = LZ4F_getFrameInfo(obj->dctx, &info, obj->inbuf, &infolen);
    if(dsock_slow(LZ4F_isError(ec))) {errno = EPROTO; return -1;}
    /* Size is a required field. */
    if(dsock_slow(info.contentSize == 0)) {errno = EPROTO; return -1;}
    /* Decompressed message would exceed the buffer size. */
    if(dsock_slow(info.contentSize > len)) {errno = EMSGSIZE; return -1;}
    /* Decompress. */
    /* TODO: Avoid the extra allocations and copies. */
    uint8_t *buf = malloc(len);
    if(dsock_slow(!buf)) {errno = ENOMEM; return -1;}
    size_t dstlen = len;
    size_t srclen = sz - infolen;
    ec = LZ4F_decompress(obj->dctx, buf, &dstlen,
        obj->inbuf + infolen, &srclen, NULL);
    if(dsock_slow(LZ4F_isError(ec))) {errno = EPROTO; return -1;}
    if(dsock_slow(ec != 0)) {errno = EPROTO; return -1;}
    dsock_assert(srclen == sz - infolen);
    uint8_t *pos = buf;
    struct iolist *it;
    for(it = first; it; it = it->iol_next) {
        if(it->iol_base) memcpy(it->iol_base, pos, it->iol_len);
        pos += it->iol_len;
    }
    free(buf);
    return dstlen;
}

static void lz4_hclose(struct hvfs *hvfs) {
    struct lz4_sock *obj = (struct lz4_sock*)hvfs;
    size_t ec = LZ4F_freeDecompressionContext(obj->dctx);
    dsock_assert(!LZ4F_isError(ec));
    free(obj->inbuf);
    free(obj->outbuf);
    int rc = hclose(obj->s);
    dsock_assert(rc == 0);
    free(obj);
}

