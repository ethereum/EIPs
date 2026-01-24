---
eip: TBA
title: BPO2 Upgrade
description: Blob parameter changes with BPO2 on Ethereum mainnet.
author: Pooja Ranjan (@poojaranjan)
discussions-to: TBA
status: Draft
type: Meta
created: 2026-01-24
requires: 7892, BPO1
---

## Abstract

This Meta EIP documents the activation details, parameter changes, and specification references for the second Blob-Parameter-Only (BPO) network upgrade, **BPO2**. It provides a canonical registry of blob target, blob maximum limits, and associated configuration values, enabling transparent tracking of incremental data availability scaling following BPO1 under Ethereum’s Surge roadmap.

## Motivation

Blob-Parameter-Only (BPO) upgrades enable Ethereum to scale data availability through incremental parameter adjustments rather than large multi-feature network upgrades. While this approach improves safety and iteration speed, there is currently no canonical reference documenting what changed in each BPO upgrade, when it was activated, and which parameter values were applied.

[EIP-7892](https://eips.ethereum.org/EIPS/eip-7892) defines the mechanism and constraints for BPO upgrades but does not track individual BPO instances. In practice, activation timing and parameter values for BPO upgrades are distributed across client repositories, coordination notes, and operational artifacts.

Following the publication of the Meta EIP documenting **BPO1**, this EIP extends the registry approach to **BPO2**, preserving continuity and enabling longitudinal comparison of blob capacity increases.

This EIP records authoritative data for BPO2 to improve traceability, ecosystem coordination, and historical accuracy.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

This section documents the Blob-Parameter-Only upgrade identified as **BPO2**.

The upgrade modifies blob-related protocol parameters as defined in [EIP-7892](https://eips.ethereum.org/EIPS/eip-7892). No other protocol behavior is affected. All timestamps are expressed as Unix epoch seconds (UTC).

### BPO-2 Parameters

| Field                    | Value       |
|--------------------------|-------------|
| BPO Identifier           | BPO2        |
| Activation Time (UTC)    | 1767747671  |
| Blob Target              | 14          |
| Blob Max                 | 21          |
| Base Fee Update Fraction | 11,684,671  |

BPO2 represents the second incremental blob capacity increase following BPO1 and continues staged scaling toward higher data availability limits.

### Historical Context

For reference, prior blob schedules were established in earlier network upgrades and BPO1:

| Upgrade | Blob Target | Blob Max | Base Fee Update Fraction |
|---------|-------------|----------|---------------------------|
| **Cancun** | 3  | 6  | 3,338,477 |
| **Prague** | 6  | 9  | 5,007,716 |
| **BPO1**   | 10 | 15 | 8,346,193 |

BPO2 builds directly on the BPO1 parameter baseline.

### Data Source

The parameter values and activation times in this EIP are derived from eth client genesis configuration, including:

```json
"bpo2Time": 1767747671,
"blobSchedule": {
  "bpo2": {
    "target": 14,
    "max": 21,
    "baseFeeUpdateFraction": 11684671
  }
}
```

Client implementations may expose these values in different formats; this EIP reflects the canonical mainnet configuration values.

## Rationale

Documenting BPO2 improves transparency, discoverability, and coordination as Ethereum incrementally scales data availability. This reference enables ecosystem participants to reliably track parameter changes, compare historical behavior, and align tooling, research, and operational assumptions without relying on fragmented or informal sources.

## Backwards Compatibility
<!--
TODO: Remove this comment before submitting
-->

## Test Cases
<!--
TODO: Remove this comment before submitting
-->

## Reference Implementation
<!--
TODO: Remove this comment before submitting
-->

## Security Considerations


## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
