---
eip: 8368
title: CPSB Recalibration for New Gas Limit
description: Re-derives the cost per state byte (CPSB) parameter introduced in EIP-8037 for a new reference block gas limit
author: Maria Silva (@misilva73), Toni Wahrstätter (@nerolation)
discussions-to: https://ethereum-magicians.org/t/eip-8368-cpsb-recalibration-for-new-gas-limit/29293
status: Draft
type: Standards Track
category: Core
created: 2026-08-05
requires: 8037
---

## Abstract

This proposal updates cost per state byte (`CPSB`), the unit gas cost per new state byte introduced in [EIP-8037](./eip-8037.md), by re-deriving it for a new reference block gas limit. All other parameters, mechanisms, and semantics defined in [EIP-8037](./eip-8037.md) are unaffected and remain unchanged.

This is a placeholder EIP. The new reference block gas limit, the re-derived `CPSB` value, and the accompanying rationale are still to be determined.

## Motivation

[EIP-8037](./eip-8037.md) derives `CPSB` from a reference block gas limit of `150M` gas units, noting that "if a future block gas limit increase materially changes the expected state growth rate, `CPSB` can be re-derived in a subsequent EIP." As the block gas limit increases beyond that reference point, `CPSB` needs to be recalibrated to keep state growth on target.

## Specification

TBD. The `CPSB` value below will be re-derived using the same methodology as [EIP-8037](./eip-8037.md), with the reference block gas limit updated to a value still to be determined.

| **Parameter** | **Value** |
|:---:|:---:|
| `CPSB` | TBD |

## Rationale

TBD

## Backwards Compatibility

This EIP updates a parameter defined by [EIP-8037](./eip-8037.md) and inherits its backwards compatibility considerations.

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
