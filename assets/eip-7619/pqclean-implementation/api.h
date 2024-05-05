// Based on PQClean https://github.com/PQClean/PQClean/tree/master/crypto_sign/falcon-512/clean
#ifndef PQCLEAN_FALCON512_CLEAN_API_H
#define PQCLEAN_FALCON512_CLEAN_API_H

#include <stddef.h>
#include <stdint.h>

#define PQCLEAN_FALCON512_CLEAN_CRYPTO_SECRETKEYBYTES   1281
#define PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES   897
#define PQCLEAN_FALCON512_CLEAN_CRYPTO_BYTES            752

#define PQCLEAN_FALCON512_CLEAN_CRYPTO_ALGNAME          "Falcon-512"

#define PQCLEAN_FALCONPADDED512_CLEAN_CRYPTO_BYTES      666 // used in signature verification

/*
 * Generate a new key pair. Public key goes into pk[], private key in sk[].
 * Key sizes are exact (in bytes):
 *   public (pk): PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES
 *   private (sk): PQCLEAN_FALCON512_CLEAN_CRYPTO_SECRETKEYBYTES
 *
 * Return value: 0 on success, -1 on error.
 */
int PQCLEAN_FALCON512_CLEAN_crypto_sign_keypair(
    uint8_t *pk, uint8_t *sk);

/*
 * Compute a signature on a provided message (m, mlen), with a given
 * private key (sk). Signature is written in sig[], with length written
 * into *siglen. Signature length is variable; maximum signature length
 * (in bytes) is PQCLEAN_FALCON512_CLEAN_CRYPTO_BYTES.
 *
 * sig[], m[] and sk[] may overlap each other arbitrarily.
 *
 * Return value: 0 on success, -1 on error.
 */
int PQCLEAN_FALCON512_CLEAN_crypto_sign_signature(
    uint8_t *sig, size_t *siglen,
    const uint8_t *m, size_t mlen, const uint8_t *sk);

/*
 * Verify a signature (sig, siglen) on a message (m, mlen) with a given
 * public key (pk).
 *
 * sig[], m[] and pk[] may overlap each other arbitrarily.
 *
 * Return value: 0 on success, -1 on error.
 */
int PQCLEAN_FALCON512_CLEAN_crypto_sign_verify(
    const uint8_t *sig, size_t siglen,
    const uint8_t *m, size_t mlen, const uint8_t *pk);

/*
 * Compute a signature on a message and pack the signature and message
 * into a single object, written into sm[]. The length of that output is
 * written in *smlen; that length may be larger than the message length
 * (mlen) by up to PQCLEAN_FALCON512_CLEAN_CRYPTO_BYTES.
 *
 * sm[] and m[] may overlap each other arbitrarily; however, sm[] shall
 * not overlap with sk[].
 *
 * Return value: 0 on success, -1 on error.
 */
int PQCLEAN_FALCON512_CLEAN_crypto_sign(
    uint8_t *sm, size_t *smlen,
    const uint8_t *m, size_t mlen, const uint8_t *sk);

/*
 * Open a signed message object (sm, smlen) and verify the signature;
 * on success, the message itself is written into m[] and its length
 * into *mlen. The message is shorter than the signed message object,
 * but the size difference depends on the signature value; the difference
 * may range up to PQCLEAN_FALCON512_CLEAN_CRYPTO_BYTES.
 *
 * m[], sm[] and pk[] may overlap each other arbitrarily.
 *
 * Return value: 0 on success, -1 on error.
 */
int PQCLEAN_FALCON512_CLEAN_crypto_sign_open(
    uint8_t *m, size_t *mlen,
    const uint8_t *sm, size_t smlen, const uint8_t *pk);

#endif
