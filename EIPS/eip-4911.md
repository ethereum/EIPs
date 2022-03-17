---
eip: 4911
title: Composability Extension For ERC-721 Standard
description: An extension of the ERC-721 standard to enable NFT tokens to own other NFT tokens
author: Muhammed Emin Aydın (@muhammedea), Dmitry Savonin (@dmitry123)
discussions-to: https://ethereum-magicians.org/t/erc-4911-composability-extension-for-erc-721-standard/8304
status: Draft
type: Standards Track
category: ERC
created: 2022-02-15
requires: 165, 721
---

# Composability Extension For ERC-721 Standard

## Abstract

This standard outlines a smart contract interface that should be applied to ERC721 contracts to add composability feature.
This extension makes an ERC721 token to be able to own other ERC721 tokens. So there is a parent child relationship.
Child tokens can be from other existing contracts.


## Motivation

NFT composability has been an important topic for especially games. But mostly it is not implemented on-chain. 
For example, attaching wearable NFTs to avatar NFTs. These can be implemented in-game, but in that case it won't be decentralized.
Making it on-chain as a generalized feature requires some standardization. 


## Specification

This specification defines an interface called **ERC721Parent** for ERC-721 contracts. 
This interface makes an NFT contract, a parent contract. ERC721Parent contract will have slots for composing other tokens.
This interface requires ERC721Receiver interface to be implemented. Because child tokens will be held by the parent contract.

### Slots

Parent child relationships are defined as slots in the contract. A parent contract can have multiple slots.
Every slot has these properties.
* slotId (uint256): Can be created as a hash of slot properties (sha3( childContract + max + name ))
* childContract (address): Address of the child contract
* max (uint256): maximum number of child tokens in this slot
* name (string): name of the slot


### Interface

```solidity
pragma solidity ^0.8.0;

/**
    @title ERC-721 Parent
 */
interface ERC721Parent /* is ERC165, ERC721Receiver */ {
    /**
        @dev This event will be emitted when new Child Slot created
        The _slotId argument MUST be an id that identifies the slot. Ex: sha3(childContract + max + name)
        The _childContract argument MUST be the address of the child contract
        The _max argument MUST be the maximum number of child tokens
        The _name argument MUST be name information for the slot. This will be stored only in the event.
    */
    event ChildSlotAdded(uint256 _slotId, address _childContract, uint256 _max, string _name);

    /**
        @dev This event will be emitted when a child token attached to a parent
        The _slotId argument MUST be the id of the slot that the child token is attached
        The _owner argument MUST be the owner of the parent token when this event happens
        The _parentId argument MUST be the id of parent token
        The _childId argument MUST be the id of child token from the child contract
    */
    event ChildAttached(uint256 indexed _slotId, address indexed _owner, uint256 indexed _parentId, uint256 indexed _childId);

    /**
        @dev This event will be emitted when a child token removed from parent
        The _slotId argument MUST be the id of the slot that the child token has removed from
        The _owner argument MUST be the owner of the parent token when this event happens
        The _parentId argument MUST be the id of parent token
        The _childId argument MUST be the id of child token from child contract
    */
    event ChildRemoved(uint256 indexed _slotId, address indexed _owner, uint256 indexed _parentId, uint256 indexed _childId);


    /**
        @notice addChildSlot
        @dev  Add new slot for attaching child tokens
        @param name : Name of the slot
        @param childContract : address of the child contract
        @param max : maximum number of items in this slot for a single parent token
    */
    function addChildSlot(string memory name,  address childContract, uint256 max) external returns(uint256);

    /**
        @notice attachChildToParent
        @dev Attaches a child token to a parent token by using the specified slot. msg.sender should be the owner of the parent. 
             Child token should be owned by or approved for msg.sender. Child token will be transferred to the parent contract.
        @param slotId : which slot the child token will be attached
        @param parentId : parent token id
        @param childId : child token id
    */
    function attachChildToParent(uint256 slotId, uint256 parentId, uint256 childId) external;

    /**
        @notice removeChildFromParent
        @dev Removes a child token from a parent token for the specified slot. Child Token will be transferred to the owner of the parent token
        @param slotId : which slot the child token will be removed from
        @param parentId : parent token id
        @param childId : child token id
    */
    function removeChildFromParent(uint256 slotId, uint256 parentId, uint256 childId) external;

    /**
        @notice swapChildForParent
        @dev Removes a child token from the parent and sends that token to the owner of the parent token. 
             Attaches the new child token to the parent and child token will be transferred to the parent contract.
             msg.sender should be the owner of the parent. 
             New Child token should be owned by or approved for msg.sender.
        @param slotId : For which slot swap action will be handled
        @param parentId : parent token id
        @param oldChildId : id of old child token
        @param newChildId : id of new child token
    */
    function swapChildForParent(uint256 slotId, uint256 parentId, uint256 oldChildId, uint256 newChildId) external;

    /**
        @notice transferChild
        @dev This will move a child token to a different parent token and a different slot.
             Old and new slots should be defined for the same child contract
        @param childId : child id to be transferred
        @param oldSlotId : old slot id that the child will be removed from
        @param oldParentId : old parent id that the child belongs to
        @param newSlotId : new slot id for the child
        @param newParentId : new parent id for the child
    */
    function transferChild(uint256 childId, uint256 oldSlotId, uint256 oldParentId, uint256 newSlotId, uint256 newParentId) external;

    /**
        @notice getChildTokens
        @dev This function gives child token ids for a given parent id and slot.
        @param slotId : slot id that the child tokens are attached
        @param parentId : the parent token id
    */
    function getChildTokens(uint256 slotId, uint256 parentId) external returns(uint256[]);
}


```

## Security Considerations
In this standard, every child token will be stored on the parent contract. So parent contract should be ERC721Receiver.

Attach actions requires approval from child token contracts to the parent contract.

Given checks for every function should be implemented.


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).