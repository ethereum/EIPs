---
eip: <to be assigned>
title: Sane limits for certain EVM parameters
author: Alex Beregszaszi (@axic), Paweł Bylica (@chfast)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2018-08-01
---

## Abstract

Introduce an explicit value range for certain EVM parameters
(such as gas limit, block number, block timestamp, size field when returning/copying data within EVM).
Some of these already have an implicit value range due to various (practical) reasons.

## Motivation

Having such an explicit value range can help in creating compatible client implementations,
in certain cases it can also offer minor speed improvements,
and can reduce the effort needed to create consensus critical test cases 
by eliminating unrealistic edge cases.

## Specification

If `block.number >= {FORK_BLOCK}`, the following value ranges are introduced:

- *gas* - a number between 0 and 9223372036854775807 (2**63 - 1)
- *gas limit* - a number between 0 and 9223372036854775807 (2**63 - 1)
- *block gas limit* - a number between 0 and 9223372036854775807 (2**63 - 1)
- *block number* - a number between 0 and 9223372036854775807 (2**63 - 1)
- *account address* - a number between 0 and 1461501637330902918203684832716283019655932542975 (2**160 - 1)
- *timestamp* - a number between 0 and 9223372036854775807 (2**63 - 1)
- *buffer sizes* - a number between 0 and 4294967295 (2**31 - 1)

### EVM changes

As a result the behaviour of the following EVM opcodes are altered as stated:

1) `ADDRESS` (`0x30`) - pushes a 160-bit (mod 2**160) value to the stack
1) `ORIGIN` (`0x32`) - pushes a 160-bit (mod 2**160) value to the stack
1) `CALLER` (`0x33`) - pushes a 160-bit (mod 2**160) value to the stack
1) `CALLDATASIZE` (`0x36`) - pushes a 32-bit (mod 2**32) value to the stack
1) `CODESIZE` (`0x38`) - pushes a 32-bit (mod 2**32) value to the stack
1) `EXTCODESIZE` (`0x3b`) - pushes a 32-bit (mod 2**32) value to the stack
1) `RETURNDATASIZE` (`0x3d`) - pushes a 32-bit (mod 2**32) value to the stack
1) `COINBASE` (`0x41`) - pushes a 160-bit (mod 2**160) value to the stack
1) `TIMESTAMP` (`0x42`) - pushes a 63-bit (mod 2**63) value to the stack
1) `NUMBER` (`0x43`) - pushes a 63-bit (mod 2**63) value to the stack
1) `GASLIMIT` (`0x45`) - pushes a 63-bit (mod 2**63) value to the stack
1) `MSIZE` (`0x59`) - pushes a 32-bit (mod 2**32) value to the stack
1) `GAS` (`0x5a`) - pushes a 63-bit (mod 2**63) value to the stack
1) `CREATE` (`0xf0`) - pushes a 160-bit (mod 2**160) value to the stack
1) `CREATE2` (`0xf5`) - pushes a 160-bit (mod 2**160) value to the stack

## Rationale

These limits have been:
- proposed by [EVMC]
- implemented partially by certain clients, such as [Aleth] and [ethereumjs]
- allowed by certain test cases in the [Ethereum testing suite]
- and implicitly also allowed by certain assumptions, such as due to gas limits some of these values cannot grow past a certain limit

Most of the limits proposed in this document have been previously explored and tested in [EVMC].

Using the `2**63 - 1` constant to limit some of the ranges:
- allows using singed 64-bit integer type to represent it, 
  what helps programming languages not having unsigned types,
- makes arithmetic simpler (e.g. checking out-of-gas conditions is simple as `gas_counter < 0`).


## Backwards Compatibility

All of these limits are already enforced mostly through the block gas limit. Since the out of range case results in a transaction failure, there should not be a change in behaviour.
Potentially however, certain contracts could fail at a different point after this change is introduced, and as a result would consume more or less gas than before while doing so.

## Test Cases

TBA

## Implementation

TBA

## TODO

1. The size of addresses are specified in Yellow Paper, 
e.g. COINBASE is specified as returning H_c which has 20 bytes.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

[EVMC]: https://github.com/ethereum/evmc
[Aleth]: https://github.com/ethereum/aleth
[ethereumjs]: https://github.com/ethereumjs
[Ethereum testing suite]: https://github.com/ethereum/tests
