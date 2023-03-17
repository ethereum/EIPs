---
title: Ethereum state using a unified verkle tree
description: <Description is one full (short) sentence>
author: Vitalik Buterin (@vbuterin), Dankrad Feist (@dankrad), Kevaundray Wedderburn (@kevaundray), Guillaume Ballet (@gballet), Piper Merriam () and Gottfried Herold ()
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2023-03-17
requires: SELFDESTRUCT removal, no eip yet
---

## Abstract

Introduce a new Verkle state tree alongside the existing hexary Patricia tree. After the hard fork, the Verkle tree stores all edits to state and a copy of all accessed state, and the hexary Patricia tree can no longer be modified. This is a first step in a multi-phase transition to Ethereum exclusively relying on Verkle trees to store execution state.

## Motivation

[Verkle trees](https://dankradfeist.de/ethereum/2021/06/18/verkle-trie-for-eth1.html) solve the key problem standing in the way of Ethereum being stateless-client-friendly: witness sizes. A witness accessing an account in today’s hexary Patricia tree is, in the average case, close to 3 kB, and in the worst case it may be three times larger. Assuming a worst case of 6000 accesses per block (15m gas / 2500 gas per access), this corresponds to a witness size of ~18 MB, which is too large to safely broadcast through a p2p network within a 12-second slot. Verkle trees reduce witness sizes to ~200 bytes per account in the average case, allowing stateless client witnesses to be acceptably small.

## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

This implements all of the logic in transitioning to a Verkle tree, and at the same time reforms gas costs, but does so in a minimally disruptive way that does not require simultaneously changing the whole tree structure. Instead, we add a new Verkle tree that starts out empty, and only new changes to state and copies of accessed state are stored in the tree. The Patricia tree continues to exist, but is frozen.

This sets the stage for a future hard fork that swaps the Patricia tree in-place with a Verkle tree storing the same data. Unlike [EIP 2584](https://eips.ethereum.org/EIPS/eip-2584), this replacement Verkle tree does not need to be computed by clients in real time. Instead, because the Patricia tree would at that point be fixed, the replacement Verkle tree can be computed off-chain.

### Verkle tree design

The Verkle tree uses a single-layer tree structure with 32-byte keys and values for several reasons:

 * **Simplicity**: working with the abstraction of a key/value store makes it easier to write code dealing with the tree (eg. database reading/writing, caching, syncing, proof creation and verification) as well as to upgrade it to other trees in the future. Additionally, witness gas rules can become simpler and clearer.
 * **Uniformity**: the state is uniformly spread out throughout the tree; even if a single contract has many millions of storage slots, the contract’s storage slots are not concentrated in one place. This is useful for state syncing algorithms. Additionally, it helps reduce the effectiveness of unbalanced tree filling attacks.
 * **Extensibility**: account headers and code being in the same structure as storage makes it easier to extend the features of both, and even add new structures if later desired.

The single-layer tree design does have a major weakness: the inability to deal with entire storage trees as a single object. This is why this EIP includes removing most of the functionality of SELFDESTRUCT. If absolutely desired, SELFDESTRUCT’s functionality could be kept by adding and incrementing an account_state_offset parameter that increments every time an account self-destructs, but this would increase complexity.
Gas reform

Gas costs for reading storage and code are reformed to more closely reflect the gas costs under the new Verkle tree design. WITNESS_CHUNK_COST is set to charge 6.25 gas per byte for chunks, and WITNESS_BRANCH_COST is set to charge ~13,2 gas per byte for branches on average (assuming 144 byte branch length) and ~2.5 gas per byte in the worst case if an attacker fills the tree with keys deliberately computed to maximize proof length.

The main differences from gas costs in Berlin are:

 * 200 gas charged per 31 byte chunk of code. This has been estimated to increase average gas usage by ~6-12% (see [this analysis](https://notes.ethereum.org/@ipsilon/code-chunk-cost-analysis) suggesting 10-20% gas usage increases at a 350 gas per chunk level).
 * Cost for accessing adjacent storage slots (`key1 // 256 == key2 // 256`) decreases from 2100 to 200 for all slots after the first in the group,
 * Cost for accessing storage slots 0…63 decreases from 2100 to 200, including the first storage slot. This is likely to significantly improve performance of many existing contracts, which use those storage slots for single persistent variables.

Gains from the latter two properties have not yet been analyzed, but are likely to significantly offset the losses from the first property. It’s likely that once compilers adapt to these rules, efficiency will increase further.

The precise specification of when access events take place, which makes up most of the complexity of the gas repricing, is necessary to clearly specify when data needs to be saved to the period 1 tree.

## Forward-compatibility

After the fork, there are two trees: a (no longer changing) hexary Patricia tree for period 0 and a Verkle tree for period 1. At that point we have forward compatibility with two paths:

    Fully implement state expiry, with a subsequent EIP that swaps out the Patricia tree root for a Verkle tree root, begins period 2 and schedules future periods (see [the roadmap](https://notes.ethereum.org/@vbuterin/verkle_and_state_expiry_proposal))
    Abandon state expiry, and slowly move all period 0 data into period 1 (so we just have weak statelessness)

Hence, while this EIP offers a very convenient path to implementing state expiry, it does not force that course of action, and it does leave open the door to simply sticking with weak statelessness.

## Backward-compatibility

The three main backwards-compatibility-breaking changes are:

 * `SELFDESTRUCT` neutering (see [here](https://hackmd.io/@vbuterin/selfdestruct) for a document stating the case for doing this despite the backwards compatibility loss)
 * Gas costs for code chunk access making some applications less economically viable
 * Tree structure change makes in-EVM proofs of historical state no longer work

(2) can be mitigated by increasing the gas limit at the same time as implementing this EIP, reducing the risk that applications will no longer work at all due to transaction gas usage rising above the block gas limit. (3) cannot be mitigated this time, but this proposal could be implemented to make this no longer a concern for any tree structure changes in the future.

## Test Cases

TODO

## Reference Implementation

 * github.com/gballet/go-ethereum, branch beverly-hills-head
 * TODO add Nethermind's

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
