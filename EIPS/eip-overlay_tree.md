---
eip: <to be assigned>
title: Trie format transition with overlay trees
author: Guillaume Ballet (@gballet)
discussions-to: https://ethresear.ch/t/overlay-method-for-hex-bin-tree-conversion/7104
status: Draft
type: Standards Track
category: Core
created: 2020-04-03
---

## Simple Summary

This EIP proposes a method to convert the state trie format from hexary to binary: new values are directly stored in a binary trie “laid over” the hexary trie. Meanwhile, the hexary trie is converted to a binary trie in the background. When the process is finished, both layers are merged.

## Abstract

This EIP describes a four phase process to complete the conversion.

  * In the first phase, all new state writes are made to an overlay binary trie, while the hexary trie is being converted to binary. The block format is changed to have two storage roots: the root of the nhexary trie and the root of the binary trie.
  * The second phase starts when miners are done with the conversion and replace the hexary root with the newly calculated root.
  * The third phase begins when a sufficient number of consecutive blocks report the same value: the overlay tree is progressively merged back into the newly converted binary base trie. A constant number of entries are deleted from the overlay and inserted into the base trie.
  * The fourth and final phase begins when the overlay trie is empty. The field holding its root is removed from the block header.

## Motivation

There is a long running interest in switching the state trie from a hexary format to a binary format, for reasons pertaining to proof and storage sizes. The conversion process poses a catch-up issue, caused by the sheer size of the full state: it can not be translated in a reasonable time (i.e. on the same order of magnitude as the block time). 

## Specification
The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).

### Binary tries

This EIP assumes that a binary trie is defined like the MPT, except that:

  * The series of bytes in I₀ is seen as a series of _bits_ and so ∀i≤256, I₀[i] is the ith bit in key I₀
  * The first item of an **extension** or a **leaf** is replacing nibbles with bits;
  * A **branch** is a 2 item structure in which both items correspond to each of the two possible bit values for the keys at this point in their traversal;
  * c(𝕴,i) ≡ RLP((u(0), u(1)) at a branch, where u(j) = n({I : I ∈ 𝕴 ⋀ I₀[i] = j}, i+1)

### Phase 1

Let _H₁_ be the previously agreed-upon block height at which phase 1 starts. For each block of height H₁ ≤ _h_ < H₂:

  * Block headers contain a block header has a new Hₒ which is the _root of the overlay binary trie_
  * Hᵣ ≡ P(H)ᵣ, i.e. the hexary trie root is the same as that of the block parent's. The hexary trie is referred to as the _hexary base trie_.

The following is changed in the execution environment:

  * Upon executing a _state read_, ϒ first searches for the address in the overlay trie. If the key can not be found there, ϒ then searches the hexary base trie as it did at block heights h' < H₁;
  * Upon executing a _state write_, ϒ will insert or update the value into the overlay tree.

A conversion process occurs in the background to turn the hexary trie into its binary equivalent. The end goal of this process is the calculation of the _root hash of the converted binary base trie_, denoted Hᵣ². The root of the hexary base trie is hereafter called Hᵣⁱ⁶.

When a miner has calculated Hᵣ², it proceeds to phase 2.

### Phase 2

Phase 2 is the same as phase 1, except for the following:

  * Hᵣ' ≡ Hᵣ²


Phase 2 ends when a sufficient number of subsequent blocks have reported the same value for Hᵣ².

### Phase 3

The following changes occur in phase 3:

  * N accounts are being deleted from the binary overlay trie and inserted into the binary base trie.
  * Upon executing a _state write_, ϒ will insert or update the value into the _base_ tree. If the search key exists in the overlay tree, it is deleted.

When the overlay trie is empty, phase 3 ends and phase 4 begins.

### Phase 4

Phase 4 is the same as phase 3, except for the following changes:

  * Hₒ is dropped from the block header

## Rationale

Methods that have been discussed until now include a "stop the world" approach, in which the chain is stopped for the significant amount of time that is required by the conversion, and a "copy on write" approach, in which branches are converted upon being accessed.
The approach suggested here has the advantage that the chain continues to operate normally during the conversion process, and that the tree is fully converted to a binary format, in a predictable time.

## Backwards Compatibility

This requires a fork and will break backwards compatibility, as the hashes and block formats will necessarily be different. This will cause a fork in clients that don't implement the overlay tree, and those that do not accept the new binary root. No mitigation is proposed, as this is a hard fork.

## Test Cases

TBD

## Implementation
<!-- The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

The implementation is still WIP, however a prototype version of the conversion process is in the works for geth in [this PR](https://github.com/holiman/go-ethereum/pull/12).

## Security Considerations
<!-- All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers. -->

There are two issues that I can foresee:

  * A targeted attack that would cause the overlay trie to be unreasonably large. Since gas costs will likely increase during the transition process, lengthening phase 3 is making Ethereum more expensive during a longer period of time. This could be solved by increasing the cost of `SSTORE` during phases 1 and 2.
  * If a large enough portion of the miners report a different value for the base binary tree root during phase 2, the start of phase 3 can be delayed indefinitely. At the limit, if miners representing more than 51% of the network are reporting an invalid value, they could be stealing funds without anyone having a say.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
