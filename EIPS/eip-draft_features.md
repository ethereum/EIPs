---
title: Contract Feature Detection
description: Standard method to publish and detect contract features that lack an ERC-165 interface
author: raffy.eth (@adraffy)
discussions-to: https://ethereum-magicians.org/t/eip-discussion-contract-feature-detection/24975
status: Draft
type: Informational
created: 2025-07-07
requires: 165
---

## Abstract

Creates a standard method to publish and detect what features a smart contract implements that lack an [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface.

## Motivation

Ethereum Name Service (ENS) has maintained backwards compatibility with contracts created in 2016 through extensive use of ERC-165.  Unfortunately, not all contract capabilities can be expressed through an unique interface.

Features allow expression of contract capabilities that preserve existing interfaces.  This proposal standardizes the concept of features and standardizes the identification (naming) of features.

## Specification

### How Interfaces are Identified

For this standard, a *feature* is any property of a contract that cannot be expressed via ERC-165.

A feature name should be a reverse domain name that uniquely defines its implication, eg. `eth.ens.resolver.extended.multicall` is the multicall feature for an extended ENS resolver contract.

A feature identifier is defined as the first four-bytes of the keccak256-hash of its name, eg. `bytes4(keccak256("eth.ens.resolver.extended.multicall")) = 0x96b62db8`.

### How a Contract will Publish the Interfaces it Implements 

A contract that is compliant with this specification shall implement the following interface:

```solidity
interface IFeatureSupporter {
    /// @notice Check if a feature is supported.
    /// @param featureId The feature identifier.
    /// @return `true` if the feature is supported by the contract.
    function supportsFeature(bytes4 featureId) external view returns (bool);
}
```

The ERC-165 interface identifier for this interface is `0x582de3e7`.

### How to Detect if a Contract Implements Features

1. Check if the contract supports the interface above according to [ERC-165](https://eips.ethereum.org/EIPS/eip-165#how-to-detect-if-a-contract-implements-erc-165).

### How to Detect if a Contract Implements any Given Feature

1. If you are not sure if the contract implements features, use the above procedure to confirm.
1. If it implements features, then call `supportsFeature(feature)` to determine if it implements the desired feature.

Note: a contract that implements features may implement no features.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

## Rationale

Defining a new standard avoids unnecessary pollution of the ERC-165 selector namespace with synthetic interfaces representing features.

## Backwards Compatibility

Callers unaware of features or any specific feature experience no change in behavior.

ENS already implements this EIP.

## Security Considerations

As with ERC-165, declaring support for a feature does not guarantee that the contract implements it.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
