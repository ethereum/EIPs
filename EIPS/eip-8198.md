---
eip: 8198
title: Quick Slots
description: Introduce variable slot timing infrastructure and reduce slot duration.
author: Carl Beekhuizen (@carlbeek)
discussions-to: https://ethereum-magicians.org/t/eip-8198-quick-slots/28057
status: Draft
type: Standards Track
category: Core
created: 2026-03-17
requires: 7892
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
fork_gas_limit = (parent_gas_limit * SLOT_DURATION_MS) // old_slot_duration_ms
```

where `old_slot_duration_ms` is the pre-fork value (12,000). The normal gas limit adjustment rule (±1/1024) does not apply to this block. From the following block onward, normal gas limit voting resumes using `fork_gas_limit` as the base.

### Blob parameter adjustment

A new entry MUST be appended to the `BLOB_SCHEDULE` (as defined in [EIP-7892](./eip-7892.md)) at `<FORK_EPOCH>` with:

```
new_max_blobs = (old_max_blobs * SLOT_DURATION_MS) // old_slot_duration_ms
```

where `old_max_blobs` is the `MAX_BLOBS_PER_BLOCK` from the most recent preceding `BLOB_SCHEDULE` entry. The blob target is derived from `MAX_BLOBS_PER_BLOCK` as usual.

## Rationale

### Why infrastructure first

The bottleneck is not picking a number. It is the hardcoded twelve-second assumption spread across every consensus and execution client. Delivering this change as a fork forces client teams to audit and remove these assumptions — once that work is done, future slot duration changes become straightforward fork-activated parameter updates rather than invasive refactors. The infrastructure work compounds across future upgrades.

### Why eight seconds

This EIP takes the approach of building the variable slot timing infrastructure first, then reduce the slot duration conservatively as a non-headliner change. Eight seconds is chosen as a reasonable placeholder value that would provide a real UX win, if we discover we can go lower, we should. Even ten seconds would be a meaningful win. The exact target follows from phase 2 performance characterization and may be revised before deployment.

### Constant scaling

The general principle is: **do not adjust a constant unless there is a concrete security or economic failure from leaving it unchanged.** Most epoch- and slot-denominated constants have generous margins: `EPOCHS_PER_SLASHINGS_VECTOR` shrinks from ~36 to ~24 days but remains far longer than any plausible attack window; `MIN_VALIDATOR_WITHDRAWABILITY_DELAY` shrinks from ~27 to ~18 hours but slashing detection takes minutes. `SLOTS_PER_EPOCH` remains 32; the resulting ~4.3 minute epochs mean finality improves from ~13 to ~8.5 minutes for free. Only four categories require adjustment:

**Issuance.** `BASE_REWARD_FACTOR` scales linearly with epoch duration to preserve annualized issuance. Integer truncation (42 vs. ideal 42.667) under-issues by ~1.6%, less than typical participation rate fluctuations.

**Inactivity leak.** The cumulative penalty is quadratic in epoch count (`K^2`), so the quotient scales by the square of the epoch ratio. As a divisor, a larger quotient produces a smaller per-epoch penalty, compensating for the faster epoch cadence. `INACTIVITY_SCORE_BIAS` cancels algebraically between the score numerator and penalty denominator and needs no adjustment. `INACTIVITY_SCORE_RECOVERY_RATE` governs post-leak decay; modestly faster recovery is benign.

**Data availability windows.** Hard external dependency on rollup challenge periods (~7 days). Scaled inversely to preserve wall-clock duration.

**Churn limits.** Preserve the wall-clock weak subjectivity period. Per-epoch limits scale by `new // old`; the quotient (a divisor) scales by `old // new`.

Blob parameters scale proportionally; integer truncation can reduce per-slot capacity by at most one blob when `old_max_blobs` is not a multiple of 3 (for 12→8s).

### Gas limit

The gas limit scales by `new_slot_duration_ms // old_slot_duration_ms`, preserving the gas-per-second invariant. This is enforced at the fork block rather than relying on validator voting, which at ±1/1024 per block would take ~45 minutes to converge — during which gas-per-second throughput would exceed the target by up to 50%. The steady-state base fee is unchanged because the gas-per-second target is preserved. A worst-case one-time transient of ~12.5% resolves within one to two blocks. After the fork block, normal gas limit voting resumes; validator sovereignty over this parameter is unchanged.

### Attestation deadlines

Intra-slot timing deadlines are specified in basis points of `SLOT_DURATION_MS` and scale automatically with slot duration. Whether the resulting absolute deadlines remain feasible is a phase 2 question; the BPS values may need tuning based on empirical results.

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
