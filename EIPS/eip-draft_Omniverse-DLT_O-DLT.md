---
eip: <to be assigned>
title: Omniverse-DLT(O-DLT for short)
description: The Omniverse DLT is a new application-level token features built over multiple existing L1 public chains, enabling asset-related operations such as transfers and receptions running over different consensus spaces synchronously and equivalently.
author: Shawn Zheng(@xiyu1984), Jason Cheng(chengjingxx@gmail.com), George Huang(@virgil2019), Kay Lin(@kay404)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-01-17
requires (*optional): <EIP number(s)>
---

## Abstract

The **Omniverse DLT**(O-DLT for short) is a new application-level token features built **over** multiple existing L1 public chains, enabling asset-related operations such as transfers and receptions running over different consensus spaces **synchronously** and **equivalently**.  
The core meaning of Omniverse is that the ***legitimacy of all on-chain states and operations can be equivalently verified and recorded simultaneously over different consensus spaces, regardless of where they were initiated.***  
O-DLT works at an application level, which means everything related is processed in smart contracts or similar mechanisms, just as the ERC20/ERC721 did.  

## Motivation

For projects serving multiple chains, it is definitely useful that the token is able to be accessed anywhere.   
This idea came to us as we are building an infrastructure to help smart contracts deployed on different blockchains work together.  
When coming to the token part, however, we do not believe that the asset-bridge paradigm is enough.  
- We want our token to be treated as a whole instead of being divided into different parts on different public chains. O-DLT can get it.
- When one chain breaks down, we don't want users to lose assets along with it. Assets-bridge paradigm cannot provide a guarantee for this. O-DLT can provide this guarantee even if there's only one chain that works.  
- Not just for a concrete token, we think the Omniverse Token might be useful for other projects on Ethereum and other chains. O-DLT is actually a new kind of asset paradigm at the application level. 

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Omniverse Account
The Omniverse account is expressed as a public key created by the elliptic curve `secp256k1`, which has already been supported by Ethereum tech stacks. For those who don’t support secp256k1 or have a different address system, a mapping mechanism is needed.  

### Data Structure
Firstly, we defined the omniverse transaction data as follows:  
- For Fungible Tokens
    ```solidity
    /**
    * @dev Omniverse transaction data structure, different `op` indicates different type of omniverse transaction
    * @Member nonce: The serial number of an o-transactions sent from an Omniverse Account. If the current nonce of an o-account is k, the valid nonce in the next o-transaction is k+1. 
    * @Member chainId: The chain where the o-transaction is initiated
    * @Member initiator: The contract address from which the o-transaction is initiated
    * @Member from: The Omniverse account which signs the o-transaction
    * @Member op: The operation type. NOTE op: 0-31 are reserved values, 32-255 are custom values
    *             op: 0 Transfers omniverse token `amount` from user `from` to user `data`, `from` MUST have at least `amount` token
    *             op: 1 User `from` mints token `amount` to user `data`
    *             op: 2 User `from` burns token `amount` from user `data`
    * @Member data: The operation data. This sector could be empty and is determined by `op`
    * @Member amount: The amount of token which is operated
    * 
    * @Member signature: The signature of the above informations. 
    *                    Firstly, the above sectors are combined as 
    *                    `bytes memory rawData = abi.encodePacked(uint128(_data.nonce), _data.chainId, _data.initiator, _data.from, _data.op, _data.data, uint128(_data.amount));`
    *                    The it is hashed by `keccak256(rawData)`
    *                    The signature is to the hashed value.
    * 
    */
    struct OmniverseTransactionData {
        uint256 nonce;
        uint32 chainId;
        bytes initiator;
        bytes from;
        uint8 op;
        bytes data;
        uint256 amount;
        bytes signature;
    }
    ```
- For Non-Fungible Tokens
    ```solidity
    /**
    * @dev Omniverse transaction data structure, different `op` indicates different type of omniverse transaction
    * @Member nonce: The serial number of an o-transactions sent from an Omniverse Account. If the current nonce of an o-account is k, the valid nonce in the next o-transaction is k+1. 
    * @Member chainId: The chain where the o-transaction is initiated
    * @Member initiator: The contract address from which the o-transaction is initiated
    * @Member from: The Omniverse account which signs the o-transaction
    * @Member op: The operation type. NOTE op: 0-31 are reserved values, 32-255 are custom values
    *             op: 0 Transfers omniverse token `tokenId` from user `from` to user `data`, the token `tokenId` MUST be owned by `from`
    *             op: 1 User `from` mints token `tokenId` to user `data`
    *             op: 2 User `from` burns token `tokenId` from user `data`
    * @Member data: The operation data. This sector could be empty and is determined by `op`
    * @Member tokenId: the token id
    * 
    * @Member signature: The signature of the above informations
    *                    Firstly, the above sectors are combined as 
    *                    `bytes memory rawData = abi.encodePacked(uint128(_data.nonce), _data.chainId, _data.initiator, _data.from, _data.op, _data.data, uint128(_data.tokenId));`
    *                    The it is hashed by `keccak256(rawData)`
    *                    The signature is to the hashed value.
    */
    struct OmniverseTransactionData {
        uint256 nonce;
        uint32 chainId;
        bytes initiator;
        bytes from;
        uint8 op;
        bytes data;
        uint256 tokenId;
        bytes signature;
    }
    ```

## Rationale

The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

## Backwards Compatibility

All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases

Test cases for an implementation are mandatory for EIPs that are affecting consensus changes.  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Reference Implementation

An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Security Considerations

All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
