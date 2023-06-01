---
eip: 8192
title: NFT Dynamic Ownership
description: An innovative extension to the standard ERC721 token that introduces dynamic ownership and nesting capabilities.
author: hiddenintheworld.eth (@hiddenintheworld)
discussions-to: https://ethereum-magicians.org/t/erc-8192-nft-dynamic-ownership/14516
status: Draft
type: Standards Track
category: ERC
created: 2023-06-01
requires: 721
---

## Simple Summary

A standard interface for non-fungible tokens (NFTs) with dynamic ownership, which extends the capabilities of the original ERC-721 standard by enabling NFTs to be owned by either addresses or other NFTs.

## Abstract

The ERC-721D standard introduces dynamic ownership in the world of NFTs. Instead of a token being owned solely by an address, as it is in the ERC-721 standard, tokens following the ERC-721D standard can be owned by either an address or another token. This opens up new possibilities and adds an extra layer of complexity and opportunity in the NFT space. This EIP outlines the rules and functions needed to support this dynamic ownership model while maintaining compatibility with ERC-721 standards.

## Motivation

Non-fungible tokens (NFTs) have paved the way for unique digital assets. However, they are inherently restricted by their static ownership. ERC-721D aims to innovate the concept of NFT ownership by allowing tokens to have dynamic ownership chains. This could unlock an entirely new dimension for tokenized digital assets and decentralized applications (dApps).

## Specification

### Overview
ERC-721D is a standard interface for NFTs with dynamic ownership. It provides the essential functionalities to manage, transfer, and track the ownership of tokens. It is an extension of the ERC-721 standard.

### Data Structures

The ERC-721D standard introduces a new data structure, Ownership. Each token has an Ownership associated with it that consists of the ownerAddress and the tokenId. The ownerAddress is the address of the token owner, which can be an EOA or a contract address. If the owner is another NFT, then tokenId represents the Id of the owner token.

### Functions

The ERC-721D standard defines a set of functions for interacting with tokens. It includes existing functions from the ERC-721 standard, like balanceOf and ownerOf, with necessary modifications to support dynamic ownership. It also introduces new functions like setOwnership to manage dynamic ownership. The mint and burn functions have been overridden to account for changes in the balance of dynamic owners. The _transfer function has been updated to handle transfers involving dynamic owners.

## Rationale

The ERC721D standard seeks to expand the potential of NFTs by introducing dynamic ownership. This innovation could open up new use-cases in the fields of digital assets, dApps, digital identity, and more. As the digital economy evolves, the need for complex and dynamic relationships between tokens will become increasingly relevant, and the ERC721D standard addresses this need.

## Backwards Compatibility

ERC721D is fully backwards compatible with the ERC-721 standard. It extends the ERC721 standard by adding dynamic ownership while maintaining all existing functionalities. Any existing ERC721 token can be upgraded to an ERC721D token while retaining its original capabilities.

## Security Considerations

As with any smart contract standard, security considerations are paramount. Implementers of ERC-721D should ensure that they have robust systems in place for managing the Ownership structure and that transfers, minting, and burning of tokens are handled securely. It's crucial to thoroughly test and audit any contracts that implement ERC-721D to avoid potential security risks. Moreover, dealing with dynamic ownership presents additional complexities, which requires extra caution while implementing this standard.

## Implementation

For a reference implementation, please see [here](https://github.com/hiddenintheworld/ERC8192). This repository contains the Solidity code for the ERC721D contract, including the necessary functions for minting tokens, setting and changing the ownership, and burning tokens.

Below are some key parts of the implementation:


```solidity
// Code snippet demonstrating dynamic ownership
struct Ownership {
    address ownerAddress;
    uint256 tokenId;
}
mapping(uint256 => Ownership) private _owners;

// Code snippet demonstrating dynamic ownership transfer
function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    require(ownerOf(tokenId) == from, "ERC721D: transfer of token that is not owned");
    Ownership memory oldOwnership = _owners[tokenId];
    _approve(address(0), tokenId);
    _owners[tokenId] = Ownership(to, 0);
    //... rest of the function
}
```

## Copyright

Copyright and related rights waived via CC0.