---
eip: <to be assigned> \
title: DEST Operation \
description: Add the DEST operation to the EVM \
author: Danno Ferrin (@shemnon) \
discussions-to: http://twitter.com/ \
status: Draft  \
type: Standards Track \
category : Core \
created: 2022-04-01 \
requires : 3670, 3855 \
---

## Abstract

Add `DEST` operation to the EVM, allowing control flow code to say where execution comes from.

## Motivation

The EVM has long had a parallel to the controversial GOTO operation ("Edgar Dijksta: Go To Statement
Considered Harmful", *Communications of the ACM.* 11 (3): 147–148), but there is a lesser known and
equally powerful operation that has not been implemented: COMEFROM (EIP link policies prevent a
relevant external link). By implementing the `DEST` operation that implements the COMEFROM semantics
we can bring a 50-year-old concept to the Ethereum ecosystem.

## Specification

The `DEST` operation is introduced at `0x5C` _&lt;ed. presuming no other conflicts&gt;_. This
operation has a two byte immediate argument. This two byte argument is a little endian distance of
this operation from a preceding `JUMPDEST` operation.

All indexes must be positive values, counting forward from the target `JUMPDEST`. Implementations
may model the index as a little endian `int16`. If a `DEST` operation does not refer to a
valid `JUMPDEST` operation the entire contract MUST fail EOF validation as an invalid operation
(see [EIP-3670](https://eips.ethereum.org/EIPS/eip-3670)).

When the EVM evaluates a `JUMPDEST` operation it will first assess any `DEST` operations that refer
to the current PC location. Each `DEST` target will be evaluated in descending PC order. The current
value on the stack will be popped, and if it is zero the PC will be set to the instruction
immediately following the `DEST` instruction being evaluated. No further `DEST`
operations will be evaluated once a new PC location is set. If no `DEST` operations apply the PC is
set to the instruction following the `JUMPDEST` operation.

## Rationale

### Requirement for positive relative index

The requirement that all `DEST` indexes be a positive relative index ensures that there will be no
backwards looping. This will ensure ZK Provability of contracts that exclusively use `DEST`
for control flow.

### Conditional `DEST`

With a conditional operation all control flow for ZK provable contracts can be implemented
with `DEST`. Adding an unconditional `DEST` cam be accomplished by calling `PUSH0` before
the `JUMPDEST`.

### Moving PC on zeros

Having `DEST` update the PC on a zero instead of a non-zero will allow `PUSH0` to be used for
unconditional `DEST` reducing code size.

### Reusing `JUMPDEST`

Two other alternatives were considered instead of reusing `JUMPDEST`. The first alternative was to
not use a marker operation and allow any operation to be pointed to by a `DEST` operation. However,
this was rejected for the same reasons that not using `JUMPDEST` was rejected for the `JUMP`
and `JUMPI` instructions. <!-- ed. What were these reasons? op. Nobody knows. -->

The second was to use three operations: `DEST`, `DESTI`, and `SRC`. By reusing `JUMPDEST`
for `SRC` and having a conditional only construction only one operation needed to be added to the
EVM, easing EVM implementor and ZK Proof modeler concerns.

The use of the name `DEST` also makes it clear that `JUMPDEST` applies to both operations, improving
the readability of assembly blocks in downstream languages like solidity and vyper.

## Backwards Compatibility

Because a multi-byte instruction is specified this will
require [EIP-3670](https://eips.ethereum.org/EIPS/eip-3670) and all dependent EIPs.

## Test Cases

//TODO -- pending testnet consensus failures

## Reference Implementation

//TODO -- investigating DAO funding

## Security Considerations

There are no security considerations because nobody implements April Fools' jokes.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
