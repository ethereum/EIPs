# Title

Title: Add RFC 7693 compression function `F` contract
Author: Tjaden Hess <tah83@cornell.edu>
Status: Draft
Type: Standard Track
Layer: Consensus (hard-fork)
Created 2016-10-04

### Abstract

This EIP introduces a new precompiled contract which implements the compression function F used in the BLAKE2b cryptographic hashing algorithm, for the purpose of allowing interoperability between the Zcash blockchain and the EVM, and introducing more flexible cryptographic hash primitives to the EVM.

## Parameters

* `METROPOLIS_FORK_BLKNUM`: TBD
* `GFROUND`: TBD

## Specification

Adds a precompile at address `0x0000....0d` which accepts [ABI encoded](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI) arguments corresponding to the function signature

```
F(bytes32[2] h, bytes32[4] m, uint t , bool f, uint rounds) returns (bytes32[2] h_new);
```

where `h`, `m`, `t` and `f` are the current state, the new message, the byte counter and a finalization flag, as defined in [RFC 7693](https://tools.ietf.org/html/rfc7693), and `rounds` is the number of rounds of mixing to perform (BLAKE2b uses 12, BLAKE2s uses 10). `h_new` is the updated state of the hash.

Each operation will cost `GFROUND * rounds`.

## Motivation

Besides being a useful cryptographic hash function and SHA3 finalist, BLAKE2b allows for efficient verification of the Equihash PoW used in Zcash, making a BTC Relay - style SPV client possible on Ethereum. A single verification of an Equihash PoW verification requires 512 iterations of the hash function, making verification of Zcash block headers prohibitively expensive if a Solidity implementation of BLAKE2b is used.

The BLAKE2b algorithm is highly optimized for 64-bit CPUs, and is faster than MD5 on modern processors.

Interoperability with Zcash could enable contracts like trustless atomic swaps between the chains, which could provide a much needed aspect of privacy to the very public Ethereum blockchain.

## Rationale

The most frequent concern with EIPs of this type is that the addition of specific functions at the protocol level is an infringement on Ethereum's "featureless" design. It is true that a more elegant solution to the issue is to simply improve the scalability characteristics of the network so as to make calculating functions requiring millions of gas practical for everyday use. In the meantime, however, I believe that certain operations are worth subsidising via precompiled contracts and there is significant precedent for this, most notably the inclusion of the SHA256 prcompiled contract, which is included largely to allow inter-operation with the Bitcoin blockchain.

Additionally, BLAKE2b is an excellent candidate for precompilation because of the extremely asymetric efficiency which it exhibits. BLAKE2b is heavily optimized for modern 64-bit CPUs, specifically utilizing 24 and 63-bit rotations to allow parallelism through SIMD instructions and little-endian arithmetic. These characteristics provide exceptional speed on native CPUs: 3.08 cycles per byte, or 1 gibibyte per second on an Intel i5.

In contrast, the big-endian 32 byte semantics of the EVM are not conducive to efficient implementation of BLAKE2, and thus the gas cost associated with computing the hash on the EVM is disproportionate to the true cost of computing the function natively.

Implementation of only the core F compression function allows substantial flexibility and extensibility while keeping changes at the protocol level to a minimum. This will allow functions like tree hashing, incremental hashing, and keyed, salted, and personalized hashing as well as variable length digests, none of which are currently available on the EVM.

There is very little risk of breaking backwards-compatibility with this EIP, the sole issue being if someone were to build a contract relying on the address at `0x000....0000d` being empty. Te likelihood of this is low, and should specific instances arise, the address could be chosen to be any arbitrary value, with negligible risk of collision.
