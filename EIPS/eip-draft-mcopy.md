---
eip: <to be assigned>
title: Memory copying instruction
description: An efficient EVM instruction for copying memory areas
author: Alex Beregszaszi (@axic), Paul Dworzanski (@poemm), Jared Wasinger (@jwasinger), Casey Detrio (@cdetrio), Pawel Bylica (@chfast), Charles Cooper (@charles-cooper)
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
the call overhead. The identity precompile was rendered ineffective by the raise of the cost of `CALL` to 700, but subsequently
the reduction by EIP-2929 made it slightly more economical.

Copying exact words can be accomplished with `<offset> MLOAD <offset> MSTORE` or `<offset> DUP1 MLOAD DUP2 MSTORE`,
at a cost of at least 12 gas per word. This is fairly efficient if the offsets are known upfront and the copying can be unrolled.
In case copying is implemented at runtime with arbitrary starting offsets, besides the control flow overhead, the offset
will need to be incremented using `32 ADD`, adding at least 6 gas per word.

Copying non-exact words is more tricky, as for the last partial word, both the source and destination needs to be loaded,
masked, or'd, and stored again. This overhead is significant. One edge case is if the last "partial word" is a single byte,
it can be efficiently stored using `MSTORE8`.

As example use case, copying 256 bytes costs:
- at least 757 gas pre-EIP-2929 using the identity precompile
- at least 157 gas post-EIP-2929 using the identity precompile
- at least 96 gas using unrolled `MLOAD`/`MSTORE` instructions
- 27 gas using this EIP

According to [an analysis done by ipsilon](https://notes.ethereum.org/@ipsilon/evm-mcopy-analysis), roughly 10.5% of memory copies from blocks 10537502 to 10538702 would have had improved performance with the availability of an `MCOPY` instruction.

Memory copying is used by languages like Solidity and Vyper, where we expect this improvement to provide efficient means of building data structures, including efficient sliced access and copies of memory objects. Having a dedicated `MCOPY` instruction would also add forward protection against future gas cost changes to `CALL` instructions in general.

Having a special `MCOPY` instruction makes the job of static analyzers and optimizers easier, since the effects of a `CALL` in general have to be fenced, whereas an `MCOPY` instruction would be known to only have memory effects. Even if special effects cases are added for precompiles, a future hard fork could change `CALL` effects, and so any analysis of code using the identity precompile would only be valid for a certain range of blocks(!).

Finally, we expect memory copying to be immensely useful for various computationally heavy operations, such as EVM384,
where it is identified [as a significant overhead](https://notes.ethereum.org/@poemm/evm384-update5#Memory-Manipulation-Cost).

## Specification

Starting `BLOCK_NUMBER >= HF`, a new instruction, `MCOPY` (`0x5c`) is introduced.

It takes three arguments off the stack (1. represents the top of the stack):
1. `dst`
2. `src`
3. `length`

It copies `length` bytes from the offset pointed at `src` to the offset pointed at `dst` in memory.

If `length > 0` and (`src + length` or `dst + length`) is beyond the current memory length, the memory is extended with respective gas cost applied.

The gas cost of this instruction mirrors that of other `Wcopy` instructions and is `Gverylow + Gcopy * ceil(length / 32)`.

The memory effects of `<length> <src> <dst> MCOPY` should match `<length> <dst> DUP2 <src> PUSH1 0 PUSH1 4 GAS CALL` exactly. To clarify a particular ambiguity - if the source and destination buffers overlap, the semantics are more similar to libc's `memmove` than `memcpy` - that is, copying takes place as if the bytes were copied to a temporary buffer `buf`, and then the bytes were copied from the temporary buffer to dst.

## Rationale

Production implementation of [exact-word memory copying](https://github.com/ethereum/solidity/blob/v0.8.0/libsolidity/codegen/CompilerUtils.cpp#L649) and
[partial-word memory copying](https://github.com/ethereum/solidity/blob/v0.8.0/libsolidity/codegen/CompilerUtils.cpp#L665) can be found in
the Solidity compiler. 

With [EIP-2929](https://eips.ethereum.org/EIPS/eip-2929) the call overhead using the identity precompile was reduced from 700 to 100 gas.
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
