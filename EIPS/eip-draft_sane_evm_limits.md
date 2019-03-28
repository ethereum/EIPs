---
eip: <to be assigned>
title: Sane limits for certain protocol and EVM parameters
author: Alex Beregszaszi (@axic)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2018-08-01
---

## Abstract

Introduce an explicit value range for certain protocol and EVM parameters (such as gas limits, block number, block timestamp, size field when returning/copying data within EVM).
Some of these already have an implicit value range due to various (practical) reasons.

## Motivation

Having such an explicit value range can help in creating compatible client implementations, in certain cases it can also offer minor speed improvements,
and can reduce the effort needed to create consensus critical test cases by eliminating

## Specification

If `block.number >= {FORK_BLOCK}`, the following value ranges are introduced:

- *gas* - 64-bit signed number
- *block gas limit* - 64-bit signed number
- *block number* - 64-bit unsigned number
- *account address* - 160-bit value
- *timestamp* - 64-bit unsigned number
- *buffer sizes* - 32-bit unsigned number

### Protocol changes

### EVM changes

List of affected EVM opcodes:
- address
- balance
- origin
- caller
- callvalue
- calldatasize
- codesize
- gasprice
- extcodesize
- returndatasize
- coinbase
- timestamp
- number
- gaslimit
- msize
- gas
- create
- create2

As a result the behaviour of the following EVM opcodes are altered as stated:

1) `GAS` (`0xf3`) - can only return a 64-bit value

2) `NUMBER` (`0xf3`) - can only return a 64-bit value

3) `TIMESTAMP` - can only return a 64-bit value

4) `BLOCKGAS` - can only return a 64-bit value

5) `CALL` / `CALLGAS` / `DELEGATECALL` / `STATICCALL`

TBD.

## Rationale

These limits have been:
- proposed by [EVMC]
- implemented partially by certain clients, such as [Aleth] and [ethereumjs]
- allowed by certain test cases in the [Ethereum testing suite]
- and implicitly also allowed by certain assumptions, such as due to gas limits some of these values cannot grow past a certain limit

Most of the limits proposed in this document have been previously explored and tested in [EVMC].


## Backwards Compatibility

All of these limits are already enforced mostly through the block gas limit. Since the out of range case results in a transaction failure, there should not be a change in behaviour.
Potentially however, certain contracts could fail at a different point after this change is introduced, and as a result would consume more or less gas than before while doing so.

## Test Cases

TBA

## Implementation

TBA

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

[EVMC]: https://github.com/ethereum/evmc
[Aleth]: https://github.com/ethereum/aleth
[ethereumjs]: https://github.com/ethereumjs
[Ethereum testing suite]: https://github.com/ethereum/tests
