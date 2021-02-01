---
eip: <to be assigned>
title: Memory copying instruction
author: Alex Beregszaszi (@axic), Paul Dworzanski (@poemm), Jared Wasinger (@jwasinger), Casey Detrio (@cdetrio), Pawel Bylica (@chfast)
discussions-to: <tba>
status: Draft
type: Standards Track
category: Core
created: 2021-02-01
---

## Abstract

Provide an efficient EVM instruction for copying memory areas.

## Motivation

Memory copying is a basic operation, yet implementing it on the EVM comes with overhead.

This was recognised and alleviated early on with the introduction of the "identity" precompile, which accomplishes
memory copying by the use of `CALL`'s input and output memory offsets. Its cost is `15 + 3 * (length / 32)` gas, plus
the call overhead. The identity precompile was rendered ineffective by the raise of the cost of `CALL` to 700.

Copying exact words can be accomplished with `<offset> MLOAD <offset> MSTORE` or `<offset> DUP1 MLOAD DUP1 MSTORE`,
at a cost of at least 12 gas. This is fairly efficient if the offsets are known upfront and the copying can be unrolled.
In case copying is implemented at runtime with arbitrary starting offsets, besides the control flow overhead, the offset
will need to be increment using `32 ADD`, adding at least 6 gas per word.

Copying non-exact words is more tricky, as for the last partial word, both the source and destination needs to be loaded,
masked, or'd, and stored again. This overhead is significant. One edge case is if the last "partial word" is a single byte,
it can be efficiently stored using `MSTORE8`.

Memory copying is used by languages like Solidity, where we expect this improvement to provide efficient means building
data structures. Including efficient sliced access of memory objects.

Finally, we expect memory copying to be immensely useful for various computationally heavy operations, such as EVM384,
where it is identified [as a significant overhead](https://notes.ethereum.org/@poemm/evm384-update5#Memory-Manipulation-Cost).

## Specification

Starting `BLOCK_NUMBER >= HF`, a new instruction, `MCOPY` (`0x5c`) is introduced.

It takes three arguments off the stack: (top) `length`, (second from top) `dst`, and `src`.
It copies `length` bytes from the offset pointed at `src` to the offset pointed at `dst` in memory.
If `src + length` or `dst + length` is beyond the current memory length, the memory is extended.

The gas cost of this instruction is `Gverylow * ceil(length / 32)`. (*Initial suggestion.*)

## Rationale

Production implementation of [exact-word memory copying](https://github.com/ethereum/solidity/blob/v0.8.0/libsolidity/codegen/CompilerUtils.cpp#L649) and
[partial-word memory copying](https://github.com/ethereum/solidity/blob/v0.8.0/libsolidity/codegen/CompilerUtils.cpp#L665) can be found in
the Solidity compiler. 

With [EIP-2929](https://eips.ethereum.org/EIPS/eip-2929) the call overhead using the identity precompile will be reduced from 700 to 100 gas.
This is still prohibitive for making the precompile a reasonable alternative again.

## Backwards Compatibility

This EIP introduces a new instruction which did not exists previously. Already deployed contracts using this instruction could change their behaviour after this EIP.

## Test Cases

TBA

## Implementation

TBA

## Security Considerations

TBA

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
