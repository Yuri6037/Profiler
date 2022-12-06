// Copyright 2022 Yuri6037
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy
// of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
// THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
// DEALINGS
// IN THE SOFTWARE.

#ifndef NodeDuration_h
#define NodeDuration_h

#include <stdint.h>

typedef struct duration_s {
    uint32_t seconds;
    uint16_t millis;
    uint16_t micros;
} duration_t;

/**
 * Returns 1 if a is less than b, 0 otherwise.
 */
int duration_is_less_than(const duration_t *a, const duration_t *b);

/**
 * Returns 1 if a is greater than b, 0 otherwise.
 */
int duration_is_greater_than(const duration_t *a, const duration_t *b);

/**
 * Adds b into a.
 */
void duration_add(duration_t *a, const duration_t *b);

/**
 * Multiplies a by a scalar and stores the result in a.
 */
void duration_mul_scalar(duration_t *a, float scalar);

/**
 * Converts seconds into this duration representation.
 */
void duration_from_seconds(duration_t *a, double seconds);

/**
 * Converts that duration to microseconds.
 */
uint64_t duration_to_micros(const duration_t *a);

/**
 * Sets the content of this duration to 0.
 */
void duration_set_zero(duration_t *a);

/**
 * Copies b into a.
 */
void duration_copy(duration_t *a, const duration_t *b);

#endif /* NodeDuration_h */
