---
title: Committee-based, Fork-choice enforced Inclusion Lists (FOCIL)
description: Allow a committee of validators to force-include a set of transactions in every block
author: Thomas Thiery (@soispoke), Barnabé Monnot (@barnabemonnot), Francesco D'Amato (@fradamt), Julian Ma (@_julianma)

discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2024-07-??
---

## Abstract
Implement a robust mechanism to preserve Ethereum’s censorship resistance and chain neutrality properties by guaranteeing timely transaction inclusion. 

FOCIL is built in three simple steps:
	- In each slot, a set of validators is selected to become IL committee members. Each member gossips one local inclusion list according to their subjective view of the mempool.
	- The block proposer collects and aggregates available local inclusion lists into a concise aggregate, which is included in its block.
	- The attesters evaluate the quality of the aggregate given their own view of the gossiped local lists to ensure the block proposer accurately reports the available local lists.

## Motivation

In an effort to shield the Ethereum validator set from centralizing forces, the right to build blocks has been auctioned off to specialized entities known as builders. Over the past year, this has resulted in a few sophisticated builders dominating the network’s block production. Economies of scale have further entrenched their position, making it increasingly difficult for new entrants to gain significant market share. A direct consequence of centralized block production is a deterioration of the network’s censorship resistance properties. In contrast, 90% of the more decentralized and heterogeneous validator set is not engaging in censorship. This has driven research toward ways that allow validators to impose constraints on block construction by force-including transactions in the blocks. These efforts recently culminated in the first practical implementation of forward ILs, [EIP-7547](./eip-7547.md), being considered for inclusion in the upcoming Pectra fork. However, some concerns were raised about the specific mechanism proposed in EIP-7547, leading to its rejection. 

FOCIL is a simple committee-based design improving upon previous IL mechanisms or block co-creation proposals and addressing issues related to bribing/extortion attacks, IL equivocation, account abstraction (AA), and incentive incompatibilities.

## Specification

### Consensus layer

#### High-level overview

#### Timeline

A set of validators is selected from the beacon committee to become IL committee members for `slot N`.

- **`Slot N`, `t=6`**: The IL committee of `slot N+1` releases local ILs, knowing the contents of `block N`. Local ILs are sets of transactions pending in the public mempool represented as (`from_address`, `gas_limit`) pairs.
- **`Slot N`, `t=9`**: Local IL freeze deadline, after which all attesters of `slot N+1` lock their view of the observed local ILs. The `slot N+1` proposer broadcasts a signed IL aggregate constructed by deduplicating and taking the union of transactions from collected local ILs. Every IL aggregate (`from_address`, `gas_limit`) is associated with a `bitlist` field indicating which IL committee member included a given transaction.
- **`Slot N+1`, `t=0`**: The block producer of `slot N+1` releases its `block B`, which contains both the payload and the IL aggregate.
- **`Slot N+1`, `t=4`**: The attesters of `slot N+1` vote on `block B`. `Block B` is considered valid if:
  - The IL aggregate included in `block B` corresponds to the attesters' local view of available local ILs and is the same IL aggregate broadcast during `slot N`
  - The IL aggregate entries are satisfied by payload transactions

## Rationale

#### Core properties:
- Committee-based: FOCIL relies on a committee of multiple validators, rather than a single proposer, to construct and broadcast 
inclusion lists. This approach imposes stricter constraints on creating the aggregate list and significantly reduces the surface for bribing and extortion attacks. For instance, instead of bribing a single party to exclude a particular transaction from the IL, attackers would instead need to bribe the entire IL committee, substantially increasing the cost of such attacks.
- Fork-choice enforced: By including the IL aggregate in `block B`, satisfying its entries by including the corresponding transactions in the payload becomes a new block validity condition enforced by all attesters. This allows reliance on a large set of participants to check the IL and block validity and addresses concerns around IL equivocation in EIP-7547. In FOCIL, an IL equivocation would result in a block equivocation, which is a known, slashable offense from the protocol's perspective.
- Same-slot: By having FOCIL run in parallel with block building during `slot N−1`, we can impose constraints on `block B` by including transactions submitted during the same slot in local ILs. This property implies that a transaction in the IL aggregate can’t be invalidated because of a transaction in the previous block, which represents a strict improvement over forward IL designs like EIP-7547. Same-slot censorship resistance might also prove particularly useful for time-sensitive transactions that might be censored for MEV reasons.
- Conditional and anywhere-in-block: Transactions satisfying entries in the IL aggregate share blockspace with the payload can only be included if the block isn’t full (i.e., has reached the gas limit) and can be ordered arbitrarily by the block producer. These choices were made to reduce the risk of sophisticated block producers using side channels to circumvent an overly rigid mechanism, imposing a specific order, or strictly limiting the size of the IL.

#### Main FOCIL Functions:
- `Agg`: This function takes a set of local ILs as input and produces an IL aggregate as output. The IL aggregate is a set of entries (`from_address`, `gas_limit`, `bitlist`). The _i_th value in the `bitlist` indicates whether the corresponding entry  (`from_address`, `gas_limit`) was included in the local IL of the _i_th committee member. This function also removes any local ILs invalidated by others and outputs the union of the remaining entries, each with its respective bitlist. 
- `Eval`: `Slot N` attesters assess the quality of the IL aggregate included in `block B` by using the `Eval` function. This function takes as input the set of local ILs observed before the freeze deadline by the attester and a list of local ILs used by the block producer to produce the IL aggregate. It outputs whether the IL aggregate was constructed correctly. First, it checks whether the aggregate IL was constructed using almost all of the local ILs according to the attester's view, allowing for the exclusion of at most a fixed amount, denoted by Δ. Then, it checks whether the  IL aggregate was constructed using the list of local ILs used by the block producer and the `Agg` function.
- `Valid`: This function  takes the execution payload and the corresponding IL aggregate as inputs, and encodes whether the IL aggregate conforms to core IL properties defined in the above section (e.g., conditional, anywhere-in-block, etc..). 

## Backwards Compatibility

This EIP introduces backward incompatible changes to the block validation rule set on the consensus layer and must be accompanied by a hard fork. These changes do not break anything related to current user activity and experience.

## Security Considerations

### Consensus Liveness

The builder or proposer of slot `n+1` cannot construct a canonical block without seeing local ILs and the IL aggregate broadcast during slot `n`. This implies the block producer (e.g., a proposer or a proposer builder pair needs to be sufficiently peered with the IL committee members. The parameter Δ also needs to be set to prevent liveness issues from accidental disparities between the proposer view and attesters' views.

### Block Construction Time

It is important to ensure there is enough time between the local IL freeze deadline (`t=9` during slot `n`) and the moment at which the block producer has to broadcast `block B` including the IL aggregate, so that:
- There is enough time to update `block B`'s execution payload according to the IL aggregate constraints.
- The proposer has enough time to collect and include all local ILs before broadcasting the IL aggregate.

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
