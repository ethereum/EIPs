---
eip: eip-nfr.md
title: NFT Future Rewards (nFR) Standard
description: In this EIP, we propose a multigenerational reward mechanism that rewards‌ all ‌owners of non-fungible tokens (NFT).
author: Yale ReiSoleil (yale@iob.fi), @dRadiant, D Wang, PhD (david@iob.fi)
discussions-to: https://ethereum-magicians.org/t/non-fungible-future-rewards-token-standard/9203
type: Standards Track
category: ERC
status: Draft
created: 2022-05-08
requires: 165,721
---

## Simple Summary

This proposal outlines the interface of a new ERC721 standard extension. NFTs can then define, process, and distribute rewards based on the realized profit to former owners.

## Abstract

In this Ethereum Improvement Proposal (EIP), we propose the implementation of a Future Rewards (FR) extension which will enable owners of ERC721 tokens (NFTs) to participate in future price increases after they sell their tokens.

Owners of NFTs can expect to make money in two ways:

1. An increase in price during their holding period;
2. They receive Future Rewards (FRs) in the form of proceeds of the realized profits from the subsequent new owners after they have sold it. 

In the event the seller is not the first owner, the original minter, the profits gained when selling an NFT will be shared with the previous owners. The same person will receive the same FR distributions under the nFR system as the next generation of new owners after them. 

## Motivation

Are you interested in finding something that may prove valuable in the future and acquiring it early? Excellent! In reality, you often find yourself in a predicament where it does not matter whether you are a paper hand trader or a diamond hand hodler, the price keeps rising. 

Imagine if you were also rewarded with future price increases following the sale of your NFT?

In addition to being desired, a feature such as this is also justified in its existence. The value of a collectible is often determined by its provenance and its ownership history. The history of ownership plays an important role in determining its value. Consequently, all parties should be compensated retrospectively for their community status, reputations, and early contributions to the price discovery process. 

NFTs, in contrast to physical art and collectibles in the physical world, are not currently reflecting the contributions of their owners to their value. Since the ERC721 token can be tracked individually, and may be modified to record every change in price of any specific NFT token, there is no reason that a Future Rewards program of this type should not be established.

This EIP establishes a standard interface for a profit sharing structure in all stages of the token's ownership history desired by all market participants.

Additionally, as we will explain later, it discourages any "under-the-table" deals that may circumvent the rules set forth by artists and marketplaces.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

We are implementing this extension based on [the Open Zeppelin ERC721 set of interfaces, contracts, and utilities](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721).

ERC721-compliant contracts MAY implement this EIP for rewards to provide a standard method of rewarding future buyers and previous owners with realized profits in the future.

Implementers of this standard MUST have all of the following functions:

```solidity
pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the Future Rewards Token Standard.
 *
 * A standardized way to receive future rewards for non-fungible tokens (NFTs.)
 *
 */
interface InFR is IERC165 {

    event FRClaimed(address indexed account, uint256 indexed amount);

    event FRDistributed(uint256 indexed tokenId, uint256 indexed soldPrice, uint256 indexed allocatedFR);

    function transferFrom(address from, address to, uint256 tokenId, uint256 soldPrice) external payable;

    function releaseFR(address payable account) external;
    
}

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
```

An nFR contract MUST implement and update for each Token ID. The data in the `FRInfo` struct MAY either be stored wholly in a single mapping, or MAY be broken down into several mappings.

```solidity
struct FRInfo {
        uint8 numGenerations; //  Number of generations corresponding to that Token ID
        uint256 percentOfProfit; // Percent of profit allocated for FR, scaled by 1e18
        uint256 successiveRatio; // The common ratio of successive in the geometric sequence, used for distribution calculation
        uint256 lastSoldPrice; // Last sale price in ETH mantissa
        uint256 ownerAmount; // Amount of owners the Token ID has seen
        address[] addressesInFR;
    }
 ```
 
An nFR smart contract MUST also store and update the amount of Ether allocated to a specific address using the `_allotedFR`  function.

### Percent Fixed Point

The `allocatedFR` MUST be calculated using a percentage fixed point with a scaling factor of 1e18 (X/1e18) - such as "5e16" - for 5%. This is REQUIRED to maintain uniformity across the standard. The max and min values would be - 1e18 - 1.

### Default FR Info

A default `FRInfo` MUST be stored in order to be backwards compatible with ERC721 mint functions. It MAY also have a function to update the `FRInfo`, assuming it has not been hard-coded.

### ERC721 Overrides

An nFR smart contract MUST override the ERC721 `_mint`, `_transfer`, and `_burn` functions. When overriding the `_mint` function, a default FR model is REQUIRED to be established if the mint is to succeed when calling the ERC721 `_mint` function and not the nFR `_mint` function. It is also to update the owner amount and directly add the recipient address to the FR cycle. When overriding the `_transfer` function, the smart contract SHALL consider the NFT as sold for 0 wei, and update state accordingly after a successful transfer. This is to prevent FR circumvention. Finally, when overriding the `_burn` function, the smart contract SHALL delete the `FRInfo` corresponding to that Token ID after a successful burn.

Additionally, the ERC721 `_checkOnERC721Received` function MAY be explicitly called after mints and transfers if the smart contract aims to have safe transfers and mints.

### Safe Transfers

If the wallet/broker/auction application will accept safe transfers, then it MUST implement the ERC721 wallet interface.

### FR `transferFrom` Function

The FR `transferFrom` function MUST be called by all nFR-supporting smart contracts, though the accommodations for non-nFR-supporting contracts MAY also be implemented to ensure backwards compatibility.

```solidity
function transferFrom(address from, address to, uint256 tokenId, uint256 soldPrice) public virtual override payable {
       //...
}
```

The FR `transferFrom` function MUST be payable and the amount the NFT sold for MUST match the `msg.value` provided to the function. This is to ensure the values are valid and will also allow for the necessary FR to be held in the contract. Based on the stored `lastSoldPrice`, the smart contract will determine whether the sale was profitable after calling the ERC721 transfer function and transferring the NFT. If it was not profitable, the smart contract SHALL update the last sold price for the corresponding Token ID, increment the owner amount, shift the generations, and return all of the  `msg.value` to the `msg.sender` or `tx.origin` depending on the implementation. Otherwise, if the transaction was profitable, the smart contract SHALL call the `_distributeFR` function, then update the `lastSoldPrice`, increment the owner amount, and finally shift generations. The `_distributeFR` function MUST return the difference between the allocated FR that is to be distributed amongst the `_addressesInFR` and the `msg.value` to the `msg.sender` or `tx.origin`.

