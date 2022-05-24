---
eip: XXXX
title: Name-bound Tokens
description: A standard interface for non-separable non-fungible tokens, also known as "Name-bound" or "soulbound tokens" or "badges"
author: Tim Daubenschütz (@TimDaub), Tom Cohen (@TheWaler), Enrico Bottazzi (<pls add GitHub User name>)
discussions-to: https://ethereum-magicians.org/t/xxxx
status: Draft
type: Standards Track
category: ERC
created: 2022-05-24
requires: 137, 165, 721
---

## Abstract

Proposes a standard API for Name-bound Tokens (NBT) within smart contracts. A NBT is a non-fungible token bound to a single ENS hashnode, and cannot be transferred between ENS names. This EIP defines basic functionality to gift, mint, and track NBT.

## Motivation

The Ethereum community has expressed a need for non-transferrable, non-fungible tokens. While Account-bound tokens technically allow for a simple binding mechanism, their central mechanic discourages healthy key rotation routines.

Common use cases for Name-bound tokens include tracking an individual's achievements (which can be used as credentials), or items that cannot be transferred (like certain loot in multiplayer online games).

The purpose of this document is to make NBTs a reality on Ethereum by creating consensus around a **maximally backward-compatible** but otherwise **minimal** interface definition.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

`EIP-XXXX` tokens _must_ implement the interfaces:

- [EIP-165](./eip-165.md)'s `ERC165` (`0x01ffc9a7`)
- [EIP-721](./eip-721.md)'s `ERC721Metadata` (`0x5b5e139f`)

`EIP-XXXX` tokens _must not_ implement the interfaces:

- [EIP-721](./eip-721.md)'s `ERC721` (`0x80ac58cd`)

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Name-bound tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-XXXX
///  Note: the ERC-165 identifier for this interface is 0x6352211e.
interface IERCXXXX /* is ERC165, ERC721Metadata */ {
  /// @dev This emits when ownership between ENS nodes of any NBT changes by any mechanism.
  ///  This event emits when NBTs are created (`from` == 0x0) and destroyed
  ///  (`to` == 0x0).
  event Transfer(bytes32 indexed _from, bytes32 indexed _to, uint256 indexed _id);
  /// @notice Find the owner of an NBT
  /// @dev NBTs assigned to empty string namehash ('') are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for an NFT
  /// @return The address of the owner of the NFT
  function ownerOf(uint256 _tokenId) external view returns (bytes32);
}
```

See [`EIP-721`](./eip-721.md) for a definition of its metadata JSON Schema.

## Rationale

### Interface

`EIP-XXXX` shall be maximally backward-compatible but still only expose a minimal and simple to implement interface definition.

As [`EIP-721`](./eip-721.md) tokens have seen widespread adoption with wallet providers and marketplaces, using its `ERC721Metadata` interface with [`EIP-165`](./eip-165.md) for feature-detection potentially allows implementers to support `EIP-XXXX` tokens out of the box.

If an implementer of [`EIP-721`](./eip-721.md) properly built [`EIP-165`](./eip-165.md)'s `function supportsInterface(bytes4 interfaceID)` function, already by recognizing that [`EIP-721`](./eip-721.md)'s track and transfer interface component with the identifier `0x80ac58cd` is not implemented, transferring of a token should not be suggested as a user interface option.

Still, however, since `EIP-XXXX` supports [`EIP-721`](./eip-721.md)'s `ERC721Metadata` extension, an account-bound token should be displayed in wallets and marketplaces with no changes needed.

### Provenance Indexing

NBTs can be indexed by tracking the emission of `event Transfer(bytes32 indexed _from, bytes32 indexed _to, uint256 indexed _id)`.

We recommend implementers to validate `Transfer`'s `_from` field by comparing it to the transaction-level `_from` field to mitigate "sleepminting" attacks.

## Backwards Compatibility

We have adopted the [`EIP-165`](./eip-165.md) and `ERC721Metadata` functions purposefully to create a high degree of backward compatibility with [`EIP-721`](./eip-721.md). We have deliberately used [`EIP-721`](./eip-721.md) terminology such as `function ownerOf(...)` and `event Transfer` to minimize the effort of familiarization for `EIP-XXXX` implementers already familiar with, e.g., [`EIP-20`](./eip-20.md) or [`EIP-721`](./eip-721.md).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
