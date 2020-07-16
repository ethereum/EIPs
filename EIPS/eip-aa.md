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

* Transactions, other than AA transactions, that call `PAYGAS` are considered
  invalid.
* AA transactions that do not call `PAYGAS` are considered invalid.
* After `PAYGAS` is executed, further invokations during the same transaction
  are treated as noops.
* If `CALLER (0x33)` is invoked in a call intiated by an AA transaction and
  `ORIGIN (0x32) == ADDRESS (0x30)`, then it must return
  `0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA`.
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
    * `STATICCALL (0xFA)`
    * `CREATE2 (0xF5)`
    * `SELFDESTRUCT (0xFF)`

## Rationale

### Only AA transactions can call `PAYGAS`

An alternative is that any transaction can call `PAYGAS`, but if the
transaction has already been sponsored it acts as a noop. The downside to this
approach is that it allows for standard transactions to modify the state of a
contract that may have pending AA transactions.

### AA transactions *must* call `PAYGAS`

AA transactions are a special type of transaction that have no signature format
defined by the protocol. Therefore, it is not clear who should pay for the
transaction. Most of the time, a non-paying AA transaction would simply be
dropped. However, it's possible that there are locked assets controlled by
`0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` and therefore a miner might be
incentivezed to transfer ownership of those assets to themselves by mining a
block with an AA transaction that does not call `PAYGAS`.

### Disallow opcodes that access external data

An invariant in the current protocol that is desirable to retain is the
ability to validate transactions in constant time. Allowing the contract
to access external data before it calls `PAYGAS` makes it possible to construct
a contract which only pay gas if an external property is true (e.g. the value
of another contract is `True`). This behaviour can be exploited to carry-out
denial-of-service attacks on the network by nesting dependencies in a non-obvious
way and invalidating the head -- thereby triggering a massive revalidation. By
forcing AA transactions to not use external data before calling `PAYGAS`, this
invariant is maintained.

## Backwards Compatibility
TODO

## Test Cases
See: https://github.com/quilt/tests/tree/account-abstraction

## Implementation
See: https://github.com/quilt/go-ethereum/tree/account-abstraction

## Security Considerations
TBD

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
