---
title: Committee-based, Fork-choice enforced Inclusion Lists (FOCIL)
description: Allow a committee of validators to force-include a set of transactions in every block
author: Thomas Thiery <thomas.thiery@ethereum.org>, Francesco D'Amato <francesco.damato@ethereum.org>, Julian Ma <julian.ma@ethereum.org>, Barnabé Monnot <barnabe.monnot@ethereum.org>, Terence Tsao <ttsao@offchainlabs.com>, Jacob Kaufmann <jacob.kaufmann@ethereum.org>, Jihoon Song <jihoonsong.dev@gmail.com>

discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2024-10-??
---

## Abstract

Implement a robust mechanism to preserve Ethereum’s censorship resistance and chain neutrality properties by guaranteeing timely transaction inclusion.

FOCIL is built in a few simple steps:

- In each slot, a set of validators is selected to become IL committee members. Each member gossips one local inclusion list (IL) according to their subjective view of the mempool.
- The proposer and all attesters of the next slot monitor, forward and collect available local ILs.
- The proposer includes transactions from all collected local ILs in its block before broadcasting it to the rest of the network.
- Attesters only vote for the proposer's block if it includes transactions from local ILs they collected.

## Motivation

In an effort to shield the Ethereum validator set from centralizing forces, the right to build blocks has been auctioned off to specialized entities known as builders. Over the past year, this has resulted in a few sophisticated builders dominating the network’s block production. Economies of scale have further entrenched their position, making it increasingly difficult for new entrants to gain significant market share. A direct consequence of centralized block production is a deterioration of the network’s censorship resistance properties. In contrast, 90% of the more decentralized and heterogeneous validator set is not engaging in censorship. This has driven research toward ways that allow validators to impose constraints on block construction by force-including transactions in the blocks. These efforts recently culminated in the first practical implementation of forward ILs, [EIP-7547](./eip-7547.md), being considered for inclusion in the upcoming Pectra fork. However, some concerns were raised about the specific mechanism proposed in EIP-7547, leading to its rejection. 

FOCIL is a simple committee-based design improving upon previous IL mechanisms or block co-creation proposals and addressing issues related to bribing/extortion attacks, IL equivocation, account abstraction (AA) and transaction invalididation.

## High-level Overview

### Roles And Participants

This section outlines the workflow of FOCIL, detailing the roles and responsibilities of various participants, including IL committee members, nodes, proposers, and attesters.

##### IL Committee Members

- **`Slot N`, `t=0 to 8s`**:
IL committee members construct their local ILs and broadcast them over the P2P network after processing the block for `slot N` and confirming it as the head. If no block is received by `t=7s`, they should run `get_head` and build and release their local ILs based on their node’s canonical head.

  By default, local ILs are built by selecting raw transactions from the public mempool, ordered by priority fees, up to the local IL’s maximum size in bits (e.g., 8 KB per local IL). Additional local rules can be optionally applied to maximize censorship resistance, such as prioritizing valid transactions that have been pending in the mempool the longest.

##### Nodes

- **`Slot N`, `t=0 to 9s`**:
Nodes receive local ILs from the P2P network and only forward and cache those that pass the CL P2P validation rules.

- **`Slot N`, `t=9s`**:, The local IL freeze deadline:
Nodes freeze their local ILs view, stop forwarding and caching new local ILs.

##### Proposer
- **`Slot N`, `t=0 to 11s`**: The proposer receives local ILs from the P2P network, forwarding and caching those that pass the CL P2P validation rules. Optionally, an RPC endpoint can be added to allow the proposer to request the missing local ILs from its peers (e.g., by committee index at `t=10s`).

- **`Slot N`, `t=11s`**:
The proposer freezes its view of local ILs and asks the EL to update its execution payload by adding transactions from its view (the exact timings will be defined after running some tests/benchmarks).

- **`Slot N+1`, `t=0s`**:
The proposer broadcasts its block with the up-to-date execution payload satisfying IL transactions over the P2P network.

##### Attesters
- **`Slot N+1`, `t=0 to 4s`**:
Attesters monitor the P2P network for the proposer’s block. Upon detecting it, they verify whether all transactions from their cached local ILs are included in the proposer’s execution payload. The `Valid` function, based on the frozen view of the local ILs from `t=9s` in the previous slot, checks if the execution payload satisfies IL validity conditions. This is done either by confirming that all transactions are present or by determining if any missing transactions are invalid when appended to the end of the payload. In such cases, attesters use the EL to perform nonce and balance checks to validate the missing transactions and check whether there is enough space in the block to include the transaction(s).

#### CL P2P Validation Rules

1. The number of transactions in the local IL does not exceed the maximum gas limit allowed.
2. The slot of the local IL matches the current slot. Local ILs not matching the current slot should be ignored.
3. The parent hash of the IL is recognized.
4. The local IL is received before the local IL freeze deadline (e.g., `t=9s`) into the slot.
5. Received two or fewer local ILs from this IL committee member (see IL equivocation section below).
6. The local IL is correctly signed by the validator.
7. The validator is part of the IL committee.
8. The size of a local IL does not exceed the maximum size allowed (e.g., 8 KB).

## Specification

### Execution Layer

On the execution layer, the block validity conditions are extended such that, after all of the transactions in the block have been executed, we attempt to execute each valid transaction from local ILs that was not present in the block.
If one of those transactions executes successfully, then the block is invalid.

Let `B` denote the current block.
Let `S` denote the execution state following the execution of the last transaction in `B`.

For each transaction `T` in local ILs, perform the following:

1. Check whether `T` is present in `B`. If `T` is present, then continue to the next transaction.
1. Validate `T`. If `T` is invalid, then continue to the next transaction.
1. Execute `T` on state `S`. Assert that the execution of `T` fails.

Note that we do not need to reset the state to `S`, since the only way for a transaction to alter the state is for it to execute sucessfully, in which case the block is invalid, and so the block will not be applied to the state.

We make the following changes to the engine API:

- Add `engine_getLocalInclusionList` endpoint to retrieve a local IL from the `ExecutionEngine`
- Modify `engine_newPayload` endpoint to include a parameter for transactions in local ILs determined by the proposer
- Modify `engine_forkchoiceUpdated` endpoint to include a field in the payload attributes for transactions in local ILs determined by the proposer

### Consensus Layer

The full consensus changes can be found in the following Github repository. They are split between: 

- [Beacon Chain](https://github.com/terencechain/consensus-specs/blob/6056b69ea1215c3dff6042da2b0a8563347be645/specs/_features/focil/beacon-chain.md) changes.
- [Fork choice](https://github.com/terencechain/consensus-specs/blob/6056b69ea1215c3dff6042da2b0a8563347be645/specs/_features/focil/fork-choice.md) changes.
- [P2P](https://github.com/terencechain/consensus-specs/blob/6056b69ea1215c3dff6042da2b0a8563347be645/specs/_features/focil/p2p-interface.md) changes.
- [Honest validator guide](https://github.com/terencechain/consensus-specs/blob/6056b69ea1215c3dff6042da2b0a8563347be645/specs/_features/focil/validator.md) changes.
- [Engine API](https://github.com/terencechain/consensus-specs/blob/6056b69ea1215c3dff6042da2b0a8563347be645/specs/_features/focil/engine-api.md) changes.

#### Beacon chain changes

##### Preset

| Name | Value |
| - | - |
| `DOMAIN_IL_COMMITTEE`       | `DomainType('0x0C000000')`  |
| `IL_COMMITTEE_SIZE` | `uint64(2**4)` (=16)  |
| `MAX_BYTES_PER_INCLUSION_LIST` |  `uint64(2**13)` (=8192) | 

##### New containers

```python
class LocalInclusionList(Container):
    slot: Slot
    validator_index: ValidatorIndex
    parent_root: Root
    parent_hash: Hash32
    transactions: List[Transaction, MAX_TRANSACTIONS_PER_INCLUSION_LIST]
```

```python
class SignedLocalInclusionList(Container):
    message: LocalInclusionList
    signature: BLSSignature
```

#### Fork choice changes

- Cache local ILs observed over gossip before the local IL freeze deadline.
- If more than one local IL is observed from the same IL committee member, remove all local ILs from the member from the cache.
- Fork choice head retrieval is based on the `Valid` function being satisfied by the EL.
  
#### P2P changes

- A new global topic for broadcasting `SignedInclusionList` objects.
- A new RPC topic for request `SignedInclusionList` based on IL committee index.

## Rationale

### Core Properties
- Committee-based: FOCIL relies on a committee of multiple validators, rather than a single proposer, to construct and broadcast local ILs. This approach significantly reduces the surface for bribery and extortion attacks and strengthens censorship resistance.
- Fork-choice enforced: FOCIL incorporates the force-inclusion mechanism into the fork-choice rule, an integral component of the consensus process, thereby preventing any actor from bypassing the system. Attesters vote only for blocks that include transactions from a set of local ILs provided by the IL committee and that satisfy the IL constraints. Any block failing to meet these criteria is deemed invalid.
- Same-slot: With FOCIL running in parallel with the block building process for `slot N+1` during `slot N`, the constraints imposed on `block B` for `slot N+1` can include transactions submitted during `slot N`. This represents a strict improvement over forward IL designs like EIP-7547, where the forward property introduced a 1-slot delay.
- Conditional inclusion: FOCIL adopts conditional inclusion, accepting blocks that may lack some transactions from local ILs if they cannot append the transactions to the end of the block or if they are full.
- Anywhere-in-block: FOCIL is unopinionated about the placement of transactions from local ILs within a block. This reduces incentives for sophisticated actors to use side channels to bypass the mechanism. Combined with conditional inclusion, this flexibility makes the emergence of off-protocol markets even less attractive.
- No incentive mechanism: FOCIL does not provide explicit rewards for IL committee members participating in the mechanism. We believe that the added complexity of implementing a transaction fee system for FOCIL is not justified. Instead, we rely on altruistic behavior, as FOCIL requires only `1/n` IL committee members to act honestly for the mechanism to function as intended.

## Backwards Compatibility

This EIP introduces backward incompatible changes to the block validation rule set on the consensus layer and must be accompanied by a hard fork. These changes do not break anything related to current user activity and experience.

## Security Considerations

### Consensus Liveness

The block producer (i.e., a proposer or a proposer builder pair) of `slot N+1` cannot construct a canonical block without first receiving the local ILs broadcast during `slot N`. This means that the block producer must be well-connected to the IL committee members to ensure timely access to these inclusion lists. Additionally, there must be sufficient time between the local IL freeze deadline (`t=9s` of `slot N`) and the moment the block producer must broadcast `block B` to the rest of the network. This buffer allows the block producer to gather all available local ILs and update the execution payload of `block B` accordingly.

### IL Equivocation

To mitigate local IL equivocation, FOCIL introduces a new P2P network rule that allows forwarding up to two local ILs per IL committee member. If the proposer or attesters detect two different local ILs sent by the same IL committee member, they should ignore all local ILs from that member. In the worst case, the bandwidth of the local IL gossip subnet can at most double.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
