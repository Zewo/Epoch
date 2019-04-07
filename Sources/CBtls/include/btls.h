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

#ifndef BTLS_H_INCLUDED
#define BTLS_H_INCLUDED

#include <libdill.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/socket.h>
#include <sys/types.h>

/******************************************************************************/
/*  Semantic Versioning - http://semver.org                                   */
/******************************************************************************/

#define BTLS_MAJOR 0
#define BTLS_MINOR 1
#define BTLS_PATCH 0
#define BTLS_SONAME 0.1

/******************************************************************************/
/*  Symbol visibility.                                                        */
/******************************************************************************/

#if !defined __GNUC__ && !defined __clang__
#error "Unsupported compiler!"
#endif

#if BTLS_NO_EXPORTS
#define BTLS_EXPORT
#else
#define BTLS_EXPORT __attribute__ ((visibility("default")))
#endif

/* Old versions of GCC don't support visibility attribute. */
#if defined __GNUC__ && __GNUC__ < 4
#undef BTLS_EXPORT
#define BTLS_EXPORT
#endif

/******************************************************************************/
/*  TLS sockets                                                               */
/******************************************************************************/

#define BTLS_PROTO_BTLSV1_0         (1 << 1)
#define BTLS_PROTO_BTLSV1_1         (1 << 2)
#define BTLS_PROTO_BTLSV1_2         (1 << 3)
#define BTLS_PROTO_BTLSV1 \
(BTLS_PROTO_BTLSV1_0|BTLS_PROTO_BTLSV1_1|BTLS_PROTO_BTLSV1_2)

#define BTLS_PROTO_ALL     BTLS_PROTO_BTLSV1
#define BTLS_PROTO_DEFAULT BTLS_PROTO_BTLSV1_2
#define BTLS_PROTO_VALUE(x)         (x & 0xf)

#define BTLS_FLAGS_RESERVED_0       (0 << 4) /* new TLS 1.3 */
#define BTLS_FLAGS_RESERVED_1       (0 << 5) /* new TLS ver? */

#define BTLS_PREFER_CIPHERS_CLIENT  (0 << 6) /* default */
#define BTLS_PREFER_CIPHERS_SERVER  (1 << 6)
#define BTLS_NO_VERIFY_CERT         (1 << 7)
#define BTLS_NO_VERIFY_NAME         (1 << 8)
#define BTLS_NO_VERIFY_TIME         (1 << 9)
#define BTLS_VERIFY_CLIENT          (1 << 10)
#define BTLS_VERIFY_CLIENT_OPTIONAL (1 << 11)
#define BTLS_CLEAR_KEYS             (1 << 12)

#define BTLS_DHEPARAMS_NONE         (0 << 13) /* default */
#define BTLS_DHEPARAMS_AUTO         (1 << 13)
#define BTLS_DHEPARAMS_LEGACY       (2 << 13)
#define BTLS_DHEPARAMS_VALUE(x)     ((x) & (0x3 << 13))

#define BTLS_ECDHECURVE_NONE        (1 << 15)
#define BTLS_ECDHECURVE_AUTO        (0 << 15) /* default */
#define BTLS_ECDHECURVE_SECP192R1   (2 << 15)
#define BTLS_ECDHECURVE_SECP224R1   (3 << 15)
#define BTLS_ECDHECURVE_SECP224K1   (4 << 15)
#define BTLS_ECDHECURVE_SECP256R1   (5 << 15)
#define BTLS_ECDHECURVE_SECP256K1   (6 << 15)
#define BTLS_ECDHECURVE_SECP384R1   (7 << 15)
#define BTLS_ECDHECURVE_SECP521R1   (8 << 15)
#define BTLS_ECDHECURVE_VALUE(x)    ((x) & (0xf << 15))

#define BTLS_CIPHERS_DEFAULT        (1 << 19)
#define BTLS_CIPHERS_SECURE         (1 << 19) /* default */
#define BTLS_CIPHERS_COMPAT         (2 << 19)
#define BTLS_CIPHERS_LEGACY         (3 << 19)
#define BTLS_CIPHERS_INSECURE       (4 << 19)
#define BTLS_CIPHERS_SPECIFIC       (5 << 19) /* see list below */
#define BTLS_CIPHERS_VALUE(x)       ((x) & (0x7 << 19))

#define BTLS_VERIFY_DEPTH_DEFAULT   (6 << 22)
#define BTLS_VERIFY_DEPTH(X)        (X << 22)
#define BTLS_VERIFY_DEPTH_MAX       (1 << 27)
#define BTLS_VERIFY_VALUE(x)        ((x) & (0x1f << 22))

/* BTLS v1.2 ciphers */
#define BTLS_CIPHERS_ECDHE_RSA_AES256_GCM_SHA384       (1ull <<  0)
#define BTLS_CIPHERS_ECDHE_ECDSA_AES256_GCM_SHA384     (1ull <<  1)
#define BTLS_CIPHERS_ECDHE_RSA_AES256_SHA384           (1ull <<  2)
#define BTLS_CIPHERS_ECDHE_ECDSA_AES256_SHA384         (1ull <<  3)
#define BTLS_CIPHERS_DHE_DSS_AES256_GCM_SHA384         (1ull <<  4)
#define BTLS_CIPHERS_DHE_RSA_AES256_GCM_SHA384         (1ull <<  5)
#define BTLS_CIPHERS_DHE_RSA_AES256_SHA256             (1ull <<  6)
#define BTLS_CIPHERS_DHE_DSS_AES256_SHA256             (1ull <<  7)
#define BTLS_CIPHERS_ECDHE_ECDSA_CHACHA20_POLY1305     (1ull <<  8)
#define BTLS_CIPHERS_ECDHE_RSA_CHACHA20_POLY1305       (1ull <<  9)
#define BTLS_CIPHERS_DHE_RSA_CHACHA20_POLY1305         (1ull << 10)
#define BTLS_CIPHERS_ECDHE_ECDSA_CHACHA20_POLY1305_OLD (1ull << 11)
#define BTLS_CIPHERS_ECDHE_RSA_CHACHA20_POLY1305_OLD   (1ull << 12)
#define BTLS_CIPHERS_DHE_RSA_CHACHA20_POLY1305_OLD     (1ull << 13)
#define BTLS_CIPHERS_DHE_RSA_CAMELLIA256_SHA256        (1ull << 14)
#define BTLS_CIPHERS_DHE_DSS_CAMELLIA256_SHA256        (1ull << 15)
#define BTLS_CIPHERS_ECDH_RSA_AES256_GCM_SHA384        (1ull << 16)
#define BTLS_CIPHERS_ECDH_ECDSA_AES256_GCM_SHA384      (1ull << 17)
#define BTLS_CIPHERS_ECDH_RSA_AES256_SHA384            (1ull << 18)
#define BTLS_CIPHERS_ECDH_ECDSA_AES256_SHA384          (1ull << 18)
#define BTLS_CIPHERS_AES256_GCM_SHA384                 (1ull << 19)
#define BTLS_CIPHERS_AES256_SHA256                     (1ull << 20)
#define BTLS_CIPHERS_CAMELLIA256_SHA256                (1ull << 21)
#define BTLS_CIPHERS_ECDHE_RSA_AES128_GCM_SHA256       (1ull << 22)
#define BTLS_CIPHERS_ECDHE_ECDSA_AES128_GCM_SHA256     (1ull << 23)
#define BTLS_CIPHERS_ECDHE_RSA_AES128_SHA256           (1ull << 24)
#define BTLS_CIPHERS_ECDHE_ECDSA_AES128_SHA256         (1ull << 25)
#define BTLS_CIPHERS_DHE_DSS_AES128_GCM_SHA256         (1ull << 26)
#define BTLS_CIPHERS_DHE_RSA_AES128_GCM_SHA256         (1ull << 27)
#define BTLS_CIPHERS_DHE_RSA_AES128_SHA256             (1ull << 28)
#define BTLS_CIPHERS_DHE_DSS_AES128_SHA256             (1ull << 29)
#define BTLS_CIPHERS_DHE_RSA_CAMELLIA128_SHA256        (1ull << 30)
#define BTLS_CIPHERS_DHE_DSS_CAMELLIA128_SHA256        (1ull << 31)
#define BTLS_CIPHERS_ECDH_RSA_AES128_GCM_SHA256        (1ull << 32)
#define BTLS_CIPHERS_ECDH_ECDSA_AES128_GCM_SHA256      (1ull << 33)
#define BTLS_CIPHERS_ECDH_RSA_AES128_SHA256            (1ull << 34)
#define BTLS_CIPHERS_ECDH_ECDSA_AES128_SHA256          (1ull << 35)
#define BTLS_CIPHERS_AES128_GCM_SHA256                 (1ull << 36)
#define BTLS_CIPHERS_AES128_SHA256                     (1ull << 37)
#define BTLS_CIPHERS_CAMELLIA128_SHA256                (1ull << 38)
#define BTLS_CIPHERS_AES256_SHA                        (1ull << 39)

#define BTLS_DEFAULT \
    (BTLS_PROTO_DEFAULT| \
    BTLS_DHEPARAMS_NONE| \
    BTLS_ECDHECURVE_AUTO| \
    BTLS_CIPHERS_DEFAULT| \
    BTLS_VERIFY_DEPTH_DEFAULT| \
    BTLS_PREFER_CIPHERS_SERVER| \
    BTLS_CLEAR_KEYS)

struct btls_kp {
    const uint8_t *certmem;
    size_t certlen;
    const uint8_t *keymem;
    size_t keylen;
};

struct btls_ca {
    const char *path, *file;
    const uint8_t *mem;
    size_t len;
};

BTLS_EXPORT uint8_t *btls_loadfile(
    const char *file,
    size_t *len,
    char *password
);

BTLS_EXPORT int btls_ca(
    struct btls_ca *c,
    const char *file,
    const char *path,
    const uint8_t *mem,
    size_t len
);

BTLS_EXPORT int btls_kp(
    struct btls_kp *kp,
    const uint8_t *cert,
    size_t certlen,
    const uint8_t *key,
    size_t keylen
);

BTLS_EXPORT const char *btls_error(
    int s
);

BTLS_EXPORT int btls_attach_server(
    int s,
    uint64_t flags,
    uint64_t ciphers,
    struct btls_kp *kp,
    size_t kplen,
    struct btls_ca *ca,
    const char *alpn
);

BTLS_EXPORT int btls_attach_accept(
    int s,
    int l
);

BTLS_EXPORT int btls_attach_client(
    int s,
    uint64_t flags,
    uint64_t ciphers,
    struct btls_ca *ca,
    const char *alpn,
    const char *servername
);

BTLS_EXPORT int btls_attach_client_kp(
    int s,
    uint64_t flags,
    uint64_t ciphers,
    struct btls_kp *kp,
    size_t kplen,
    struct btls_ca *ca,
    const char *alpn,
    const char *servername
);

BTLS_EXPORT int btls_detach(
    int s,
    int64_t deadline
);

BTLS_EXPORT void btls_reset(
    int s
);

BTLS_EXPORT int btls_handshake(
    int s,
    int64_t deadline
);

BTLS_EXPORT int btls_peercertprovided(
    int s
);

BTLS_EXPORT int btls_peercertcontainsname(
    int s,
    const char *name
);

BTLS_EXPORT const char *btls_peercerthash(
    int s
);

BTLS_EXPORT const char *btls_peercertissuer(
    int s
);

BTLS_EXPORT const char *btls_peercertsubject(
    int s
);

BTLS_EXPORT time_t btls_peercertnotbefore(
    int s
);

BTLS_EXPORT time_t btls_peercertnotafter(
    int s
);

BTLS_EXPORT const char *btls_connalpnselected(
    int s
);

BTLS_EXPORT const char *btls_conncipher(
    int s
);

BTLS_EXPORT const char *btls_connservername(
    int s
);

BTLS_EXPORT const char *btls_connversion(
    int s
);

#endif
