### Title

      EIP: 9
      Title: Add precompiled contracts for blockchain interoperability
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

### Rationale

Besides being a useful cryptographic hash function and SHA3 finalist, BLAKE2b allows for efficient verification of the Equihash PoW used in Zcash, making a BTC Relay - style SPV client possible on Ethereum. One BLAKE2 digest in Soldity, (see https://github.com/tjade273/eth-blake2/blob/optimise_everything/contracts/blake2.sol) currently requires `~480,000 + ~90*INSIZE` gas, and a single verification of an [Equihash](https://www.internetsociety.org/sites/default/files/blogs-media/equihash-asymmetric-proof-of-work-based-generalized-birthday-problem.pdf) PoW verification requires 2<sup>5</sup> to 2<sup>7</sup> iterations of the hash function, making verification of Zcash block headers prohibitively expensive.

The BLAKE2b algorithm is highly optimised for 64-bit CPUs, and is faster than MD5 on modern processors.

Interoperability with Zcash would enable trustless atomic swaps between the chain, which could provide a much needed aspect of privacy to the very public Ethereum blockchain.

Other functions useful for cross-chain interoperability, such as the Scrypt KDF, should also be considered for inclusion.

# Implementation

There are public-domain BLAKE2b libraries in most languages:

* [Go](https://godoc.org/github.com/codahale/blake2#pkg-files)
* [Python](https://github.com/dchest/pyblake2)
* [Rust](https://github.com/cesarb/blake2-rfc)
* [JavaScript](https://github.com/ludios/node-blake2)
* [Java](https://github.com/alphazero/Blake2b)
* [C++](https://github.com/BLAKE2/BLAKE2)
