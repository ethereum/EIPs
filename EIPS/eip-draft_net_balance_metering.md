---
title: Net Gas Metering for Account Changes
description: Charge value transfers per modified account, reducing cost and adding refunds for accounts already changed in the transaction
author: Dragan Rakita (@rakita)
discussions-to: https://ethereum-magicians.org/t/net-gas-metering-for-balance-changes/99999
status: Draft
type: Standards Track
category: Core
created: 2026-07-26
requires: 161, 2200, 2780, 2929, 3529, 7702, 7708, 8037, 8038
---

## Abstract

This EIP introduces net gas metering for account changes, mirroring the scheme [EIP-2200](./eip-2200.md) established for storage, on top of the transaction gas structure of [EIP-2780](./eip-2780.md).
An account counts as changed once its balance or nonce differs from its value at the start of the transaction.
The value transfer cost of `CALL` and `CALLCODE` — `CALL_VALUE`, defined by [EIP-8038](./eip-8038.md) as `ACCOUNT_WRITE + CALL_STIPEND` — is decomposed into a base component of `CALL_VALUE_BASE_GAS`, which prepays the `2300` gas stipend, plus a charge for each account the transfer modifies:
`CLEAN_BALANCE_CHANGE_GAS` for the first change of an account within a transaction, and `DIRTY_BALANCE_CHANGE_GAS` for accounts already changed.
When a transfer returns an account to its original balance while its nonce is unchanged, `BALANCE_RESET_REFUND` is added to the refund counter, and EIP-2780's runtime `ACCOUNT_WRITE` charge for an [EIP-7702](./eip-7702.md) authorization is conditioned on the same predicate.
A call that adds the stipend always consumes at least the stipend: unused stipend gas is no longer returned to the caller.
A transfer between two unmodified accounts costs `8000` gas, matching the current effective cost; a transfer between two already-modified accounts costs `2700` gas.

## Motivation

The gas cost of an in-execution value transfer is flat per transfer — `CALL_VALUE`, currently `ACCOUNT_WRITE + CALL_STIPEND = 10300`, an effective `8000` since the unused portion of the `2300` stipend routinely returns to the caller — regardless of whether the affected accounts were already modified within the same transaction.
The dominant resource behind that cost is the state write: at the end of a block, each account whose balance or nonce changed requires one update of its account trie leaf.
That write happens once per modified account, not once per transfer.
A transaction that moves ether through the same accounts repeatedly pays for state writes that never happen.

Storage received net gas metering through [EIP-1283](./eip-1283.md), [EIP-2200](./eip-2200.md), [EIP-2929](./eip-2929.md) and [EIP-3529](./eip-3529.md), refined by [EIP-8038](./eip-8038.md): the first change of a slot pays the full write cost, subsequent changes pay `100` gas, and a slot reset to its original value earns a refund.
Account balances — the most frequently written state on Ethereum — never received the same treatment: [EIP-8038](./eip-8038.md) names `ACCOUNT_WRITE` a surcharge for changing an account leaf "for the first time", but for `CALL` it is charged flat on every transfer, with no first-change tracking.
The result is that a token balance implemented in contract storage enjoys accurate metering while native ether does not:
moving a storage-based token from A to B and then from B to C charges the second write only `100` gas, whereas the same two hops of ether pay the full transfer cost twice.
Ether is the only asset on Ethereum whose repeated movement is priced as if every hop were an independent state write.

This mispricing penalizes common composition patterns:

* **Forwarders and routers** that receive `msg.value` and pass it on pay twice for what is, in state, a single transfer. Under this EIP the pass-through hop nets `2700` gas, since the intermediary's balance returns full circle to its original value.
* **Refund patterns** where a contract returns excess ether to the payer pay full price for balance changes that partially or fully cancel. A complete round trip (deposit and return within one transaction) drops from an effective `16000` to a net `5400` gas.
* **Batched operations**, including [EIP-7702](./eip-7702.md) delegated accounts executing multiple transfers, pay the full cost per transfer even when the same accounts are touched repeatedly. A contract distributing ether to `N` recipients pays the sender-side write `N` times; under this EIP it pays it once — and a delegated account's authorization already marks it as changed before execution begins.

An `N`-hop pass-through chain costs an effective `8000 * N` today; under this EIP it nets `8000 + 2700 * (N - 1)`, a 50% reduction at `N = 4`.

Pricing of the transaction-level value transfer is handled by [EIP-2780](./eip-2780.md) (`TX_VALUE_COST`); this EIP extends net metering to transfers performed during execution.

## Specification

### Parameters

| Constant | Value |
| - | - |
| `CALL_VALUE_BASE_GAS` | `2500` |
| `CLEAN_BALANCE_CHANGE_GAS` | `(ACCOUNT_WRITE - CALL_VALUE_BASE_GAS) / 2` (= `2750`) |
| `DIRTY_BALANCE_CHANGE_GAS` | `= WARM_ACCESS` (= `100`) |
| `BALANCE_RESET_REFUND` | `CLEAN_BALANCE_CHANGE_GAS - DIRTY_BALANCE_CHANGE_GAS` (= `2650`) |
| `CALL_STIPEND` | `2300` (unchanged) |

`ACCOUNT_WRITE` (currently `8000`) and `WARM_ACCESS` (currently `100`) are the parameters of [EIP-8038](./eip-8038.md); retuning them there retunes this schedule.

### Definitions

* **Original balance** and **original nonce**: the balance and nonce an account holds after the transaction's intrinsic effects, excluding authorization processing: after the up-front gas purchase and nonce increment of the transaction sender and after the transaction-level value transfer, but before [EIP-7702](./eip-7702.md) authorization processing.
  For accounts not touched by these intrinsic operations, these equal the account's values at the start of the transaction.
  Although authorization processing precedes the transaction-level value transfer, the baseline is well defined without a snapshot: it is the pre-transaction state adjusted by the statically known gas purchase, sender nonce increment and transaction value.
  Note that for the transaction sender and recipient the original balance deliberately differs from the balance they would hold if the transaction were reverted; see [Rationale](#baseline-at-the-start-of-execution).
* **Current balance** and **current nonce**: the values an account holds immediately before the metered operation.
* **New balance**: the balance an account would hold immediately after the metered transfer.

An account is *clean* if its *current balance* equals its *original balance* and its *current nonce* equals its *original nonce*; it is *dirty* (changed) otherwise.

### Value transfer cost

The flat `CALL_VALUE` charge applied by `CALL` (`0xF1`) and `CALLCODE` (`0xF2`) when the transferred value is nonzero is replaced by the following:

* Charge `CALL_VALUE_BASE_GAS`.
* Apply the [balance change charge](#balance-change-charge) to the account being debited (the currently executing account), with *new balance* equal to *current balance* minus the transferred value.
* Apply the [balance change charge](#balance-change-charge) to the account being credited (the call target), with *new balance* equal to *current balance* plus the transferred value.
* If the debited and credited accounts are the same account — a self-transfer via `CALL`, or any `CALLCODE` with nonzero value, whose transfer debits and credits the executing account itself — apply the balance change charge once, with *new balance* equal to *current balance*.

All other components of the call cost are unchanged:

* The [EIP-2929](./eip-2929.md) account access cost, memory expansion cost and the base call cost are charged as before.
* The new-account state-gas charge of [EIP-8037](./eip-8037.md) continues to apply when the transferred value is nonzero and the call target is dead, as defined in [EIP-161](./eip-161.md).
* `CALL_STIPEND` continues to be added to the gas available to the callee whenever the transferred value is nonzero.
* The [EIP-7708](./eip-7708.md) transfer log continues to be emitted for nonzero-value calls to a different account, with no separate charge; see [Security Considerations](#transfer-log-volume).
* Calls with zero value are unaffected by this EIP.

The charges above are applied at the time the call instruction executes, before computing the 63/64ths of remaining gas available to the callee, exactly as the replaced `CALL_VALUE` charge was.
If the call subsequently fails without performing the transfer — because the debited account's balance is insufficient or the call depth limit is reached — the charges are still consumed, matching current behavior, but no refund is issued and no balance changes.

### Stipend consumption

Whenever `CALL_STIPEND` is added to the gas available to the callee, the call MUST consume at least `CALL_STIPEND` gas.
Let *forwarded gas* be the gas made available to the callee before the stipend is added, so that the callee frame starts with *forwarded gas* `+ CALL_STIPEND`.
When the callee frame completes, whether by success or by revert, the gas returned to the caller is:

```
returned_gas = min(callee_gas_remaining, forwarded_gas)
```

Equivalently: unused stipend gas is not returned to the caller.
The same rule applies when a call that added the stipend fails without creating a callee frame (insufficient balance or call depth limit): only *forwarded gas* is returned, and the stipend is consumed.
This differs from current behavior, where the unused stipend flows back to the caller in all of these cases.

The callee's execution is unaffected: the gas available inside the callee frame, including as observed via the `GAS` opcode, is unchanged.

### Balance change charge

For an account with a given *original balance*, *current balance* and *new balance*:

* If *new balance* equals *current balance* (the transfer is a no-op for this account), charge `DIRTY_BALANCE_CHANGE_GAS`.
* If *new balance* does not equal *current balance*:
  * If the account is clean, charge `CLEAN_BALANCE_CHANGE_GAS`.
  * If the account is dirty, charge `DIRTY_BALANCE_CHANGE_GAS`.
    Additionally, if *new balance* equals *original balance* and *current nonce* equals *original nonce* (the account has returned to its original state), add `BALANCE_RESET_REFUND` to the refund counter.

The refund counter is the existing transaction-scoped counter used by `SSTORE` refunds:
additions revert together with the call frame they were made in, and the total refund applied at the end of the transaction is capped as specified in [EIP-3529](./eip-3529.md).
This EIP never removes gas from the refund counter.

### EIP-7702 authorization processing

Applying a valid [EIP-7702](./eip-7702.md) authorization tuple increments the authority's nonce and sets its code.
Because a nonce only ever increments, this makes the authority account dirty irreversibly: a nonce-dirtied account can never return to its original state within the transaction, and authorization processing can never trigger `BALANCE_RESET_REFUND`.
The only metering question at application time is therefore whether the authority is already dirty.

[EIP-2780](./eip-2780.md) charges `ACCOUNT_WRITE` at runtime, during authorization processing, if the authorization is the first write to the authority within the transaction, approximated there as the authority differing from `tx.to`.
This EIP replaces that approximation with the exact test: charge `ACCOUNT_WRITE` if and only if the authority is clean at the time the tuple is applied; a dirty authority incurs no account-write charge, its warm writes being already priced by `REGULAR_PER_AUTH_BASE_COST`.

During authorization processing an authority is dirty if it was targeted by an earlier tuple in the same list, and — when the transaction carries nonzero value — if it equals the transaction sender or recipient, whose *current balance* differs from the value-transfer-adjusted baseline.
The latter is intended: both of those leaves are written by the transaction's intrinsic effects, priced by `TX_VALUE_COST`, so their authorization carries no additional first-write cost.
Conversely, in a zero-value transaction an authority equal to `tx.to` is clean and is charged `ACCOUNT_WRITE`: the delegation itself is the first write to that leaf, a case the `tx.to` approximation exempted.

The intrinsic per-authorization cost (`REGULAR_PER_AUTH_BASE_COST`) and the state-gas charges of [EIP-8037](./eip-8037.md) are unchanged.

### Interaction with other account-modifying operations

Dirtiness is derived solely from comparing balances and nonces against their original values, so a change effected by any means updates the metering of subsequent operations.
In particular, the value endowment of `CREATE` and `CREATE2` and the balance sweep of `SELFDESTRUCT` make the affected accounts dirty, as do nonce changes: a `CREATE` or `CREATE2` increments the creator's nonce and initializes the created account's nonce, and authorization processing increments the authority's nonce.

The gas costs of `CREATE`, `CREATE2` and `SELFDESTRUCT` (as restricted by [EIP-6780](./eip-6780.md)) are themselves unchanged by this EIP, to keep the change minimal.

Gas costs and semantics not specified above remain unchanged.
`DELEGATECALL` and `STATICCALL` transfer no value and are unaffected.

## Rationale

### Per-account decomposition of the value transfer cost

The `CALL_VALUE` charge is a lump sum: [EIP-8038](./eip-8038.md) defines it as `ACCOUNT_WRITE + CALL_STIPEND`, with the stipend portion routinely rebated to the caller when the callee does not use it, making the effective cost `ACCOUNT_WRITE = 8000` — a first-change account write surcharge that is nevertheless charged on every transfer.
This EIP makes the effective cost the explicit schedule and gives `ACCOUNT_WRITE` the first-change semantics its definition claims: `CALL_VALUE_BASE_GAS + 2 * CLEAN_BALANCE_CHANGE_GAS = 2500 + 2750 + 2750 = 8000 = ACCOUNT_WRITE`, preserving the current effective cost exactly in the common case of a transfer between two unmodified accounts, while allowing each component to be metered by what it actually consumes.
Only the per-account components collapse when an account is dirty; the base component is charged on every transfer because the stipend and the processing overhead — balance checks, stipend accounting, frame setup for the value semantics — recur on every transfer.

A transfer that changes no balance — a self-transfer, or `CALLCODE` with value — still charges `DIRTY_BALANCE_CHANGE_GAS` for its single touched account rather than nothing, exactly as [EIP-2200](./eip-2200.md) charges a no-op `SSTORE` the `SLOAD_GAS` rate: the balance check and value accounting still run, and the account leaf is read even though it is not modified.

### The stipend is prepaid and always consumed

Under current rules the stipend is conjured on top of the caller's gas and its unused portion is returned to the caller, so a parent frame ends a value call with up to `2300` gas it never paid for.
With the flat `CALL_VALUE` charge this rebate is harmless, but combined with per-account charges as low as `100` it becomes an exploit surface: the parent would recover most of a small charge, the effective cost of a dirty transfer would collapse to `charge - 2300`, and every constant in the schedule would need to carry a defensive `+2300` margin against stipend-funded gas amplification.

This EIP instead makes the stipend prepaid and non-refundable: `CALL_VALUE_BASE_GAS` exceeds `CALL_STIPEND`, so the stipend is funded by the base charge (`2500 = 2300 + 200` of transfer processing), and the [stipend consumption](#stipend-consumption) rule guarantees the funded gas is spent or destroyed, never returned.
No conjured gas exists anywhere in the scheme, and the parent can never be rewarded gas from a child call.

The combination strictly dominates the current rules for callers.
For a value call whose callee consumes `s` gas, the caller's remaining gas afterwards is `G - charge - max(s - CALL_STIPEND, 0)` compared to `G - 8000 - s` today; since `charge <= 8000` and `max(s - 2300, 0) <= s`, the caller is always left with at least as much gas as under current rules, with equality exactly in the case of a first-change transfer whose callee spends no gas (e.g. a plain transfer to an EOA).

### Nonce as part of the dirtiness predicate

The resource being metered is the account trie leaf, which commits to the account's nonce, balance, storage root and code hash; a change to any of them forces the same end-of-block leaf write.
Including the nonce in the predicate captures the in-execution sources of leaf writes that a balance comparison misses: `CREATE`/`CREATE2` incrementing the creator's nonce, the initialization of a newly created account, and [EIP-7702](./eip-7702.md) authorization processing.
The nonce also guards the reset refund: an account whose balance comes full circle but whose nonce changed still requires a leaf write, so `BALANCE_RESET_REFUND` demands both conditions.
Because a nonce only ever increases, this guard is permanent — a nonce-dirtied account can never return to clean within the transaction.
Code changes need no separate clause because every operation that changes an account's code within a transaction also increments its nonce.
Storage-root changes are deliberately excluded: detecting "any slot of this account changed" cannot be done by comparing two field values and would require per-account dirty-slot tracking; a future EIP may extend the predicate.

### Exact first-write predicate for authorizations

[EIP-2780](./eip-2780.md) already charges the state-dependent portion of authorization cost at runtime, during authorization processing, where the authority's state is readable — but it approximates "first write to the authority" with the static condition that the authority differ from `tx.to`.
With dirtiness tracking available, the approximation is replaced by the exact test at no additional implementation cost, and the two predicates identify the same event in almost every case, since the only writes preceding authorization processing are the transaction's intrinsic effects and earlier tuples.

The exact test diverges from the approximation twice, both times in the right direction.
An authority equal to the sender or recipient of a value-bearing transaction is dirty against the value-transfer-adjusted baseline, so it is exempt from `ACCOUNT_WRITE` — correctly, as `TX_VALUE_COST` already pays for those leaves.
An authority equal to `tx.to` of a zero-value transaction is clean, so it pays `ACCOUNT_WRITE` — correcting an undercharge of the approximation, which exempted a delegation that is in fact the first and only write to that leaf.

The larger effect runs in the other direction: every applied authorization marks its authority dirty, so subsequent transfers involving delegated accounts during execution are metered at the dirty rate.

### Baseline at the start of execution

For storage, EIP-2200's *original value* — "the value if a reversion happens on the current transaction" — coincides with the value at the start of execution.
For balances the two differ: if the transaction reverts, the transaction-level value transfer is undone but the gas purchase is not.
Defining the baseline as the reversion state would make the transaction sender and recipient start execution dirty without any charged balance change, and a transfer returning the sender's balance to that baseline would mint an unbacked `BALANCE_RESET_REFUND`.
With an [EIP-7702](./eip-7702.md) delegated sender this becomes a loop: value out through the delegated account, value back from a cooperating contract, collecting `2650` of refund per round trip against only `400` of dirty charges.
Anchoring *original balance* at the start of execution — after the intrinsic gas purchase and value transfer — makes every account start clean, so every divergence from the baseline passes through a charged path and every refund is backed by a prior charge.

Authorization processing is deliberately excluded from the baseline.
This lets the [authorization rule](#eip-7702-authorization-processing) observe whether an authority was already changed, and it means an applied delegation leaves the authority dirty for the whole execution phase, so transfers through delegated accounts take the dirty path.
The transaction sender's nonce increment, by contrast, is included in the baseline, so the sender starts execution clean.

### Refund soundness

The scheme maintains the invariant that, per account, gas added to the refund counter never exceeds gas previously charged for that account's divergence.
An account can diverge from its original state only through:

* the clean branch of the balance change charge: `2750` charged, versus at most `2650` later refunded;
* a `CREATE`/`CREATE2` endowment or nonce increment: at least `CREATE_ACCESS` (`11000`) charged;
* a `SELFDESTRUCT` sweep: at least `5000` charged;
* an applied [EIP-7702](./eip-7702.md) authorization on a clean authority: `ACCOUNT_WRITE` (`8000`) charged.

Each divergence path charges more than `BALANCE_RESET_REFUND`, and after a refund the account is clean again, so repeating the cycle repeats the full clean charge.
The authorities exempt from `ACCOUNT_WRITE` — those equal to the sender or recipient of a value-bearing transaction — have their leaf writes paid by `TX_VALUE_COST`, and having changed nonces they can never satisfy the `BALANCE_RESET_REFUND` condition, so no refund can arise from an uncharged divergence.
The [EIP-3529](./eip-3529.md) cap of `gas_used // MAX_REFUND_QUOTIENT` bounds total refunds as defense in depth.

## Backwards Compatibility

This EIP requires a hard fork, since it modifies gas metering rules.

No gas cost increase is anticipated for value transfers.
As shown in [Rationale](#the-stipend-is-prepaid-and-always-consumed), the caller's remaining gas after a value call is always greater than or equal to what it would be under current rules, with equality only for a first-change transfer whose callee consumes no gas.
Contracts that forward fixed gas amounts to sub-calls therefore cannot newly run out of gas.
The `CALL_STIPEND` of `2300` is unchanged inside the callee frame, so callee code written against the stipend behaves identically.

One authorization case becomes more expensive: an [EIP-7702](./eip-7702.md) authorization whose authority equals `tx.to` of a zero-value transaction is charged `ACCOUNT_WRITE`, which the `tx.to` approximation of [EIP-2780](./eip-2780.md) exempted.
This corrects an undercharge — the delegation is the first write to that leaf — rather than repricing correctly-charged behavior.

One observable behavior changes: a caller no longer receives unused stipend gas back after a value call.
Contracts that measure `gasleft()` around value calls will observe different (never smaller) remaining gas, and any contract that specifically budgeted on the returned stipend continues to work because the reduced charge more than compensates for it.

Two economic (non-consensus) effects should be noted:

* Contracts that rely on the cost of a value transfer as an implicit rate limit on repeated deposits or withdrawals within one transaction will find repetition roughly 3 times cheaper; the stipend-based reentrancy protections are unaffected (see [Security Considerations](#reentrancy)).
* Gas estimation becomes order-dependent, as it already is for [EIP-2929](./eip-2929.md) warm and cold access: the cost of a value call depends on prior account changes within the transaction. Wallets and RPC providers must estimate against the transaction's actual starting state.

## Test Cases

The table below lists the value-transfer component of gas consumed by the caller, excluding the [EIP-2929](./eip-2929.md) access cost, base call cost and memory costs.
All accounts are warm and existing, have sufficient balances (except where noted), callees consume no gas, and `x` and `y` are distinct nonzero values.
Arrows denote a `CALL` transferring the indicated value.
The "Before this EIP" column is likewise effective consumption: the `CALL_VALUE` charge (`10300`) less the `2300` unused stipend returned under current rules.
Calls that create a new account additionally incur the unchanged [EIP-8037](./eip-8037.md) new-account state-gas charges under both columns.

| Scenario | Charged | Refund | Net | Before this EIP |
| - | - | - | - | - |
| `A→B x` | 8000 | 0 | 8000 | 8000 |
| `A→B x; A→B x` | 10700 | 0 | 10700 | 16000 |
| `A→B x; B→C x` | 13350 | 2650 | 10700 | 16000 |
| `A→B x; B→C y` | 13350 | 0 | 13350 | 16000 |
| `A→B x; B→A x` | 10700 | 5300 | 5400 | 16000 |
| `A→A x` (self-transfer) | 2600 | 0 | 2600 | 8000 |
| `CALLCODE` with value `x` | 2600 | 0 | 2600 | 8000 |
| `A→B x`, balance of `A` less than `x` | 8000 | 0 | 8000 | 8000 |

Worked example for `A→B x; B→C x`:
the first call charges `2500 + 2750 + 2750 = 8000` (both accounts clean), and its unused stipend is consumed rather than returned.
The second call charges `2500` base, `100` for dirty `B`, and `2750` for clean `C`, totaling `5350`; because `B`'s new balance equals its original balance, `2650` is added to the refund counter.

Stipend consumption cases, for a value call forwarding `g` gas to a callee that consumes `s` gas:

* `s = 0` (e.g. the callee is an EOA): `g` gas is returned; the `2300` stipend is consumed in full.
* `0 < s < 2300`: `g` gas is returned; the caller does not recover the unused `2300 - s`.
* `s >= 2300`: `g + 2300 - s` gas is returned, as under current rules.
* The call fails on insufficient balance or depth limit: `g` gas is returned, not `g + 2300`.

Account-change cases involving nonces and [EIP-7702](./eip-7702.md) authorizations:

* A transaction carrying an authorization for `B`, whose execution then performs `A→B x`: the transfer charges `2500 + 2750 + 100 = 5350`, since the applied authorization left `B` dirty.
* An authorization list containing two valid tuples for the same authority: only the first application charges `ACCOUNT_WRITE`.
* An authorization whose authority equals the sender or recipient of a value-bearing transaction: no `ACCOUNT_WRITE` is charged.
* An authorization whose authority equals `tx.to` of a zero-value transaction: `ACCOUNT_WRITE` is charged.
* Contract `A` performs a `CREATE` and then `A→B x`: `A`'s nonce differs from its original, so the transfer charges `2500 + 100 + 2750 = 5350`.
* `A→B x`, then `B` performs a `CREATE`, then `B→A x`: `A` earns `BALANCE_RESET_REFUND`, but `B` does not — its balance came full circle while its nonce changed, so its account leaf must still be written.

Tests should additionally cover: reverted sub-frames restoring cleanliness and rolling back refunds; the stipend consumption rule under callee revert; transfers interleaved with `CREATE` endowments and `SELFDESTRUCT` sweeps; cleanliness of the transaction sender and recipient at the start of execution, including a self-sponsored authorization dirtying the sender; and the [EIP-3529](./eip-3529.md) refund cap.
Test cases in `ethereum/execution-spec-tests` are to be added.

## Security Considerations

### Gas stipend amplification

A value-bearing call grants the callee a `CALL_STIPEND` of `2300` gas.
Under current rules this gas is conjured on top of the caller's charge and its unused portion returns to the caller; a naive reduction of the value transfer cost below the stipend would let calls between dirty accounts manufacture more execution gas than they consume, breaking the block gas limit as a bound on computation.
This EIP closes the concern structurally rather than by margin:

* The stipend is prepaid — `CALL_VALUE_BASE_GAS = 2500 > CALL_STIPEND`, and the base charge is applied on every value call — so the callee's stipend gas is always paid for by the caller.
* The [stipend consumption](#stipend-consumption) rule guarantees the prepaid gas is spent or destroyed: the caller's gas after the call never exceeds its gas before the call minus the full charge.

Consequently a transaction with gas limit `G` can never cause more than `G` gas of execution, with no dependence on the relative sizes of the per-account charges — the invariant that must be preserved under any retuning is only `CALL_VALUE_BASE_GAS > CALL_STIPEND`.

### Transfer log volume

[EIP-7708](./eip-7708.md) emits a transfer log for every nonzero-value `CALL` to a different account without charging for it, arguing that the transfer cost — a minimum of `6700` gas at the time — far exceeds the cost of the equivalent `LOG3` with 32 data bytes (`TRANSFER_LOG_COST = 1756` per [EIP-2780](./eip-2780.md)).
This EIP thins that margin but preserves the inequality.
The cheapest log-emitting transfer is a dirty-to-dirty call at `2700` gas, still above `1756`; self-transfers, which fall to `2600`, transfer to the same account and emit no log.
Even against the maximal [EIP-3529](./eip-3529.md) refund of 20% of gas used, the effective floor is `2700 * 0.8 = 2160 > 1756`.
Emitting logs through value transfers therefore never becomes cheaper than emitting them directly with the `LOG` opcodes, and the worst-case log volume per block remains governed by the `LOG` opcodes themselves.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
