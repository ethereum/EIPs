---
eip: 7814
title: Introspection precompiles
description: Introspection precompiles that expose the current block context to the EVM
author: Brecht Devos (@Brechtpd)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2024-11-09
---

## Abstract

This EIP proposes to add two precompiles that enable introspection of the chain state at arbitrary points within a block in the EVM. Currently, the EVM only has access to the state of previous blocks. No block data is currently exposed to the EVM for the block it's executing in.

## Motivation

The new precompiles aim to enhance introspection capabilities within the EVM, enabling the calculation of the latest chain state offchain at any point in an Ethereum block. This is important to allow general and efficient synchronous composability with L1. Otherwise, to ensure having the latest L1 state, the state would have to be read on L1 and passed in as a separate input. This is expensive and there may be limitations on who can read the state without something like [EIP-2330](https://eips.ethereum.org/EIPS/eip-2330).

This proposal allows computing the latest state from the state root of the previous block and the transactions that are in the current block. This data can then be passed into any system requiring the latest chain state where the partial block can be re-executed to compute the latest state in a provable way.

## Specification

If `block.number >= TBD` two new precompiled contracts shall be created:
- `TXTRIEROOT` at address `TBD`: This precompile returns the transaction trie root of all transactions in the current block, up to and including the transaction that is currently executing. The tx trie is already calculated for the block header. This EIP just enforces that the trie is constructed incrementally per transaction and exposes the root to the EVM.
- `OPCODECOUNTER` at address `TBD`: This precompile returns a 4 byte uint in big endian encoding representing the total number of opcodes that have been executed for the current transaction up till (and excluding) the call to this precompile.

### Gas Cost

The gas cost for `TXTRIEROOT` and `OPCODECOUNTER` is a fixed fee of `2`.

## Rationale

Simple and efficient access to the latest state of a chain is critical for composability. For synchronous composability, we need to be able to immediately prove all offchain work inside the same block. This makes it impossible to delay the proving to a later block where more information about the current block is available.

### Gas Price

The precompiles are priced to match similar opcodes in the `W_base` set.

### Precompile

Implementing this feature via precompiles instead of opcodes gives L2s flexibility to decide whether to implement it.

## Backwards Compatibility

Further discussion required.

## Test Cases

N/A

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
