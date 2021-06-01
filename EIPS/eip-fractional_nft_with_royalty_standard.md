---
eip: <to be assigned>
title: Fractional nft with Royalty Distribution system
author: Yongjun Kim (@PowerStream3604)
discussions-to: <URL>
status: Draft
type: Standards Track
category : ERC
created: 2021-06-01
requires : 20, 165, 721
---
  
## Simple Summary
A ERC-20 contract becoming the owner of a nft token.
Fractionalizing the ownership of NFT into multiple ERC-20 tokens by making the ERC-20 contract as the owner of NFT.
Distributing the royalty(income) to the shareholders who own the specific ERC-20 token.
  
## Abstract
The intention of this proposal is to extend the functionalities of ERC-20 to represent it as a share of nft and provide automated and trusted method to distribute royalty
to ERC-20 token holders.
Utilizing ERC-165 Standard Interface Detection, it detects if a ERC-20 token is representing the shared ownership of ERC-721 Non-Fungible Token.
ERC-165 implementation of this proposal makes it possible to verify from both contract and offchain level if it adheres to this proposal(standard).
This proposal makes small changes to existing ERC-20 Token Standard and ERC-721 Token Standard to support most of software working on top of this existing token standard.
By sending ether to the address of the ERC-20 Contract it will distribute the amount of ether per holders and keep it inside the chain.
Whenever the owner of the contract calls the function for withdrawing their proportion of royalty, they will receive the exact amount of compensation according to their amount 
of share at that very moment.

## Motivation
It is evident that many industries need cryptographically verifiable method to represent shared ownership.
ERC-721 Non-Fungible Token standards are ubiquitously used to represent ownership of assets from digital assets such as Digital artworks, Game items(characters), Virtual real estate
to real-world assets such as Real estate, artworks, cars, etc.
As more assets are registered as ERC-721 Non-Fungible Token demands for fractional ownership will rise.

Fractional ownership does not only mean that we own a portion of assets.
But It also means that we need to obtain financial profit whenever the asset is making profit through any kinds of financial activities.
For instance, token holders of NFT representing World Trade Center should receive monthly rent from tenants.
Token holders of NFT representing "Everydays-The First 5000 days" should receive advertisement charge, exhibition fees whenever their artwork is being used for financial activities.
To make this possible this proposal implements a reasonable logic to distribute income fairly to the holders.
In order to make this profit-distribution-system work with little changes from the standard and comply with distribution logic, several math operations and mappings are used.
By implementing this standard, wallets will be able to determine if a erc20 token is representing NFT and that means
everywhere that supports the ERC-20 and this proposal(standard) will support fractional NFT tokens.

## Specification
```solidity
pragma solidity ^0.8.0;

/*  

*/
interface FNFT {
  
}
  
```
  
  
