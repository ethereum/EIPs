---
eip: 
title: ERC-721 Time Extension
description: Add start time and end time to ERC-721 tokens.
author: Anders (@0xanders), Lance (@LanceSnow), Shrug <shrug@emojidao.org>
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2022-04-13
requires: 165, 721
---

## Abstract

This standard is an extension of [ERC-721](./eip-721.md). It proposes some additional property( `startTime`, `endTime`,`originalTokenId`) to help with the on-chain time management.

## Motivation

Some NFTs have a defined usage period and cannot be used when they are not at a specific time. If you want to make NFT invalid when it is not in use period, or make NFT enabled at a specific time, while the NFT does not contain time information, you often need to actively submit the chain transaction, this process is both cumbersome and a waste of gas.

There are also some NFTs contain time functions, but the naming is different, third-party platforms are difficult to develop based on it.

By introducing (`startTime`, `endTime`) and unifying the naming, it is possible to enable and disable NFT automatically on chain.

## Specification

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY" and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

```solidity
interface ITimeNFT  {

    /// @notice Emitted when the `startTime` or `endTime` of a NFT is changed 
    /// @param tokenId  The tokenId of the NFT
    /// @param startTime  The new start time of the NFT
    /// @param endTime  The new end time of the NFT
    event TimeUpdate(uint256 tokenId,uint64 startTime,uint64 endTime);

    /// @notice Get the start time of the NFT 
    /// @dev Throws if `tokenId` is not valid NFT 
    /// @param tokenId  The tokenId of the NFT
    /// @return The start time of the NFT
    function startTime(uint256 tokenId) external view returns (uint64);
    
    /// @notice Get the end time of the NFT  
    /// @dev Throws if `tokenId` is not valid NFT 
    /// @param tokenId  The tokenId of the NFT
    /// @return The end time of the NFT
    function endTime(uint256 tokenId) external view returns (uint64);

    /// @notice Get the token id which this NFT mint from
    /// @dev Throws if `tokenId` is not valid NFT 
    /// @param tokenId  The tokenId of the NFT
    /// @return The token id which this NFT mint from
    function originalTokenId(uint256 tokenId) external view returns (uint256);

    /// @notice Check the NFT is valid now 
    /// @dev Throws if `tokenId` is not valid NFT 
    /// @param tokenId  The tokenId of the NFT
    /// @return The the NFT is valid now
    /// if(startTime <= now <= endTime) {return true;} else {return false;} 
    function isValidNow(uint256 tokenId) external view returns (bool);

    /// @notice Mint a new NFT from an old NFT  
    /// @dev Throws if `tokenId` is not valid NFT 
    /// @param originalTokenId  The token id which the new NFT mint from
    /// @param newNftStartTime  The start time of the new NFT
    /// @return The the token id of the new NFT
    function split(uint256 originalTokenId,uint64 newNftStartTime) external returns(uint256);

    /// @notice Merge two NFTs to one NFT  
    /// @dev Throws if `tokenAId` or `tokenBId` is not valid NFT 
    /// @param firstTokenId   The token id of the first NFT
    /// @param secondTokenId  The token id of the second NFT
    /// @return The the token id of the new NFT
    function merge(uint256 firstTokenId,uint256 secondTokenId) external returns(uint256);
}
```

## Rationale


## Backwards Compatibility

As mentioned in the specifications section, this standard can be fully ERC721 compatible by adding an extension function set.


## Test Cases



## Reference Implementation


## Security Considerations


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

