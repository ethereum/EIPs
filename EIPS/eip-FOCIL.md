---
title: <Committee-based, Fork-choice enforced Inclusion Lists (FOCIL)>
description: <Allow a committee of validators to force-include a set of transactions in every block>
author: Thomas (@soispoke), Barnabé (@barnabemonnot), Francesco (@fradamt), Julian (@_julianma)

discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2024-07-03
---

## Abstract
Implement a robust mechanism to preserve Ethereum’s censorship resistance and chain neutrality properties by guaranteeing timely transaction inclusion. 

FOCIL is built in three simple steps:
	- Each slot, a set of validators is selected to become IL committee members. Each member gossips one local inclusion list according to their subjective view of the mempool.
	- The block proposer collects and aggregates available local inclusion lists into a concise aggregate, which is included in its block.
	- The attesters evaluate the quality of the aggregate given their own view of the gossiped local lists to ensure the block proposer accurately reports the available local lists.

## Motivation

In an effort to shield the Ethereum validator set from centralizing forces, the right to build blocks has been auctioned off to specialized entities known as builders. Over the past year, this has resulted in a few sophisticated builders dominating the network’s block production. Economies of scale have further entrenched their position, making it increasingly difficult for new entrants to gain significant market share. A direct consequence of centralized block production is a deterioration of the network’s censorship resistance properties. Today, two of the top three builders are actively filtering out transactions interacting with sanctioned addresses from their blocks. In contrast, 90% of the more decentralized and heterogeneous validator set is not engaging in censorship. This has driven research toward ways that allow validators to impose constraints on builders by force-including transactions in their blocks. These efforts recently culminated in the first practical implementation of forward ILs, [EIP-7547](./eip-7547.md), being considered for inclusion in the upcoming Pectra fork. However, some concerns were raised about the specific mechanism proposed in EIP-7547, leading to its rejection. 

FOCIL is a simple committee-based design improving upon previous IL mechanisms or co-created blocks proposals, and addressing issues related to bribing/extortion attacks, IL equivocation, account abstraction (AA) and incentive incompatibilities.

## Specification

### Consensus layer

#### High-level overview

#### Timeline

A set of validators is selected from the beacon committee to become IL committee members for `slot N`.

- **`Slot N`, `t=6`**: The IL committee releases local ILs, knowing the contents of `block N`. Local ILs are sets of transactions pending in the public mempool represented as (`from_address`, `gas_limit`) pairs.
- **`Slot N`, `t=9`**: Local IL freeze deadline, after which everyone locks their view of the observed local ILs. The `slot N` proposer broadcasts a signed IL aggregate, constructed by deduplicated and taking the union of transactions from collected local ILs. Every IL aggregate (`from_address`, `gas_limit`) is associated with a `bitlist` field indicating which IL committee member included a given transaction.
- **`Slot N+1`, `t=0`**: The block producer of `slot N+1` releases its `block B` which contains both the payload and the IL aggregate.
- **`Slot N+1`, `t=4`**: The attesters of `slot N+1` vote on `block B`. `Block B` is considered valid if:
  - The IL aggregate corresponds to the attesters' local view of available local ILs
  - The IL aggregate entries are satifisfied by payload transactions

## Rationale

#### Main Functions:
- Aggregation
- Evaluation
- Validation

#### Core properties:
- Committee-based
- Fork-choice enforced (mention IL equivocation)
- Conditional
- Anywhere-in-block
- Same-slot 
- Account Abstraction compatibility

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.
    eaea
  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Backwards Compatibility

This EIP introduces backward incompatible changes to the block validation rule set on the consensus layer, as well as execution  and must be accompanied by a hard fork. These changes do not break anything related to current user activity and experience.

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
