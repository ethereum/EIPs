---
eip: 7797
title: Double speed for hash_tree_root
description: Double the performance of hash_tree_root by customizing SHA-256
author: Etan Kissling (@etan-status)
discussions-to: https://ethereum-magicians.org/t/eip-7797-double-speed-for-hash-tree-root/21447
status: Draft
type: Standards Track
category: Core
created: 2024-10-23
---

## Abstract

This EIP explains how to customize [`hash_tree_root`](https://github.com/ethereum/consensus-specs/blob/ef434e87165e9a4c82a99f54ffd4974ae113f732/ssz/simple-serialize.md#merkleization) to double its performance.

## Motivation

Hashing is a dominant performance bottleneck for Consensus Layer implementations. To support large validator counts, it is critical to optimize hashing performance.

Consensus Layer hashes are based on [`hash_tree_root`](https://github.com/ethereum/consensus-specs/blob/ef434e87165e9a4c82a99f54ffd4974ae113f732/ssz/simple-serialize.md#merkleization), a mechanism that splits up the data into chunks and then forms a tree by recursively combining two adjacent chunks and hashing them into a single parent chunk until only a single root chunk remains.

For hashing, Secure Hash Algorithm 2 with a digest size of 256 bits is used (SHA-256). This algorithm produces _exactly_ 256 bits of output for a variable-length input message. However, as `hash_tree_root` pads all input chunks to exactly 256 bits, the effective input message length is always _exactly_ 512 bits.

This EIP defines how the SHA-256 algorithm used by `hash_tree_root` can be customized to exploit knowledge of the exact input length to double its performance, while retaining its security properties.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### SHA-256 preprocessing

Before SHA-256 hash computation begins, the input message is preprocessed. A single `1` bit is appended to the input message, followed by a varying number of `0` bits, and finally a big endian `uint64` indicating the input message bit length. The number of `0` bits is chosen so that the message size is the smallest possible multiple of 512 bits. In the context of `hash_tree_root` where the input message size is 512 bits, preprocessing results in the following padded message:

```
         0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
        +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   0x00 |                                               |
   0x10 |                     Input                     |
   0x20 |                    message                    |
   0x30 |                                               |
        +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   0x40 |80|00 00 00 00 00 00 00 00 00 00 00 00 00 00 00|
   0x50 |00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00|
   0x60 |00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00|
   0x70 |00 00 00 00 00 00 00 00|00 00 00 00 00 00 02 00|
        +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

### SHA-256 blocks

SHA-256 operates on message blocks of 512 bits. Therefore, in the context of `hash_tree_root` where the input message size is 512 bits, two message blocks are formed, the first containing the entire input message, and the second containing entirely static data resulting from the preprocessing step.

Note that the second 512 bit message block does not provide any entropy, and is only useful to distinguish input messages that share a common prefix and only vary in the number of trailing `0` bits. As `hash_tree_root` uses a fixed message size, no distinguishing is necessary. Further, SHA-256 is also considered secure for padded messages that fit into a single message block.

### SHA-256-512

A new algorithm SHA-256-512 is defined as a modified SHA-256 algorithm that skips input message preprocessing and is restricted to inputs of exactly 512 bits. The input message SHALL be processed as is, as a single 512-bit SHA-256 message block.

For every [composite SSZ type](https://github.com/ethereum/consensus-specs/blob/ef434e87165e9a4c82a99f54ffd4974ae113f732/ssz/simple-serialize.md#composite-types) in use, implementations SHALL support a new type that shares the same functionality, but hashes using SHA-256-512 instead of regular SHA-256.

### Consensus types

Starting with the hard fork that introduces this EIP, the SHA-256-512 based composite SSZ types SHOULD be preferred over existing SHA-256 based types.

Certain use cases covering historical objects MAY require conversion to the historical data type and re-hashing with the original SHA-256 type to recover their historical root. This includes [`compute_signing_root`](https://github.com/ethereum/consensus-specs/blob/ef434e87165e9a4c82a99f54ffd4974ae113f732/specs/phase0/beacon-chain.md#compute_signing_root) signing over historical data, and also individual fields such as `BeaconState.latest_block_header` which MAY refer to data from prior forks.

Certain other objects such as `DepositData` or `VoluntaryExit` MAY continue to rely on existing SHA-256 logic.

## Rationale

Doubling the throughput of the underlying hash algorithm allows scaling to more validators on the same hardware, or allows using the freed CPU time for other tasks. Even when caching rarely-changed intermediate hashes across computations such as the `validators` list of a `BeaconState`, and employing hardware-accelerated SHA-256 implementations that are further optimized for the tree structure using libraries such as `prysmaticlabs/hashtree`, the state root validation step of the Consensus Layer state transition function can still consume ~25% of CPU time (Holesky test network, ~1.7m validators), mostly dominated by frequently changing per-validator structures such as the `EpochParticipationFlags` lists.

If the hash algorithm is changed to a more zero-knowledge friendly one in the future, similar efforts as described in this EIP would be needed to identify the locations where historical objects need to be hashed using historical hashes, and also to introduce new composite SSZ types. A switch from SHA-256 to SHA-256-512 would pull such work ahead, and any future hash algorithm changes would solely have to extend on these known locations. The total work necessary to switch hash algorithms multiple times is comparable to switching a single time.

Existing hardware acceleration for SHA-256 continues to be viable, as only the message preprocessing step is dropped. Hardware acceleration typically only implements the SHA-256 message block function, which is unchanged by this EIP.

## Backwards Compatibility

Smart contracts and client applications that verify Consensus Layer data require updates to remain compatible with data hashed using SHA-256-512. New logic may be required to correctly select the hash algorithm for historical structures such as `BeaconBlockHeader`.

SSZ serialization, generalized indices, as well as semantics of individual object fields remain unchanged.

## Security Considerations

Certain SHA-256-512 hashes of 512 bit data may collide with regular SHA-256 hashes of shorter data. For example:

- Any common 440-bit prefix: `COMMON_PREFIX := 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f30313233343536`
- `SHA-256-512(COMMON_PREFIX ++ 0x80 ++ 0x00000000000001b8) == 463eb28e72f82e0a96c0a4cc53690c571281131f672aa229e0d45ae59b598b59`
- `SHA-256(COMMON_PREFIX) == 463eb28e72f82e0a96c0a4cc53690c571281131f672aa229e0d45ae59b598b59`

Because SSZ has never hashed data with sizes different from 512 bits, SSZ hashes based on SHA-256 do not collide with hashes based on SHA-256-512.

SHA-256-512 SHOULD NOT be used for purposes other than SSZ Merkleization.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
