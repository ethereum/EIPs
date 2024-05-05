// Based on PQClean https://github.com/PQClean/PQClean/tree/master/crypto_sign/falcon-512/clean
/*
 * PRNG and interface to the system RNG.
 *
 * ==========================(LICENSE BEGIN)============================
 *
 * Copyright (c) 2017-2019  Falcon Project
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ===========================(LICENSE END)=============================
 *
 * @author   Thomas Pornin <thomas.pornin@nccgroup.com>
 */

#include <assert.h>

#include "inner.h"

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_prng_init(prng *p, inner_shake256_context *src) {
    /*
     * To ensure reproducibility for a given seed, we
     * must enforce little-endian interpretation of
     * the state words.
     */
    uint8_t tmp[56];
    uint64_t th, tl;
    int i;

    uint32_t *d32 = (uint32_t *) p->state.d;
    uint64_t *d64 = (uint64_t *) p->state.d;

    inner_shake256_extract(src, tmp, 56);
    for (i = 0; i < 14; i ++) {
        uint32_t w;

        w = (uint32_t)tmp[(i << 2) + 0]
            | ((uint32_t)tmp[(i << 2) + 1] << 8)
            | ((uint32_t)tmp[(i << 2) + 2] << 16)
            | ((uint32_t)tmp[(i << 2) + 3] << 24);
        d32[i] = w;
    }
    tl = d32[48 / sizeof(uint32_t)];
    th = d32[52 / sizeof(uint32_t)];
    d64[48 / sizeof(uint64_t)] = tl + (th << 32);
    PQCLEAN_FALCON512_CLEAN_prng_refill(p);
}

/*
 * PRNG based on ChaCha20.
 *
 * State consists in key (32 bytes) then IV (16 bytes) and block counter
 * (8 bytes). Normally, we should not care about local endianness (this
 * is for a PRNG), but for the NIST competition we need reproducible KAT
 * vectors that work across architectures, so we enforce little-endian
 * interpretation where applicable. Moreover, output words are "spread
 * out" over the output buffer with the interleaving pattern that is
 * naturally obtained from the AVX2 implementation that runs eight
 * ChaCha20 instances in parallel.
 *
 * The block counter is XORed into the first 8 bytes of the IV.
 */
void
PQCLEAN_FALCON512_CLEAN_prng_refill(prng *p) {

    static const uint32_t CW[] = {
        0x61707865, 0x3320646e, 0x79622d32, 0x6b206574
    };

    uint64_t cc;
    size_t u;

    /*
     * State uses local endianness. Only the output bytes must be
     * converted to little endian (if used on a big-endian machine).
     */
    cc = *(uint64_t *)(p->state.d + 48);
    for (u = 0; u < 8; u ++) {
        uint32_t state[16];
        size_t v;
        int i;

        memcpy(&state[0], CW, sizeof CW);
        memcpy(&state[4], p->state.d, 48);
        state[14] ^= (uint32_t)cc;
        state[15] ^= (uint32_t)(cc >> 32);
        for (i = 0; i < 10; i ++) {

#define QROUND(a, b, c, d)   do { \
        state[a] += state[b]; \
        state[d] ^= state[a]; \
        state[d] = (state[d] << 16) | (state[d] >> 16); \
        state[c] += state[d]; \
        state[b] ^= state[c]; \
        state[b] = (state[b] << 12) | (state[b] >> 20); \
        state[a] += state[b]; \
        state[d] ^= state[a]; \
        state[d] = (state[d] <<  8) | (state[d] >> 24); \
        state[c] += state[d]; \
        state[b] ^= state[c]; \
        state[b] = (state[b] <<  7) | (state[b] >> 25); \
    } while (0)

            QROUND( 0,  4,  8, 12);
            QROUND( 1,  5,  9, 13);
            QROUND( 2,  6, 10, 14);
            QROUND( 3,  7, 11, 15);
            QROUND( 0,  5, 10, 15);
            QROUND( 1,  6, 11, 12);
            QROUND( 2,  7,  8, 13);
            QROUND( 3,  4,  9, 14);

#undef QROUND

        }

        for (v = 0; v < 4; v ++) {
            state[v] += CW[v];
        }
        for (v = 4; v < 14; v ++) {
            state[v] += ((uint32_t *)p->state.d)[v - 4];
        }
        state[14] += ((uint32_t *)p->state.d)[10]
                     ^ (uint32_t)cc;
        state[15] += ((uint32_t *)p->state.d)[11]
                     ^ (uint32_t)(cc >> 32);
        cc ++;

        /*
         * We mimic the interleaving that is used in the AVX2
         * implementation.
         */
        for (v = 0; v < 16; v ++) {
            p->buf.d[(u << 2) + (v << 5) + 0] =
                (uint8_t)state[v];
            p->buf.d[(u << 2) + (v << 5) + 1] =
                (uint8_t)(state[v] >> 8);
            p->buf.d[(u << 2) + (v << 5) + 2] =
                (uint8_t)(state[v] >> 16);
            p->buf.d[(u << 2) + (v << 5) + 3] =
                (uint8_t)(state[v] >> 24);
        }
    }
    *(uint64_t *)(p->state.d + 48) = cc;

    p->ptr = 0;
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_prng_get_bytes(prng *p, void *dst, size_t len) {
    uint8_t *buf;

    buf = dst;
    while (len > 0) {
        size_t clen;

        clen = (sizeof p->buf.d) - p->ptr;
        if (clen > len) {
            clen = len;
        }
        memcpy(buf, p->buf.d, clen);
        buf += clen;
        len -= clen;
        p->ptr += clen;
        if (p->ptr == sizeof p->buf.d) {
            PQCLEAN_FALCON512_CLEAN_prng_refill(p);
        }
    }
}
