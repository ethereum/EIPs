---
eip: <to be assigned>
title: Account Abstraction
author: Ansgar Dietrichs (@adietrichs), Matt Garnett (@lightclient), Will Villanueva (@villanuevawill), Sam Wilson (@SamWilsn)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2020-08-15
requires: 2718
replaces: 86
---

## Simple Summary
Account abstraction (AA) allows contracts to pay for users' transactions.

## Motivation
TODO

## Specification

After `FORK_BLOCK`, the following changes will be recognized by the protocol.

### New Transaction Type
A new EIP-2718 transaction with type `2` is introduced. Transactions of this
type are referred to as "AA transactions". Their payload is be interpreted as
`rlp([gas_limit, to, data])`.

### `PAYGAS (0xAA)` Opcode

A new opcode `PAYGAS (0xAA)` is introduced. It consumes a single stack element
representing the `gas_price` that the contract is willing to pay for the
subsequent execution. If the contract's balance is at least `gas_price *
tx.gas_limit`, then that amount will subtracted from the contract's balance
and execution will proceed. At the end of execution, the contract will be
refunded for any remaining gas. If the contract's balance is too low, then
execution will revert and the contract will not pay for the execution.

### Execution Semantics

The following semantics are enforced:

* AA transactions which do not call `PAYGAS` are considered invalid
* After `PAYGAS` is first called, further calls during the same transaction
  are treated as noops
* If `PAYGAS` is called after any of the following opcodes are encountered,
  it must revert:
    * `BALANCE (0x31)`
    * `GASPRICE (0x3A)`
    * `EXTCODESIZE (0x3B)`
    * `EXTCODECOPY (0x3C)`
    * `EXTCODEHASH (0x3F)`
    * `BLOCKHASH (0x40)`
    * `COINBASE (0x41)`
    * `TIMESTAMP (0x42)`
    * `NUMBER (0x43)`
    * `DIFFICULTY (0x44)`
    * `GASLIMIT (0x45)`
    * `CREATE (0xF0)`
    * `CALL (0xF1)`
    * `CALLCODE (0xF2)`
    * `DELEGATECALL (0xF4)`
    * `CREATE2 (0xF5)`
    * `SELFDESTRUCT (0xFF)`

## Rationale
TODO

## Backwards Compatibility
TODO

## Test Cases
TODO

## Implementation
TODO

## Security Considerations
TBD

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
