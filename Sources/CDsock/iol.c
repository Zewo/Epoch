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

#include <string.h>

#include "iol.h"
#include "utils.h"

int iol_check(struct iolist *first, struct iolist *last,
      size_t *nbufs, size_t *nbytes) {
    if(dsock_slow(!first || !last || last->iol_next)) {
        errno = EINVAL; return -1;}
    size_t nbf = 0, nbt = 0, res = 0;
    struct iolist *it;
    for(it = first; it; it = it->iol_next) {
        if(dsock_slow(it->iol_rsvd || (!it->iol_next && it != last)))
            goto error;
        it->iol_rsvd = 1;
        nbf++;
        nbt += it->iol_len;
    }
    for(it = first; it; it = it->iol_next) it->iol_rsvd = 0;
    if(nbufs) *nbufs = nbf;
    if(nbytes) *nbytes = nbt;
    return 0;
error:;
    struct iolist *it2;
    for(it2 = first; it2 != it; it2 = it2->iol_next) it->iol_rsvd = 0;
    errno = EINVAL;
    return -1;
}

void iol_toiov(struct iolist *first, struct iovec *iov) {
    while(first) {
        iov->iov_base = first->iol_base;
        iov->iov_len = first->iol_len;
        ++iov;
        first = first->iol_next;
    }
}

void iol_copy(struct iolist *first, uint8_t *dst) {
    while(first) {
        memcpy(dst, first->iol_base, first->iol_len);
        dst += first->iol_len;
        first = first->iol_next;
    }
}

void iol_slice_init(struct iol_slice *self, struct iolist *first,
      struct iolist *last, size_t offset, size_t len) {
    struct iolist *it = first;
    while(offset >= it->iol_len) {
        offset -= it->iol_len;
        it = it->iol_next;
        dsock_assert(it);
    }
    self->first = *it;
    self->first.iol_base += offset;
    self->first.iol_len -= offset;
    self->first.iol_rsvd = 0;
    it = &self->first;
    while(len > it->iol_len) {
        len -= it->iol_len;
        it = it->iol_next;
        dsock_assert(it);
    }
    self->oldlast = *it;
    self->last = it;
    it->iol_len = len;
    it->iol_next = NULL;
}

void iol_slice_term(struct iol_slice *self) {
    *self->last = self->oldlast;
}

