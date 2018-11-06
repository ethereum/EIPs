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
Some of these already have an implicit value range due to various reasons.

## Motivation

Having such an explicit value range can help in creating compatible client implementations, in certain cases it can also offer minor speed improvements,
and can reduce the effort needed to create consensus critical test cases.

## Specification

If `block.number >= {FORK_BLOCK}`, the following value ranges are introduced:

- *gas* - 64 bit signed number
- *block number* - 

As a result the behaviour of the following EVM opcodes are altered as stated:

1) `GAS` (`0xf3`)

2) `NUMBER` (`0xf3`)

3) `TIMESTAMP`

4) `BLOCKGAS`

5) `CALL` / `CALLGAS` / `DELEGATECALL` / `STATICCALL`

If `block.number >= BYZANTIUM_FORK_BLKNUM`, add two new opcodes and amend the semantics of any opcode that creates a new call frame (like `CALL`, `CREATE`, `DELEGATECALL`, ...) called call-like opcodes in the following. It is assumed that the EVM (to be more specific: an EVM call frame) has a new internal buffer of variable size, called the return data buffer. This buffer is created empty for each new call frame. Upon executing any call-like opcode, the buffer is cleared (its size is set to zero). After executing a call-like opcode, the complete return data (or failure data, see [EIP-140](./eip-140.md)) of the call is stored in the return data buffer (of the caller), and its size changed accordingly. As an exception, `CREATE` and `CREATE2` are considered to return the empty buffer in the success case and the failure data in the failure case. If the call-like opcode is executed but does not really instantiate a call frame (for example due to insufficient funds for a value transfer or if the called contract does not exist), the return data buffer is empty.


In EVM the

    evmc_uint256be tx_gas_price;     /**< The transaction gas price. */
    evmc_address tx_origin;          /**< The transaction origin account. */
    evmc_address block_coinbase;     /**< The miner of the block. */
    int64_t block_number;            /**< The block number. */
    int64_t block_timestamp;         /**< The block timestamp. */
    int64_t block_gas_limit;         /**< The block gas limit. */
    evmc_uint256be block_difficulty; /**< The block difficulty. */

<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).

## Rationale

These limits have been:
- proposed by [EVMC]
- implemented partially by certain clients, such as [Aleth] and [ethereumjs]
- allowed by certain test cases in the [Ethereum testing suite]
- and implicitly also allowed by certain assumptions, such as due to gas limits some of these values cannot grow past a certain limit

Most of the limits proposed in this document have been previously explored and tested in [EVM].

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

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
