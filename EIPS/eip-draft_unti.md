---
eip: <to be assigned>
title: UNTransferability Indicator for ERC-1155
description: An extension of ERC-1155 for indicating the transferability of the token.
author: Yuki Aoki (@yuki-js)
discussions-to: https://ethereum-magicians.org/t/sbt-implemented-in-erc1155/12182
status: Draft
type: Standards Track
category (*only required for Standards Track): ERC
created: 2022-01-06
requires (*optional): 1155
---

## Abstract

The following standard is an extension of [EIP-1155](./eip-1155.md). It introduces the interface for indicating whether the token is transferable or not, without regard to non-fungibility, using the feature detection functionality of [EIP-165](./eip-165.md).

## Motivation

We propose the introduction of the UNTransferability Indicator, a universal indicator that demonstrates untransferability without regard to non-fungibility. This will enable the use of Soulbound Tokens (SBT), which are untransferable and fungible/non-fungible entities, to associate items with an account, user-related information, memories, and event attendance records, in a universal manner. The [EIP-5192](./eip-5192.md) specification was invented for this purpose, but SBT in [EIP-5192](./eip-5192.md) is non-fungible and has a tokenId, allowing them to be distinguished from each other using the tokenId. However, for example, in the case of event attendance records, it is not necessary to distinguish between those who attended the same event using the tokenId, and all participants should have the same indistinguishable entity. Rather, the existence of the tokenId creates discriminability.

Additionally, there is currently no mechanism to indicate untransferability in [EIP-20](./eip-20.md) or [EIP-1155](./eip-1155.md). Therefore, a universal specification with the same functionality as [EIP-5192](./eip-5192.md), which can be applied to more than just [EIP-721](./eip-721.md), is required.

Therefore, we propose the introduction of a universal indicator that demonstrates untransferability without regard to non-fungibility, inspired by [EIP-5192](./eip-5192.md). This will make it impossible to identify individuals when using SBT to associate information, protecting the privacy of personal information. It will also make it possible to choose a method other than [EIP-721](./eip-721.md) when implementing SBT. Then tokens with UNTransferability Indicator become something like account-bound attributes rather than assets.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Smart contracts implementing the ERC-tba standard MUST comform to the ERC-1155 specification.

Smart contracts implementing the ERC-tba standard MUST implement all of the functions in the UNTI interface.

Smart contracts implementing the ERC-tba standard MUST implement the ERC-165 supportsInterface function and MUST return the constant value true if `0xd87116f3` is passed through the interfaceID argument.

For the token identifier `_id` that is marked as `locked`, `locked(_id)` MUST return the constant value true and any functions that try transferring the token, including `safeTransferFrom` and `safeBatchTransferFrom` function MUST throw.

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface UNTI {
  /// @notice Either `LockedSingle` or `LockedBatch` MUST emit when the locking status is changed to locked.
  /// @dev If a token is minted and the status is locked, this event should be emitted.
  /// @param _id The identifier for a token.
  event LockedSingle(uint256 _id);

  /// @notice Either `LockedSingle` or `LockedBatch` MUST emit when the locking status is changed to locked.
  /// @dev If a token is minted and the status is locked, this event should be emitted.
  /// @param _ids The list of identifiers for tokens.
  event LockedBatch(uint256[] _ids);

  /// @notice Either `UnlockedSingle` or `UnlockedBatch` MUST emit when the locking status is changed to unlocked.
  /// @dev If a token is minted and the status is unlocked, this event should be emitted.
  /// @param _id The identifier for a token.
  event UnlockedSingle(uint256 _id);

  /// @notice Either `UnlockedSingle` or `UnlockedBatch` MUST emit when the locking status is changed to unlocked.
  /// @dev If a token is minted and the status is unlocked, this event should be emitted.
  /// @param _ids The list of identifiers for tokens.
  event UnlockedBatch(uint256[] _ids);


  /// @notice Returns the locking status of the token.
  /// @dev SBTs assigned to zero address are considered invalid, and queries
  /// about them do throw.
  /// @param _id The identifier for a token.
  function locked(uint256 _id) external view returns (bool);

  /// @notice Returns the locking statuses of the multiple tokens.
  /// @dev SBTs assigned to zero address are considered invalid, and queries
  /// about them do throw.
  /// @param _ids The list of identifiers for tokens
  function lockedBatch(uint256[] _ids) external view returns (bool);
}
```

## Rationale

There are some proposed uses of UNTransferability Indicator for [EIP-1155](./eip-1155.md). One example is the "Resident Bound Tokens", which indicates that he or she lives in the country or prefecture, and helps creating the local community or providing the government services. Another example is the lecture credit which doesn't need to distinguish the attendees.

This standard will introduce the fungible but non-transferable token, and also introduce the account-bound attributes, and then redefine the definition of SBTs.

## Backwards Compatibility

This proposal is fully backward compatible with [EIP-1155](./eip-1155.md).

## Security Considerations

There are no security considerations related directly to the implementation of this standard.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
