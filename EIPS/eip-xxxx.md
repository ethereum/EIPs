---
eip: TBD
title: Quick Slots
description: Introduce variable slot timing infrastructure and reduce slot duration.
author: Carl Beekhuizen (@carlbeek)
discussions-to: https://ethereum-magicians.org/t/the-case-for-quick-slots-in-hegota/27708
status: Draft
type: Standards Track
category: Core
created: 2026-03-17
---

## Abstract

This EIP makes `SLOT_DURATION_MS` a runtime configuration on the consensus layer rather than a compile-time constant, then uses that infrastructure to reduce slot duration. Block gas limits and blob parameters scale proportionally to maintain constant throughput per unit time.

## Motivation

Slot time is the heartbeat of Ethereum's user experience. Every second shaved off means faster transaction landings, faster exchange deposits, and faster real-world payments. But the benefits extend well beyond UX.

### User experience

Twelve seconds is slow. It is perceptible in payments, exchange deposits, and every on-chain interaction. Reducing slot time brings Ethereum closer to the responsiveness users already expect from modern financial infrastructure.

### DEX pricing and MEV

Arbitrage losses scale with the square root of inter-block time. Going from twelve to eight seconds cuts this by roughly 18%, tightening on-chain pricing and reducing value extracted from users. MEV extraction is also non-linear in slot time: shorter slots compress the surplus available per block, squeezing the entire MEV supply chain.

### Empty blocks and ePBS

Proposer builder separation grants builders a free option on the block — they can abandon it if prices move against them. The value of that option grows with slot duration. Shorter slots shrink it, mitigating the empty block problem.

### Preconfirmation complexity

Preconfirmation protocols exist to paper over twelve-second latency. Reducing slot time attacks the root cause, decreasing the need for additional trust assumptions and protocol complexity layered on top.

### L2 sequencing & interop

Based rollups inherit L1 block time as their sequencing interval. Faster L1 slots mean faster based rollups, with zero changes required on the rollup side.

L2s that use the L1 for interop between themselves also inherit the L1's slot duration. Shorter slots reduce the latency of interop transactions.

### A phased approach to shorter slots

Nobody knows the safe minimum slot duration with today's client implementations. Rather than stalling on the choice of a number, this EIP separates the work into three phases:

1. **Variable slot timing infrastructure** — Remove the assumption that slots are twelve seconds. Update background task scheduling, timing constants, functions such as `compute_time_at_slot(...)`, and fork transition logic to derive timing from a runtime configuration.
2. **CL performance characterization** — Systematically identify consensus layer bottlenecks through devnets and benchmarks, analogous to the execution layer's bloat-nets and perf-nets. Current understanding of blob propagation limits, attestation aggregation capacity, and local block building times remains incomplete.
3. **Iterative slot time reduction** — Cut slack from the slot duration based on the results of phase 2. Address client constraints, reduce further as headroom emerges, iterate.

Phase 1 has value regardless of the final number. It turns `SLOT_DURATION_MS` from a compile-time constant into a runtime configuration, so future slot duration changes become configuration updates rather than contentious protocol upgrades. If analysis ultimately shows twelve seconds is optimal, the effort still delivers a cleaner client architecture, a comprehensive CL performance characterization, and the readiness to reduce when conditions permit.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

All arithmetic in this specification uses integer division (truncating toward zero). Formulas are written with the multiply performed before the divide to preserve precision.

### Parameters

At `<FORK_EPOCH>`, the following constants take effect. All consensus layer timing derivations MUST use the fork-activated values from the fork epoch onward. Functions that compute wall-clock time from slot numbers, such as `compute_time_at_slot(...)`, MUST account for the duration change at the fork boundary.

| Constant | Current | New |
| -------- | ------- | --- |
| `SLOT_DURATION_MS` | 12,000 | 8,000 |
| `BASE_REWARD_FACTOR` | 64 | 42 |
| `INACTIVITY_PENALTY_QUOTIENT_BELLATRIX` | 16,777,216 | 37,748,736 |
| `MIN_EPOCHS_FOR_BLOB_SIDECARS_REQUESTS` | 4,096 | 6,144 |
| `MIN_EPOCHS_FOR_DATA_COLUMN_SIDECARS_REQUESTS` | 4,096 | 6,144 |
| `CHURN_LIMIT_QUOTIENT` | 65,536 | 98,304 |
| `MIN_PER_EPOCH_CHURN_LIMIT_ELECTRA` | 128,000,000,000 | 85,333,333,333 |
| `MAX_PER_EPOCH_ACTIVATION_EXIT_CHURN_LIMIT` | 256,000,000,000 | 170,666,666,666 |

### Gas limit adjustment

The first block produced at or after the fork activation timestamp MUST set its gas limit to:

```
fork_gas_limit = parent_gas_limit * SLOT_DURATION_MS // old_slot_duration_ms
```

where `old_slot_duration_ms` is the pre-fork value (12,000). The normal gas limit adjustment rule (±1/1024 per [EIP-1559](./eip-1559.md)) does not apply to this block. From the following block onward, normal gas limit voting resumes using `fork_gas_limit` as the base.

### Blob parameter adjustment

A new entry MUST be appended to the `BLOB_SCHEDULE` at `<FORK_EPOCH>` with:

```
new_max_blobs = old_max_blobs * SLOT_DURATION_MS // old_slot_duration_ms
```

where `old_max_blobs` is the `MAX_BLOBS_PER_BLOCK` from the most recent preceding `BLOB_SCHEDULE` entry. The blob target is derived from `MAX_BLOBS_PER_BLOCK` as usual.

## Rationale

### Why infrastructure first

The bottleneck is not picking a number. It is the hardcoded twelve-second assumption spread across every consensus and execution client. Delivering this change as a fork forces client teams to audit and remove these assumptions — once that work is done, future slot duration changes become straightforward fork-activated parameter updates rather than invasive refactors. The infrastructure work compounds across future upgrades.

### Why eight seconds

This EIP takes the approach of building the variable slot timing infrastructure first, then reduce the slot duration conservatively as a non-headliner change. Eight seconds is chosen as a reasonable placeholder value that would provide a real UX win, if we discover we can go lower, we should. Even ten seconds would be a meaningful win. The exact target follows from phase 2 performance characterization and may be revised before deployment.

### Constant scaling

The general principle is: **do not adjust a constant unless there is a concrete security or economic failure from leaving it unchanged.** Most epoch- and slot-denominated constants were chosen as clean powers of two with generous margins; shorter slots make epochs arrive faster, which incidentally improves finality time, and the vast majority tolerate this without issue. Only four categories require adjustment, each with a distinct scaling formula.

**Issuance.** `BASE_REWARD_FACTOR` is applied once per epoch. More epochs per year means proportionally higher issuance. It scales linearly: `BASE_REWARD_FACTOR * new_slot_duration_ms // old_slot_duration_ms`. Integer truncation produces `42` rather than the ideal `42.667`, under-issuing by approximately 1.6% — a smaller deviation than typical validator participation rate fluctuations.

**Inactivity leak.** The per-epoch penalty grows linearly with epoch count, making the cumulative penalty over `K` epochs proportional to `K²`. The quotient must therefore scale by the **square** of the epoch ratio: `INACTIVITY_PENALTY_QUOTIENT_BELLATRIX * old² // new²`. Because the quotient is a *divisor* in the penalty formula, a larger quotient produces a smaller per-epoch penalty, compensating for the increased number of epochs per wall-clock time.

**Data availability windows.** `MIN_EPOCHS_FOR_BLOB_SIDECARS_REQUESTS` and `MIN_EPOCHS_FOR_DATA_COLUMN_SIDECARS_REQUESTS` have a hard external dependency on optimistic rollup challenge periods (typically seven days). They scale inversely to preserve wall-clock duration: `CONSTANT * old_slot_duration_ms // new_slot_duration_ms`.

**Churn limits.** Validator churn rates determine the weak subjectivity period, a wall-clock security property. Per-epoch limits scale by `new // old`; `CHURN_LIMIT_QUOTIENT`, which acts as a divisor, scales by `old // new`.

Blob parameters are also scaled proportionally. Integer division truncates when `old_max_blobs` is not a multiple of `old_slot_duration_ms // gcd(new_slot_duration_ms, old_slot_duration_ms)` (e.g., not a multiple of 3 for a 12→8 second transition), producing at most one blob of throughput reduction per slot.

### Why proportional gas scaling

Scaling the gas limit by `new_slot_duration_ms // old_slot_duration_ms` preserves the gas-per-second invariant. Block validation, gas accounting, and state growth rates stay the same on a per-second basis. Deriving the scaling ratio from the slot duration change rather than introducing separate scaling parameters ensures a single source of truth — changing the target slot duration automatically produces the correct gas limit adjustment, eliminating the risk of mismatched parameters.

### Why a protocol-enforced gas limit adjustment

The alternative is to rely on validators to gradually vote the gas limit down after the fork. At the maximum adjustment rate of ±1/1024 per block, reducing from 36M to 24M gas would take approximately 341 blocks (~45 minutes at eight-second slots). During that transition, gas-per-second throughput would be up to 50% above the intended target — twelve-second blocks' worth of gas arriving every eight seconds — precisely when the network is also adapting to tighter slot timing. A one-time protocol-enforced adjustment eliminates this coordination problem and ensures correct throughput from the first post-fork block.

### EIP-1559 base fee impact

The instant gas limit reduction does not cause a sustained base fee disruption. Gas-per-second target is preserved across the fork: the pre-fork target of 18M gas per twelve-second block equals the post-fork target of 12M gas per eight-second block (both 1.5M gas/sec). Since demand in gas-per-second terms is unchanged, the steady-state base fee is identical on both sides of the fork.

In the worst case, the mempool backlog at the fork block fills it completely (24M gas used against a 12M target), producing a one-time base fee increase of 12.5% via the EIP-1559 update rule. The following blocks see demand at the normal per-second rate (~10M gas per eight-second block, below the 12M target), so the base fee immediately begins decreasing. The transient resolves within one to two blocks (8–16 seconds) — well within normal base fee volatility. The blob base fee mechanism has an analogous update rule and the same analysis applies.

### Validator gas limit sovereignty

After the fork block, normal ±1/1024 gas limit voting resumes. Validators could, in principle, immediately vote the gas limit back up. This is no different from today: validators already have the ability to vote for any gas limit within the adjustment bounds, and the protocol has always relied on validator judgment to set this parameter responsibly. The one-time fork adjustment does not alter this social contract.

### Attestation deadlines

Intra-slot timing deadlines (attestation, aggregation, sync committee contributions, etc.) are specified in basis points of `SLOT_DURATION_MS` and automatically scale with slot duration — no specification changes are required. Whether the resulting absolute deadlines remain feasible for network propagation at shorter slot durations is a phase 2 question; the BPS values may need tuning based on empirical results, but this is a configuration concern rather than a specification change.

### Why the inactivity leak requires quadratic scaling

The inactivity penalty at epoch `k` of a finality failure is proportional to `k` (the score grows linearly). The cumulative penalty over `K` epochs is therefore proportional to `K²`. When slot duration shrinks by a factor `r = new / old`, there are `1/r` more epochs per unit of wall-clock time. A naïve linear scaling of `INACTIVITY_PENALTY_QUOTIENT_BELLATRIX` by `1/r` cancels only the linear increase in epoch count, leaving the quadratic term under-corrected — the leak would be `1/r` times faster in wall-clock time than intended. Scaling by `1/r²` correctly compensates for the quadratic accumulation, preserving the originally calibrated relationship between finality failure duration and validator balance loss.

### Why `INACTIVITY_SCORE_BIAS` and `INACTIVITY_SCORE_RECOVERY_RATE` are unchanged

In the penalty formula `effective_balance * inactivity_score // (INACTIVITY_SCORE_BIAS * INACTIVITY_PENALTY_QUOTIENT_BELLATRIX)`, the score after `k` offline epochs is `k * INACTIVITY_SCORE_BIAS`. Substituting:

```
penalty_at_epoch_k = effective_balance * k * INACTIVITY_SCORE_BIAS
                     // (INACTIVITY_SCORE_BIAS * INACTIVITY_PENALTY_QUOTIENT_BELLATRIX)
                   = effective_balance * k // INACTIVITY_PENALTY_QUOTIENT_BELLATRIX
```

`INACTIVITY_SCORE_BIAS` cancels entirely. Adjusting it would change the raw score numbers without affecting the economic outcome. `INACTIVITY_SCORE_RECOVERY_RATE` governs post-leak score decay; with more epochs per wall-clock time, scores recover faster — a benign side effect that requires no correction.

### `SLOTS_PER_EPOCH` unchanged

`SLOTS_PER_EPOCH` remains 32. With eight-second slots, epochs shrink from ~6.4 minutes to ~4.3 minutes. This means Ethereum finalizes in roughly 8.5 minutes instead of 13 — a 35% improvement to finality that falls out of shorter slots for free, with no changes to Casper FFG or the attestation mechanism.

### Minimal constant adjustment

Many consensus layer constants are denominated in epochs or slots, and shorter slots cause their wall-clock durations to shrink proportionally. This EIP deliberately does not adjust the majority of these constants. Most were chosen as clean powers of two and have generous margins — for example, `EPOCHS_PER_SLASHINGS_VECTOR` shrinks from ~36 to ~24 days, but 24 days is still far longer than any plausible correlated attack window; `MIN_VALIDATOR_WITHDRAWABILITY_DELAY` shrinks from ~27 to ~18 hours, but slashing detection and processing takes minutes, not hours. Adjustments are made only where a concrete security or economic property would be violated: annualized issuance (which would rise ~50%), inactivity leak timing (which was precisely calibrated with a quadratic penalty structure), data availability windows (which have an external dependency on L2 challenge periods), and churn limits (which directly determine the weak subjectivity period).

### Fallback

If going below twelve seconds proves infeasible, the outcome defaults to the status quo plus a properly characterized CL and future-ready infrastructure. The slot duration stays at twelve seconds, but the work of removing hardcoded timing assumptions delivers a cleaner client architecture and the readiness to reduce when conditions permit.

## Backwards Compatibility

This EIP requires a hard fork. The consensus layer bears most of the change: clients must replace hardcoded twelve-second slot assumptions with fork-aware timing derivations. The execution layer impact is limited to a one-time gas limit and blob parameter adjustment at the fork boundary. Applications and tooling that assume twelve-second block times will need updating.

## Security Considerations

### Network propagation

Tighter slots shrink the window for block propagation, validation, and attestation aggregation. Intra-slot timing deadlines are specified in basis points and scale automatically, but the resulting absolute durations must remain feasible for real-world network conditions. Phase 2 (CL performance characterization) is explicitly designed to surface these bottlenecks before committing to a final slot duration.

### Validator hardware requirements

Shorter slots raise per-second computational and bandwidth demands. Validator hardware distribution should be considered when deciding the slot duration. Note that peak bandwidth per payload is not affected — gas per block and the number of blobs decreases proportionally with slot time.

### Weak subjectivity period

The weak subjectivity period depends on the rate at which the validator set can turn over. Without churn limit adjustment, per-epoch churn rates applied over more epochs per year would allow the validator set to change faster in wall-clock time, shrinking the safe window for weak subjectivity checkpoints. This EIP scales churn limits to preserve the current wall-clock churn rate, maintaining the existing weak subjectivity period.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
