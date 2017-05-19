/*
 * Copyright (c) 2016 Tai Chi Minh Ralph Eastwood <tcmreastwood@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */


#include <openssl/opensslv.h>

#if (OPENSSL_VERSION_NUMBER < 0x10003000L)
#include <openssl/x509_vfy.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

int SSL_CTX_load_verify_mem(SSL_CTX *ctx, void *buf, int len)
{
    char fname[] = "/tmp/dsockcompatXXXXXX";
    int rc;
#ifdef HAVE_MKSTEMP
    int fd;
    fd = mkstemp(fname);
#else
    const char *tmp_fname = mktemp(fname);
    int fd;
    
    if(tmp_fname) {
        fd = open(tmp_fname, O_EXCL | O_WRONLY | O_SYNC, S_IRUSR | S_IWUSR);
    } else {
        fd = -1;
    }
#endif
    if (fd < 0)
        return -1;
    do {
        ssize_t wrote = write(fd, buf, len);
        if(wrote == -1) {
            break;
        } else {
            buf = (char *)buf + wrote;
            len -= wrote;
        }
    } while(len);
    close(fd);
	rc = SSL_CTX_load_verify_locations(ctx, fname, NULL);
    remove(fname);
    return rc;
}

/*
 * Copyright (c) 2015 Bob Beck <beck@openbsd.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/*
 * Parse an RFC 5280 format ASN.1 time string.
 *
 * mode must be:
 * 0 if we expect to parse a time as specified in RFC 5280 from an X509 object.
 * V_ASN1_UTCTIME if we wish to parse on RFC5280 format UTC time.
 * V_ASN1_GENERALIZEDTIME if we wish to parse an RFC5280 format Generalized time.
 *
 * Returns:
 * -1 if the string was invalid.
 * V_ASN1_UTCTIME if the string validated as a UTC time string.
 * V_ASN1_GENERALIZEDTIME if the string validated as a Generalized time string.
 *
 * Fills in *tm with the corresponding time if tm is non NULL.
 */

#define GENTIME_LENGTH 15
#define UTCTIME_LENGTH 13

#define	ATOI2(ar)	((ar) += 2, ((ar)[-2] - '0') * 10 + ((ar)[-1] - '0'))
int
asn1_time_parse(const char *bytes, size_t len, struct tm *tm, int mode)
{
	size_t i;
	int type = 0;
	struct tm ltm;
	struct tm *lt;
	const char *p;

	if (bytes == NULL)
		return (-1);

	/* Constrain to valid lengths. */
	if (len != UTCTIME_LENGTH && len != GENTIME_LENGTH)
		return (-1);

	lt = tm;
	if (lt == NULL) {
		memset(&ltm, 0, sizeof(ltm));
		lt = &ltm;
	}

	/* Timezone is required and must be GMT (Zulu). */
	if (bytes[len - 1] != 'Z')
		return (-1);

	/* Make sure everything else is digits. */
	for (i = 0; i < len - 1; i++) {
		if (isdigit((unsigned char)bytes[i]))
			continue;
		return (-1);
	}

	/*
	 * Validate and convert the time
	 */
	p = bytes;
	switch (len) {
	case GENTIME_LENGTH:
		if (mode == V_ASN1_UTCTIME)
			return (-1);
		lt->tm_year = (ATOI2(p) * 100) - 1900;	/* cc */
		type = V_ASN1_GENERALIZEDTIME;
		/* FALLTHROUGH */
	case UTCTIME_LENGTH:
		if (type == 0) {
			if (mode == V_ASN1_GENERALIZEDTIME)
				return (-1);
			type = V_ASN1_UTCTIME;
		}
		lt->tm_year += ATOI2(p);		/* yy */
		if (type == V_ASN1_UTCTIME) {
			if (lt->tm_year < 50)
				lt->tm_year += 100;
		}
		lt->tm_mon = ATOI2(p) - 1;		/* mm */
		if (lt->tm_mon < 0 || lt->tm_mon > 11)
			return (-1);
		lt->tm_mday = ATOI2(p);			/* dd */
		if (lt->tm_mday < 1 || lt->tm_mday > 31)
			return (-1);
		lt->tm_hour = ATOI2(p);			/* HH */
		if (lt->tm_hour < 0 || lt->tm_hour > 23)
			return (-1);
		lt->tm_min = ATOI2(p);			/* MM */
		if (lt->tm_min < 0 || lt->tm_min > 59)
			return (-1);
		lt->tm_sec = ATOI2(p);			/* SS */
		/* Leap second 60 is not accepted. Reconsider later? */
		if (lt->tm_sec < 0 || lt->tm_sec > 59)
			return (-1);
		break;
	default:
		return (-1);
	}

	return (type);
}

#endif
