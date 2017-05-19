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

#include <fcntl.h>
#include "libdill.h"
#include <string.h>
#include <unistd.h>

#include "fd.h"
#include "iol.h"
#include "utils.h"

#if defined MSG_NOSIGNAL
#define FD_NOSIGNAL MSG_NOSIGNAL
#else
#define FD_NOSIGNAL 0
#endif

void fd_initrxbuf(struct fd_rxbuf *rxbuf) {
    dsock_assert(rxbuf);
    rxbuf->len = 0;
    rxbuf->pos = 0;
}

int fd_unblock(int s) {
    /* Switch to non-blocking mode. */
    int opt = fcntl(s, F_GETFL, 0);
    if (opt == -1)
        opt = 0;
    int rc = fcntl(s, F_SETFL, opt | O_NONBLOCK);
    dsock_assert(rc == 0);
    /*  Allow re-using the same local address rapidly. */
    opt = 1;
    rc = setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof (opt));
    dsock_assert(rc == 0);
    /* If possible, prevent SIGPIPE signal when writing to the connection
        already closed by the peer. */
#ifdef SO_NOSIGPIPE
    opt = 1;
    rc = setsockopt (s, SOL_SOCKET, SO_NOSIGPIPE, &opt, sizeof (opt));
    dsock_assert (rc == 0 || errno == EINVAL);
#endif
    return 0;
}

int fd_connect(int s, const struct sockaddr *addr, socklen_t addrlen,
      int64_t deadline) {
    /* Initiate connect. */
    int rc = connect(s, addr, addrlen);
    if(rc == 0) return 0;
    if(dsock_slow(errno != EINPROGRESS)) return -1;
    /* Connect is in progress. Let's wait till it's done. */
    rc = fdout(s, deadline);
    if(dsock_slow(rc == -1)) return -1;
    /* Retrieve the error from the socket, if any. */
    int err = 0;
    socklen_t errsz = sizeof(err);
    rc = getsockopt(s, SOL_SOCKET, SO_ERROR, (void*)&err, &errsz);
    if(dsock_slow(rc != 0)) return -1;
    if(dsock_slow(err != 0)) {errno = err; return -1;}
    return 0;
}

int fd_accept(int s, struct sockaddr *addr, socklen_t *addrlen,
      int64_t deadline) {
    int as;
    while(1) {
        /* Try to accept new connection synchronously. */
        as = accept(s, addr, addrlen);
        if(dsock_fast(as >= 0))
            break;
        /* If connection was aborted by the peer grab the next one. */
        if(dsock_slow(errno == ECONNABORTED)) continue;
        /* Propagate other errors to the caller. */
        if(dsock_slow(errno != EAGAIN && errno != EWOULDBLOCK)) return -1;
        /* Operation is in progress. Wait till new connection is available. */
        int rc = fdin(s, deadline);
        if(dsock_slow(rc < 0)) return -1;
    }
    int rc = fd_unblock(as);
    dsock_assert(rc == 0);
    return as;
}

int fd_send(int s, struct iolist *first, struct iolist *last,
      int64_t deadline) {
    /* Make a local iovec array. */
    /* TODO: This is dangerous, it may cause stack overflow.
       There should probably be a on-heap per-socket buffer for that. */
    size_t niov;
    int rc = iol_check(first, last, &niov, NULL);
    if(dsock_slow(rc < 0)) return -1;
    struct iovec iov[niov];
    iol_toiov(first, iov);
    /* Message header will act as an iterator in the following loop. */
    struct msghdr hdr;
    memset(&hdr, 0, sizeof(hdr));
    hdr.msg_iov = iov;
    hdr.msg_iovlen = niov;
    /* It is very likely that at least one byte can be sent. Therefore,
       to improve efficiency, try to send and resort to fdout() only after
       send failed. */
    while(1) {
        ssize_t sz = sendmsg(s, &hdr, FD_NOSIGNAL);
        if(sz < 0) {
            if(dsock_slow(errno != EWOULDBLOCK && errno != EAGAIN)) {
                if(errno == EPIPE) errno = ECONNRESET;
                return -1;
            }
            sz = 0;
        }
        /* Adjust the iovec array so that it doesn't contain data
           that was already sent. */
        while(sz) {
            struct iovec *head = &hdr.msg_iov[0];
            if(head->iov_len > sz) {
                head->iov_base += sz;
                head->iov_len -= sz;
                break;
            }
            sz -= head->iov_len;
            hdr.msg_iov++;
            hdr.msg_iovlen--;
            if(!hdr.msg_iovlen) return 0;
        }
        /* Wait till more data can be sent. */
        int rc = fdout(s, deadline);
        if(dsock_slow(rc < 0)) return -1;
    }
}

/* Same as fd_recv() but with no rx buffering. */
static int fd_recv_(int s, struct iolist *first, struct iolist *last,
      int64_t deadline) {
    /* Make a local iovec array. */
    /* TODO: This is dangerous, it may cause stack overflow.
       There should probably be a on-heap per-socket buffer for that. */
    size_t niov;
    int rc = iol_check(first, last, &niov, NULL);
    if(dsock_slow(rc < 0)) return -1;
    struct iovec iov[niov];
    iol_toiov(first, iov);
    /* Message header will act as an iterator in the following loop. */
    struct msghdr hdr;
    memset(&hdr, 0, sizeof(hdr));
    hdr.msg_iov = iov;
    hdr.msg_iovlen = niov;
    while(1) {
        ssize_t sz = recvmsg(s, &hdr, 0);
        if(dsock_slow(sz == 0)) {errno = EPIPE; return -1;}
        if(sz < 0) {
            if(dsock_slow(errno != EWOULDBLOCK && errno != EAGAIN)) {
                if(errno == EPIPE) errno = ECONNRESET;
                return -1;
            }
            sz = 0;
        }
        /* Adjust the iovec array so that it doesn't contain buffers
           that ware already filled in. */
        while(sz) {
            struct iovec *head = &hdr.msg_iov[0];
            if(head->iov_len > sz) {
                head->iov_base += sz;
                head->iov_len -= sz;
                break;
            }
            sz -= head->iov_len;
            hdr.msg_iov++;
            hdr.msg_iovlen--;
            if(!hdr.msg_iovlen) return 0;
        }
        /* Wait for more data. */
        int rc = fdin(s, deadline);
        if(dsock_slow(rc < 0)) return -1;
    }
}

/* Copy data from rxbuf to one iolist structure.
   Returns number of bytes copied. */
static size_t fd_copy(struct fd_rxbuf *rxbuf, struct iolist *iol) {
    size_t rmn = rxbuf->len  - rxbuf->pos;
    if(rmn < iol->iol_len) {
        if(dsock_fast(iol->iol_base))
            memcpy(iol->iol_base, rxbuf->data + rxbuf->pos, rmn);
        rxbuf->len = 0;
        rxbuf->pos = 0;
        return rmn;
    }
    else {
        if(dsock_fast(iol->iol_base))
            memcpy(iol->iol_base, rxbuf->data + rxbuf->pos, iol->iol_len);
        rxbuf->pos += iol->iol_len;
        return iol->iol_len;
    }
}

int fd_recv(int s, struct fd_rxbuf *rxbuf, struct iolist *first,
      struct iolist *last, int64_t deadline) {
    /* Fill in data from the rxbuf. */
    size_t sz;
    while(1) {
        sz = fd_copy(rxbuf, first);
        if(sz < first->iol_len) break;
        first = first->iol_next;
        if(!first) return 0;
    }
    /* Copy the current iolist element so that we can modify it without
       changing the original list. */
    struct iolist curr;
    curr.iol_base = first->iol_base + sz;
    curr.iol_len = first->iol_len - sz;
    curr.iol_next = first->iol_next;
    curr.iol_rsvd = 0;
    /* Find out how much data is still missing. */
    size_t miss = 0;
    struct iolist *it = &curr;
    while(it) {
        miss += it->iol_len;
        it = it->iol_next;
    }
    /* If requested amount of data is larger than rx buffer avoid the copy
       and read it directly into user's buffer. */
    if(miss > sizeof(rxbuf->data)) return fd_recv_(s, &curr, last, deadline);
    /* If small amount of data is requested use rx buffer. */
    while(1) {
        /* Read as much data as possible to the buffer to avoid extra
           syscalls. Do the speculative recv() first to avoid extra
           polling. Do fdin() only after recv() fails to get data. */
        ssize_t sz = recv(s, rxbuf->data, sizeof(rxbuf->data), 0);
        if(dsock_slow(sz == 0)) {errno = EPIPE; return -1;}
        if(sz < 0) {
            if(dsock_slow(errno != EWOULDBLOCK && errno != EAGAIN)) {
                if(errno == EPIPE) errno = ECONNRESET;
                return -1;
            }
            sz = 0;
        }
        rxbuf->len = sz;
        rxbuf->pos = 0;
        /* Copy the data from rxbuffer to the iolist. */
        while(1) {
            sz = fd_copy(rxbuf, &curr);
            if(sz < curr.iol_len) break;
            if(!curr.iol_next) return 0;
            curr = *curr.iol_next;
        }
        curr.iol_base += sz;
        curr.iol_len -= sz;
        /* Wait for more data. */
        int rc = fdin(s, deadline);
        if(dsock_slow(rc < 0)) return -1;
    }
}

int fd_close(int s) {
    fdclean(s);
    /* Discard any pending outbound data. If SO_LINGER option cannot
       be set, never mind and continue anyway. */
    struct linger lng;
    lng.l_onoff=1;
    lng.l_linger=0;
    setsockopt(s, SOL_SOCKET, SO_LINGER, (void*)&lng, sizeof(lng));
    return close(s);
}

