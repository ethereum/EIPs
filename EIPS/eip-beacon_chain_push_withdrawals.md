---
eip: TBD
title: Beacon chain push withdrawals
description: Support validator withdrawals from the beacon chain to the EVM via a new "push-style" transaction type.
author: Alex Stokes (@ralexstokes), Danny Ryan (@djrtwo)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2022-02-28
---

## Abstract

Introduce a new [EIP-2718 transaction type](./eip-2718.md) to support validator withdrawals that are "pushed" from the beacon chain to the EVM.

Add block validations to ensure the withdrawal transactions are sound with respect to withdrawal processing on the beacon chain.

## Motivation

This EIP provides a way for validators withdrawals made on the beacon chain to enter into the EVM.
The architecture is "push"-based, rather than "pull"-based, where withdrawals are required to be processed in the execution block as soon as they are dequeued from the beacon chain.

This approach is more involved than "pull"-based alternatives (e.g. [EIP-4788](./eip-4788.md) + user-space withdrawal contract) with respect to the core protocol (by providing a new transaction type with special semantics) but does provide tighter integration of a critical feature into the protocol itself.

## Specification

| constants                     | value                                          | units
|---                            |---                                             |---
| `FORK_TIMESTAMP`              | TBD                                            |
| `WITHDRAWAL_TX_TYPE`          | `0x3`                                          | byte

Beginning with the execution timestamp `FORK_TIMESTAMP`, execution clients **MUST** introduce the following extensions to transaction processing and block validation:

### New transaction type

Define a new [EIP-2718](./eip-2718.md) transaction type with `TransactionType` `WITHDRAWAL_TX_TYPE`.

The `TransactionPayload` is an SSZ-encoded container given by the following schema:

```python
class WithdrawalTransaction(Container):
    address: ExecutionAddress
    amount: Gwei
```

where `ExecutionAddress` is an alias for a `Bytes20` SSZ type and `Gwei` is an alias for a `uint64` SSZ type.
Refer to the [SSZ specs](https://github.com/ethereum/consensus-specs/blob/master/ssz/simple-serialize.md) for further details on layout and encoding.

### Block validity

If a block contains *any* transactions with `WITHDRAWAL_TX_TYPE` type, they **MUST** come before **ALL** other transactions in the block.

If the execution client receives a block where this is not the case, it **MUST** consider the block invalid.

### Transaction processing

When processing a transaction with `WITHDRAWAL_TX_TYPE` type, the implementation should make a balance transfer for `amount` Gwei to the `address` specified by the `WithdrawalTransaction`.
There is no source for this balance transfer, much like the coinbase transfer.

This balance transfer is unconditional and **MUST** not fail.

This transaction type has no associated gas costs.

TODO: add logs?

## Rationale

### Push vs pull

cheaper for validators

happens automatically

### Why a new transaction type? And why no gas?

Special semantics

Firewall off generic EVM excution from this type of processing to simplify testing, security review.

### Why no gas costs for new transaction type?

The maximum number of this transaction type that can reach the execution layer at a given time is bounded (enforced by the consensus layer) and this limit is kept small so that
any gas required is negligible in the context of the broader block gas limit.

### Why only balance updates? No general EVM execution?

more general processing introduces the risk of failures, which complicates accounting on the beacon chain

generic execution doesn't pull its weight given this increase in complexity

### Why block validations?

ensure only those receipts genuinely made on the beacon chain are passed to the EVM

provide efficient means for beacon chain to check this

### SSZ vs RLP, and their boundary

< explain where we put the translation boundary from SSZ to RLP >

point out that the transaction hash is hash of RLP of SSZ encoding, not the hash tree root of the SSZ

## Backwards Compatibility

No issues.

## Reference Implementation

A draft PR containing a prototype implementation in Geth can be found here:

https://github.com/ethereum/go-ethereum/pull/24468

## Security Considerations

Consensus-layer validation of withdrawal transactions is critical to ensure that the proper amount of ETH is withdrawn back into the execution layer.
This consensus-layer to execution-layer ETH transfer does not have a current analog in the EVM and thus deserves very high security scrutiny.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
