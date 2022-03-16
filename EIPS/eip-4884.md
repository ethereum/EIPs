---
eip: 4884
title: Rentable NFT Standard
description: An extension for NFT contracts to enable tokens to be rentable
author: Muhammed Emin Aydın (@muhammedea)
discussions-to: https://github.com/ethereum/EIPs/issues/4918
status: Draft
type: Standards Track
category: ERC
created: 2022-02-15
requires: 165
---

# Renting Extension For NFT Contracts

## Abstract

This extension defines some extra functions to the ERC-721 standard for renting NFT tokens to another account.
This enables NFT owners to rent their assets to someone else for some period of time. 
So the owner of the token will be changed temporarily. 

This can be applied to ERC-1155 tokens too. 
Because an ERC-1155 contract can have fungible tokens (FT) and non-fungible tokens (NFT), so this functionality will be usable by only NFTs.
So the contract should implement [split id proposal](https://eips.ethereum.org/EIPS/eip-1155#split-id-bits) in ERC-1155 standard

## Motivation

This kind of functionality is specifically important for gaming industry. 
It is important for a gamer to have the ability to give an NFT to someone else for a period of time. 
For example, you can give an NFT to someone else for playing for a period of time. So sharing an NFT will be possible.


## Specification

This specification defines an interface for ERC-721 and ERC-1155 contracts. 

**rentOut** function will transfer the ownership to the renter. 
After the renting period has passed, the actual owner can use **finishRenting** function to take the ownership back.
Renter can finish renting earlier than that.

**principalOwner** and **isRented** functions are helper functions.


```solidity
pragma solidity ^0.8.0;

/**
    @title ERC-721 Rentable
 */
interface ERC721Rentable /* is ERC165 */ {
    /**
        @dev This event will be emitted when token is rented
        tokenId: token id to be rented
        owner:  principal owner address
        renter: renter address
        expiresAt:  end of renting period as timestamp
    */
    event Rented(uint256 indexed tokenId, address indexed owner, address indexed renter, uint256 expiresAt);

    /**
        @dev This event will be emitted when renting is finished by the owner or renter
        tokenId: token id to be rented
        owner:  principal owner address
        renter: renter address
        expiresAt:  end of renting period as timestamp
    */
    event FinishedRent(uint256 indexed tokenId, address indexed owner, address indexed renter, uint256 expiresAt);

    /**
        @notice rentOut
        @dev Rent a token to another address. This will change the owner.
        @param renter: renter address
        @param tokenId: token id to be rented
        @param expiresAt: end of renting period as timestamp 
    */
    function rentOut(address renter, uint256 tokenId, uint256 expiresAt) external;

    /**
        @notice finishRenting
        @dev This will returns the token, back to the actual owner. Renter can run this anytime but owner can run after expire time.
        @param tokenId: token id
    */
    function finishRenting(uint256 tokenId) external;

    /**
        @notice principalOwner
        @dev  Get the actual owner of the rented token
        @param tokenId: token id
    */
    function principalOwner(uint256 tokenId) external returns (address);

    /**
        @notice isRented
        @dev  Get whether or not the token is rented
        @param tokenId: token id
    */
    function isRented(uint256 tokenId) external returns (bool);
}
```

## Security Considerations
### Transfer Checks
A rented token can not be transferred to someone else. So on every transfer the token status should be checked. 
If the token is rented, it can not be transferred to someone else.
### Finishing Renting
**finishRenting** function can be called by the renter anytime, but the owner can run only after expire time.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).