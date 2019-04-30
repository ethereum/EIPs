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

If `block.number >= {FORK_BLOCK}`, the following value ranges are introduced.
They restrict the results (i.e. values pushed to the stack) of the opcodes listed below.

1. *gas*, *gas limit*, *block gas limit*
   is a range between `0` and `9223372036854775807` (`2**63 - 1`).
   It affects following the opcodes:
   - `GASLIMIT` (`0x45`),
   - `GAS` (`0x5a`).
   
2. *block number*, *timestamp*
   is a range between `0` and `9223372036854775807` (`2**63 - 1`).
   It affects the following opcodes:
   - `TIMESTAMP` (`0x42`),
   - `NUMBER` (`0x43`).
   
3. *account address*
   is a range between `0` and `1461501637330902918203684832716283019655932542975` (`2**160 - 1`).
   It affects the following opcodes:
   - `ADDRESS` (`0x30`),
   - `ORIGIN` (`0x32`),
   - `CALLER` (`0x33`),
   - `COINBASE` (`0x41`),
   - `CREATE` (`0xf0`),
   - `CREATE2` (`0xf5`). 
   
4. *buffer size*
   is a range between `0` and `4294967295` (`2**32 - 1`).
   It affects the following opcodes:
   - `CALLDATASIZE` (`0x36`),
   - `CODESIZE` (`0x38`),
   - `EXTCODESIZE` (`0x3b`),
   - `RETURNDATASIZE` (`0x3d`),
   - `MSIZE` (`0x59`).
   

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
2. Do the gas limit applies for the gas param in CALL?

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

[EVMC]: https://github.com/ethereum/evmc
[Aleth]: https://github.com/ethereum/aleth
[ethereumjs]: https://github.com/ethereumjs
[Ethereum testing suite]: https://github.com/ethereum/tests
