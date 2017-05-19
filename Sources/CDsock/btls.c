/*

  Copyright (c) 2016 Tai Chi Minh Ralph Eastwood

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

#include "tls/tls.h"

#include "dsock.h"
#include "iol.h"
#include "utils.h"

/* This symbol is secretly exported from libdill. More thinking should be
   done on how to do this kind of thing without breaking the encapsulation. */
extern const void *tcp_type;
extern const void *tcp_listener_type;
int tcp_fd(int s);

static int btls_init();
static struct tls_config *btls_configure(uint64_t flags, uint64_t ciphers,
      struct btls_kp *kp, size_t kplen, struct btls_ca *ca, const char *alpn);
static int btls_conn_create(int s, struct tls *tls, struct tls_config *c,
      const char *servername);
static int btls_listener_create(int s, struct tls *tls, struct tls_config *c,
      const char *servername);
static int btls_wait_close(struct tls *tls, int fd, int64_t deadline);

struct btls_rxbuf {
    size_t len;
    size_t pos;
    uint8_t data[2000];
};

/******************************************************************************/
/*  TLS connection socket                                                     */
/******************************************************************************/

dsock_unique_id(btls_conn_type);

static void *btls_conn_hquery(struct hvfs *hvfs, const void *type);
static void btls_conn_hclose(struct hvfs *hvfs);
static int btls_conn_bsendl(struct bsock_vfs *bvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);
static ssize_t btls_conn_brecvl(struct bsock_vfs *bvfs,
    struct iolist *first, struct iolist *last, int64_t deadline);

struct btls_conn {
    struct hvfs hvfs;
    struct bsock_vfs bvfs;
    struct btls_rxbuf rxbuf;
    struct tls_config *c;
    struct tls *tls;
    int s, fd, handshake;
    const char *servername;
};

static int btls_conn_handshake(struct btls_conn *obj, int64_t deadline);
static ssize_t btls_conn_brecv(struct btls_conn *obj, void *buf, size_t len,
    int64_t deadline);

static int btls_wait_close(struct tls *tls, int fd, int64_t deadline) {
    while(1) {
        ssize_t rc = tls_close(tls);
        if(rc == TLS_WANT_POLLIN)
            rc = fdin(fd, deadline);
        else if(rc == TLS_WANT_POLLOUT)
            rc = fdout(fd, deadline);
        if(rc == 0) {
            tls_free(tls);
            return 0;
        } else
            return -1;
    }
}

static void *btls_conn_hquery(struct hvfs *hvfs, const void *type) {
    struct btls_conn *obj = (struct btls_conn *)hvfs;
    if(type == bsock_type) return &obj->bvfs;
    if(type == btls_conn_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

static void btls_conn_hclose(struct hvfs *hvfs) {
    struct btls_conn *obj = (struct btls_conn *)hvfs;
    btls_wait_close(obj->tls, obj->fd, 0);
    if(obj->c) tls_config_free(obj->c);
    int rc = hclose(obj->s);
    dsock_assert(rc == 0);
    free(obj);
}

static int btls_conn_handshake(struct btls_conn *obj, int64_t deadline) {
    errno = 0;
    while(!obj->handshake && errno != ETIMEDOUT) {
        int rc = tls_handshake(obj->tls);
        if(rc == TLS_WANT_POLLIN) rc = fdin(obj->fd, deadline);
        else if(rc == TLS_WANT_POLLOUT) rc = fdout(obj->fd, deadline);
        else if(rc == 0) obj->handshake = 1;
        else {errno = ECONNRESET; return -1;}
    }
    return 0;
}

static ssize_t btls_conn_get(struct btls_conn *obj, void *buf, size_t len,
      int block, int64_t deadline) {
    size_t pos = 0;
    if(btls_conn_handshake(obj, deadline)) return -1;
    while(1) {
        ssize_t rc = tls_read(obj->tls, buf + pos, len);
        if(rc == TLS_WANT_POLLIN)
            rc = fdin(obj->fd, deadline);
        else if(rc == TLS_WANT_POLLOUT)
            rc = fdout(obj->fd, deadline);
        else if(dsock_slow(rc < 0))
            return -1;
        else if(dsock_slow(rc == 0)) {
            errno = ECONNRESET;
            return -1;
        } else if(dsock_fast(rc == len))
            return pos + rc;
        else if(dsock_fast(rc > 0)) {
            if(!block) return rc;
            pos += rc;
            len -= rc;
        }
        if(dsock_slow(rc < 0)) return -1;
    }
}

static int btls_conn_bsendl(struct bsock_vfs *bvfs, struct iolist *first,
      struct  iolist *last, int64_t deadline) {
    struct btls_conn *obj = dsock_cont(bvfs, struct btls_conn, bvfs);
    int rc = iol_check(first, last, NULL, NULL);
    if(dsock_slow(rc < 0)) return -1;
    if(btls_conn_handshake(obj, deadline)) return -1;
    struct iolist *it;
    for(it = first; it; it = it->iol_next) {
        uint8_t *base = it->iol_base;
        size_t len = it->iol_len;
        while(len) {
            rc = tls_write(obj->tls, base, len);
            if(rc == TLS_WANT_POLLIN) {
                rc = fdin(obj->fd, deadline);
                if(dsock_slow(rc < 0)) return -1;
                continue;
            }
            if(rc == TLS_WANT_POLLOUT) {
                rc = fdout(obj->fd, deadline);
                if(dsock_slow(rc < 0)) return -1;
                continue;
            }
            if(dsock_slow(rc < 0)) return -1;
            base += rc;
            len -= rc;
        }
    }
    return 0;
}

static ssize_t btls_conn_brecv(struct btls_conn *obj, void *buf, size_t len,
      int64_t deadline) {
    size_t pos = 0;
    struct btls_rxbuf *rxbuf = &obj->rxbuf;
    size_t read = 0;
    while(1) {
        /* Use data from rxbuf. */
        size_t remaining = rxbuf->len - rxbuf->pos;
        size_t tocopy = remaining < len ? remaining : len;
        memcpy(buf + pos, (char*)(rxbuf->data) + rxbuf->pos, tocopy);
        rxbuf->pos += tocopy;
        pos += tocopy;
        len -= tocopy;
        read += tocopy;
        if(!len) return read;
        /* If requested amount of data is large avoid the copy
           and read it directly into user's buffer. */
        if(len >= sizeof(rxbuf->data)) {
            ssize_t sz = btls_conn_get(obj, buf + pos, len, 1, deadline);
            if(dsock_slow(sz < 0)) return -1;
            read += sz;
            return read;
        }
        /* Read as much data as possible into rxbuf. */
        dsock_assert(rxbuf->len == rxbuf->pos);
        ssize_t sz = btls_conn_get(obj, rxbuf->data, sizeof(rxbuf->data), 0,
            deadline);
        if(dsock_slow(sz < 0)) return -1;
        read += sz;
        rxbuf->len = sz;
        rxbuf->pos = 0;
    }
}

static ssize_t btls_conn_brecvl(struct bsock_vfs *bvfs,
    struct iolist *first, struct iolist *last, int64_t deadline) {
    struct btls_conn *obj = dsock_cont(bvfs, struct btls_conn, bvfs);
    int rc = iol_check(first, last, NULL, NULL);
    if(dsock_slow(rc < 0)) return -1;
    struct iolist *it;
    ssize_t read = 0;
    for(it = first; it; it = it->iol_next) {
        rc = btls_conn_brecv(obj, it->iol_base, it->iol_len, deadline);
        if(dsock_slow(rc < 0)) return -1;
        read += rc;
    }
    return read;
}

static int btls_conn_create(int s, struct tls *t, struct tls_config *c,
      const char *servername) {
    /* Check whether underlying socket is a TCP socket. */
    if(dsock_slow(!hquery(s, tcp_type))) return -1;
    struct btls_conn *obj = malloc(sizeof(struct btls_conn));
    obj->hvfs.query = btls_conn_hquery;
    obj->hvfs.close = btls_conn_hclose;
    obj->bvfs.bsendl = btls_conn_bsendl;
    obj->bvfs.brecvl = btls_conn_brecvl;
    obj->tls = t;
    obj->s = s;
    obj->c = c;
    obj->fd = tcp_fd(s);
    obj->handshake = 0;
    obj->servername = servername;
    obj->rxbuf.len = 0;
    obj->rxbuf.pos = 0;
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

int btls_attach_client(int s, uint64_t flags, uint64_t ciphers,
      struct btls_ca *ca, const char *alpn, const char *servername) {
    return btls_attach_client_kp(s, flags, ciphers, NULL, 0, ca, alpn,
        servername);
}

int btls_attach_client_kp(int s, uint64_t flags, uint64_t ciphers,
      struct btls_kp *kp, size_t kplen, struct btls_ca *ca, const char *alpn,
      const char *servername) {
    struct tls *t = NULL;
    struct tls_config *c = NULL;
    const char *emsg;
    if(btls_init()) return -1;
    /* Check whether underlying socket is a TCP socket. */
    if(dsock_slow(!hquery(s, tcp_type))) return -1;
    /* Generate configuration for the server. */
    c = btls_configure(flags, ciphers, kp, kplen, ca, alpn);
    if(!c) {errno = ENOMEM; goto error;}
    /* Create the client tls context. */
    t = tls_client();
    if(!t) {errno = ENOMEM; goto error;}
    /* Apply the configuration to the server. */
    if(tls_configure(t, c)) {errno = ENOTSUP; goto error;}
    /* Clear keys from memory. */
    if(flags & DSOCK_BTLS_CLEAR_KEYS)
        tls_config_clear_keys(c);
    /* Connect to the server. */
    int rc = tls_connect_socket(t, tcp_fd(s), servername);
    if(rc == -1) goto error;
    /* Create the btls object. */
    int h = btls_conn_create(s, t, c, servername);
    if(h == -1) goto error;
    return h;
error:
    /* cannot handle errors in the start routine, so dump them */
    emsg = tls_config_error(c);
    if(!emsg) emsg = tls_error(t);
    if(emsg) fprintf(stderr, "tls error: %s\n", emsg);
    if(t) btls_wait_close(t, tcp_fd(s), 0);
    if(c) tls_config_free(c);
    return -1;
}

/******************************************************************************/
/*  TLS listener socket                                                       */
/******************************************************************************/

dsock_unique_id(btls_listener_type);

static void *btls_listener_hquery(struct hvfs *hvfs, const void *type);
static void btls_listener_hclose(struct hvfs *hvfs);

struct btls_listener {
    struct hvfs hvfs;
    struct tls_config *c;
    struct tls *tls;
    int s, fd;
};

static void *btls_listener_hquery(struct hvfs *hvfs, const void *type) {
    struct btls_listener *obj = (struct btls_listener*)hvfs;
    if(type == btls_listener_type) return obj;
    errno = ENOTSUP;
    return NULL;
}

static void btls_listener_hclose(struct hvfs *hvfs) {
    struct btls_listener *obj = (struct btls_listener*)hvfs;
    btls_wait_close(obj->tls, obj->fd, 0);
    dsock_assert(obj->c);
    tls_config_free(obj->c);
    int rc = hclose(obj->s);
    dsock_assert(rc == 0);
    free(obj);
}

static int btls_listener_create(int s, struct tls *tls, struct tls_config *c,
      const char *servername) {
    /* Check whether underlying socket is a TCP listener socket. */
    if(dsock_slow(!hquery(s, tcp_listener_type))) return -1;
    /* Create the object. */
    struct btls_listener *obj = malloc(sizeof(struct btls_listener));
    obj->hvfs.query = btls_listener_hquery;
    obj->hvfs.close = btls_listener_hclose;
    obj->tls = tls;
    obj->s = s;
    obj->c = c;
    obj->fd = tcp_fd(s);
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

int btls_attach_server(int s, uint64_t flags, uint64_t ciphers,
      struct btls_kp *kp, size_t kplen, struct btls_ca *ca, const char *alpn) {
    struct tls *t = NULL;
    struct tls_config *c = NULL;
    const char *emsg;
    if(btls_init()) return -1;
    /* Check whether underlying socket is a TCP listener socket. */
    if(dsock_slow(!hquery(s, tcp_listener_type))) return -1;
    /* Create the server tls context. */
    t = tls_server();
    if(!t) {errno = ENOMEM; goto error;}
    /* Generate configuration for the server. */
    if(!kp || !kplen) {errno = EINVAL; goto error;};
    c = btls_configure(flags, ciphers, kp, kplen, ca, alpn);
    if(!c) {errno = ENOMEM; goto error;}
    /* Apply the configuration to the server. */
    if(tls_configure(t, c) == -1) {errno = ENOTSUP; goto error;}
    /* Clear keys from memory. */
    if(flags & DSOCK_BTLS_CLEAR_KEYS)
        tls_config_clear_keys(c);
    /* Create the btls object. */
    int h = btls_listener_create(s, t, c, NULL);
    if(h == -1) goto error;
    return h;
error:
    /* cannot handle errors in the start routine, so dump them */
    emsg = tls_config_error(c);
    if(!emsg) emsg = tls_error(t);
    if(emsg) fprintf(stderr, "tls error: %s\n", emsg);
    if(t) btls_wait_close(t, tcp_fd(s), 0);
    if(c) tls_config_free(c);
    return -1;
}

int btls_attach_accept(int s, int l) {
    /* Check whether underlying socket is a TCP socket. */
    if(dsock_slow(!hquery(s, tcp_type))) return -1;
    /* Check whether passed socket is a configured btls. */
    struct btls_listener *listener = hquery(l, btls_listener_type);
    if(dsock_slow(!listener)) return -1;
    /* Accept socket and create server connection context. */
    struct tls *t = NULL;
    int rc = tls_accept_socket(listener->tls, &t, tcp_fd(s));
    if(rc == -1) return -1;
    /* Create the btls object. */
    int h = btls_conn_create(s, t, NULL, NULL);
    if(h == -1) {
        btls_wait_close(t, tcp_fd(s), 0);
        return -1;
    }
    return h;
}

/******************************************************************************/
/*  TLS common functions                                                      */
/******************************************************************************/

static int btls_init() {
    static int init = 0;
    if(dsock_fast(init))
        return 0;
    int rc = tls_init();
    init = !rc;
    return rc;
}

int btls_ca(struct btls_ca *ca, const char *file, const char *path,
      const uint8_t *mem, size_t len) {
    if(dsock_slow(!ca)) {errno = EINVAL; return -1;}
    ca->file = file;
    ca->path = path;
    ca->mem = mem;
    ca->len = len;
    return 0;
}

int btls_kp(struct btls_kp *kp, const uint8_t *cert, size_t certlen,
      const uint8_t *key, size_t keylen) {
    if(dsock_slow(!kp)) {errno = EINVAL; return -1;}
    kp->certmem = cert;
    kp->certlen = certlen;
    kp->keymem = key;
    kp->keylen = keylen;
    return 0;
}

const char *btls_error(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(c) return tls_error(c->tls);
    struct btls_listener *l = hquery(s, btls_listener_type);
    if(l) return tls_error(l->tls);
    return NULL;
}

int btls_detach(int s, int64_t deadline) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(c) {
        int rc = btls_wait_close(c->tls, c->fd, deadline);
        int tmp_errno = errno;
        if(c->c) tls_config_free(c->c);
        int underlying_fd = c->s;
        c->s = -1;
        free(c);
        if(rc < 0) {
            hclose(underlying_fd);
            errno = tmp_errno;
            return -1;
        } else {
            return underlying_fd;
        }
    }
    struct btls_listener *l = hquery(s, btls_listener_type);
    if(l) {
        int rc = btls_wait_close(l->tls, l->fd, deadline);
        int tmp_errno = errno;
        if(l->c) tls_config_free(l->c);
        int underlying_fd = l->s;
        l->s = -1;
        free(l);
        if(rc < 0) {
            hclose(underlying_fd);
            errno = tmp_errno;
            return -1;
        } else {
            return underlying_fd;
        }
    }
    return -1;
}

void btls_reset(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return;}
    return tls_reset(c->tls);
}

int btls_handshake(int s, int64_t deadline) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return -1;}
    return btls_conn_handshake(c, deadline);
}

int btls_peercertprovided(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return -1;}
    return tls_peer_cert_provided(c->tls);
}

int btls_peercertcontainsname(int s, const char *name) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return -1;}
    return tls_peer_cert_contains_name(c->tls, name);
}

const char *btls_peercerthash(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return NULL;}
    return tls_peer_cert_hash(c->tls);
}

const char *btls_peercertissuer(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return NULL;}
    return tls_peer_cert_issuer(c->tls);
}

const char *btls_peercertsubject(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return NULL;}
    return tls_peer_cert_subject(c->tls);
}

time_t btls_peercertnotbefore(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return -1;}
    return tls_peer_cert_notbefore(c->tls);
}

time_t btls_peercertnotafter(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return -1;}
    return tls_peer_cert_notafter(c->tls);
}

const char *btls_connalpnselected(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return NULL;}
    return tls_conn_alpn_selected(c->tls);
}

const char *btls_conncipher(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return NULL;}
    return tls_conn_cipher(c->tls);
}

const char *btls_connservername(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return NULL;}
    return tls_conn_servername(c->tls);
}

const char *btls_connversion(int s) {
    struct btls_conn *c = hquery(s, btls_conn_type);
    if(dsock_slow(!c)) {errno = ENOTSUP; return NULL;}
    return tls_conn_version(c->tls);
}

uint8_t *btls_loadfile(const char *file, size_t *len, char *password) {
    return tls_load_file(file, len, password);
}

#define strappend(p,b,s) strncpy(p, s, sizeof(b) - (p - b))
static struct tls_config *btls_configure(uint64_t flags, uint64_t ciphers,
      struct btls_kp *kp, size_t kplen, struct btls_ca *ca, const char *alpn) {
    /* create the configuration */
    struct tls_config *c = tls_config_new();
    if(!c) {errno = ENOMEM; goto err;};
    if(kplen) {
        tls_config_set_keypair_mem(c, kp->certmem, kp->certlen,
            kp->keymem, kp->keylen);
        kp++;
        for(size_t i = 1; i < kplen; ++i, ++kp) {
            if(tls_config_add_keypair_mem(c, kp->certmem, kp->certlen,
                kp->keymem, kp->keylen)) {
                errno = ENOMEM;
                goto err;
            }
        }
    }
    if(ca && ((ca->path && tls_config_set_ca_path(c, ca->path)) ||
        (ca->file && tls_config_set_ca_file(c, ca->file)) ||
        (ca->mem && ca->len && tls_config_set_ca_mem(c, ca->mem , ca->len)))) {
        errno = ENOMEM;
        goto err;
    }
    int proto = DSOCK_BTLS_PROTO_VALUE(flags);
    tls_config_set_protocols(c, proto ? proto : DSOCK_BTLS_PROTO_DEFAULT);
    const char *dheparams;
    switch(DSOCK_BTLS_DHEPARAMS_VALUE(flags)) {
        case DSOCK_BTLS_DHEPARAMS_AUTO: dheparams = "auto"; break;
        case DSOCK_BTLS_DHEPARAMS_LEGACY: dheparams = "legacy"; break;
        default: dheparams = "none";
    }
    tls_config_set_dheparams(c, dheparams);
    const char *ecdhecurve;
    switch(DSOCK_BTLS_ECDHECURVE_VALUE(flags)) {
        case DSOCK_BTLS_ECDHECURVE_NONE: ecdhecurve = "none"; break;
        case DSOCK_BTLS_ECDHECURVE_SECP192R1: ecdhecurve = "secp192r1"; break;
        case DSOCK_BTLS_ECDHECURVE_SECP224R1: ecdhecurve = "secp224r1"; break;
        case DSOCK_BTLS_ECDHECURVE_SECP224K1: ecdhecurve = "secp224k1"; break;
        case DSOCK_BTLS_ECDHECURVE_SECP256R1: ecdhecurve = "secp256r1"; break;
        case DSOCK_BTLS_ECDHECURVE_SECP256K1: ecdhecurve = "secp256k1"; break;
        case DSOCK_BTLS_ECDHECURVE_SECP384R1: ecdhecurve = "secp384r1"; break;
        case DSOCK_BTLS_ECDHECURVE_SECP521R1: ecdhecurve = "secp521r1"; break;
        default: ecdhecurve = "auto";
    }
    tls_config_set_ecdhecurve(c, ecdhecurve);
    switch(DSOCK_BTLS_CIPHERS_VALUE(flags)) {
        case DSOCK_BTLS_CIPHERS_COMPAT:
            tls_config_set_ciphers(c, "compat"); break;
        case DSOCK_BTLS_CIPHERS_LEGACY:
            tls_config_set_ciphers(c, "legacy"); break;
        case DSOCK_BTLS_CIPHERS_INSECURE:
            tls_config_set_ciphers(c, "insecure"); break;
        case DSOCK_BTLS_CIPHERS_SPECIFIC: {
            char cl[2048]; char *p = cl;
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_RSA_AES256_GCM_SHA384)
                p = strappend(p, cl, "ECDHE-RSA-AES256-GCM-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_ECDSA_AES256_GCM_SHA384)
                p = strappend(p, cl, "ECDHE-ECDSA-AES256-GCM-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_RSA_AES256_SHA384)
                p = strappend(p, cl, "ECDHE-RSA-AES256-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_ECDSA_AES256_SHA384)
                p = strappend(p, cl, "ECDHE-ECDSA-AES256-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_DSS_AES256_GCM_SHA384)
                p = strappend(p, cl, "DHE-DSS-AES256-GCM-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_RSA_AES256_GCM_SHA384)
                p = strappend(p, cl, "DHE-RSA-AES256-GCM-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_RSA_AES256_SHA256)
                p = strappend(p, cl, "DHE-RSA-AES256-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_DSS_AES256_SHA256)
                p = strappend(p, cl, "DHE-DSS-AES256-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_ECDSA_CHACHA20_POLY1305)
                p = strappend(p, cl, "ECDHE-ECDSA-CHACHA20-POLY1305:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_RSA_CHACHA20_POLY1305)
                p = strappend(p, cl, "ECDHE-RSA-CHACHA20-POLY1305:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_RSA_CHACHA20_POLY1305)
                p = strappend(p, cl, "DHE-RSA-CHACHA20-POLY1305:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_ECDSA_CHACHA20_POLY1305_OLD)
                p = strappend(p, cl, "ECDHE-ECDSA-CHACHA20-POLY1305-OLD:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_RSA_CHACHA20_POLY1305_OLD)
                p = strappend(p, cl, "ECDHE-RSA-CHACHA20-POLY1305-OLD:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_RSA_CHACHA20_POLY1305_OLD)
                p = strappend(p, cl, "DHE-RSA-CHACHA20-POLY1305-OLD:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_RSA_CAMELLIA256_SHA256)
                p = strappend(p, cl, "DHE-RSA-CAMELLIA256-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_DSS_CAMELLIA256_SHA256)
                p = strappend(p, cl, "DHE-DSS-CAMELLIA256-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDH_RSA_AES256_GCM_SHA384)
                p = strappend(p, cl, "ECDH-RSA-AES256-GCM-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDH_ECDSA_AES256_GCM_SHA384)
                p = strappend(p, cl, "ECDH-ECDSA-AES256-GCM-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDH_RSA_AES256_SHA384)
                p = strappend(p, cl, "ECDH-RSA-AES256-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDH_ECDSA_AES256_SHA384)
                p = strappend(p, cl, "ECDH-ECDSA-AES256-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_AES256_GCM_SHA384)
                p = strappend(p, cl, "AES256-GCM-SHA384:");
            if(ciphers & DSOCK_BTLS_CIPHERS_AES256_SHA256)
                p = strappend(p, cl, "AES256-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_CAMELLIA256_SHA256)
                p = strappend(p, cl, "CAMELLIA256-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_RSA_AES128_GCM_SHA256)
                p = strappend(p, cl, "ECDHE-RSA-AES128-GCM-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_ECDSA_AES128_GCM_SHA256)
                p = strappend(p, cl, "ECDHE-ECDSA-AES128-GCM-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_RSA_AES128_SHA256)
                p = strappend(p, cl, "ECDHE-RSA-AES128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDHE_ECDSA_AES128_SHA256)
                p = strappend(p, cl, "ECDHE-ECDSA-AES128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_DSS_AES128_GCM_SHA256)
                p = strappend(p, cl, "DHE-DSS-AES128-GCM-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_RSA_AES128_GCM_SHA256)
                p = strappend(p, cl, "DHE-RSA-AES128-GCM-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_RSA_AES128_SHA256)
                p = strappend(p, cl, "DHE-RSA-AES128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_DSS_AES128_SHA256)
                p = strappend(p, cl, "DHE-DSS-AES128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_RSA_CAMELLIA128_SHA256)
                p = strappend(p, cl, "DHE-RSA-CAMELLIA128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_DHE_DSS_CAMELLIA128_SHA256)
                p = strappend(p, cl, "DHE-DSS-CAMELLIA128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDH_RSA_AES128_GCM_SHA256)
                p = strappend(p, cl, "ECDH-RSA-AES128-GCM-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDH_ECDSA_AES128_GCM_SHA256)
                p = strappend(p, cl, "ECDH-ECDSA-AES128-GCM-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDH_RSA_AES128_SHA256)
                p = strappend(p, cl, "ECDH-RSA-AES128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_ECDH_ECDSA_AES128_SHA256)
                p = strappend(p, cl, "ECDH-ECDSA-AES128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_AES128_GCM_SHA256)
                p = strappend(p, cl, "AES128-GCM-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_AES128_SHA256)
                p = strappend(p, cl, "AES128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_CAMELLIA128_SHA256)
                p = strappend(p, cl, "CAMELLIA128-SHA256:");
            if(ciphers & DSOCK_BTLS_CIPHERS_AES256_SHA)
                p = strappend(p, cl, "AES256-SHA:");
            if(p != cl) {
                dsock_assert(p - cl <= sizeof(cl));
                *(p - 1) = '\0'; /* remove last ':' */
            }
            tls_config_set_ciphers(c, cl);
            break;
        }
        default: tls_config_set_ciphers(c, "secure");
    }
    if(DSOCK_BTLS_VERIFY_DEPTH(flags) == 0)
        flags |= DSOCK_BTLS_VERIFY_DEPTH_DEFAULT;
    tls_config_set_verify_depth(c, DSOCK_BTLS_VERIFY_VALUE(flags));
    if(flags & DSOCK_BTLS_PREFER_CIPHERS_SERVER)
        tls_config_prefer_ciphers_server(c);
    else
        tls_config_prefer_ciphers_client(c);
    if(flags & DSOCK_BTLS_NO_VERIFY_CERT)
        tls_config_insecure_noverifycert(c);
    if(flags & DSOCK_BTLS_NO_VERIFY_NAME)
        tls_config_insecure_noverifyname(c);
    if(flags & DSOCK_BTLS_NO_VERIFY_TIME)
        tls_config_insecure_noverifytime(c);
    if(alpn && tls_config_set_alpn(c, alpn)) {
        errno = ENOMEM;
        goto err;
    }
    return c;
err:
    return NULL;
}
