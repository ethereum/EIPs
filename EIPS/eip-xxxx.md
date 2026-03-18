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

This EIP makes `SECONDS_PER_SLOT` a runtime configuration on the consensus layer rather than a compile-time constant, then uses that infrastructure to reduce slot duration. Block gas limits and blob parameters scale proportionally to maintain constant throughput per unit time.

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

Phase 1 has value regardless of the final number. It turns `SECONDS_PER_SLOT` from a compile-time constant into a runtime configuration, so future slot duration changes become configuration updates rather than contentious protocol upgrades. If analysis ultimately shows twelve seconds is optimal, the effort still delivers a cleaner client architecture, a comprehensive CL performance characterization, and the readiness to reduce when conditions permit.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Parameters

| Name | Value | Note |
| ---- | ----- | ---- |
| `SECONDS_PER_SLOT` | `8` | Placeholder pending CL performance characterization |

### Slot schedule

A `SLOT_SCHEDULE` configuration parameter is added to the consensus layer:

```
SLOT_SCHEDULE:
  - EPOCH: 0
    SECONDS_PER_SLOT: 12
  - EPOCH: <FORK_EPOCH>
    SECONDS_PER_SLOT: 8
```

For any given slot, clients MUST resolve `SECONDS_PER_SLOT` by selecting the `SLOT_SCHEDULE` entry with the greatest `EPOCH` less than or equal to the slot's epoch. All references to `SECONDS_PER_SLOT` in the consensus specification MUST use this resolved value.

### Gas limit adjustment

The first block produced at or after the fork activation timestamp MUST set its gas limit to:

```
fork_gas_limit = parent_gas_limit * new_seconds_per_slot / old_seconds_per_slot
```

where `new_seconds_per_slot` and `old_seconds_per_slot` are the `SECONDS_PER_SLOT` values from the current and immediately preceding `SLOT_SCHEDULE` entries, respectively. This value is computed using integer division (truncating). The normal gas limit adjustment rule (±1/1024 of the parent gas limit) does not apply to this block; the fork block's gas limit MUST equal exactly `fork_gas_limit`. From the following block onward, normal gas limit voting resumes using `fork_gas_limit` as the base.

The consensus layer communicates the expected gas limit to the execution layer via the engine API payload attributes for the fork block.

### Blob limit adjustment

The blob target and blob limit MUST each be scaled by `new_seconds_per_slot / old_seconds_per_slot` (integer division, truncating) at the fork boundary. These are protocol-set constants and do not involve a voting mechanism. This preserves constant blob throughput per unit time.

### Attestation deadlines

Deadlines are recalibrated for the eight-second slot:

| Event | Time into slot |
| ----- | -------------- |
| Block proposal | 0 ms |
| Attestation deadline | 4000 ms |
| Aggregate deadline | 6000 ms |

### Consensus timing constants

The following constants depend on `SECONDS_PER_SLOT` and MUST be recalculated when the slot duration changes:

- Epoch duration (`SECONDS_PER_SLOT * SLOTS_PER_EPOCH`)
- Time to finality
- `ATTESTATION_DUE_BPS` and related deadline parameters
- Reward and penalty calculations that scale with epoch duration

## Rationale

### Why infrastructure first

The bottleneck is not picking a number. It is the hardcoded twelve-second assumption spread across every consensus and execution client. `SLOT_SCHEDULE` decouples slot duration from protocol upgrades: once it ships, changing slot time is a configuration update, not a hard fork. This also gives client teams a concrete reason to audit and clean up timing-related technical debt — work that compounds across future upgrades.

### Why eight seconds

FOCIL is likely to be the consensus layer headliner for the next fork, and each layer is typically limited to one headliner. Six-second slots — as proposed in [EIP-7782](./eip-7782.md) — are a heavy lift; they may be infeasible as a non-headliner alongside FOCIL. Eight seconds is a middle path: conservative enough to ship alongside FOCIL, aggressive enough to move the needle on UX and MEV. Even ten seconds would be a meaningful win. The exact target follows from phase 2 performance characterization and may be revised before deployment.

### Why proportional gas scaling

Scaling the gas limit by `new_seconds_per_slot / old_seconds_per_slot` preserves the gas-per-second invariant. Block validation, gas accounting, and state growth rates stay the same on a per-second basis. Deriving the scaling ratio from the slot schedule rather than introducing separate scaling parameters ensures a single source of truth — changing the target slot duration automatically produces the correct gas limit adjustment, eliminating the risk of mismatched parameters. The execution layer impact is deliberately minimal — this EIP is designed to ship as a non-headliner.

### Why a protocol-enforced gas limit adjustment

The alternative is to rely on validators to gradually vote the gas limit down after the fork. At the maximum adjustment rate of ±1/1024 per block, reducing from 36M to 24M gas would take approximately 341 blocks (~45 minutes at eight-second slots). During that transition, gas-per-second throughput would be up to 50% above the intended target — twelve-second blocks' worth of gas arriving every eight seconds — precisely when the network is also adapting to tighter slot timing. A one-time protocol-enforced adjustment eliminates this coordination problem and ensures correct throughput from the first post-fork block.

### EIP-1559 base fee impact

The instant gas limit reduction does not cause a sustained base fee disruption. Gas-per-second target is preserved across the fork: the pre-fork target of 18M gas per twelve-second block equals the post-fork target of 12M gas per eight-second block (both 1.5M gas/sec). Since demand in gas-per-second terms is unchanged, the steady-state base fee is identical on both sides of the fork.

In the worst case, the mempool backlog at the fork block fills it completely (24M gas used against a 12M target), producing a one-time base fee increase of 12.5% via the EIP-1559 update rule. The following blocks see demand at the normal per-second rate (~10M gas per eight-second block, below the 12M target), so the base fee immediately begins decreasing. The transient resolves within one to two blocks (8–16 seconds) — well within normal base fee volatility. The blob base fee mechanism has an analogous update rule and the same analysis applies.

### Validator gas limit sovereignty

After the fork block, normal ±1/1024 gas limit voting resumes. Validators could, in principle, immediately vote the gas limit back up. This is no different from today: validators already have the ability to vote for any gas limit within the adjustment bounds, and the protocol has always relied on validator judgment to set this parameter responsibly. The one-time fork adjustment does not alter this social contract.

### Fallback

If going below twelve seconds proves infeasible, the outcome defaults to the status quo plus a properly characterized CL and future-ready infrastructure. `SLOT_SCHEDULE` ships regardless. The slot duration stays at twelve seconds until conditions permit a reduction — but the infrastructure to make that reduction is already in place.

## Backwards Compatibility

This EIP requires a hard fork. The consensus layer bears most of the change: clients must replace hardcoded twelve-second slot assumptions with the `SLOT_SCHEDULE` lookup. The execution layer impact is limited to a one-time gas limit and blob limit adjustment at the fork boundary. Applications and tooling that assume twelve-second block times will need updating.

## Security Considerations

### Network propagation

Tighter slots shrink the window for block propagation and validation. Clients must reliably propagate and validate blocks within the four-second attestation deadline; failure to do so increases missed attestations and degrades consensus participation. Phase 2 (CL performance characterization) is explicitly designed to surface these bottlenecks before committing to a final slot duration.

### Validator hardware requirements

Shorter slots raise per-second computational and bandwidth demands. The eight-second target should be validated against the current validator hardware distribution to avoid increasing centralization pressure. Note that peak bandwidth per block is not affected — gas per block decreases proportionally with slot time.

### Attestation aggregation

The six-second aggregate deadline leaves two fewer seconds than today for collecting and aggregating attestations. Subnet aggregation strategies may need optimization to maintain aggregate quality under the tighter schedule.

### Graceful degradation

`SLOT_SCHEDULE` provides a natural escape hatch: if the network degrades after the fork, a subsequent configuration change can revert to longer slots without additional protocol-level modifications.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
