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
Account abstraction (AA) allows contracts to pay for user transactions.

## Motivation
Transaction validity is defined rigidly by the protocol, precluding innovation.
Allowing contracts to determine whether they will pay for a transaction makes
it possible for developers to innovate in this area. If alternative
requirements for transaction validity are added over time, Account Abstraction
would actually reduce the protocol's resulting complexity. Over the years,
there have been numerous proposals which would've benefited from
contract-defined transaction validity. From obvious proposals, like
multi-sig transaction, to more radical ones, such as allowing signatures to be
batched and verified at the block level--these can be primarily implemented
using Account Abstraction, instead of being explicitly defined and implemented
in every client.

## Specification

After `FORK_BLOCK`, the following changes will be recognized by the protocol.

### New Transaction Type
A new EIP-2718 transaction with type `2` is introduced. Transactions of this
type are referred to as "AA transactions". Their payload should be interpreted
as `rlp([gas_limit, to, data])`.

### `PAYGAS (0xAA)` Opcode

A new opcode `PAYGAS (0xAA)` is introduced. It consumes a single stack element
representing the `gas_price` that the contract is willing to pay for the
subsequent execution. If the contract's balance is at least `gas_price *
tx.gas_limit`, then that amount will subtracted from the contract's balance and
execution will proceed. At the end of execution, the contract will be refunded
for any remaining gas. If the contract's balance is too low, then execution
will revert and the contract will not pay for the execution.

### Execution Semantics

The following semantics are enforced:

* Transactions, other than AA transactions, that call `PAYGAS` are invalid.
* AA transactions that do not call `PAYGAS` are invalid.
* Multiple invocations of `PAYGAS` must cause a revert.
* If `ORIGIN (0x32)` or `CALLER (0x33)` is invoked in the first frame of
  execution of a call initiated by an AA transaction, then it must return
  `0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA`.
* If `ORIGIN (0x32)` is invoked in any other frame of execution of an AA
  transaction it must return `tx.to`.
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
* AA transactions' `tx.to` must be a contract that begins with a prelude that
  verifies `CALLER == 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA`, otherwise
  the transaction is invalid.


### Mining Strategies
TODO

## Rationale

### AA transactions *must* call `PAYGAS`

AA transactions are a special type of transaction that have no signature format
defined by the protocol. Therefore, it's not immediately clear who should pay
for the transaction. Most of the time, a non-paying AA transaction would simply
be dropped. However, it's possible that there are locked assets controlled by
`0xAA...AA`. This could incentivize a miner to mine a block with an AA
transaction that does not call `PAYGAS`, gaining control of any assets owned by
`0xAA...AA`.

### Disallow opcodes that access external data

An important property of legacy transactions is the ability to validate them in
constant time. This is due to the finite validity requirements of legacy
transactions (e.g. signature recovery & nonce / balance check). 

Allowing Abstract Accounts to access external data before they calls `PAYGAS`
makes it possible to write validation logic with infinite validity requirements.
Although clients can bound the validation computation to some rational amount,
it's impossible to bound the space of potential validity dependencies. 

This can be extorted to create long, opaque chains of dependent transactions
that can be completely invalidated by a single new transaction. This forces
miners to revalidate each one in the order they intend to include them in a
block, creating a denial-of-service vector.

To avoid this, Abstract Accounts must be validatable in constant time. This is
achieved by removing their ability to rely on data external to their own account.
Miners can then adjust the number of AA transactions they are willing to validate
per account on an as-needed basis.

It's important that this execution semantic is enforced by the protocol and not
just a transaction pool heuristic. If this were not the case, malicious miners
could invalidate an innumerable number of pending transactions with a single
transaction in a malicious, but valid, block.

### AA transactions must call contracts with prelude

The prelude is used to ensure that *only* AA transactions can call the
contract. This is another measure taken to ensure the invariant described
above. If this check did not occur, it would be possible for a transaction to
invalidate an innumerable number of AA transactions.

There are drawbacks to the prelude mechanism. Upgrades to AA in the future may
require modified logic in the prelude, which would require one of the
following:
* changing the bytecode in the affect contracts
* changing the semantics of that specific bytecode prefix
* introducing a new version of AA. 

None of these solutions are desirable.

The optimal solution is to recognize AA contracts at the protocol level as a
type of account separate from EOAs and contracts. This would provide the
flexibility to make modifications in the future, without the need to continue
supporting legacy versions. This is not the path taken in this EIP due to the
increased complexity and risk that an additional type would incur. 

## Backwards Compatibility
It is possible that an AA contract does not implement a replay protection
mechanism, allowing a single transaction to be included multiple times
on-chain. This would break the transaction uniqueness invariant currently
maintained by the network and affect downstream applications which rely
on this invariant.

We anticipate to resolve this compatibility issue before this EIP reaches
a finalized state, after which there will be no backwards compatibility
concerns.

## Test Cases
See: https://github.com/quilt/tests/tree/account-abstraction

## Implementation
See: https://github.com/quilt/go-ethereum/tree/account-abstraction

## Security Considerations

Much of the work on this EIP has been focused on addressing the security
concerns that arise in the `tx_pool`. Although the miner strategies laid out
here are not required in a hard fork, they are important for maintaining the
network's resilience.

### Transaction pool validation
When a transaction enters the `tx pool`, the client is able to quickly
ascertain whether the transaction is valid. Once it determines this, it can be
confident that the transaction will continue to be valid unless a transaction
from the same account invalidates it.

#### Block invalidation attack
The attack can be carried out as follows. Suppose an adversary has deployed
many AA contracts. The adversary sends a valid transaction to each of the AA
contracts. Before the transactions can be included in a block, the adversary
releases a block with transactions to each of their AA contracts that
invalidate the pending transactions. The transactions in the block can be very
minimal, just enough to update a nonce--whereas the transactions that are
pending would be maximally expensive to validate.

This attack allows the adversary to force clients on the network to perform
work disproportionate to the amount of work paid for on-chain. There is no
"solution" to an attack like this. It's possible to carry out on today's
network, but the cost of validation is so low that is not a concern.
Significantly increasing the amount of computation required for validation
gives adversaries a larger attack surface. This is why is is important for
miners to follow the recommended mining strategies as they will minimize their
vulnerability to attacks of this type.

#### Peer denial-of-service
TODO

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
