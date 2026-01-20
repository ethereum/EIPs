---
eip: 4
title: EIP Classification
description: Classification scheme for EIPs by system layer
author: Joseph Chow (@ethers)
discussions-to: https://ethereum-magicians.org/t/decentralizing-eip-workflow/1525
status: Final
type: Meta
created: 2015-11-17
---

## Abstract

This document describes a classification scheme for EIPs, adapted from BIP 123.

EIPs are classified by system layers with lower numbered layers involving more intricate interoperability requirements.

The specification defines the layers and sets forth specific criteria for deciding to which layer a particular standards EIP belongs.

## Motivation

Ethereum is a system involving a number of different standards. Some standards are absolute requirements for interoperability while others can be considered optional, giving implementers a choice of whether to support them.

In order to have an EIP process which more closely reflects the interoperability requirements, it is necessary to categorize EIPs accordingly. Lower layers present considerably greater challenges in getting standards accepted and deployed.

## Specification

Standards EIPs are placed in one of four layers:

1. Consensus
2. Networking
3. API/RPC
4. Applications

### Consensus Layer

The consensus layer defines cryptographic commitment structures. Its purpose is ensuring that anyone can locally evaluate whether a particular state and history is valid, providing settlement guarantees, and assuring eventual convergence.

The consensus layer is not concerned with how messages are propagated on a network.

Disagreements over the consensus layer can result in network partitioning, or forks, where different nodes might end up accepting different incompatible histories. We further subdivide consensus layer changes into soft forks and hard forks.

#### Soft Forks

In a soft fork, some structures that were valid under the old rules are no longer valid under the new rules. Structures that were invalid under the old rules continue to be invalid under the new rules.

#### Hard Forks

In a hard fork, structures that were invalid under the old rules become valid under the new rules.

### Networking Layer

The networking layer specifies the Ethereum wire protocol (eth) and the Light Ethereum Subprotocol (les). RLPx is excluded and tracked in the `devp2p` repository.

Only a subset of subprotocols are required for basic node interoperability. Nodes can support further optional extensions.

It is always possible to add new subprotocols without breaking compatibility with existing protocols, then gradually deprecate older protocols. In this manner, the entire network can be upgraded without serious risks of service disruption.


### API/RPC Layer

The API/RPC layer specifies higher level calls accessible to applications. Support for these EIPs is not required for basic network interoperability but might be expected by some client applications.

There's room at this layer to allow for competing standards without breaking basic network interoperability.

### Applications Layer

The applications layer specifies high level structures, abstractions, and conventions that allow different applications to support similar features and share data.

## Rationale

Categorizing proposals by layer highlights the relative interoperability requirements and deployment complexity across different kinds of changes.

## Security Considerations

This document defines a classification scheme and does not itself introduce protocol changes. It has no direct security impact.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
