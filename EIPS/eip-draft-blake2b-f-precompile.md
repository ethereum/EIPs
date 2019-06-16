---
eip: <to be assigned>
Title: Add Blake2 compression function `F` precompile
Author: Tjaden Hess <tah83@cornell.edu>, Matt Luongo (@mhluongo)
discussions-to: https://ethereum-magicians.org/t/blake2b-f-precompile/3157
Status: Draft
type: Standards Track
category Core
Created 2016-10-04
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

This EIP will enable the Blake2b hash function to run cheaply on the EVM, allowing easier interoperability between Ethereum and Zcash as well as other Equihash-based PoW coins.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

This EIP introduces a new precompiled contract which implements the compression function `F` used in the BLAKE2b cryptographic hashing algorithm, for the purpose of allowing interoperability between the EVM and Zcash, as well as introducing more flexible cryptographic hash primitives to the EVM.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

Besides being a useful cryptographic hash function and SHA3 finalist, BLAKE2b allows for efficient verification of the Equihash PoW used in Zcash, making a BTC Relay - style SPV client possible on Ethereum. A single verification of an Equihash PoW verification requires 512 iterations of the hash function, making verification of Zcash block headers prohibitively expensive if a Solidity implementation of BLAKE2b is used.

The BLAKE2b algorithm is highly optimized for 64-bit CPUs, and is faster than MD5 on modern processors.

Interoperability with Zcash could enable contracts like trustless atomic swaps between the chains, which could provide a much needed aspect of privacy to the very public Ethereum blockchain.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

Adds a precompile at address `0x0d` which accepts [ABI encoded](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI) arguments corresponding to the function signature

```
F(bytes32[2] h, bytes32[4] m, uint t , bool f, uint rounds) returns (bytes32[2] h_new);
```

where `h`, `m`, `t` and `f` are the current state, the new message, the byte counter and a finalization flag, as defined in [RFC 7693](https://tools.ietf.org/html/rfc7693), and `rounds` is the number of rounds of mixing to perform (BLAKE2b uses 12, BLAKE2s uses 10). `h_new` is the updated state of the hash.

Each operation will cost `GFROUND * rounds`.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The most frequent concern with EIPs of this type is that the addition of specific functions at the protocol level is an infringement on Ethereum's "featureless" design. It is true that a more elegant solution to the issue is to simply improve the scalability characteristics of the network so as to make calculating functions requiring millions of gas practical for everyday use. In the meantime, however, I believe that certain operations are worth subsidising via precompiled contracts and there is significant precedent for this, most notably the inclusion of the SHA256 prcompiled contract, which is included largely to allow inter-operation with the Bitcoin blockchain.

Additionally, BLAKE2b is an excellent candidate for precompilation because of the extremely asymetric efficiency which it exhibits. BLAKE2b is heavily optimized for modern 64-bit CPUs, specifically utilizing 24 and 63-bit rotations to allow parallelism through SIMD instructions and little-endian arithmetic. These characteristics provide exceptional speed on native CPUs: 3.08 cycles per byte, or 1 gibibyte per second on an Intel i5.

In contrast, the big-endian 32 byte semantics of the EVM are not conducive to efficient implementation of BLAKE2, and thus the gas cost associated with computing the hash on the EVM is disproportionate to the true cost of computing the function natively.

Implementation of only the core F compression function allows substantial flexibility and extensibility while keeping changes at the protocol level to a minimum. This will allow functions like tree hashing, incremental hashing, and keyed, salted, and personalized hashing as well as variable length digests, none of which are currently available on the EVM.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

There is very little risk of breaking backwards-compatibility with this EIP, the sole issue being if someone were to build a contract relying on the address at `0x0d` being empty. The likelihood of this is low, and should specific instances arise, the address could be chosen to be any arbitrary value with negligible risk of collision.

## Test Cases

<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

Test cases are in progress, and can be followed along in our [Golang Blake2 library fork](https://github.com/keep-network/blake2-f) as well as our fork of [go-ethereum](https://github.com/keep-network/go-ethereum).

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

Implementations are in progress, and can be followed along in our [Golang Blake2 library fork](https://github.com/keep-network/blake2-f) as well as our fork of [go-ethereum](https://github.com/keep-network/go-ethereum).

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
