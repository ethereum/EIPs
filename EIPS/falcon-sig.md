---
title: Precompile for Falcon Signature Verification
description: This EIP aims to bring quantum resistance to Ethereum through support for Falcon digital signatures.
author: Po-Chun Kuo <pk@btq.com>, Chen-Mou Cheng <cheng@btq.com>, Chris Tam (christam96)
status: Draft
type: Standards Track
category: Core
created: 2023-12-27
---

## Abstract
Pre-compiles for additional signatures are common-place to enable new functionality on blockchains (see [EIP-7212](https://eips.ethereum.org/EIPS/eip-7212) for support of mobile devices and [ERC-2494](https://eips.ethereum.org/EIPS/eip-2494) for zero-knowledge compatibility). This EIP aims to bring quantum resistance ******to Ethereum through support for Falcon digital signatures.

## Motivation

Ethereum's public key infrastructure heavily relies on the Elliptic Curve Digital Signature Algorithm (ECDSA), an algorithm whose security is rooted in the assumed complexity of the discrete logarithm problem. In 1994, Peter Shor introduced [Shor's algorithm](https://en.wikipedia.org/wiki/Shor%27s_algorithm), capable of solving the discrete logarithm problem in polylogarithmic time, implying that ECDSA will no longer be safe in the face of a quantum adversary. While it may be such that there is not a general purpose quantum computer capable of breaking ECC today, this will likely not be the case tomorrow. This urgency underscores the pressing need to explore alternative cryptographic solutions to safeguard Ethereum's infrastructure. [Falcon](https://falcon-sign.info/) is a cryptographic signature algorithm submitted to the [NIST Post-Quantum Cryptography Project](https://csrc.nist.gov/projects/post-quantum-cryptography) and is [set to be standardized](https://www.nist.gov/news-events/news/2022/07/pqc-standardization-process-announcing-four-candidates-be-standardized-plus#standardization) in 2024. Of the digital signatures to be standardized by NIST, Falcon wields a signature size a full order of magnitude smaller than it's contemporaries. The addition of a precompiled contract for Falcon signature verification would:

   1. Open the door to quantum-safe wallets using signature abstraction to replace ECDSA with Falcon
   2. Allow for efficient verification of Falcon transactions
   3. Facilitate further research such as signature aggregation of Falcon signatures, and the adoption of quantum-safe cryptographic primitives across Ethereum

## Specification

### Falcon Signature Verification
We will now describe the process of verifying Falcon signatures.

```
# falcon format: FALCON_SIG_COMPRESSED
# public key: pk (897 bytes)
# signature: (sig, r) (752 ~~666~~ bytes)
# All pk, sig, Hash(m) are ring elements

# Verify:
t = Hash(m; r) - pk*sig
||t|| and ||sig|| ≤ 34,034,726 # check square norm of (t, sig) is short
```

### Precompiled Contract Specification

The `FALCON_VERIFY` precompiled contract is proposed with the following input and outputs, which are big-endian values:

- **Input data:** 1681 bytes of data including:
    - 897 bytes for the public key component
    - 752 bytes of the signature component
    - 32 bytes of the hashed data
- **Output data:** 1 byte of result data
    - If the signature verification process succeeds, determined as a boolean.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

### Gas Usage

We can see that `Falcon signature verification` is 36.8% faster than `ecrecover`. Furthermore, `ecrecover` has a fixed gas consumption of `3000`. Therefore we propose a fixed gas cost of `1200` (3000 * 40%) for `Falcon signature verification`.

### Cost for storage

Storing Falcon signatures on Ethereum incurs a cost. Each Falcon signature is 1681 bytes, and the most cost-effective storage option, `calldata`, requires 16 gas per non-zero byte. Consequently, storing one Falcon signature costs `26,896` gas (1681 * 16). Ethereum blocks have a maximum gas limit of 30 million, with a target block size of 15 million, which is essential to consider for resource allocation.

## Backwards Compatibility

This EIP introduces backwards incompatible changes to the signature verification rules on the consensus layer and must be accompanied by a hard fork.


## Security Considerations

There are no known security considerations introduced by this change. Adding a pre-compile for Falcon signature verification doesn’t affect the existing signature verification process for ECDSA.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
