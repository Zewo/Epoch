/*

  Copyright (c) 2016 Martin Sustrik

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

#include "libdill.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "utils.h"

uint16_t dsock_gets(const uint8_t *buf) {
    return (((uint16_t)buf[0]) << 8) |
           ((uint16_t)buf[1]);
}

void dsock_puts(uint8_t *buf, uint16_t val) {
    buf[0] = (uint8_t)(((val) >> 8) & 0xff);
    buf[1] = (uint8_t)(val & 0xff);
}

uint32_t dsock_getl(const uint8_t *buf) {
    return (((uint32_t)buf[0]) << 24) |
           (((uint32_t)buf[1]) << 16) |
           (((uint32_t)buf[2]) << 8) |
           ((uint32_t)buf[3]);
}

void dsock_putl(uint8_t *buf, uint32_t val) {
    buf[0] = (uint8_t)(((val) >> 24) & 0xff);
    buf[1] = (uint8_t)(((val) >> 16) & 0xff);
    buf[2] = (uint8_t)(((val) >> 8) & 0xff);
    buf[3] = (uint8_t)(val & 0xff);
}

uint64_t dsock_getll(const uint8_t *buf) {
    return (((uint64_t)buf[0]) << 56) |
           (((uint64_t)buf[1]) << 48) |
           (((uint64_t)buf[2]) << 40) |
           (((uint64_t)buf[3]) << 32) |
           (((uint64_t)buf[4]) << 24) |
           (((uint64_t)buf[5]) << 16) |
           (((uint64_t)buf[6]) << 8) |
           (((uint64_t)buf[7] << 0));
}

void dsock_putll(uint8_t *buf, uint64_t val) {
    buf[0] = (uint8_t)((val >> 56) & 0xff);
    buf[1] = (uint8_t)((val >> 48) & 0xff);
    buf[2] = (uint8_t)((val >> 40) & 0xff);
    buf[3] = (uint8_t)((val >> 32) & 0xff);
    buf[4] = (uint8_t)((val >> 24) & 0xff);
    buf[5] = (uint8_t)((val >> 16) & 0xff);
    buf[6] = (uint8_t)((val >> 8) & 0xff);
    buf[7] = (uint8_t)(val & 0xff);
}

int dsock_random(uint8_t *buf, size_t len, int64_t deadline) {
    /* Open /dev/urandom if not already opened. */
    static int fd = -1;
    if(dsock_slow(fd == -1)) {
        /* Should we use /dev/random here? */
        fd = open("/dev/urandom", O_RDONLY | O_NONBLOCK);
        if(dsock_slow(fd < 0)) return -1;
    }
    /* Read the bytes. */
    while(len) {
        /* Do reads in at most 1MB chunks. */
        size_t toread = len < 1024 * 1024 ? len : 1024 * 1024;
        ssize_t sz = read(fd, buf, toread);
        if(dsock_slow(sz < 0)) return -1;
        /* If there's not enough entropy, wait for 1 second, then try again. */
        if(sz == 0) {
            int64_t d = now() + 1000;
            if(d > deadline) {errno = ETIMEDOUT; return -1;}
            int rc = msleep(d);
            if(dsock_slow(rc < 0)) return -1;
            continue;
        }
        buf += sz;
        len -= sz;
    }
    return 0;
}

const char *dsock_lstrip(const char *string, char delim) {
    const char *pos = string;
    while(*pos && *pos == delim) ++pos;
    return pos;
}

const char *dsock_rstrip(const char *string, char delim) {
    const char *end = string + strlen(string) - 1;
    while(end > string && *end == delim) --end;
    return ++end;
}
