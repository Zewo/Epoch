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

#ifndef DSOCK_UTILS_H_INCLUDED
#define DSOCK_UTILS_H_INCLUDED

#include <stdint.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define dsock_concat(x,y) x##y

/* Defines a unique identifier of type const void*. */
#define dsock_unique_id(name) \
    static const int dsock_concat(name, ___) = 0;\
    const void *name = & dsock_concat(name, ___);

/*  Takes a pointer to a member variable and computes pointer to the structure
    that contains it. 'type' is type of the structure, not the member. */
#define dsock_cont(ptr, type, member) \
    (ptr ? ((type*) (((char*) ptr) - offsetof(type, member))) : NULL)

/* Compile-time assert. */
#define DSOCK_CT_ASSERT_HELPER2(prefix, line) \
    prefix##line
#define DSOCK_CT_ASSERT_HELPER1(prefix, line) \
    DSOCK_CT_ASSERT_HELPER2(prefix, line)
#define DSOCK_CT_ASSERT(x) \
    typedef int DSOCK_CT_ASSERT_HELPER1(ct_assert_,__COUNTER__) [(x) ? 1 : -1]

#if defined __GNUC__ || defined __llvm__
#define dsock_fast(x) __builtin_expect(!!(x), 1)
#define dsock_slow(x) __builtin_expect(!!(x), 0)
#else
#define dsock_fast(x) (x)
#define dsock_slow(x) (x)
#endif

/* Define our own assert. This way we are sure that it stays in place even
   if the standard C assert would be thrown away by the compiler. */
#define dsock_assert(x) \
    do {\
        if (dsock_slow(!(x))) {\
            fprintf(stderr, "Assert failed: " #x " (%s:%d)\n",\
                __FILE__, __LINE__);\
            fflush(stderr);\
            abort();\
        }\
    } while (0)

uint16_t dsock_gets(const uint8_t *buf);
void dsock_puts(uint8_t *buf, uint16_t val);
uint32_t dsock_getl(const uint8_t *buf);
void dsock_putl(uint8_t *buf, uint32_t val);
uint64_t dsock_getll(const uint8_t *buf);
void dsock_putll(uint8_t *buf, uint64_t val);

int dsock_random(uint8_t *buf, size_t len, int64_t deadline);

/* Returns a pointer to the first character in string that is not delim */
const char *dsock_lstrip(const char *string, char delim);

/* Returns a pointer after the last character in string that is not delim */
const char *dsock_rstrip(const char *string, char delim);

#define MIN(a,b) (((a)<(b))?(a):(b))

#define MAX(a,b) (((a)>(b))?(a):(b))

#endif

