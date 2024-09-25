---
title: ERC721AS - Auto Staking
description: ERC721AS is an zero-gas staking system for NFTs that does not require holders to ‘actively prove’ their holding status.
author: Kiwoong Kim (@helloing0119), Jeff Rhie (@jeff-rhie), Jay B (@DalecB)
discussions-to: https://ethereum-magicians.org/c/eips/5
status: Draft
type: Standards Track
category: ERC
created: 2024-09-24
---

## Abstract

- ERC721AS is an zero-gas staking system for NFTs that does not require holders to ‘actively prove’ their holding status.
- We provide it as open-source to accommodate best holder-experience for the broader community.

## Motivation

## Specification

ERC721AS is an advanced extension of the ERC721A standard that introduces an automated staking mechanism and efficient token management features for NFTs. The primary functionalities and enhancements of ERC721AS are as follows:

### 1. **Automated Staking Mechanism**

- The contract integrates a staking system that automatically tracks the staking status and duration of each token.
- Staking information is maintained using the `TokenStatus` struct and `StakingPolicy` struct, which store staking parameters and timestamps.
- Key functions include:
  - `isTakingBreak(uint256 tokenId)`: Checks whether a given token is currently taking a break from staking.
  - `stakingTimestamp(uint256 tokenId)`: Returns the latest change in staking status for a token.
  - `stakingTotal(uint256 tokenId)`: Calculates and returns the total staking time for a token.

### 2. **Efficient Batch Minting**

- Supports batch minting with reduced gas costs through the `_safeMint` and `_mint` functions, enabling multiple tokens to be minted in a single transaction.
- The `totalSupply()` and `_totalMinted()` functions provide information on the total supply of tokens and those minted, respectively.

### 3. **Token Ownership and Transfer Management**

- The contract overrides standard ERC721 functions to integrate staking data with token transfers.
- The `_beforeTokenTransfers` and `_afterTokenTransfers` hooks are used to update staking status during token transfers.
- Functions such as `_applyNewStakingPolicy` allow dynamic updates to staking parameters.

### 4. **Staking Policy Customization**

- Developers can customize staking parameters such as staking start and end times, break times, and staking identifiers.
- Functions include:
  - `_setStakingBegin(uint40 _begin)`: Sets the staking start time.
  - `_setStakingEnd(uint40 _end)`: Sets the staking end time.
  - `_setStakingBreaktime(uint40 _breaktime)`: Sets the break time between staking periods.
  - `_applyNewStakingPolicy(uint40 _begin, uint40 _end, uint40 _breaktime)`: Starts a new staking policy and validates existing parameters.

### 5. **ERC721 Compatibility**

- Implements all standard ERC721 interfaces, such as `IERC721` and `IERC721Metadata`, ensuring compatibility with existing ERC721-based systems.
- Functions like `balanceOf`, `ownerOf`, `approve`, and `safeTransferFrom` are implemented and extended to support staking features.

### 6. **Enhanced Staking Controls**

- The contract provides enhanced staking controls, allowing for the manual setting and updating of staking policies via internal functions.
- Developers can override staking-related functions to implement custom staking logic and integrate unique project requirements.

## Rationale

The design of ERC721AS addresses several challenges and limitations observed in the existing NFT standards:

### 1. **Gas Efficiency**

- Traditional NFT standards incur high gas costs for minting and transferring multiple tokens individually. ERC721AS introduces batch minting and optimized state management to minimize these costs.

### 2. **Integrated Staking Mechanism**

- Existing NFT standards require separate contracts for staking functionality, complicating development and integration. ERC721AS integrates staking directly into the token contract, providing a seamless experience for staking without additional dependencies.

### 3. **Flexibility and Extensibility**

- The contract is designed to be easily extended, allowing developers to override and customize key staking-related functions.
- By supporting dynamic updates to staking policies, ERC721AS enables projects to adapt staking parameters as needed for different phases or events.

### 4. **Backward Compatibility**

- While introducing advanced features, ERC721AS remains compatible with the ERC721 standard, ensuring that projects can adopt it without losing functionality or compatibility with existing platforms and tools.

This design provides a comprehensive solution for projects that require efficient batch processing and staking features, while still maintaining compatibility with the broader ERC721 ecosystem.

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

## Reference Implementation

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
