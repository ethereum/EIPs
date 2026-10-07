---
eip: 3298
title: Remove storage-clear refund and refund cap
description: Removes the SSTORE storage-clearing refund and the transaction refund cap, leaving only net-metered same-transaction write reversals
author: Vitalik Buterin (@vbuterin), Martin Swende (@holiman), Jochem Brouwer (@jochem-brouwer)
discussions-to: https://ethereum-magicians.org/t/eip-3298-removal-of-refunds/5430
status: Draft
type: Standards Track
category: Core
created: 2021-02-26
requires: 2780, 3529, 7778, 8037, 8038
---

## Abstract

This EIP removes the storage-clearing refund (`STORAGE_CLEAR_REFUND`, as defined by [EIP-8038](./eip-8038.md)) and the transaction refund cap ([EIP-3529](./eip-3529.md)). The [EIP-8038](./eip-8038.md)'s net-metered `STORAGE_WRITE` reversal remains.

## Motivation

Refunds were originally (the Frontier "fork", i.e. start of the chain) part of protocol to incentivize "good state hygiene": clearing storage that is no longer needed. The incentive has not worked in practice, and state growth is now addressed by pricing state creation directly ([EIP-8037](./eip-8037.md)), not by cleanup rebates.

What refunds still cost the protocol is settlement complexity: a refund counter that must be capped at 20% of gas used ([EIP-3529](./eip-3529.md)), a cap that interacts non-obviously with the calldata floor of [EIP-7623](./eip-7623.md) / [EIP-7976](./eip-7976.md) and with the two gas dimensions of [EIP-8037](./eip-8037.md). Most refunds since chainstart are already gone by the fork this EIP targets: `SELFDESTRUCT` ([EIP-3529](./eip-3529.md)), the [EIP-7702](./eip-7702.md) per-authorization refund ([EIP-2780](./eip-2780.md)), and refunds in block-level gas accounting ([EIP-7778](./eip-7778.md)).

That leaves the `SSTORE` refund rules, which split cleanly in two. The `STORAGE_WRITE` reversal is genuine net metering: a slot that ends the transaction at its starting value pays only access costs, not the execution write costs to that storage, as no execution calculations have to be done anymore. The clearing refund is a cross-transaction incentive with no remaining justification. Since `STORAGE_WRITE` would cover the refund in situatoins it happened (it has already been paid for in the same transaction), the refund cap is removed.

## Specification

This EIP is a delta against [EIP-8037](./eip-8037.md) and [EIP-8038](./eip-8038.md) and assumes both are active, together with [EIP-2780](./eip-2780.md) and [EIP-7778](./eip-7778.md).

### `SSTORE` refund rules

`STORAGE_CLEAR_REFUND` (11,616; the successor of [EIP-3529](./eip-3529.md)'s `SSTORE_CLEARS_SCHEDULE`) is removed from the gas schedule, together with the two [EIP-8038](./eip-8038.md) refund rules that use it: the grant when a slot with a non-zero original value is cleared, and its reversal when such a cleared slot is restored.

A single refund rule remains, unchanged from [EIP-8038](./eip-8038.md): `STORAGE_WRITE` is refunded if the new value equals the original value and differs from the current value — a change made earlier in the same transaction is undone. (As in [EIP-2200](./eip-2200.md), the *original value* is the slot's value at the start of the transaction and the *current value* is its value just before the `SSTORE` executes.) In the `SSTORE` case table of [EIP-8038](./eip-8038.md), every `STORAGE_CLEAR_REFUND` entry is struck; no other entry changes.

The refund counter's semantics are otherwise unchanged: refunds accumulate during execution, are journaled with the call frame that grants them (a reverting frame's additions are discarded), and are applied once in the end-of-transaction settlement. The `SSTORE` charging rules and the state-gas charges and refills of [EIP-8037](./eip-8037.md) are untouched; state-gas refills are not refunds and do not enter the counter.

### Removal of the refund cap

The transaction gas settlement of [EIP-8037](./eip-8037.md) loses the [EIP-3529](./eip-3529.md) cap:

```python
tx_gas_used_before_refund = tx.gas - tx_output.gas_left - tx_output.state_gas_reservoir
tx_gas_used_after_refund = tx_gas_used_before_refund - tx_output.refund_counter
tx_gas_used = max(tx_gas_used_after_refund, calldata_floor_gas_cost)
```

That is, `tx_gas_refund = min(tx_gas_used_before_refund // 5, tx_output.refund_counter)` becomes simply `tx_output.refund_counter`. The [EIP-7623](./eip-7623.md) calldata floor still applies after refunds, and the receipt `cumulative_gas_used` still uses the post-floor value. Block-level accounting is unchanged: per [EIP-7778](./eip-7778.md) and [EIP-8037](./eip-8037.md), the execution-gas dimension counts `max(tx_gas_used_before_refund - tx_state_gas, calldata_floor_gas_cost)`, before refunds.

## Rationale

### Why the write reversal stays and the cap goes

The `STORAGE_WRITE` reversal is not an incentive; it is the accounting rule that makes `SSTORE` net-metered within a transaction. Without it, a round trip such as `x → y → x` would pay for a write that was undone, overcharging common patterns (pre-[EIP-1153](./eip-1153.md) re-entrancy locks, netting in settlement systems) while simplifying nothing: clients must track original values regardless, because the charging rules depend on them.

It is also self-bounded: a slot can only be restored to its original value (earning the refund) after a write moved it away (paying the charge), and each restore reverses exactly one such charge. The counter therefore never exceeds the `STORAGE_WRITE` charges already paid in the same transaction, so no cap is needed. The cap's other historical purpose — bounding the block-size impact of refunds — is already served by [EIP-7778](./eip-7778.md). Keeping it would only preserve the cap–floor–dimension interactions this EIP sets out to remove.

### Why the clearing refund goes

It is the last cross-transaction refund. Its purpose — incentivizing cleanup — is obsolete now that state growth is priced at creation time, and under [EIP-8037](./eip-8037.md) pricing it is far too small relative to `STATE_BYTES_PER_STORAGE_SET × CPSB` to work as an incentive or as a gas bank. What remains is pure specification and implementation burden: a parameter, two refund rules, and the cap that exists chiefly to contain it. ([EIP-8038](./eip-8038.md) raises `STORAGE_CLEAR_REFUND` to 11,616 in Glamsterdam; this EIP, scheduled for the following fork, removes it entirely.)

## Backwards Compatibility

This is a backwards-incompatible gas repricing that requires a scheduled network upgrade.

Refunds are applied only in the end-of-transaction settlement, so removing one cannot affect execution; it changes only net costs: a transaction that clears a slot with a non-zero original value no longer receives 11,616 gas back per slot, so applications that batch storage cleanup for the refund pay proportionally more. Gas estimators and wallets MUST drop the clearing-refund and refund-cap logic from `eth_estimateGas` and fee computation.

## Test Cases

The following sequences (single warm slot, values symbolic) illustrate the refund counter under this EIP. `W` denotes `STORAGE_WRITE`:

| Sequence (original value first) | Charges | Refund counter | Net write cost |
| :--- | :--- | :---: | :---: |
| `0 → x` | `W` | 0 | `W` |
| `0 → x → 0` | `W` | `W` | 0 |
| `x → 0` | `W` | 0 | `W` |
| `x → 0 → x` | `W` | `W` | 0 |
| `x → y → x` | `W` | `W` | 0 |
| `x → y → 0` | `W` | 0 | `W` |
| `x → y → x → z` | `W`, `W` | `W` | `W` |
| `x → 0 → x → 0` | `W`, `W` | `W` | `W` |

In every case the refund counter is bounded by the same transaction's `STORAGE_WRITE` charges, and no cap is applied. State-gas charges and refills ([EIP-8037](./eip-8037.md)) are orthogonal and unchanged.

Tests should additionally cover: a transaction clearing many slots (no refund granted); a refund counter exceeding 20% of pre-refund gas used (asserting the uncapped subtraction); a refund pushing `tx_gas_used_after_refund` below the [EIP-7623](./eip-7623.md) floor (the floor binds); and [EIP-7778](./eip-7778.md) block accounting (refunds reduce the sender's payment, not the block's execution-gas usage).

## Security Considerations

Removing the cap is safe only because the remaining refund is self-bounded and the counter is journaled across reverts; both properties are load-bearing. Any future EIP that adds a refund not backed by a same-transaction charge MUST reintroduce a cap or demonstrate an equivalent bound, otherwise a transaction could pay less than the resources it consumed.

Since [EIP-7778](./eip-7778.md) already excludes refunds from block-level accounting, this EIP does not change worst-case block resource consumption; it only raises the net payment of storage-clearing transactions.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
