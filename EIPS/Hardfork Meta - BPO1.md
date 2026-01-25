---
eip: TBA
title: BPO1 Upgrade 
description: Blob parameter changes with BPO1 on Ethereum mainnet.
author: Pooja Ranjan (@poojaranjan)
discussions-to: https://ethereum-magicians.org/t/hardfork-meta-bpo1/27582
status: Draft
type: Meta
created: 2026-01-24
requires: 7892
---

## Abstract

This Meta EIP documents the activation details, parameter changes, and specification references for the first Blob-Parameter-Only (BPO) network upgrades, BPO1. It provides a canonical registry of blob target, blob maximum limits, and associated configuration values to improve transparency, traceability, and ecosystem coordination for early-stage data availability scaling under Ethereum’s Surge roadmap.

## Motivation 

Blob-Parameter-Only (BPO) upgrades enable Ethereum to scale data availability through incremental parameter adjustments rather than large multi-feature network upgrades. While this approach improves safety and iteration speed, there is currently no canonical reference documenting what changed in each BPO upgrade, when it was activated, and which parameter values were applied.

[EIP-7892](https://eips.ethereum.org/EIPS/eip-7892) specifies the mechanism and constraints for BPO upgrades but does not track individual BPO instances. In practice, activation timing and parameter values for BPO1 are distributed across client repositories, coordination notes, and operational artifacts, making consistent interpretation and historical analysis difficult for ecosystem participants.

This EIP addresses this gap by recording authoritative data for BPO1 in a canonical reference to improve transparency, traceability, and ecosystem coordination.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

This section documents the Blob-Parameter-Only upgrade identified as **BPO1**.

The upgrade modifies blob-related protocol parameters as defined in [EIP-7892](https://eips.ethereum.org/EIPS/eip-7892). No other protocol behavior is affected. All timestamps are expressed as Unix epoch seconds (UTC).

### BPO-1 Parameters

| Field                    | Value      |
|--------------------------|------------|
| BPO Identifier           | BPO1       |
| Activation Time (UTC)    | 1765290071  |
| Blob Target              | 10          |
| Blob Max                 | 15          |
| Base Fee Update Fraction | 8,346,193   |

BPO-1 represents the first mainnet deployment of a Blob-Parameter-Only upgrade and establishes the initial incremental increase in blob capacity following the Fusaka upgrade.

### Historical Context

For reference, the blob schedule before BPO upgrades was established in earlier network upgrades:

| Upgrade | Blob Target | Blob Max | Base Fee Update Fraction |
|---------|-------------|----------|---------------------------|
| **Cancun** | 3 | 6 | 3,338,477 |
| **Prague** | 6 | 9 | 5,007,716 |

### Data Source

The parameter values and activation times in this EIP are derived from eth_client genesis configuration, including:

```json
"bpo1Time": 1765290071,
"blobSchedule": {
  "cancun": {
    "target": 3,
    "max": 6,
    "baseFeeUpdateFraction": 3338477
  },
  "prague": {
    "target": 6,
    "max": 9,
    "baseFeeUpdateFraction": 5007716
  },
  "bpo1": {
    "target": 10,
    "max": 15,
    "baseFeeUpdateFraction": 8346193
  },
}
```

Client implementations may expose these values in different formats; this EIP reflects the canonical mainnet configuration values.

## Rationale

Documenting BPO1 improves transparency, discoverability, and coordination as Ethereum incrementally scales data availability. This reference enables ecosystem participants to reliably track parameter changes, compare historical behavior, and align tooling, research, and operational assumptions without relying on fragmented or informal sources.

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

