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

FOCIL is built in a few simple steps:

- In each slot, a set of validators is selected to become IL committee members. Each member gossips one local inclusion list according to their subjective view of the mempool.
- The proposer and all attesters of the next slot monitor, forward and collect available local inclusion lists.
- The proposer includes transactions from all collected local ILs in its block before broadcasting it to the rest of the network.
- Attesters only vote for the proposer's block if it includes transactions from local inclusion lists they collected.

## Motivation

In an effort to shield the Ethereum validator set from centralizing forces, the right to build blocks has been auctioned off to specialized entities known as builders. Over the past year, this has resulted in a few sophisticated builders dominating the network’s block production. Economies of scale have further entrenched their position, making it increasingly difficult for new entrants to gain significant market share. A direct consequence of centralized block production is a deterioration of the network’s censorship resistance properties. In contrast, 90% of the more decentralized and heterogeneous validator set is not engaging in censorship. This has driven research toward ways that allow validators to impose constraints on block construction by force-including transactions in the blocks. These efforts recently culminated in the first practical implementation of forward ILs, [EIP-7547](./eip-7547.md), being considered for inclusion in the upcoming Pectra fork. However, some concerns were raised about the specific mechanism proposed in EIP-7547, leading to its rejection. 

FOCIL is a simple committee-based design improving upon previous IL mechanisms or block co-creation proposals and addressing issues related to bribing/extortion attacks, IL equivocation, account abstraction (AA), and incentive incompatibilities.

## Specification

### Execution Layer

TBD

### Consensus Layer

#### Timeline

A set of validators is selected from the beacon committee to become IL committee for `slot N`.

- **`Slot N`, `t=0 to 8s`**: After processing the block for `slot N` and confirming it as the head, each IL committee member of `slot N` constructs a local inclusion list based on the head and their view of the public mempool, then broadcasts it over the P2P network.
- **`Slot N`, `t=9s`**: IL committee members freeze their view of a set of local inclusion lists and no longer produce new ones.
- **`Slot N`, `t=9 to 11s`**: IL committee members continue forwarding the local inclusion lists they are aware of but ignore any new ones. The block proposer and attesters of `slot N+1` continue listening to gossiped local inclusion lists. To ensure none are omitted, the block proposer can request for any missing local inclusion lists from a specific IL committee member via an RPC endpoint, for example, at `t=10s`.
- **`Slot N`, `t=11s`**: The block proposer freezes its local inclusion lists view and IL committee members stop gossiping.
- **`Slot N+1`, `t=0s`**: The block proposer broadcasts `block B` for `slot N+1` with an execution payload that satisfies the IL constraints.
- **`Slot N+1`, `t=4s`**: The attesters accept `block B` only if it includes all transactions from the local inclusion lists, or if any missing transactions cannot be appended to the end of the execution payload, or if the block is full.

## Rationale

### Core properties:
- Committee-based: FOCIL relies on a committee of multiple validators, rather than a single proposer, to construct and broadcast local inclusion lists. This approach significantly reduces the surface for bribery and extortion attacks and strengthens censorship resistance as the cost of censorship increases with the size of IL committee.
- Fork-choice enforced: FOCIL incorporates the force-inclusion mechanism into the fork-choice rule, an integral component of the consensus process, thereby preventing any actor from bypassing the system. Attesters vote only for blocks that include transactions from a set of local inclusion lists provided by the IL committee and that satisfy the IL constraints. Any block failing to meet these criteria is deemed invalid.
- Same-slot: With FOCIL running in parallel with the block building process for `slot N+1` during `slot N`, the constraints imposed on `block B` for `slot N+1` can include transactions submitted during `slot N`. This represents a strict improvement over forward IL designs like EIP-7547, where the forward property introduced a 1-slot delay. Same-slot censorship resistance could prove particularly beneficial for time-sensitive transactions that might be censored for MEV reasons.
- Conditional inclusion: FOCIL adopts conditional inclusion, accepting blocks that may lack some transactions from the local inclusion lists if they cannot append the transactions to the end of the block or if they are full.
- Anywhere-in-block: FOCIL is unopinionated about the placement of transactions from the local inclusion lists within a block. This reduces incentives for sophisticated actors to use side channels to bypass the mechanism. Combined with conditional inclusion, this flexibility makes the emergence of off-protocol markets even less attractive.
- No incentive mechanism: While FOCIL relies on altruistic validators, the participation of even a few validators can strengthen the protocol's censorship resistance to a great extent.

## Backwards Compatibility

This EIP introduces backward incompatible changes to the block validation rule set on the consensus layer and must be accompanied by a hard fork. These changes do not break anything related to current user activity and experience.

## Security Considerations

### Consensus Liveness

The block builder or proposer of `slot N+1` cannot construct a canonical block without seeing local inclusion lists broadcast during `slot N`. This implies the block producer (e.g., a proposer or a proposer builder pair) needs to be sufficiently peered with the IL committee members. 

### Block Construction Time

It is important to ensure there is enough time between the local inclusion list freeze deadline (`t=9s` of `slot N`) and the moment at which the block producer has to broadcast `block B`, so that there is enough time to update `block B`'s execution payload according to the observed IL constraints.

### IL Equivocation

Since the local inclusion lists from the IL committee are all different and FOCIL does not introduce any single actor with sole responsibility, it seems infeasible to aggregate local inclusion lists while satisfying the aforementioned core properties. A malicious IL committee member may equivocate their local inclusion list.

To mitigate local inclusion list equivocation, FOCIL introduces a new P2P network rule that allows forwarding up to two local inclusion lists per IL committee member. If the block proposer or attesters detect two different local inclusion lists sent by the same IL committee member, they should ignore all local inclusion lists from that member. In the worst case, the bandwidth of the local inclusion list gossip subnet can at most double.

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
