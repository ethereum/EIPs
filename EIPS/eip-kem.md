---
eip: KEM
title: Private Key Encapsulation
description: defines a specification for encapsulating private keys.
author: Base Labs (@Base-Labs)
discussions-to: https://ethereum-magicians.org/t/private-key-encapsulation-to-move-around-securely-without-entering-seed/11604
status: Draft
type: Standards Track
category: ERC
created: 2022-11-21
---


## Abstract

This EIP proposes a mechanism to encapsulate a private key so that it could be securely relocated to another application without providing the seed. This EIP combines `ECIES` and optional signature verification under various choices to ensure that the private key is encapsulated to a known or trusted party.

## Motivation

There are various cases that we might want to export one of many private keys from a much securer but less convenient wallet, which is controlled with a seed or pass phrase.

1.  We might dedicate one of many private keys for messaging purpose, and that private key is probably managed in a not-so-secure manner;
2.  We might want to export one of many private keys from a hardware wallet, and split it with MPC technology so that a 3rd party service could help us identify potential frauds or known bad addresses, enforce 2FA, etc., meanwhile we can initiate transactions from a mobile device with much better UX and without carrying a hardware wallet.

In both cases, it is safer not to provide the seed which controls the whole wallet and might contains many addresses in multiple chains.

This EIP aims to enable such use cases.

## Specification

The basic idea is to encapsulate the private key with ECIES. To ensure that the ephemeral public key to encapsulate the private key to is indeed generated from a trusted party and has not been tampered with, an option is provided to sign that ephemeral public key.

There should be a mandatory  `version`  parameter. This allows various kinds of Key Encapsulation Mechanisms to be adopted depending on the security considerations or preference. The list shall be short to minimize compatibility issues among different vendors.

### Core Algorithms

In addition to `version` string, parameters, involved keys and functions include:

1.  Sender private key  `sk`, to be encapsulated to recipient.
2.  Ephemeral recipient key pair  `(r, R)`  such that `R = [r]G`. `G` denotes the base point of the elliptic curve, and `[r]G` denotes the scalar multiplication. Optionally, `R` could be signed and `signerPubKey` and `signature` are then provided for sender to verify if `R`  could be trusted or not.
3.  Ephemeral sender key pair  `(s, S)`  such that `S = [s]G`.
4.  Share secret  `ss  := [s]R = [r]S` according to ECDH.
5.  `oob`, out of band data, optional. This could be digits or an alpha-numeric string entered by user.
6.  Let  `derivedKey  :=  HKDF(hash=SHA256, ikm=ss, info=oob,  salt,  length)`. HKDF is defined in RFC5869. The  `length`  should be determined by  `skey`  and  `IV`  requirements such that the symmetric key  `skey  = derivedKey[0:keySize]`, and  `IV  = derivedKey[keySize:length]`.  `keySize`  denotes the key size of underlying symmetric algorithm, for example, 16 (bytes) for AES-128, and 32 (bytes) for Chacha20. See **Security Considerations** for the use of  `salt`.
7.  `cipher  := authenticated_cncryption(symAlg,  skey,  IV, data=sk)`. The symmetric cipher algorithm (`symAlg`) and authentication scheme are decided by the version parameter.

A much simplified example flow without signature and verification is:

1.  Recipient application generates  `(r, R)`.
2.  User inputs  `R`  to Sender application, along with a six-digit code “123456” as  `oob`.
3.  Sender application generates  `(s, S)`, and computes  `cipher`.
4.  Recipient application scans to read  `S`  and  `cipher`. User enters “123456” as  `oob`  to Recipient application.
5.  Recipient application decrypts  `cipher`  to get  `sk`.
6.  Optionally Recipient application could derive the address corresponding to  `sk`  so that user can confirm the correctness.

### Requests
#### R1. Request for Recipient to generate ephemeral key pair

```
request({
	method: 'eth_generateEphemeralKeyPair',
	params: [version, signerPubKey],
})
```

`signerPubKey`  is optional. If provided, it is assumed that the implementation has the corresponding private key and the implementation MUST sign the ephemeral public key (in the form of what is to be returned). The signature algorithm is determined by the curve part of the  `version`  parameter, that is, ECDSA for secp256k1, and EdDSA for Ed25519. And in this situation, it should be the case that the sender trusts  `signerPubKey`, no matter how this trust is maintained. If not, next request WILL be rejected by Sender application. Also see **Security Considerations**.

Implementation then MUST generate random private key `r` with cryptographic secure random number generator (CSRNG), and derives ephemeral public key `R = [r]G`. Implementation SHOULD safe keep the generated key pair `(r, R)` in a secure manner in accordance with the circumstances, and SHOULD keep it only for limited duration, but the specific duration is left to individual implementations. Implementation SHOULD be able to retrieve `r` when given back the corresponding public key `R` if within said duration.

Returned value is `R`, compressed if applicable. Also see ****Encoding of data and messages****. If  `signerPubKey`  is provided, then `R` is followed by the `signature`, also hex-encoded.

Alternatively, `signature` could be calculated separately, and then appended to the returned data.

#### R2. Request for Sender to encapsulate the private key

```
request({
	method: 'eth_encapsulatePrivateKey',
	params: [
		version,
		recipient, // public key, may be followed by its signature, see signerPubKey
		signerPubKey,
		oob,
		salt,
		account
	],
})
```

`recipient`  is the return value from the call to generate ephemeral key pair, with optional `signature` appended either as returned or separately.

`oob`  and  `salt`  are just byte arrays.

`account`  is used to identify which private key to be encapsulated. With Ethereum it is an address. Also see ****Encoding of data and messages****.

If  `signerPubKey`  is provided or  `recipient`  contains signature, the implementation MUST perform signature verification. Missing data or incorrect format etc. SHALL result in empty return and optional error logs.

The implementation shall then proceed to retrieve the private key corresponding to  `account`, and follow the ****Core Algorithms**** to encrypt it.

The return data is a byte array which contains first the ephemeral sender public key (compressed if applicable), then cipher including any authentication tag.

#### R3. Request for Recipient to unwrap and intake the private key

```
request({
	method: 'eth_intakePrivateKey',
	params: [
		version,
		recipientPublicKey, //  no signature this time
		oob,
		salt,
		data
	],
})
```

This time  `recipientPublicKey`  is only the ephemeral public key `R` generated earlier in the recipient side, just for the implementation to retrieve the corresponding private key `r`.  `data`  is the return value from the call to encapsulate private key, which includes `S` and `cipher`.

When the encapsulated private key `sk` is decrypted successfully, the implementation can process it further according to the designated purposes. Some general security guidelines SHALL be followed, for example, do  *not*  log the value, do securely wipe it after use, etc. The implementation COULD derive the corresponding public key or address for user’s verification.

The return value of this function SHOULD be empty if success, or any error message. NEVER return the decrypted private key.

### Options and Parameters

Available elliptic curves are:

-   secp256k1 (mandatory)
-   Ed25519

Available authenticated encryption schemes are:

-   AES-128-GCM (mandatory)
-   AES-256-GCM
-   Chacha20-Poly1305

Version string is simply concatenation of elliptic curve and AE scheme, for example, secp256k1-AES-128-GCM.

Signature algorithms for each curve is:

-   secp256k1 --> ECDSA
-   Ed25519 --> EdDSA

### Encoding of data and messages

- Raw bytes are encoded in hex and prefixed with '0x'.
- `cipher`  is encoded into single byte buffer as: (`IV  || encrypted_sk || tag`).
- `R`, `S` and `signerPubKey` are compressed if applicable.
- `R` or `signerPubKey` could be followed by a signature to it.

## Rationale

A crucial difference of this proposal with [EIP-5630](eip-5630.md) is that, with key encapsulation in order to transport private key securely, the public key from the key-recipient should be ephemeral, and mostly used only one-time. While in EIP-5630 settings, the public key of message recipient shall be stable for a while so that message senders can encrypt messages without key discovery every time.

There is security implication to this difference, including perfect forward secrecy. We aim to achieve perfect forward secrecy by generating ephemeral key pairs in both sides every time: 1) first the recipient shall generate an ephemeral key pair, retain the private key securely, and export the public key; 2) then the key sender securely wrap the private key in ECIES, with another ephemeral key pair, then destroy the ephemeral key securely; 3) finally the recipient can unwrap the private key, then destroy its ephemeral key pair securely. After these steps, the cipher text in transport intercepted by a malicious 3rd party, is no longer decrypt-able.

## Backward Compatibility

No backward compatibility issues for this new proposal.

To minimize potential compatibility issues among applications (including hardware wallets), this EIP requires that version secp256k1-AES-128-GCM MUST be supported.

Version could be decided by user or negotiated by both sides. When there is no user input or negotiation, secp256k1-AES-128-GCM is assumed.

### UX Recommendations
`salt` and/or `oob` data: both are inputs to the HKDF function (`oob` as “info” parameter). For better UX we suggest to require from users only one of them but this is up to the implementation.

Recipient application is assumed to be powerful enough. Sender application could have very limited computing power and user interaction capabilities.

## Test Cases
TODO

## Reference Implementation
TODO

## Security Considerations

**Perfect Forward Secrecy**: PFS is achieved by using ephemeral key pairs in both sides.

**Optional Signature and Trusted Public Keys**

`R` could be signed so that Sender application can verify if `R` could be trusted or not. This involves both signature verification and if the signer could be trusted or not. While signature verification is quite straightforward in itself, the latter should be managed with care. To facilitate this trust management issue, `signerPubKey` could be further signed, creating a dual-layer trust structure:

```
R <-- signerPubKey <-- trusted public key
```

This allows various strategies to mange the trust. For example:

-   A hardware wallet vendor which takes it very serious about the brand reputation and the fund safety for its customers, could choose to trust only its own public key(s). These public keys only sign `signerPubKey` from selected partners.
-   A MPC service could publish its `signerPubKey` online so that users won't verify the signature against a wrong or fake public key.

**Security Level**:

1. We are not considering post-quantum security. If quantum computer becomes a materialized threat, the underlying cipher of Ethereum and other L1 chains would have been replaced, and this EIP will be outdated then (as the EC part of ECIES is also broken).
2. The security level shall match that of the elliptic curve used by the underlying chains. It does not make much sense to use AES-256 to safeguard a secp256k1 private key but implementation could choose freely.
3. That being said, a key might be used in multiple chains. So the security level shall cover the most demanding requirement and potential future developments.

AES-128, AES-256 and ChaCha20 are provided.

**Randomness**. `r` and `s` must be generated with a cryptographic secure random number generator (CSRNG).

`salt`  could be random bytes generated the same way as  `r`  or  `s`.  `salt`  could be in any length but the general suggestion is 12 or 16, which could be displayed as QR code by the screen of some hardware wallet (so that another application could scan to read). If  `salt`  is not provided, this EIP uses default value as “EIP-xxxx” (to be determined).

**Out of Band Data**: `oob`  data is optional. When non-empty, its content is digits or an alpha-numeric string from user. Sender application may mandate  `oob`  from user.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).

## Citation
Please cite this document as:
TODO
