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
Poseidon is one of the most efficient hashing algorithms that can be used in this context.
Moreover it is compatible with all major proof systems (SNARKs, STARKs, Bulletproofs, etc...).

## Specification

TODO: Add specification

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
However, Poseidon has been thoroughly tested and is considered secure by multiple independent research groups and layers 2 systems are already using it in production (StarkWare, Polygon, Loopring).

Moreover, the impact of a potential vulnerability in the Poseidon hash function would be limited to the rollups that use it.

We can see the same rationale for the KZG ceremony in the [EIP-4844](https://eips.ethereum.org/EIPS/eip-4844), arguing that the risk of a vulnerability in the KZG ceremony is limited to the rollups that use it.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
