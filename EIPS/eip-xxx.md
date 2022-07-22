---
eip: XXX
title: Light Contract Ownership Standard
description: A standard interface for identifying ownership of contracts
author: William Entriken (@fulldecent)
discussions-to: https://github.com/ethereum/EIPs/issues/XXX
type: Standards Track
category: ERC
status: Draft
created: 2022-07-22
---

## Abstract

This specification defines the minimum interface required to identify an account that controls a contract.

## Motivation

This is a slimmed-down alternative to ERC-173.

## Specification

Every ERC-XXX compliant contract must implement the `ERCXXXX` interface.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title ERC-XXX Light Contract Ownership Standard
interface ERC173 {
    /// @notice Get the address of the owner    
    /// @return The address of the owner
    function owner() view external returns(address);
}
```

## Rationale

Key factors influencing the standard: 

- Minimize the number of functions in the interface
- Backwards compatibility with existing contracts

This standard can be (and has been) extended by other standards to add additional ownership functionality. The smaller scope of this specification allows more and more straightforward ownership implementations, see limitations explained in ERC-173 under "other schemes that were considered".

## Security Considerations

None

## Backwards Compatibility

Every contract that implement ERC-173 already implements this specification.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
