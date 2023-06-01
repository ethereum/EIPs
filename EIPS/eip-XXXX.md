---
title: SoulBounds - Standard Interface for Soulbound Assets
description: Interface for representing and managing soulbound assets based on the ERC-1155 token standard
author: Leonid Shaydenko (@lssleo)
status: Draft
type: Standards Track
category: ERC
created: 2023-06-01
---

## Abstract

The SoulBounds EIP proposes a standard interface, called SoulBounds, that extends the ERC-1155 token standard to support the representation and management of soulbound assets on the Ethereum network. Soulbound assets are unique digital items that are permanently bound to a specific user or address, preventing transferability to other addresses.

## Motivation

The concept of soulbound assets is commonly used in gaming and non-fungible token (NFT) applications, where certain items or collectibles are intended to be non-transferable. Currently, there is no standardized way to represent and manage soulbound assets on the Ethereum network. By introducing the SoulBounds interface, I aim to establish a common standard for developers to create, manage, and interact with soulbound assets in a consistent and interoperable manner.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Smart contracts implementing the SoulBounds interface MUST implement all of the functions defined in the IERC1155SoulBounds interface


The SoulBounds interface extends the ERC-1155 token standard by introducing the following additional functions:

```solidity
interface IERC1155SoulBounds {
    /**
     * @notice Returns the address to which the given token ID is soulbound.
     * @param _tokenId The ID of the token
     * @return The address to which the token is soulbound
     */
    function soulboundOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Checks if the given token ID is soulbound.
     * @param _tokenId The ID of the token
     * @return True if the token is soulbound, false otherwise
     */
    function isSoulbound(uint256 _tokenId) external view returns (bool);

    /**
     * @notice Binds the given token ID to the specified address, making it soulbound and non-transferable.
     * @dev Caller must have the necessary permissions to soulbind the token.
     * @param _tokenId The ID of the token
     * @param _address The address to which the token will be soulbound
     */
    function soulbind(uint256 _tokenId, address _address) external;

    /**
     * @notice Removes the soulbound status of the given token ID, allowing it to be transferred freely.
     * @dev Caller must have the necessary permissions to soulunbind the token.
     * @param _tokenId The ID of the token
     */
    function soulunbind(uint256 _tokenId) external;
}
```

## Rationale

The SoulBounds interface provides a standardized way to represent and manage soulbound assets. By defining a common set of functions, developers can create contracts and applications that handle soulbound assets consistently. This standardization enhances interoperability, simplifies integration across platforms, and promotes the growth of the soulbound asset ecosystem on Ethereum.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via CC0.
