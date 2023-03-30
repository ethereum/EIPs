---
eip: 0000
title: ERC721 Holding Time Tracking
description: Add holding time information to ERC-721 tokens
author: Combo <combo@1combo.io>, Luigi <luigi@1combo.io>, Saitama <saitama@1combo.io>
discussions-to: https://ethereum-magicians.org/t/draft-eip-erc721-holding-time-tracking/13605
status: Draft
type: Standards Track
category: ERC
created: 2023-03-30
requires: 721
---

## Abstract

This standard is an extension of ERC-721. It adds an interface that tracks and describes the holding time of a Non-Fungible Token (NFT) by an account. 

## Motivation

In some use cases, it is valuable to know the duration for which a NFT has been held by an account. This information can be useful for rewarding long-term holders, determining access to exclusive content, or even implementing specific business logic based on holding time. However, the current ERC-721 standard does not have a built-in mechanism to track NFT holding time. Furthermore, in certain scenarios, the holding time should not be reset when an NFT is transferred between accounts, such as during NFT-based staking.

This proposal aims to address these limitations by extending the ERC-721 standard to include holding time tracking functionality and allowing for selective exclusion of transfers from affecting holding time calculations.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

**Interface**

The following interface extends the existing ERC-721 standard:

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0

interface IERC721HoldingTime {
  function getHoldingInfo(uint256 tokenId) external view returns (address holder, uint256 holdingTime);
  function setWhitelistedContract(address whitelistContract, bool ignoreReset) external;
}
```

**Functions**

#### getHoldingInfo

```
function getHoldingInfo(uint256 tokenId) external view returns (address holder, uint256 holdingTime);
```

This function returns the current holder of the specified NFT and the length of time (in seconds) the NFT has been held by the current account.

* `tokenId`: The unique identifier of the NFT.
* Returns: A tuple containing the current holder's address and the holding time (in seconds).
#### setWhitelistedContract

```
function setWhitelistedContract(address whitelistContract, bool ignoreReset) external;
```

This function allows the contract owner or an authorized account to specify whether a specific transfer should be ignored for the purposes of tracking holding time.

* `whitelistContract`: The smart contract address that should be whitelisted for holding time reset exceptions. 
* `ignoreReset`: A boolean value indicating whether the holding time reset should be ignored (`true`) or not (`false`) when transferring to or from the specified whitelistContract. 
## Rationale

The addition of the `getHoldingInfo` and `setWhitelistedContract` functions to an extension of the ERC-721 standard enables developers to implement NFT-based applications that require holding time information and allow for selective transfer exceptions. This extension maintains compatibility with existing ERC-721 implementations while offering additional functionality for new use cases.

The `getHoldingInfo` function provides a straightforward method for retrieving the holding time and holder address of an NFT. By using seconds as the unit of time for holding duration, it ensures precision and compatibility with other time-based functions in smart contracts.

The `setWhitelistedContract` function introduces flexibility in determining which transfers should affect holding time calculations. By allowing the contract owner or authorized accounts to whitelist specific addresses, transfers involving these addresses will not reset the holding time. This is particularly important for NFT-based financial transactions or special cases where holding time should not be affected by transfers.

Together, these functions enhance the utility of the ERC-721 standard, enabling developers to create more sophisticated applications and experiences based on NFT holding time and offering the ability to selectively ignore holding time resets during transfers to or from whitelisted addresses. 

## Backwards Compatibility

This proposal is fully backwards compatible with the existing ERC-721 standard, as it extends the standard with new functions that do not affect the core functionality.

## Reference Implementation 

An implementation of this EIP will be provided upon acceptance of the proposal.

## Security Considerations

This EIP introduces additional state management for tracking holding times and whitelisted addresses, which may have security implications. Implementers should be cautious of potential vulnerabilities related to holding time manipulation and whitelisting management, especially during transfers. Access control measures should be in place to ensure that only authorized accounts can call the `setWhitelistedContract` function.

When implementing this EIP, developers should be mindful of potential attack vectors, such as reentrancy and front-running attacks, as well as general security best practices for smart contracts. Adequate testing and code review should be performed to ensure the safety and correctness of the implementation.

Furthermore, developers should consider the gas costs associated with maintaining and updating holding time information and managing whitelisted addresses. Optimizations may be necessary to minimize the impact on contract execution costs.

It is also important to note that the accuracy of holding time information depends on the accuracy of the underlying blockchain's timestamp. While block timestamps are generally reliable, they can be manipulated by miners to some extent. As a result, holding time data should not be relied upon as a sole source of truth in situations where absolute precision is required.

Lastly, proper management of the whitelisted addresses is crucial to avoid potential abuse. Contract owners should have a clear understanding of the implications of whitelisting addresses and establish a process for adding or removing addresses from the whitelist. Regular monitoring and auditing of the whitelisted addresses can help identify and mitigate potential risks or abuse. 

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).