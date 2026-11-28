---
title: Bounded Storage Credit and Debit
description: Two opcodes add to or subtract from a storage slot within two bounds and push whether they did.
author: Csaba Kiraly (@cskiraly), Danno Ferrin (@shemnon)
discussions-to: https://ethereum-magicians.org/t/add-eip-bounded-storage-credit-and-debit/30477
status: Draft
type: Standards Track
category: Core
created: 2026-11-19
requires: 2200, 2929, 3529
---

## Abstract

Two opcodes change a storage slot by an amount: `SCREDIT` adds it and `SDEBIT` subtracts it. Each
takes a lower and an upper bound and applies the change only if the slot's value lies within them
before and after. Each pushes 1 if its bound check passes and 0 if it fails. Neither pushes the
slot's value, and both are charged as `SSTORE` is for the value they leave. This EIP supersedes
[EIP-7519](./eip-7519.md), which proposed the same two operations without bounds and with an
exceptional halt on overflow and underflow.

## Motivation

A contract that moves a balance today loads it, checks it and stores the result:

```
balance = SLOAD(slot)
if balance < amount: revert
SSTORE(slot, balance - amount)
```

The outcome depends on the balance only through the check, but the execution reads its exact
value. Two transfers out of an account whose balance covers both succeed in either order, yet
anything that must know which state a transaction depended on sees the second depend on the first.

This matters wherever transactions are executed or proven against state that others may change
concurrently:

- blocks built concurrently by several proposers or builders, where each block must stay valid
  whatever the others contain, and conflicts are decided from what each block commits to;
- execution proofs that commit to the ranges their inputs may take rather than to exact values;
- parallel execution that schedules transactions by declared dependencies.

Implementations can recognise such updates by analysing code, each in its own way. These
operations let the contract state them.

For block validation the gain is small. After Glamsterdam activates, validators can use its
block-level access lists ([EIP-7928](./eip-7928.md)) and the state before the block to reconstruct
each transaction's starting values and execute transactions in parallel, so these dependencies
don't make them wait.

The operations let a contract update a shared value, such as a balance many transactions credit
or a counter toward a cap, and branch on the success flag without loading the value. With
`min = 0`, for example, credits to a supply counter pass their bound checks in any order if the
starting supply plus their sum is at most the cap. Gas and refunds still follow `SSTORE`'s rules
and can depend on the value. Today's contracts were written for sequential execution, where each
transaction already waits for the preceding one to finish. They show where the operations could
replace existing updates, not how contracts designed around them would use them.

The case for specifying them now is adoption: the additive updates that would conflict between
concurrently built blocks concentrate in a few widely used token contracts, and with the semantics
settled those contracts, and new ones, can plan for them before any design depends on them.

The operations differ from EIP-7519 in two ways, each needed by contracts deployed today:

- **Two bound operands.** USDC's token contract stores a blacklist flag in the most significant bit
  of each balance's storage word, so its balances lie between 0 and 2^255 − 1. Without an upper
  bound, a credit could carry into the blacklist flag. Checking the flag separately would load the
  whole word, including the exact balance, which systems that track exact reads would treat as a
  dependency. A lower bound states a floor, such as a minimum balance, in the same way.
- **A success flag instead of an exceptional halt.** Tokens revert with their own errors, and some
  take another branch when a check fails. An exceptional halt consumes the executing frame's
  remaining execution gas and returns no revert data. A failed operation here costs what a store of
  the unchanged value costs.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Opcodes

| Mnemonic  | Opcode | Inputs (top first)       | Output    |
|-----------|--------|--------------------------|-----------|
| `SCREDIT` | `TBD`  | `slot, amount, min, max` | `success` |
| `SDEBIT`  | `TBD`  | `slot, amount, min, max` | `success` |

Each instruction has no immediate, pops four words, pushes one and advances the program counter by
one. All values are unsigned 256-bit words. The storage is that of the account `SSTORE` would write
in the same context: the current target, also under `DELEGATECALL` and `CALLCODE`.

### Execution

The steps use these terms:

- `original`: the original value that the active fork's `SSTORE` uses for the slot.
- `current`: the slot's value immediately before the operation.
- `new`: the value that step 4 gives, which step 5 charges for and step 6 stores if the operation
  gets that far.
- The *bound check*: step 4's test of `current` and `amount` against `min` and `max`. It *passes*
  when the operation's condition holds and *fails* otherwise.
- An operation *fails* when its bound check fails. If it can pay its charge, it then completes,
  leaves the slot unchanged and pushes 0; if not, it halts in step 5.

1. If the current execution context is static, the operation MUST halt exceptionally.
2. The operation MUST make every gas check that the active fork's `SSTORE` makes before reading
   the slot, and halt exceptionally where it would.
3. The operation accesses the slot as the active fork's `SSTORE` does, which warms it, and obtains
   `original` and `current`.
4. The bound check gives `success` and `new`:
   - `SCREDIT`: if `min <= current` and `current + amount <= max`, then `success = 1` and
     `new = current + amount`.
   - `SDEBIT`: if `amount <= current`, `current <= max` and `min <= current - amount`, then
     `success = 1` and `new = current - amount`.
   - Otherwise `success = 0` and `new = current`.

   Sums and differences are computed without reduction modulo 2^256.
5. The operation is charged as specified below. If the charge can't be paid, it halts
   exceptionally.
6. The slot is set to `new` as `SSTORE(slot, new)` would set it.
7. `success` is pushed onto the stack.

**The range.** The bound check passes exactly when `current` and the changed value,
`current + amount` for `SCREDIT` or `current − amount` for `SDEBIT`, both lie in `[min, max]`.
When `min > max`, no value does, and both operations fail.

**Warmth.** Step 3 warms the slot, whether or not the bound check passes.

**Before the access.** If the operation halts in step 1 or 2, it contributes no access to the slot.
In every fork with [EIP-2200](./eip-2200.md), step 2 halts when the gas left (execution gas, where
the fork distinguishes it) is 2300 or less. From Amsterdam, Glamsterdam's execution-layer fork, on,
it also halts when the gas left is less than the slot's access cost; these checks are then
`SSTORE`'s pre-state validation in [EIP-7928](./eip-7928.md).

**Halts.** Any halt follows the fork's rules for an exceptional halt, including the rollback of
storage-key warmth. Stack underflow halts exceptionally, as for any instruction.

### Gas and access lists

**Cost.** Each operation costs what `SSTORE(slot, new)` costs. There is no separate charge for
reading the slot. A gas check made before the access deducts nothing; the access is charged once,
as part of `SSTORE`'s charge. A failed operation is charged and recorded as a store of the value
the slot already holds.

**Effects.** From the access in step 3 on, each operation MUST have exactly the effects that
`SSTORE(slot, new)` would have at the same point of execution, with the same `original` and
`current`, in the same order and with the same treatment on an exceptional halt or a revert:

- the execution gas and the refund counter adjustments;
- state gas charges and refunds, where the fork has them;
- the slot's warmth under [EIP-2929](./eip-2929.md);
- the entries of any access list the fork records.

**Later forks.** Any later change to `SSTORE` applies to both operations in the same way.

**Reference costs.** The tables below give `SSTORE`'s costs for a slot whose value is unchanged
earlier in the transaction. The operations are not part of Amsterdam, so Amsterdam's costs are the
ones that would apply unless a later fork changes them. The test cases use Osaka's costs as their
reference.

As of Osaka, under the schedules of EIP-2929 and [EIP-3529](./eip-3529.md):

| Case | Cold slot | Warm slot | Refund counter |
|------|-----------|-----------|----------------|
| zero to nonzero | 22,100 | 20,000 | 0 |
| nonzero to another nonzero value | 5,000 | 2,900 | 0 |
| nonzero to zero | 5,000 | 2,900 | +4,800 |
| `success = 0`, or `amount = 0` | 2,200 | 100 | 0 |

As of Amsterdam, under the schedules of [EIP-8037](./eip-8037.md) and [EIP-8038](./eip-8038.md),
with EIP-8037's state gas counted apart from the execution gas:

| Case | Cold slot | Warm slot | State gas | Refund counter |
|------|-----------|-----------|-----------|----------------|
| zero to nonzero | 12,100 | 10,100 | 97,920 | 0 |
| nonzero to another nonzero value | 12,100 | 10,100 | 0 | 0 |
| nonzero to zero | 12,100 | 10,100 | 0 | +11,616 |
| `success = 0`, or `amount = 0` | 2,100 | 100 | 0 | 0 |

### Scope

`SLOAD`, `SSTORE` and transient storage are unchanged. The operations act on persistent storage
only.

## Rationale

### Two bounds

The bounds give the range a value may take, and an operation changes only a value in that range
and leaves it there.

- An upper bound lets a contract keep other fields above a value in the same word. A set flag bit
  puts the word above the bound, so both operations fail on it: on USDC's layout, with
  `max = 2^255 − 1`, the balance word's blacklist check comes from the bound. Any other checks the
  token makes still apply. The upper bound also expresses caps, such as a supply cap.
- A lower bound expresses a floor, such as a minimum balance or an amount that must stay locked,
  without reading the slot.
- `min = 0` and `max = 2^256 − 1` give plain overflow and underflow protection.
- The bounds assert a field's width before any change: with `[0, 2^64 − 1]`, an operation fails on
  a word that holds anything above its low 64 bits. With `amount = 0`, the assertion changes
  nothing.

Each operation checks the bound it moves toward against the changed value, and the bound it moves
away from against `current`, so the two operations mirror each other. A credit that may start below
a floor passes `min = 0`.

Alternatives not taken:

- **No caller-supplied bounds**, as in EIP-7519, which checks only whole-word overflow and
  underflow. A credit can still carry into a field above the balance, so a contract with packed
  balances would need to rule out that carry separately, and checking a flag bit above the balance
  would take a read of the word.
- **One bound per operation**, a ceiling for credits and a floor for debits. A debit can then
  borrow from a flag bit: with a floor of 0, subtracting 4 from 2^255 + 3 gives 2^255 − 1, which
  clears the flag bit.
- **Checking only the changed value.** The same debit would pass a check of its result against
  `[0, 2^255 − 1]`, since 2^255 − 1 lies inside the range.

### Checks before the access

Step 1 comes first because a write in a static context can never succeed, so the slot need not be
read. Osaka's `SSTORE` checks the static context only after it reads the slot and charges for it;
Amsterdam's checks it first, as these operations do. Step 2 makes the checks `SSTORE` makes before
it reads the slot. From Amsterdam on, where `SSTORE` also checks the static context first, each
operation therefore reaches the slot read under the same conditions as `SSTORE` on that slot, given
its stack inputs. As with `SSTORE`, the slot access counts toward the block-level access list even
if the later write charge makes the operation halt.

### Unsigned values only

The operations compare as `LT` and `GT` do. Signed comparison, which would read a bound with the
high bit set as negative, was not taken. For example, using an unchecked `0 − 1` as `min` gives
2^256 − 1; with `max = 10`, the range is empty and the operation fails. Read as two's-complement
integers, the same bounds would give `[−1, 10]`, a range that crosses the end of the unsigned word.
Signed ranges would need operations of their own.

### A success flag

The success flag lets the contract decide what a failure means: revert with its own error, or take
another branch. EIP-7519's exceptional halt on overflow or underflow was not taken: it consumes the
executing frame's remaining execution gas, returns no revert data, and ends that frame before it can
branch on the result; only a calling frame can still branch, on the call's result. The success flag
also allows probes that change nothing. If `SDEBIT(slot, 0, 0, 2^256 − 2)` completes, it pushes 0
for the conventional unlimited allowance of 2^256 − 1 and 1 otherwise. The contract can use that
success flag to skip a later debit of an unlimited allowance without loading the allowance's
value.

### No value pushed

The operations push the success flag and not the slot's value. Pushing the value would make
whatever the contract does next depend on the exact value. A contract that needs the value reads it
with `SLOAD`, and the dependence is then explicit.

If the operation completes, its success flag reports whether `current` falls within the range its
bound check accepts: `[min, max − amount]` for `SCREDIT` and `[min + amount, max]` for `SDEBIT`,
each empty when it can't be formed without wrapping or its lower end exceeds its upper end. A
pushed 0 says only that `current` lies outside that range.

### The gas of `SSTORE`

The operations are charged as `SSTORE` is, so their gas depends on the slot's value as `SSTORE`'s
does. Gas that did not depend on the value at all was not taken: it would need a new rule for
storage creation charges and refunds. The test cases use Osaka's costs because Osaka meters gas in
one dimension, which makes each row easy to check.

The dependence is narrow. Consider executions that follow the same path with the same amounts,
bound-check results and frame reverts, where the slot changes only through these operations.
Whether `current` or `new` equals `original` then follows from the net signed amount applied so
far, those of reverted frames left out, and whether `current` equals `new` from the amount applied
by this operation. The remaining value-dependent comparisons of `SSTORE`'s gas and refunds, under
Osaka's schedules and those of [EIP-8037](./eip-8037.md) and [EIP-8038](./eip-8038.md), test
whether `original`, `current` or `new` is zero. A design that commits to the values a transaction
depends on can treat these as values it requires or excludes.

### Operations, not analysis

Implementations can find additive updates in existing code by tracking at run time which loaded
values only feed checks and additions, and a proof system could verify such an analysis. Where all
parties must agree on which values a transaction depended on, that analysis has to be specified
exactly and give every implementation the same answer. The operations let the contract state the
update instead.

### Not a precompile or system contract

As in EIP-7519: a call costs more in gas and in code size than the operation it would wrap.

### Block-level access lists

The same block-level access-list rules apply as for `SSTORE`: for each transaction after which a
slot's value differs from its value before it, `storage_changes` records the new value, and an
accessed slot with no `storage_changes` entry in the block appears in `storage_reads`, no-op writes
included. A design that needs the credit and debit amounts can record them separately. Putting them
in the standard list would tie the operations to one such design and make every validator verify
those entries.

## Backwards Compatibility

The opcodes are new: the two bytes become valid instructions on activation, and every existing
instruction keeps its behaviour. Before activation, executing either byte halts with an invalid
instruction.

## Test Cases

Each case starts with the slot cold and unchanged earlier in the transaction, with `SSTORE`'s costs
as of Osaka. `M` is 2^256 − 1.

| Operation | `current` | `amount` | `min` | `max` | `success` | Value after | Gas | Refund counter |
|-----------|-----------|----------|-------|-------|-----------|-------------|-----|----------------|
| `SCREDIT` | 0 | 5 | 0 | `M` | 1 | 5 | 22,100 | 0 |
| `SCREDIT` | 10 | 5 | 0 | 15 | 1 | 15 | 5,000 | 0 |
| `SCREDIT` | 10 | 6 | 0 | 15 | 0 | 10 | 2,200 | 0 |
| `SCREDIT` | `M` | 1 | 0 | `M` | 0 | `M` | 2,200 | 0 |
| `SCREDIT` | 2^255 + 3 | 1 | 0 | 2^255 − 1 | 0 | 2^255 + 3 | 2,200 | 0 |
| `SCREDIT` | 4 | 5 | 4 | 100 | 1 | 9 | 5,000 | 0 |
| `SCREDIT` | 3 | 5 | 4 | 100 | 0 | 3 | 2,200 | 0 |
| `SCREDIT` | 7 | 0 | 0 | 7 | 1 | 7 | 2,200 | 0 |
| `SCREDIT` | 8 | 0 | 0 | 7 | 0 | 8 | 2,200 | 0 |
| `SCREDIT` | 2^64 − 1 | 0 | 0 | 2^64 − 1 | 1 | 2^64 − 1 | 2,200 | 0 |
| `SCREDIT` | 2^64 | 0 | 0 | 2^64 − 1 | 0 | 2^64 | 2,200 | 0 |
| `SCREDIT` | 5 | 0 | 6 | 5 | 0 | 5 | 2,200 | 0 |
| `SCREDIT` | 0 | 6 | 0 | 5 | 0 | 0 | 2,200 | 0 |
| `SDEBIT` | 10 | 10 | 0 | 2^255 − 1 | 1 | 0 | 5,000 | +4,800 |
| `SDEBIT` | 10 | 4 | 0 | 2^255 − 1 | 1 | 6 | 5,000 | 0 |
| `SDEBIT` | 9 | 10 | 0 | 2^255 − 1 | 0 | 9 | 2,200 | 0 |
| `SDEBIT` | 16 | 1 | 0 | 15 | 0 | 16 | 2,200 | 0 |
| `SDEBIT` | 2^255 + 20 | 10 | 0 | 2^255 − 1 | 0 | 2^255 + 20 | 2,200 | 0 |
| `SDEBIT` | 10 | 3 | 7 | `M` | 1 | 7 | 5,000 | 0 |
| `SDEBIT` | 10 | 4 | 7 | `M` | 0 | 10 | 2,200 | 0 |
| `SDEBIT` | `M` | 0 | 0 | `M` − 1 | 0 | `M` | 2,200 | 0 |
| `SDEBIT` | 100 | 0 | 0 | `M` − 1 | 1 | 100 | 2,200 | 0 |
| `SDEBIT` | 7 | 1 | 9 | 8 | 0 | 7 | 2,200 | 0 |
| `SDEBIT` | 5 | 0 | 6 | 10 | 0 | 5 | 2,200 | 0 |
| `SDEBIT` | `M` | 1 | `M` | `M` | 0 | `M` | 2,200 | 0 |

Under Amsterdam the same rows cost, by case: 12,100 execution gas and 97,920 state gas for the
first row, which creates the slot; 12,100 for every other row that changes the value, with 11,616
added to the refund counter for the row that clears it; and 2,100 for every row that leaves the
value unchanged.

More cases:

- **A restore.** A warm slot with `original = 5` and `current = 8`: `SDEBIT(slot, 3, 0, M)` pushes
  1, leaves 5, costs 100 and adds 2,800 to the refund counter (10,000 under Amsterdam).
- **Warm after a failure.** A failed operation on a cold slot leaves it warm: an `SLOAD` of the
  slot right after costs 100.
- **A static context.** Either operation in a static context halts exceptionally without reading
  the slot.
- **The sentry.** Outside a static context, either operation with 2300 gas or less left halts
  exceptionally without reading the slot. On a warm slot with 2301 gas left, a failing operation
  completes, pushes 0 and costs 100.
- **The block-level access list.** Under Amsterdam, `SCREDIT(slot, 1, 0, M)` on a cold slot with
  `original = current = 5`, the only attempt to access the slot in each of two otherwise identical
  blocks: with 2300 execution gas left at the operation, the frame halts before the read and the
  slot is absent from the block-level access list; with 2301, the slot is read, the frame runs out
  of gas when the write is charged, and the slot appears among the storage reads.

## Security Considerations

- **An unchecked success flag.** A contract that ignores `success = 0` carries on as if the update
  had happened, as with an unchecked call result. A compiler that lowers checked arithmetic on a
  storage variable to these operations should revert when they push 0.
- **The bounds.** The upper bound must exclude every bit the contract uses for other fields. On
  USDC's layout, an upper bound of 2^256 − 1 would let a credit carry into the blacklist flag. A
  value with other fields in use above it lies above any such bound, so the operations fail on it
  rather than change it.
- **Bounds computed at run time.** When `min > max`, both operations fail. A lower bound computed
  past the upper one, for example by an unchecked subtraction that wrapped, makes the operation
  fail instead of describing a range that wraps around 2^256.
- **Concurrency is not guaranteed.** Even when a transaction accesses a slot only through these
  operations, its starting value can affect bound-check results, gas charges and refunds. Whoever
  chooses the amounts and bounds can make a bound check sensitive to a small change in the slot.
  Execution in block order always defines the outcome.
  - Where block validity and transaction dependencies permit, a builder can put a transaction after
    the bound checks it would cause to fail, or omit it. A builder can sometimes detect the conflict
    without executing the candidate. An omitted candidate can still waste speculative work without
    paying on-chain gas.
  - Validation and proving must respect the submitted transaction order. If speculation fails,
    affected transactions may need to be re-executed. From Amsterdam on, validators can use the
    pre-block state and the supplied block-level access list to reconstruct transaction inputs,
    execute the transactions against those inputs, and verify the list.
  - A design can check inputs from the chosen block order against committed ranges and reuse prior
    execution when those ranges guarantee that the result remains valid. The ranges must account
    for bound checks, gas charges, refunds and other execution dependencies. The design determines
    how conflicts are resolved and who bears their cost.
- **Reentrancy.** The sentry applies as for `SSTORE`: a call with only the stipend cannot change
  storage through these operations.
- **Gas.** Every case costs what `SSTORE` costs for the same write; a failed operation costs a store
  of the unchanged value.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
