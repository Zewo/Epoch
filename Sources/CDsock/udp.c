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
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "dsock.h"
#include "fd.h"
#include "iol.h"
#include "utils.h"

dsock_unique_id(udp_type);

static void *udp_hquery(struct hvfs *hvfs, const void *type);
static void udp_hclose(struct hvfs *hvfs);
static int udp_msendl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t udp_mrecvl(struct msock_vfs *mvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);

struct udp_sock {
    struct hvfs hvfs;
    struct msock_vfs mvfs;
    int fd;
    int hasremote;
    struct ipaddr remote;
};

static void *udp_hquery(struct hvfs *hvfs, const void *type) {
    struct udp_sock *obj = (struct udp_sock*)hvfs;
    if(type == msock_type) return &obj->mvfs;
    if(type == udp_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

int udp_open(struct ipaddr *local, const struct ipaddr *remote) {
    int err;
    /* Sanity checking. */
    if(dsock_slow(local && remote &&
          ipaddr_family(local) != ipaddr_family(remote))) {
        err = EINVAL; goto error1;}
    /* Open the listening socket. */
    int family = AF_INET;
    if(local) family = ipaddr_family(local);
    if(remote) family = ipaddr_family(remote);
    int s = socket(family, SOCK_DGRAM, 0);
    if(s < 0) {err = errno; goto error1;}
    /* Set it to non-blocking mode. */
    int rc = fd_unblock(s);
    if(dsock_slow(rc < 0)) {err = errno; goto error2;}
    /* Start listening. */
    if(local) {
        rc = bind(s, ipaddr_sockaddr(local), ipaddr_len(local));
        if(s < 0) {err = errno; goto error2;}
        /* Get the ephemeral port number. */
        if(ipaddr_port(local) == 0) {
            struct ipaddr baddr;
            socklen_t len = sizeof(struct ipaddr);
            rc = getsockname(s, (struct sockaddr*)&baddr, &len);
            if(dsock_slow(rc < 0)) {err = errno; goto error2;}
            ipaddr_setport(local, ipaddr_port(&baddr));
        }
    }
    /* Create the object. */
    struct udp_sock *obj = malloc(sizeof(struct udp_sock));
    if(dsock_slow(!obj)) {err = ENOMEM; goto error2;}
    obj->hvfs.query = udp_hquery;
    obj->hvfs.close = udp_hclose;
    obj->hvfs.done = NULL; /* hdone() is not supported for UDP sockets. */
    obj->mvfs.msendl = udp_msendl;
    obj->mvfs.mrecvl = udp_mrecvl;
    obj->fd = s;
    obj->hasremote = remote ? 1 : 0;
    if(remote) obj->remote = *remote;
    /* Create the handle. */
    int h = hmake(&obj->hvfs);
    if(dsock_slow(h < 0)) {err = errno; goto error3;}
    return h;
error3:
    free(obj);
error2:
    rc = fd_close(s);
    dsock_assert(rc == 0);
error1:
    errno = err;
    return -1;
}

int udp_sendl_(struct msock_vfs *mvfs, const struct ipaddr *addr,
      struct iolist *first, struct iolist *last) {
    struct udp_sock *obj = dsock_cont(mvfs, struct udp_sock, mvfs);
    /* If no destination IP address is provided, fall back to the stored one. */
    const struct ipaddr *dstaddr = addr;
    if(!dstaddr) {
        if(dsock_slow(!obj->hasremote)) {errno = EINVAL; return -1;}
        dstaddr = &obj->remote;
    }
    struct msghdr hdr;
    memset(&hdr, 0, sizeof(hdr));
    hdr.msg_name = (void*)ipaddr_sockaddr(dstaddr);
    hdr.msg_namelen = ipaddr_len(dstaddr);
    /* Make a local iovec array. */
    /* TODO: This is dangerous, it may cause stack overflow.
       There should probably be a on-heap per-socket buffer for that. */
    size_t niov;
    int rc = iol_check(first, last, &niov, NULL);
    if(dsock_slow(rc < 0)) return -1;
    struct iovec iov[niov];
    iol_toiov(first, iov);
    hdr.msg_iov = (struct iovec*)iov;
    hdr.msg_iovlen = niov;
    ssize_t sz = sendmsg(obj->fd, &hdr, 0);
    if(dsock_fast(sz >= 0)) return 0;
    if(errno == EAGAIN || errno == EWOULDBLOCK) return 0;
    return -1;
}

ssize_t udp_recvl_(struct msock_vfs *mvfs, struct ipaddr *addr,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct udp_sock *obj = dsock_cont(mvfs, struct udp_sock, mvfs);
    struct msghdr hdr;
    memset(&hdr, 0, sizeof(hdr));
    hdr.msg_name = (void*)addr;
    hdr.msg_namelen = sizeof(struct ipaddr);
    /* Make a local iovec array. */
    /* TODO: This is dangerous, it may cause stack overflow.
       There should probably be a on-heap per-socket buffer for that. */
    size_t niov;
    int rc = iol_check(first, last, &niov, NULL);
    if(dsock_slow(rc < 0)) return -1;
    struct iovec iov[niov];
    iol_toiov(first, iov);
    hdr.msg_iov = (struct iovec*)iov;
    hdr.msg_iovlen = niov;
    while(1) {
        ssize_t sz = recvmsg(obj->fd, &hdr, 0);
        if(sz >= 0) return sz;
        if(errno != EAGAIN && errno != EWOULDBLOCK) return -1;
        rc = fdin(obj->fd, deadline);
        if(dsock_slow(rc < 0)) return -1;
    }
}

int udp_send(int s, const struct ipaddr *addr, const void *buf, size_t len) {
    struct msock_vfs *m = hquery(s, msock_type);
    if(dsock_slow(!m)) return -1;
    struct iolist iol = {(void*)buf, len, NULL, 0};
    return udp_sendl_(m, addr, &iol, &iol);
}

ssize_t udp_recv(int s, struct ipaddr *addr, void *buf, size_t len,
      int64_t deadline) {
    struct msock_vfs *m = hquery(s, msock_type);
    if(dsock_slow(!m)) return -1;
    struct iolist iol = {(void*)buf, len, NULL, 0};
    return udp_recvl_(m, addr, &iol, &iol, deadline);
}

int udp_sendl(int s, const struct ipaddr *addr,
      struct iolist *first, struct iolist *last) {
    struct msock_vfs *m = hquery(s, msock_type);
    if(dsock_slow(!m)) return -1;
    return udp_sendl_(m, addr, first, last);
}

ssize_t udp_recvl(int s, struct ipaddr *addr,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    struct msock_vfs *m = hquery(s, msock_type);
    if(dsock_slow(!m)) return -1;
    return udp_recvl_(m, addr, first, last, deadline);
}

static int udp_msendl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    return udp_sendl_(mvfs, NULL, first, last);
}

static ssize_t udp_mrecvl(struct msock_vfs *mvfs,
      struct iolist *first, struct iolist *last, int64_t deadline) {
    return udp_recvl_(mvfs, NULL, first, last, deadline);
}

static void udp_hclose(struct hvfs *hvfs) {
    struct udp_sock *obj = (struct udp_sock*)hvfs;
    /* We do not switch off linger here because if UDP socket was fully
       implemented in user space, msend() would block until the packet
       was flushed into network, thus providing some basic reliability.
       Kernel-space implementation here, on the other hand, may queue
       outgoing packets rather than flushing them. The effect is balanced
       out by lingering when closing the socket. */
    int rc = fd_close(obj->fd);
    dsock_assert(rc == 0);
    free(obj);
}

