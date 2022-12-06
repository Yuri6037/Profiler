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

#include "NodeDuration.h"

uint64_t duration_to_micros(const duration_t *a) {
    return a->seconds * 1000000 + a->millis * 1000 + a->micros;
}

int duration_is_less_than(const duration_t *a, const duration_t *b) {
    return duration_to_micros(a) < duration_to_micros(b) ? 1 : 0;
}

int duration_is_greater_than(const duration_t *a, const duration_t *b) {
    return duration_to_micros(a) > duration_to_micros(b) ? 1 : 0;
}

static void rectify_duration(duration_t *a, uint64_t ms, uint64_t us) {
    if (us > 1000) {
        uint64_t acc = us / 1000;
        ms += acc;
        us -= (acc * 1000);
    }
    if (ms > 1000) {
        uint64_t acc = ms / 1000;
        a->seconds += acc;
        ms -= (acc * 1000);
    }
    a->millis = ms;
    a->micros = us;
}

void duration_add(duration_t *a, const duration_t *b) {
    a->seconds += b->seconds;
    uint32_t ms = a->millis + b->millis;
    uint32_t us = a->micros + b->micros;
    rectify_duration(a, ms, us);
}

void duration_mul_scalar(duration_t *a, float scalar) {
    uint64_t us = duration_to_micros(a);
    us *= scalar;
    a->seconds = 0;
    rectify_duration(a, 0, us);
}

void duration_set_zero(duration_t *a) {
    a->seconds = 0;
    a->millis = 0;
    a->micros = 0;
}

void duration_from_seconds(duration_t *a, double seconds) {
    uint64_t us = (uint64_t)(seconds * 1000000);
    uint64_t ms = us / 1000;
    uint64_t s = ms / 1000;
    ms -= s * 1000; //Remove seconds from millis
    us -= ms * 1000; //Remove millis from micros
    us -= s * 1000000; //Remove seconds from micros
    a->seconds = (uint32_t)s;
    a->millis = (uint16_t)ms;
    a->micros = (uint16_t)us;
}

void duration_copy(duration_t *a, const duration_t *b) {
    a->seconds = b->seconds;
    a->millis = b->millis;
    a->micros = b->micros;
}
