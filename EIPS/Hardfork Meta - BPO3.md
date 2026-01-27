---
eip: TBA
title: Hardfork Meta - BPO3
description: Blob parameter changes with BPO3 on Ethereum mainnet.
author: Pooja Ranjan (@poojaranjan) 
discussions-to: https://ethereum-magicians.org/t/hardfork-meta-bpo1/27582
status: Draft
type: Meta
created: 2026-01-24
requires: 7892, BPO1, BPO2
---

## Abstract

This Meta EIP documents the activation details, parameter changes, and specification references for the third Blob-Parameter-Only (BPO) network upgrade, **BPO3**. It provides a canonical reference of blob target, blob maximum limits, and associated configuration values, enabling transparent tracking of incremental data availability scaling following [BPO2]().

## Motivation

Following the publication of Meta EIPs documenting BPO1 and BPO2, this EIP extends the reference approach to BPO3, preserving continuity and enabling longitudinal comparison of blob capacity increases.

This EIP records authoritative data for BPO3 to improve traceability, ecosystem coordination, and historical accuracy.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “NOT RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119 and RFC 8174.

This section documents the Blob-Parameter-Only upgrade identified as **BPO3**.

The upgrade modifies blob-related protocol parameters as defined in EIP-7892. No other protocol behavior is affected. All timestamps are expressed as Unix epoch seconds (UTC).

### BPO-3 Parameters

| Field | Value |
|--------|--------|
| BPO Identifier | BPO3 |
| Activation Time (UTC) | TBA |
| Blob Target | TBA |
| Blob Max | TBA |
| Base Fee Update Fraction | TBA |

BPO3 represents the third incremental blob capacity adjustment following BPO2 and continues staged scaling toward higher data availability limits.

## Historical Context

For reference, prior blob schedules were established in earlier network upgrades and BPO upgrades:

| Upgrade | Blob Target | Blob Max | Base Fee Update Fraction |
|------------|--------------|-----------|----------------------------|
| Cancun | 3 | 6 | 3,338,477 |
| Prague | 6 | 9 | 5,007,716 |
| BPO1 | 10 | 15 | 8,346,193 |
| BPO2 | 14 | 21 | 11,684,671 |
| BPO3 | TBA | TBA | TBA |

BPO3 builds directly on the BPO2 parameter baseline.

## Data Source

The parameter values and activation time for BPO3 will be derived from Ethereum client configuration once finalized.

Example (placeholder only):

```json
"bpo3Time": TBA,
"blobSchedule": {
  "bpo3": {
    "target": TBA,
    "max": TBA,
    "baseFeeUpdateFraction": TBA
  }
}
```

Client implementations may expose these values in different formats; this EIP will reflect the canonical mainnet configuration once confirmed.

## Rationale

Documenting BPO3 improves transparency, discoverability, and coordination as Ethereum incrementally scales data availability. This registry enables ecosystem participants to reliably track parameter changes, compare historical behavior, and align tooling, research, and operational assumptions without relying on fragmented or informal sources.

## Backwards Compatibility

No backward compatibility issues are introduced. BPO3 modifies only parameter values within the bounds defined by EIP-7892.

## Test Cases

<!--
  TODO
-->

## Reference Implementation

<!--
  TODO
-->

## Security Considerations

BPO upgrades adjust blob throughput parameters and may impact network load characteristics. Careful monitoring, staged rollout, and ecosystem coordination are required to ensure stability.

## Copyright

Copyright and related rights waived via CC0.
