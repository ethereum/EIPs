---
eip: xxxx
title: Gas Limit Schedule
description: Move the block gas limit to a hard-fork-scheduled, consensus-enforced parameter, removing proposer/builder/operator configurability.
author: Barnabas Busa (@barnabasbusa)
discussions-to: https://ethereum-magicians.org/t/eip-xxxxx-gas-limit-schedule-gpo/28494
status: Draft
type: Standards Track
category: Core
created: 2026-05-11
requires: 1559, 7840, 7892
---

## Abstract

This EIP removes the block gas limit from the set of values that node operators, validators, builders, and proposers can choose freely. Instead, the gas limit becomes a hard-fork-scheduled parameter, configured through a `gasLimitSchedule` on the execution layer and a `GAS_LIMIT_SCHEDULE` on the consensus layer. Each fork (including BPO-style lightweight "Gas Parameter Only" forks) pins a single, exact gas limit value. Producing or attesting to a block whose `gas_limit` differs from the scheduled value is a consensus error and renders the block invalid. The legacy ±1/1024 elasticity rule from [EIP-1559](./eip-1559.md) is removed and the validator gas-limit preference exposed via the Engine API is deprecated.

## Motivation

Today the block gas limit is effectively a free parameter set by each block proposer, plumbed through:

1. Execution layer client flags (e.g., `--miner.gaslimit`, `--gas-ceil`, `--target-gas-limit`).
2. The consensus layer validator client's "preferred gas limit", forwarded to the execution layer via `engine_forkchoiceUpdatedV*` payload attributes.
3. Builder bids in the MEV-Boost / PBS flow, which advertise a `gas_limit` chosen by the builder to match (or approximate) the proposer's preference.
4. Block-level "voting" via the ±1/1024 elasticity rule introduced in [EIP-1559](./eip-1559.md), allowing the gas limit to drift up or down per block.

This design has several drawbacks:

- **Operational risk.** A coordinated client-default change or a popular configuration push can move the gas limit by millions of gas in days, with no protocol-level safety net. Recent gas limit changes have been preceded by months of off-chain coordination precisely because there is no in-protocol gate. If clients ship a default that turns out to be unsafe at scale (e.g., worst-case block validation times, mempool blow-ups, state-growth surprises), there is no consensus rule preventing the network from reaching it.
- **Implicit governance.** Setting the gas limit on mainnet is currently an opaque social process performed by individual validators and large staking operators. This makes it difficult for client teams and researchers to commit to safe upper bounds that are guaranteed to be respected.
- **Asymmetry with blob parameters.** [EIP-7892](./eip-7892.md) already established BPO ("Blob Parameter Only") hard forks as the canonical, low-overhead path for scaling blob capacity. Blob `target`, `max`, and `baseFeeUpdateFraction` are now hard-fork-scheduled and consensus enforced. Block gas remains the only major capacity dial still set by social consensus among validators.
- **Builder/proposer surface area.** Builder bids and validator preferences carry a `gas_limit` field that must be validated, communicated, and reconciled across the EL, CL, and relay. Removing this field shrinks the trusted interface and removes a class of bugs.

The goal of this EIP is to make the gas limit behave like every other hard-fork parameter: a single value, agreed at fork time, enforced by consensus, changeable only through a fork (a normal fork, or a lightweight Gas Parameter Only fork modeled on [EIP-7892](./eip-7892.md)).

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Activation

Let `FORK_TIMESTAMP` denote the activation timestamp of the fork that includes this EIP. The rules below apply to any execution payload whose `timestamp >= FORK_TIMESTAMP`, and to any beacon block whose slot maps to an epoch at or after the corresponding consensus-layer fork epoch.

### Gas limit schedule

The protocol gas limit at any timestamp `t >= FORK_TIMESTAMP` is determined by a `gasLimitSchedule` keyed by fork name. Each fork that changes the gas limit MUST add (or modify) its own entry. Subsequent forks that do not change the gas limit MUST copy the previous fork's value forward into their own entry.

#### Execution layer configuration

The chain configuration is extended with a `gasLimitSchedule` object and per-fork `<fork_name>Time` activation timestamps, following the convention established by [EIP-7840](./eip-7840.md) and [EIP-7892](./eip-7892.md):

```json
{
  "gasLimitSchedule": {
    "glamsterdam": 60000000,
    "gpo1":        75000000,
    "gpo2":        90000000
  },
  "glamsterdamTime": 1772000000,
  "gpo1Time":        1780000000,
  "gpo2Time":        1788000000
}
```

`gpo<index>` ("Gas Parameter Only") forks follow the same naming convention and lifecycle as BPO forks defined in [EIP-7892](./eip-7892.md). Activation timestamps are required only for forks at or after the activation fork of this EIP.

Define:

```python
def get_scheduled_gas_limit(timestamp: int, config: ChainConfig) -> int:
    active_fork = config.fork_active_at(timestamp)
    return config.gas_limit_schedule[active_fork]
```

`config.fork_active_at(timestamp)` returns the most recently activated fork (regular or `gpo<index>`) whose `<fork_name>Time <= timestamp`.

#### Consensus layer configuration

A new `GAS_LIMIT_SCHEDULE` field is added to consensus layer configuration, mirroring the `BLOB_SCHEDULE` mechanism in [EIP-7892](./eip-7892.md). Entries represent gas limit changes that take effect at the start of the listed epoch:

```yaml
GAS_LIMIT_SCHEDULE:
  - EPOCH: 500000     # Activation fork (e.g., Glamsterdam)
    GAS_LIMIT: 60000000
  - EPOCH: 520000     # A future GPO fork
    GAS_LIMIT: 75000000
  - EPOCH: 540000     # A future GPO fork
    GAS_LIMIT: 90000000
```

**Requirements:**

- Execution and consensus clients MUST share consistent gas-limit schedules.
- For every entry, the consensus-layer epoch start slot MUST map (via the slot-to-timestamp function) to the same activation timestamp used in the EL's `gasLimitSchedule` for that fork.
- The `GAS_LIMIT` value MUST equal the EL's `gasLimitSchedule[fork_name]` for that fork.

### Block-validity rule

The execution payload header field `gas_limit` is now consensus-fixed.

For any block with `timestamp >= FORK_TIMESTAMP`, the block is valid only if:

```
block.header.gas_limit == get_scheduled_gas_limit(block.header.timestamp, config)
```

A block whose `gas_limit` does not match the scheduled value MUST be rejected by both execution and consensus clients. This applies symmetrically to:

- Block production (proposers and builders MUST set `gas_limit` to the scheduled value).
- Block import and re-execution.
- Beacon block / `ExecutionPayloadHeader` validation in the consensus layer.
- Attestation: validators MUST NOT attest to a block that violates this rule.

This replaces the legacy [EIP-1559](./eip-1559.md) elasticity rule. Specifically, the constraints

```
parent.gas_limit - parent.gas_limit // 1024 < block.gas_limit < parent.gas_limit + parent.gas_limit // 1024
block.gas_limit >= 5000
```

are no longer enforced for blocks at or after `FORK_TIMESTAMP`; they are superseded by the exact-match rule above.

### Engine API changes

Starting at the engine API version released alongside this EIP:

- The `payloadAttributes` object passed to `engine_forkchoiceUpdatedV*` MUST NOT include a proposer-supplied gas limit field. Any existing field carrying the proposer's preferred gas limit (e.g., `gasLimit` payload attribute on networks where it was added) is removed; if present, it MUST be ignored by the execution layer and SHOULD cause the call to be rejected with `-32602 invalid payload attributes`.
- When building a payload, the execution layer MUST set `gas_limit = get_scheduled_gas_limit(payloadAttributes.timestamp, config)`. It MUST NOT read this value from any operator-supplied configuration (CLI flag, JSON config, RPC, etc.).
- Execution layer clients SHOULD log a warning and ignore any operator-supplied gas-limit configuration at startup for timestamps at or after `FORK_TIMESTAMP`. Operator configuration MAY still apply to pre-fork blocks (e.g., for historical reproduction and replay).

### Validator client and builder API changes

- Validator clients MUST NOT expose or transmit a "preferred gas limit" setting that influences post-fork blocks.
- The builder API's `SignedBuilderBid` / `ExecutionPayloadHeader` MUST carry `gas_limit` equal to the scheduled value. Relays MUST reject builder bids whose `gas_limit` does not match `get_scheduled_gas_limit(timestamp, config)`. Proposers MUST NOT sign a header that violates this rule.
- The proposer's pre-registration with a relay (the "validator registration" carrying `gas_limit`) is deprecated for purposes of influencing the block's gas limit. Relays SHOULD continue to accept the field for backward compatibility but MUST ignore it when constructing post-fork bids.

### Chain Specifics

Testnets and devnets MUST include a `gasLimitSchedule` entry for genesis if their genesis is at or after this EIP's activation. For testnets that were live before the activation fork, the genesis entry is unnecessary; only the activation fork's entry is required.

For private testnets exercising rapid scaling (e.g., shadowforks of `gpo<index>` forks), the same mechanism is used: define a new `gpo<index>` entry and the corresponding activation time.

## Rationale

### Why a schedule rather than a runtime parameter?

A schedule (rather than, say, an on-chain vote or a moving average) keeps the change minimal, mirrors the established BPO mechanism from [EIP-7892](./eip-7892.md), and matches how the community already coordinates gas-limit changes in practice: socially, with months of lead time, tied to a specific upgrade window. Encoding that decision into config and enforcing it in consensus is the smallest change that gives the desired safety property.

### Why remove validator/proposer choice entirely?

Per-proposer choice was originally motivated by the desire to let stakers respond quickly to network conditions. In practice the mechanism is used for slow, coordinated changes ([EIP-7935](./eip-7935.md) being a recent example), not for rapid response. Meanwhile, the configurability creates risk: a single popular client default change can move the network's effective gas limit without any in-protocol gate. The `gpo<index>` mechanism preserves the ability to move quickly when needed — a GPO fork can be scheduled with the same lead time as a BPO fork — while ensuring the change is explicit and auditable.

### Why exact equality, not an upper bound?

An upper bound (e.g., "block.gas_limit MUST NOT exceed scheduled value") would still allow proposers to set lower values, which preserves a class of edge cases (split views, builder/proposer disagreement, accidental misconfiguration that produces unusually small blocks). Exact equality is simpler, cheaper to verify, and forecloses these edge cases. If a future hard fork wants to reintroduce flexibility within a bounded range, it can do so explicitly.

### Why is this consensus-breaking instead of a client-side default?

The motivating concern is exactly that client-side defaults are not consensus-enforced. A misconfigured or malicious client could ship a default well above what the network has been tested for, and the protocol would accept those blocks. Moving the rule into consensus closes that gap.

### Relationship to EIP-1559

[EIP-1559](./eip-1559.md) introduced the elasticity multiplier and the ±1/1024 gas-limit adjustment rule. The base-fee mechanism (target = `gas_limit / elasticity_multiplier`, max = `gas_limit`) is unchanged in spirit; it now uses the scheduled `gas_limit` as its input. The per-block adjustment rule is removed because the gas limit no longer varies block-to-block within a fork.

### Relationship to EIP-7825

[EIP-7825](./eip-7825.md) caps per-transaction gas. This EIP caps (and fixes) per-block gas. The two are complementary: EIP-7825 prevents single-transaction DoS within a block; this EIP prevents the block-level capacity itself from drifting away from a tested safe value.

## Backwards Compatibility

This change is consensus-breaking. Specifically:

- Blocks valid under the [EIP-1559](./eip-1559.md) elasticity rule but whose `gas_limit` differs from the scheduled value are invalid after `FORK_TIMESTAMP`.
- Execution layer client configuration related to gas limit (CLI flags, JSON keys) becomes a no-op for post-fork blocks. Clients SHOULD continue to honor these flags for historical replay and for pre-fork blocks.
- Validator client "preferred gas limit" settings become a no-op for post-fork blocks.
- Builder API consumers (relays, builders, proposer middleware) must be updated to set `gas_limit` to the scheduled value and to reject mismatches.

Tooling that reads `block.gas_limit` continues to work unchanged; the field is still present in the header, it is simply protocol-determined.

## Test Cases

The following cases describe the expected validation behavior at and after `FORK_TIMESTAMP`. Let `S = get_scheduled_gas_limit(block.timestamp, config)`.

1. **Equal to schedule.** `block.gas_limit == S` → block valid (with respect to this rule).
2. **Above schedule.** `block.gas_limit == S + 1` → block invalid.
3. **Below schedule.** `block.gas_limit == S - 1` → block invalid.
4. **Within legacy elasticity, not on schedule.** `parent.gas_limit == S`, `block.gas_limit == S + S // 1024` → block invalid (legacy rule no longer applies).
5. **GPO transition block.** Block with `timestamp` exactly equal to `gpo1Time`: `block.gas_limit == gasLimitSchedule["gpo1"]` → valid; any other value → invalid.
6. **Pre-fork block at fork boundary.** Block with `timestamp == FORK_TIMESTAMP - 1` is still subject to the legacy rule; the new rule does not apply.
7. **Engine API payload attributes carrying gas-limit field.** `engine_forkchoiceUpdated` call with a non-empty proposer gas-limit attribute → call rejected with `-32602`.
8. **Builder bid mismatch.** Relay receives a builder bid with `gas_limit != S` → relay rejects bid.

## Reference Implementation

Pseudocode for the execution-layer block validity check:

```python
def validate_gas_limit(block: Block, parent: Block, config: ChainConfig) -> None:
    if block.header.timestamp < config.activation_timestamp(THIS_EIP_FORK):
        # Legacy EIP-1559 elasticity rule
        delta = parent.header.gas_limit // 1024
        assert parent.header.gas_limit - delta < block.header.gas_limit < parent.header.gas_limit + delta
        assert block.header.gas_limit >= 5000
        return

    scheduled = get_scheduled_gas_limit(block.header.timestamp, config)
    if block.header.gas_limit != scheduled:
        raise InvalidBlock(
            f"gas_limit {block.header.gas_limit} != scheduled {scheduled}"
        )
```

Pseudocode for the consensus-layer execution payload header check:

```python
def verify_execution_payload_header(state: BeaconState, header: ExecutionPayloadHeader) -> None:
    scheduled = get_scheduled_gas_limit_cl(compute_epoch_at_slot(state.slot), state.config)
    assert header.gas_limit == scheduled
    # ... other existing checks ...
```

## Security Considerations

**Primary goal: prevent unsafe gas-limit drift.** The dominant risk this EIP addresses is that the network reaches a gas limit that has not been tested at scale, due to a coordinated default change in clients or staking pools. Encoding the limit in consensus closes this gap: no popular default and no validator preference can push the network past the scheduled value.

**Liveness.** Because the rule is exact-equality, a misconfigured proposer or builder that produces a block with the wrong `gas_limit` orphans that slot rather than producing an invalid-but-followed chain. This is the intended behavior — incorrect gas-limit values are now a self-correcting safety condition rather than a silent capacity change — but it does mean that bugs in the schedule plumbing manifest as missed slots. Clients SHOULD validate the schedule at startup and refuse to start if the EL and CL disagree.

**Fork coordination risk.** This EIP creates a hard dependency between EL and CL gas-limit schedules. A divergence (EL says 90M, CL says 75M) will split the network at the fork boundary. The same risk exists today for BPO blob schedules; the same mitigations apply: schedule consistency checks at startup, devnet rehearsals, and clear off-chain coordination of `gpo<index>` schedules.

**Upgrade pressure.** Removing per-validator gas-limit voting removes one informal mechanism for the staking community to signal concerns about capacity. EIP authors and core devs SHOULD treat this as a reason to maintain visible, structured channels for capacity discussion (e.g., All Core Devs calls, public test results) ahead of any `gpo<index>` fork.

**Privacy/MEV considerations.** Builders and relays no longer compete on or advertise gas limits. This is a small reduction in the builder-proposer interface and is not expected to affect MEV economics meaningfully, since post-fork the gas limit is the same across all blocks.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
