### Title

      Title: Add precompiled BLAKE2b contract
      Author: Tjaden Hess <tah83@cornell.edu>
      Status: Draft
      Type: Standard Track
      Layer: Consensus (hard-fork)
      Created 2016-06-30

### Abstract

This EIP introduces a new precompiled contract which implements the BLAKE2b cryptographic hashing algorithm, for the purpose of allowing interoperability between the Zcash blockchain and the EVM.

### Parameters

* `METROPOLIS_FORK_BLKNUM`: TBD
* `GBLAKEBASE`: 30
* `GBLAKEWORD`: 6

### Specification

Adds a precompile at address `0x0000....0c` which accepts a variable length input interpreted as

    [INSIZE, OUTSIZE, D_1, D_2, ..., D_INSIZE]


 where `INSIZE` is the length in words of the input. If the bytes of data provided is fewer than `INSIZE`, remaining bytes are assumed to be zero, extra bytes are ignored. Throws if `OUTSIZE` is greater than 64. Returns the `OUTSIZE`-byte BLAKE2b digest, as defined in [RFC 7693](https://tools.ietf.org/html/rfc7693).

Gas costs would be equal to `GBLAKEBASE + GBLAKEWORD * INSIZE`

In order to maintain backwards compatibility, the precompile will return `0` if `CURRENT_BLOCKNUM < METROPOLIS_FORK_BLKNUM`

### Motivation

Besides being a useful cryptographic hash function and SHA3 finalist, BLAKE2b allows for efficient verification of the Equihash PoW used in Zcash, making a BTC Relay - style SPV client possible on Ethereum. One BLAKE2 digest in Soldity, (see https://github.com/tjade273/eth-blake2/blob/optimise_everything/contracts/blake2.sol) currently requires `~480,000 + ~90*INSIZE` gas, and a single verification of an [Equihash](https://www.internetsociety.org/sites/default/files/blogs-media/equihash-asymmetric-proof-of-work-based-generalized-birthday-problem.pdf) PoW verification requires 2<sup>5</sup> to 2<sup>7</sup> iterations of the hash function, making verification of Zcash block headers prohibitively expensive.

The BLAKE2b algorithm is highly optimized for 64-bit CPUs, and is faster than MD5 on modern processors.

Interoperability with Zcash would enable trustless atomic swaps between the chains, which could provide a much needed aspect of privacy to the very public Ethereum blockchain.

### Rationale

The most frequent concern with EIPs of this type is that the addition of specific functions at the protocol level is an infringement on Ethereum's "featureless" design. It is true that a more elegant solution to the issue is to simply improve the scalability characteristics of the network so as to make calculating functions requiring millions of gas practical for everyday use. In the meantime, however, I believe that certain operations are worth subsidising via precompiled contracts and there is significant precedent for this, most notably the inclusion of the SHA256 prcompiled contract, which is included largely to allow inter-operation with the Bitcoin blockchain.

Additionally, BLAKE2b is an excellent candidate for precompilation because of the extremely asymetric efficiency which it exhibits. BLAKE2b is heavily optimized for modern 64-bit CPUs, specifically utilizing 24 and 63-bit rotations to allow parallelism through SIMD instructions and is little-endian. These characteristics provide exceptional speed on native CPUs: 3.08 cycles per byte, or 1 gibibyte per second on an Intel i5.

In contrast, the big-endian 32 byte semantics of the EVM are not conducive to efficient implementation of BLAKE2, and thus the gas cost associated with computing the hash on the EVM is disproportionate to the true cost of computing the function natively.

Note that the function can produce a variable-length digest, up to 64 bytes, which is a feature currently missing from the hash functions included in the EVM and is an important component in the Equihash PoW algorithm.  

There is very little risk of breaking backwards-compatibility with this EIP, the sole issue being if someone were to build a contract relying on the address at `0x000....0000c` being empty. Te likelihood of this is low, and should specific instances arise, the address could be chosen to be any arbitrary value, with negligible risk of collision.

The community response to this EIP has been largely positive, and besides the "no features" issue, there have as yet been no major objections to its implementation.
