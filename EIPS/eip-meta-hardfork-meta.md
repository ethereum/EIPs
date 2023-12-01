---
title: Meta Hardfork Meta, from Berlin to Shapella
description: Pointers to specifications used for the network upgrades from Berlin to Shapella.
author: Tim Beiko (@timbeiko)
discussions-to: TBA
status: Draft
type: Meta
created: 2023-12-01
requires: 2070, 2982
---

## Abstract

Between the Berlin and Shapella network upgrades, Meta EIPs were abandoned in favor of other ways of tracking changes made as part of Ethereum network upgrades. This EIP links the canonical specification used for each of these forks, to provide a complete reference. 

## Motivation

For many years, Ethereum used Meta EIPs to document network upgrades. Recently, consensus has formed around using them again. This EIP acts as a backfill, linking out the specifications for upgrades which did not have Meta EIPs. 

## Specification

The network upgrades below are listed in order of activation on the Ethereum network. Upgrades to Ethereum's execution layer are marked [EL], and those to Ethereum's consensus layer are marked [CL]. 

### Beacon Chain Launch - Serenity Phase 0 [CL]

The full specifications for the Beacon Chain at launch can be found in the [v.1.0.0 release of the `ethereum/consensus-specs` repository](https://github.com/ethereum/consensus-specs/blob/579da6d2dc734b269dbf67aa1004b54bb9449784). Additionally, [EIP-2982](./eip-2982.md) provides context on the overall Beacon Chain design and rationale for the parameterization. 

### Berlin [EL]

The Berlin upgrade was originally specified in [EIP-2070](./eip-2079.md), but was then moved to the [`berlin.md`](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/berlin.md) file of the `ethereum/execution-specs` repository. 

### London [EL]

The original London upgrade specifications can be found in the [`london.md`](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/london.md) file of the `ethereum/execution-specs` repository. 

### Altair [CL]

### Arrow Glacier [EL]

The original Arrow Glacier upgrade specifications can be found in the [`arrow-glacier.md`](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/arrow-glacier.md) file of the `ethereum/execution-specs` repository. 

### Gray Glacier [EL]

The original Gray Glacier upgrade specifications can be found in the [`gray-glacier.md`](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/gray-glacier.md) file of the `ethereum/execution-specs` repository. 

### The Merge 

#### Bellatrix [CL]

#### Paris [EL]

The original Paris upgrade specifications can be found in the [`paris.md`](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/paris.md) file of the `ethereum/execution-specs` repository. 


### Shapella 

#### Shanghai [EL]

The original Shanghai upgrade specifications can be found in the [`shanghai.md`](https://github.com/ethereum/execution-specs/blob/8dbde99b132ff8d8fcc9cfb015a9947ccc8b12d6/network-upgrades/mainnet-upgrades/shanghai.md) file of the `ethereum/execution-specs` repository. 

#### Capella [CL]


## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
