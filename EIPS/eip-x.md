---
eip: x
title: Minimalistic Souldbound interface for NFTs
description: An interface for Soulbound Non-Fungible Tokens extension allowing for tokens to be non-transferrable.
author: Bruno Škvorc (@Swader), Francesco Sullo(@sullof), Steven Pineda (@steven2308), Stevan Bogosavljevic (@stevyhacker), Jan Turk (@ThunderDeliverer)
discussions-to: x
status: Draft
type: Standards Track
category: ERC
created: 2023-01-31
requires: 165, 721
---

## Abstract

The Minimalistic Souldbound interface for Non-Fungible Tokens standard extends [EIP-721](./eip-721.md) by preventing NFTs to be transferred.

This proposal introduces the ability to prevent a token to be transferred from their owner, making them bound to the externally owned account, smart contract or token that owns it.

## Motivation

With NFTs being a widespread form of tokens in the Ethereum ecosystem and being used for a variety of use cases, it is time to standardize additional utility for them. Having the ability to prevent the tokens to be transferred introduces new possibilities of NFT utility and evolution.

This proposal is designed in a way to be as minimal as possible in order to be compatible with any usecases that wish to utilize this proposal.

This EIP introduces new utilities for [EIP-721](./eip-721.md) based tokens in the following areas:

- [Foo](#foo)

### Foo

The ability to prevent the tokens to be transferred

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

```solidity
/// @title EIP-x Minimalistic Souldbound interface for NFTs
/// @dev See https://eips.ethereum.org/EIPS/eip-x
/// @dev Note: the ERC-165 identifier for this interface is 0x0.

pragma solidity ^0.8.16;

interface IERCx is IERC165 {
    /**
     * @notice Used to check whether the given token is soulbound or not.
     * @param tokenId ID of the token being checked
     * @return Boolean value indicating whether the given token is soulbound
     */
    function isSoulbound(uint256 tokenId) external view returns (bool);
}
```

## Rationale

Designing the proposal, we considered the following questions:

## Backwards Compatibility

The Emotable token standard is fully compatible with [EIP-721](./epi-721.md) and with the robust tooling available for implementations of EIP-721 as well as with the existing EIP-721 infrastructure.

## Test Cases

Tests are included in [`soulbound.ts`](../assets/eip-x/test/soulbound.ts).

To run them in terminal, you can use the following commands:

```
cd ../assets/eip-x
npm install
npx hardhat test
```

## Reference Implementation

See [`Soulbound.sol`](../assets/eip-x/contracts/Soulbound.sol).

## Security Considerations

The same security considerations as with [EIP-721](./eip-721.md) apply: hidden logic may be present in any of the functions, including burn, add asset, accept asset, and more.

Caution is advised when dealing with non-audited contracts.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
