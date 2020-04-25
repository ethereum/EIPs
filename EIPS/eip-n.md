---
eip: <to be assigned>
title: Non funglible property standard
author: Kohshi Shiba<kohshi.shiba@gmail.com>
discussions-to: <URL>
status: Draft
type: Standards Track
category : ERC
created: 2020-04-25
requires (*optional): 165 721
---

## Simple Summary
Non fungible property standard enables rental or collateralized lending without escrow.
This is an advanced version of the widely accepted ERC721-Non fungible token standard.

## Abstract
The current ERC721 standard prospers where an item is unique such as digital collectibles or tokenized real world properties. 
Although the standard is showing adoption in the market, its specification, token can only deal with simple ownership in which the owner has full authority over its property and no others can transfer tokens, limits the variety of functions around tokens.

For example, collateralized loans or rental without escrow are activities which can be widely seen in the real world. 
However, these are unavailable with ERC721. 
This EIP proposes a novel token standard that realizes these kinds of utilities with other latest improvement proposals that also aim to improve ERC721. 


## Motivation
The main motivation for this proposal is to make rental and collateralizing possible without any escrow. 

With the current ERC721’s design, an owner of a digital item needs to escrow their token in order to use those services. 
This strain limits the user’s utility while escrow. for example, while escrow, users become unable to use most of the applications that grant some rights to users by reference to the mapping of ownership in the ERC721’s contract.

In the real world, people can take out a loan by collateralizing a house while using the house, or borrow cars while the ownership is still in others' hands. Of course, it is still possible to do those cases with ERC721 by adding additional functions on each application, but it is difficult  to gain interoperability because there is no common standard among the ecosystem, and thus such applications are not prevailing as of today. 

This EIP proposal intends to standardize those kinds of utilities as the non fungible property standard. 

## Specification
### Features

![concept image](../assets/eip-n/concept.png "concept")

The overall structure concept of the architecture is as above.
Like ERC721, there will be many IDs which represent distinctive items.
However, unlike ERC721, in addition to owner right, one ID has user right and lien.

By dividing one ownership to three-layer ownership, each layer may represent mortgagee, owner, lessee respectively in the sense of land or car in the real world. The privilege functions are summarized below.

| Types of right| Lien   | Owner  | User  |
| ------------- |:------:|:------:|:-----:|
| Their right   | Transfer owner and user | Transfer owner and user |Transfer user|

For the usages of each right, it is expected that applications which adopt this standard give the address of the user the right to use the application or the right to receive something from the application. Owner and Lien are expected to be just utility layers of the user.

### Lien and Tenant right
In order to make the standard simple and flexible, yet viable, Only lien and tenant right are introduced to the standard and it is open to external contracts to configure complex functions around those functions 

1)Lien
Lien is set when the owner and the counter party agreed and the external contract called the set function.
After setting, it is required to manage in the external contract about whether the agreement has been broken or not. If the agreement hasn’t been broken, the contract shouldn’t allow activate lien and transfer the ownership.

2)Tenant right
Like lien, after an external contract reaches agreement, both parties interact to set tenant right. 
When tenant right is valid, owner cannot transfer the usership. Once tenant right is set, it is valid regardless of ownership transfer.

### Codes
#### ERC-N Interface
```solidity

  event TransferUser(address indexed from, address indexed to, uint256 indexed itemId, address operator);
  event ApprovalForUser(address indexed user, address indexed approved, uint256 itemId);
  event TransferOwner(address indexed from, address indexed to, uint256 indexed itemId, address operator);
  event ApprovalForOwner(address indexed owner, address indexed approved, uint256 itemId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event LienApproval(address indexed to, uint256 indexed itemId);
  event TenantRightApproval(address indexed to, uint256 indexed itemId);
  event LienSet(address indexed to, uint256 indexed itemId, bool status);
  event TenantRightSet(address indexed to, uint256 indexed itemId,bool status);

  function balanceOfOwner(address owner) public view returns (uint256);
  function balanceOfUser(address user) public view returns (uint256);
  function userOf(uint256 itemId) public view returns (address);
  function ownerOf(uint256 itemId) public view returns (address);

  function safeTransferOwner(address from, address to, uint256 itemId) public;
  function safeTransferOwner(address from, address to, uint256 itemId, bytes memory data) public;
  function safeTransferUser(address from, address to, uint256 itemId) public;
  function safeTransferUser(address from, address to, uint256 itemId, bytes memory data) public;

  function approveForOwner(address to, uint256 itemId) public;
  function getApprovedForOwner(uint256 itemId) public view returns (address);
  function approveForUser(address to, uint256 itemId) public;
  function getApprovedForUser(uint256 itemId) public view returns (address);
  function setApprovalForAll(address operator, bool approved) public;
  function isApprovedForAll(address requester, address operator) public view returns (bool);

  function approveLien(address to, uint256 itemId) public;
  function getApprovedLien(uint256 itemId) public view returns (address);
  function setLien(uint256 itemId) public;
  function getCurrentLien(uint256 itemId) public view returns (address);
  function revokeLien(uint256 itemId) public;

  function approveTenantRight(address to, uint256 itemId) public;
  function getApprovedTenantRight(uint256 itemId) public view returns (address);
  function setTenantRight(uint256 itemId) public;
  function getCurrentTenantRight(uint256 itemId) public view returns (address);
  function revokeTenantRight(uint256 itemId) public;


```

#### ERC-N Receiver
```solidity
  
  function onERCXReceived(address operator, address from, uint256 itemId, uint256 layer, bytes memory data) public returns(bytes4);
  
```

#### ERC-N Extensions
Extensions are introduced to help developers to build and use their application more flexible and easier.
1)  ERC721 Compatible functions

This extension makes ERCX compatible with ERC721. By adding the following functions developers can take advantage of the existing tools for ERC721. Transfer functions in this extension transfer both Owner and User when tenant right has not been set(only ownership can be transferred when tenant right is set)
```solidity
  
  function balanceOf(address owner) public view returns (uint256)
  function ownerOf(uint256 itemId) public view returns (address) 
  function approve(address to, uint256 itemId) public 
  function getApproved(uint256 itemId) public view returns (address)
  function transferFrom(address from, address to, uint256 itemId) public 
  function safeTransferFrom(address from, address to, uint256 itemId) public
  function safeTransferFrom(address from, address to, uint256 itemId, bytes memory data) pubic 
  
```
2)  Enumerable

This extension is analogue to the enumerable extension of the ERC721 standard.

```solidity
  
  function totalNumberOfItems() public view returns (uint256);
  function itemOfOwnerByIndex(address owner, uint256 index, uint256 layer)public view returns (uint256 itemId);
  function itemByIndex(uint256 index) public view returns (uint256);
  
```

3)  Metadata

This extension is analogous to the metadata extension of the ERC721 standard.

```solidity
    
  function itemURI(uint256 itemId) public view returns (string memory);
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  
```

## Rationale
Prior to this propsosal, it seems there have been attempts to implement rental or lending at an application level or just with escrow. However, there are no standard proposal for such functions withour escrow.

Architecture's principles are as follows.
### Simple and flexible 
The standard doesn't handle lending or rental functions directly.
This is because simplicity makes flexible implementation of the standard and opens up further possibilities

### ERC721 compatible and similarity
As mentioned, the standard is fully compatible with ERC721. In addition to that, the manner of function is similar to ERC721.

## Backwards Compatibility
As mentioned in the specifications section, ERC-N can be fully ERC721 compatible by adding an extension function set.
In addition to that, new functions introduced in ERC-N have many similarities to the existing functions in ERC721. Because of that, developers become able to learn and adopt a new standard quickly.

## Test Cases
Test is provided in [the reposotory](https://github.com/kohshiba/ERC-X).
Powered by Truffle and Openzeppelin test helper.

## Implementation
[the reposotory](https://github.com/kohshiba/ERC-X).

## Security Considerations
Since it is expected that lien or tenant right will be controlled by the external contract, flaws within the external contract directly lead to unexpected behavior of the standard.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
