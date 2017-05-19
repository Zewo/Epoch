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

dsock_unique_id(websock_type);

static void *websock_hquery(struct hvfs *hvfs, const void *type);
static void websock_hclose(struct hvfs *hvfs);
static int websock_msendl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t websock_mrecvl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);

struct websock_sock {
    struct hvfs hvfs;
    struct msock_vfs mvfs;
    int s;
    int txerr;
    int rxerr;
    int client;
    uint8_t txbuf[2048];
};

static void *websock_hquery(struct hvfs *hvfs, const void *type) {
    struct websock_sock *obj = (struct websock_sock*)hvfs;
    if(type == msock_type) return &obj->mvfs;
    if(type == websock_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

int websock_attach(int s, int client) {
    /* Check whether underlying socket is a bytestream. */
    if(dsock_slow(!hquery(s, bsock_type))) return -1;
    /* Create the object. */
    struct websock_sock *obj = malloc(sizeof(struct websock_sock));
    if(dsock_slow(!obj)) {errno = ENOMEM; return -1;}
    obj->hvfs.query = websock_hquery;
    obj->hvfs.close = websock_hclose;
    obj->mvfs.msendl = websock_msendl;
    obj->mvfs.mrecvl = websock_mrecvl;
    obj->s = s;
    obj->txerr = 0;
    obj->rxerr = 0;
    obj->client = client;
    /* Create the handle. */
    int h = hmake(&obj->hvfs);
    if(dsock_slow(h < 0)) {
        int err = errno;
        free(obj);
        errno = err;
        return -1;
    }
    return h;
}

int websock_detach(int s, int64_t deadline) {
    int err;
    struct websock_sock *obj = hquery(s, websock_type);
    if(dsock_slow(!obj)) return -1;
    dsock_assert(0);
}

static int websock_msendl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct websock_sock *obj = dsock_cont(mvfs, struct websock_sock, mvfs);
    if(dsock_slow(obj->txerr)) {errno = obj->txerr; return -1;}
    size_t len;
    int rc = iol_check(first, last, NULL, &len);
    if(dsock_slow(rc < 0)) return -1;
    /* Construct message header. */
    uint8_t buf[12];
    size_t sz;
    buf[0] = 0x82;
    if(len > 0xffff) {
        buf[1] = 127;
        dsock_putll(buf + 2, len);
        sz = 10;
    }
    else if(len > 125) {
        buf[1] = 126;
        dsock_puts(buf + 2, len);
        sz = 4;
    }
    else {
        buf[1] = (uint8_t)len;
        sz = 2;
    }
    /* Server sends unmasked message. */
    if(!obj->client) {
        struct iolist hdr = {buf, sz, first};
        int rc = bsendl(obj->s, &hdr, last, deadline);
        if(dsock_slow(rc < 0)) {obj->txerr = errno; return -1;}
        return 0;
    }
    /* Client sends masked message. */
    uint8_t mask[4];
    rc = dsock_random(mask, 4, deadline);
    if(dsock_slow(rc < 0)) return -1;
    buf[1] |= 0x80;
    memcpy(buf + sz, mask, 4);
    sz += 4;
    /* TODO: It should be worth sending the header together with the first
       batch of data. */
    rc = bsend(obj->s, buf, sz, deadline);
    if(dsock_slow(rc < 0)) {obj->txerr = errno; return -1;}
    struct iolist *it = first;
    size_t srcoff = 0;
    size_t dstoff = 0;
    int pos = 0;
    while(it) {
        size_t srcrmn = it->iol_len - srcoff;
        size_t dstrmn = sizeof(obj->txbuf) - dstoff;
        if(srcrmn < dstrmn) {
            memcpy(obj->txbuf + dstoff, it->iol_base + srcoff, srcrmn);
            dstoff += srcrmn;
            it = it->iol_next;
            srcoff = 0;
            if(it) continue;
        }
        else {
            memcpy(obj->txbuf + dstoff, it->iol_base + srcoff, dstrmn);
            srcoff += dstrmn;
            dstoff += dstrmn;
        }
        /* Either txbuf is full or there's no more data to send. */
        int i;
        for(i = 0; i != dstoff; ++i, ++pos)
            obj->txbuf[i] ^= mask[pos % 4];
        rc = bsend(obj->s, obj->txbuf, dstoff, deadline);
        if(dsock_slow(rc < 0)) {obj->txerr = errno; return -1;}
        dstoff = 0; 
    }
    return 0;
}

static ssize_t websock_mrecvl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct websock_sock *obj = dsock_cont(mvfs, struct websock_sock, mvfs);
    if(dsock_slow(obj->rxerr)) {errno = obj->rxerr; return -1;}
    size_t len;
    int rc = iol_check(first, last, NULL, &len);
    if(dsock_slow(rc < 0)) return -1;
    size_t pos = 0;
    while(1) {
        uint8_t hdr1[2];
        int rc = brecv(obj->s, hdr1, 2, deadline);
        if(dsock_slow(rc < 0)) {obj->rxerr = errno; return -1;}
        if(hdr1[0] & 0x70) {errno = obj->rxerr = EPROTO; return -1;}
        int opcode = hdr1[0] & 0x0f;
        switch(opcode) {
        case 0:
        case 1:
        case 2:
            goto dataframe;
        case 8:
            /* TODO: close frame */
            dsock_assert(0);
        case 9:
            /* TODO: ping frame */
            dsock_assert(0);
        case 10:
            /* TODO: pong frame */
            dsock_assert(0);
        default:
            errno = obj->rxerr = EPROTO;
            return -1;
        }
dataframe:
        if(!!(obj->client) ^ !(hdr1[1] & 0x80)) {
            errno = obj->rxerr = EPROTO; return -1;}
        size_t sz = hdr1[1] & 0x7f;
        if(sz == 126) {
            uint8_t hdr2[2];
            int rc = brecv(obj->s, hdr2, 2, deadline);
            if(dsock_slow(rc < 0)) {obj->rxerr = errno; return -1;}
            sz = dsock_gets(hdr2);
        }
        else if(sz == 127) {
            uint8_t hdr2[8];
            int rc = brecv(obj->s, hdr2, 8, deadline);
            if(dsock_slow(rc < 0)) {obj->rxerr = errno; return -1;}
            sz = dsock_getll(hdr2);
        }
        uint8_t mask[4];
        if(!obj->client) {
            int rc = brecv(obj->s, mask, 4, deadline);
            if(dsock_slow(rc < 0)) {obj->rxerr = errno; return -1;}
        }
        if(dsock_slow(sz > len)) {errno = obj->rxerr = EMSGSIZE; return -1;}
        struct iol_slice slc;
        iol_slice_init(&slc, first, last, pos, sz);
        rc = brecvl(obj->s, &slc.first, slc.last, deadline);
        iol_slice_term(&slc);
        if(dsock_slow(rc < 0)) {obj->rxerr = errno; return -1;}
        if(!obj->client) {
            /* Unmask the frame data. */
            size_t i, mpos = 0;
            struct iolist *it;
            for(it = first; it; it = it->iol_next)
                for(i = 0; i != it->iol_len; ++i)
                    ((uint8_t*)it->iol_base)[i] ^= mask[mpos++ % 4];
        }
        pos += sz;
        len -= sz;
        if(hdr1[0] & 0x80)
            break;
    }
    return pos;
}

static void websock_hclose(struct hvfs *hvfs) {
    struct websock_sock *obj = (struct websock_sock*)hvfs;
    int rc = hclose(obj->s);
    dsock_assert(rc == 0);
    free(obj);
}

