---
eip: <to be assigned>
title: Add Poseidon hash function precompile
description: Add a precompiled contract which implements the hash function used in the Poseidon cryptographic hashing algorithm
author: Abdelhamid Bakhta (@abdelhamidbakhta)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2022-11-15
---

## Abstract

This EIP introduces a new precompiled contract which implements the hash function used in the Poseidon cryptographic hashing algorithm, for the purpose of allowing interoperability between the EVM and ZK / Validity rollups, as well as introducing more flexible cryptographic hash primitives to the EVM.

## Motivation

[Poseidon](https://eprint.iacr.org/2019/458.pdf) is an arithmetic hash function that is designed to be efficient for Zero-Knowledge Proof Systems.
Ethereum adopts a rollup centric roadmap and hence must adopt facilities for L2s to be able to communicate with the EVM in an optimal manner.

ZK-Rollups have particular needs for cryptographic hash functions that can allow for efficient verification of proofs.

The Poseidon hash function is a set of permutations over a prime field, which makes it particularly well-suited for the purpose of building efficient ZK / Validity rollups on Ethereum.

Poseidon is one of the most efficient hashing algorithms that can be used in this context.
Moreover it is compatible with all major proof systems (SNARKs, STARKs, Bulletproofs, etc...).
This makes it a good candidate for a precompile that can be used by many different ZK-Rollups.

An important point to note is that ZK rollups using Poseidon have chosen different sets of parameters, which makes it harder to build a single precompile for all of them.

However, we can still build a generic precompile that supports arbitrary parameters, and allow the ZK rollups to choose the parameters they want to use.

This is the approach that we have taken in this EIP.

## Specification

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

The `POSEIDON` precompile MUST be available at address `0xPOSEIDON_PRECOMPILE_ADDRESS`.

The precompile MUST be activated at `FORK_BLOCK_NUMBER`.

Here are the Poseidon parameters that the precompile will support:

- `p`: the prime field modulus.
- `security_level`: the security level measured in bits. Denoted `M` in the Poseidon paper.
- `alpha`: the power of S-box.
- `input_rate`: the size of input.
- `t`: the size of the state.
- `full_round`: the number of full rounds. Denoted as `R_F` in the Poseidon paper.
- `partial_round`: the number of partial rounds. Denoted as `R_P` in the Poseidon paper.

The input to the precompile MUST be encoded as follows:

- `p`: 32 bytes
- `security_level`: 2 bytes
- `alpha`: 1 byte
- `input_rate`: 2 bytes
- `t`: 1 byte
- `full_round`: 1 byte
- `partial_round`: 1 byte
- `input`: `input_rate` \* 32 bytes

```
[32 bytes for p][2 bytes for security_level][1 byte for alpha][2 bytes for input_rate][1 byte for t][1 byte for full_round][1 byte for partial_round][input_rate * 32 bytes for input]
```

The precompile should compute the hash function as [specified in the Poseidon paper](https://eprint.iacr.org/2019/458.pdf) and return hash output.

## Rationale

TODO: Add rationale

## Backwards Compatibility

There is very little risk of breaking backwards-compatibility with this EIP, the sole issue being if someone were to build a contract relying on the address at `0xPOSEIDON_PRECOMPILE_ADDRESS` being empty. The likelihood of this is low, and should specific instances arise, the address could be chosen to be any arbitrary value with negligible risk of collision.

## Test Cases

The Poseidon reference implementation contains test vectors that can be used to test the precompile.
Those tests are available [here](https://extgit.iaik.tugraz.at/krypto/hadeshash/-/blob/master/code/test_vectors.txt).

## Reference Implementation

The reference implementation for various versions of Starkad and Poseidon can be found [here](https://extgit.iaik.tugraz.at/krypto/hadeshash). The repository also includes [test vectors](https://extgit.iaik.tugraz.at/krypto/hadeshash/-/blob/master/code/test_vectors.txt).

Those test vectors can be used to test the implementation of the precompile in the different client implementations.

TODO: Add initial Geth implementation link

## Security Considerations

Quoting Vitalik Buterin from [Arithmetic hash based alternatives to KZG for proto-danksharding](https://ethresear.ch/t/arithmetic-hash-based-alternatives-to-kzg-for-proto-danksharding-eip-4844/13863) thread:

```text
The Poseidon hash function was officially introduced in 2019. Since then it has seen considerable attempts at cryptanalysis and optimization. However, it is still very young compared to popular “traditional” hash functions (eg. SHA256 and Keccak), and its general approach of accepting a high level of algebraic structure to minimize constraint count is relatively untested.
There are layer-2 systems live on the Ethereum network and other systems that already rely on these hashes for their security, and so far they have seen no bugs for this reason. Use of Poseidon in production is still somewhat “brave” compared to decades-old tried-and-tested hash functions, but this risk should be weighed against the risks of proposed alternatives (eg. pairings with trusted setups) and the risks associated with centralization that might come as a result of dependence on powerful provers that can prove SHA256.
```

It is true that arithmetic hash functions are relatively untested compared to traditional hash functions.
However, Poseidon has been thoroughly tested and is considered secure by multiple independent research groups and layers 2 systems are already using it in production (StarkWare, Polygon, Loopring) and also by other projects (e.g. Filecoin).

Moreover, the impact of a potential vulnerability in the Poseidon hash function would be limited to the rollups that use it.

We can see the same rationale for the KZG ceremony in the [EIP-4844](https://eips.ethereum.org/EIPS/eip-4844), arguing that the risk of a vulnerability in the KZG ceremony is limited to the rollups that use it.

List of projects (non exhaustive) using Poseidon:

- StarkWare plans to use Poseidon as the main hash function for StarkNet, and to add a Poseidon built-in in Cairo.
- Filecoin employs POSEIDON for Merkle tree proofs with different arities and for two-value commitments.
- Dusk Network uses POSEIDON to build a Zcash-like protocol for securities trading.11 It also uses POSEIDON
  for encryption as described above.
- Sovrin uses POSEIDON for Merkle-tree based revocation.
- Loopring uses POSEIDON for private trading on Ethereum.
- Polygon uses Poseidon for Hermez ZK-EVM.

### Papers and research related to Poseidon security

- [Poseidon: A New Hash Function for Zero-Knowledge Proof Systems](https://eprint.iacr.org/2019/458.pdf)
- [Security of the Poseidon Hash Function Against Non-Binary Differential and Linear Attacks](https://link.springer.com/content/pdf/10.1007/s10559-021-00352-y.pdf)
- [Report on the Security of STARK-friendly Hash Functions](https://hal.inria.fr/hal-02883253/document)
- [Practical Algebraic Attacks against some Arithmetization-oriented Hash Functions](https://hal.archives-ouvertes.fr/hal-03518757/document)

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
