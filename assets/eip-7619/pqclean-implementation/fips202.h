// Based on PQClean https://github.com/PQClean/PQClean/tree/master/crypto_sign/falcon-512/clean
#ifndef FIPS202_H
#define FIPS202_H

#include <stddef.h>
#include <stdint.h>

#define SHAKE128_RATE 168
#define SHAKE256_RATE 136
#define SHA3_256_RATE 136
#define SHA3_384_RATE 104
#define SHA3_512_RATE 72

#define PQC_SHAKEINCCTX_BYTES (sizeof(uint64_t)*26)
#define PQC_SHAKECTX_BYTES (sizeof(uint64_t)*25)

// Context for incremental API
typedef struct {
    uint64_t *ctx;
} shake128incctx;

// Context for non-incremental API
typedef struct {
    uint64_t *ctx;
} shake128ctx;

// Context for incremental API
typedef struct {
    uint64_t *ctx;
} shake256incctx;

// Context for non-incremental API
typedef struct {
    uint64_t *ctx;
} shake256ctx;

// Context for incremental API
typedef struct {
    uint64_t *ctx;
} sha3_256incctx;

// Context for incremental API
typedef struct {
    uint64_t *ctx;
} sha3_384incctx;

// Context for incremental API
typedef struct {
    uint64_t *ctx;
} sha3_512incctx;

/* Initialize the state and absorb the provided input.
 *
 * This function does not support being called multiple times
 * with the same state.
 */
void shake128_absorb(shake128ctx *state, const uint8_t *input, size_t inlen);
/* Squeeze output out of the sponge.
 *
 * Supports being called multiple times
 */
void shake128_squeezeblocks(uint8_t *output, size_t nblocks, shake128ctx *state);
/* Free the state */
void shake128_ctx_release(shake128ctx *state);
/* Copy the state. */
void shake128_ctx_clone(shake128ctx *dest, const shake128ctx *src);

/* Initialize incremental hashing API */
void shake128_inc_init(shake128incctx *state);
/* Absorb more information into the XOF.
 *
 * Can be called multiple times.
 */
void shake128_inc_absorb(shake128incctx *state, const uint8_t *input, size_t inlen);
/* Finalize the XOF for squeezing */
void shake128_inc_finalize(shake128incctx *state);
/* Squeeze output out of the sponge.
 *
 * Supports being called multiple times
 */
void shake128_inc_squeeze(uint8_t *output, size_t outlen, shake128incctx *state);
/* Copy the context of the SHAKE128 XOF */
void shake128_inc_ctx_clone(shake128incctx *dest, const shake128incctx *src);
/* Free the context of the SHAKE128 XOF */
void shake128_inc_ctx_release(shake128incctx *state);

/* Initialize the state and absorb the provided input.
 *
 * This function does not support being called multiple times
 * with the same state.
 */
void shake256_absorb(shake256ctx *state, const uint8_t *input, size_t inlen);
/* Squeeze output out of the sponge.
 *
 * Supports being called multiple times
 */
void shake256_squeezeblocks(uint8_t *output, size_t nblocks, shake256ctx *state);
/* Free the context held by this XOF */
void shake256_ctx_release(shake256ctx *state);
/* Copy the context held by this XOF */
void shake256_ctx_clone(shake256ctx *dest, const shake256ctx *src);

/* Initialize incremental hashing API */
void shake256_inc_init(shake256incctx *state);
void shake256_inc_absorb(shake256incctx *state, const uint8_t *input, size_t inlen);
/* Prepares for squeeze phase */
void shake256_inc_finalize(shake256incctx *state);
/* Squeeze output out of the sponge.
 *
 * Supports being called multiple times
 */
void shake256_inc_squeeze(uint8_t *output, size_t outlen, shake256incctx *state);
/* Copy the state */
void shake256_inc_ctx_clone(shake256incctx *dest, const shake256incctx *src);
/* Free the state */
void shake256_inc_ctx_release(shake256incctx *state);

/* One-stop SHAKE128 call */
void shake128(uint8_t *output, size_t outlen,
              const uint8_t *input, size_t inlen);

/* One-stop SHAKE256 call */
void shake256(uint8_t *output, size_t outlen,
              const uint8_t *input, size_t inlen);

/* Initialize the incremental hashing state */
void sha3_256_inc_init(sha3_256incctx *state);
/* Absorb blocks into SHA3 */
void sha3_256_inc_absorb(sha3_256incctx *state, const uint8_t *input, size_t inlen);
/* Obtain the output of the function and free `state` */
void sha3_256_inc_finalize(uint8_t *output, sha3_256incctx *state);
/* Copy the context */
void sha3_256_inc_ctx_clone(sha3_256incctx *dest, const sha3_256incctx *src);
/* Release the state, don't use if `_finalize` has been used */
void sha3_256_inc_ctx_release(sha3_256incctx *state);

void sha3_256(uint8_t *output, const uint8_t *input, size_t inlen);

/* Initialize the incremental hashing state */
void sha3_384_inc_init(sha3_384incctx *state);
/* Absorb blocks into SHA3 */
void sha3_384_inc_absorb(sha3_384incctx *state, const uint8_t *input, size_t inlen);
/* Obtain the output of the function and free `state` */
void sha3_384_inc_finalize(uint8_t *output, sha3_384incctx *state);
/* Copy the context */
void sha3_384_inc_ctx_clone(sha3_384incctx *dest, const sha3_384incctx *src);
/* Release the state, don't use if `_finalize` has been used */
void sha3_384_inc_ctx_release(sha3_384incctx *state);

/* One-stop SHA3-384 shop */
void sha3_384(uint8_t *output, const uint8_t *input, size_t inlen);

/* Initialize the incremental hashing state */
void sha3_512_inc_init(sha3_512incctx *state);
/* Absorb blocks into SHA3 */
void sha3_512_inc_absorb(sha3_512incctx *state, const uint8_t *input, size_t inlen);
/* Obtain the output of the function and free `state` */
void sha3_512_inc_finalize(uint8_t *output, sha3_512incctx *state);
/* Copy the context */
void sha3_512_inc_ctx_clone(sha3_512incctx *dest, const sha3_512incctx *src);
/* Release the state, don't use if `_finalize` has been used */
void sha3_512_inc_ctx_release(sha3_512incctx *state);

/* One-stop SHA3-512 shop */
void sha3_512(uint8_t *output, const uint8_t *input, size_t inlen);

#endif
