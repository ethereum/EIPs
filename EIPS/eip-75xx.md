---
eip: 75xx
title: Reserve Precompile Address range for RIPs/L2s
author: Carl Beekhuizen (@carlbeek), Ansgar Dietrichs (@adietrichs), Danny Ryan (@djrtwo), Tim Beiko (@timbeiko)
discussions-to: https://ethereum-magicians.org/t/eip-75xx-reserve-precompile-address-range-for-rips-l2s/17828
status: Draft
type: Informational
created: 2023-12-21
---

## Abstract

This EIP reserves precompile ranges to ensure there are no conflicts with those used by the RIP process.

## Motivation

As L2s begin to deploy RIPs, it is necessary to reserve an address range for use by the RIP process so as to ensure there are no conflicts between precompile addresses used by RIPs and EIPs.

## Specification

The address range between `0x00000000000000000000000000000000000000ff` and `0x00000000000000000000000000000000000001ff` is reserved for use by the RIP process.

## Rationale

By reserving an address range for RIPs, it allows the RIP process to maintain it's own registry of precompiles that are not (necessarily) deployed on L1 mainnet, the EIP process is freed from having to maintain a registry of RIP precompiles while still having 255 addresses for it's own use.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

Nil.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
