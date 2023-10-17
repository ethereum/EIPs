---
eip: 6381
title: Emotable Extension for Non-Fungible Tokens
description: React to Non-Fungible Tokens using Unicode emojis.
author: Bruno Škvorc (@Swader), Steven Pineda (@steven2308), Stevan Bogosavljevic (@stevyhacker), Jan Turk (@ThunderDeliverer)
discussions-to: https://ethereum-magicians.org/t/eip-6381-emotable-extension-for-non-fungible-tokens/12710
status: Review
type: Standards Track
category: ERC
created: 2023-01-22
requires: 165, 721
---

## Abstract

The Emotable Extension for Non-Fungible Tokens standard extends [ERC-721](./eip-721.md) by allowing NFTs to be emoted at.

This proposal introduces the ability to react to NFTs using Unicode standardized emoji.

## Motivation

With NFTs being a widespread form of tokens in the Ethereum ecosystem and being used for a variety of use cases, it is time to standardize additional utility for them. Having the ability for anyone to interact with an NFT introduces an interactive aspect to owning an NFT and unlocks feedback-based NFT mechanics.


This ERC introduces new utilities for [ERC-721](./eip-721.md) based tokens in the following areas:


- [Interactivity](#interactivity)
- [Feedback based evolution](#feedback-based-evolution)
- [Valuation](#valuation)

### Interactivity

The ability to emote on an NFT introduces the aspect of interactivity to owning an NFT. This can either reflect the admiration for the emoter (person emoting to an NFT) or can be a result of a certain action performed by the token's owner. Accumulating emotes on a token can increase its uniqueness and/or value.

### Feedback based evolution

Standardized on-chain reactions to NFTs allow for feedback based evolution.

Current solutions are either proprietary or off-chain and therefore subject to manipulation and distrust. Having the ability to track the interaction on-chain allows for trust and objective evaluation of a given token. Designing the tokens to evolve when certain emote thresholds are met incentivizes interaction with the token collection.

### Valuation

Current NFT market heavily relies on previous values the token has been sold for, the lowest price of the listed token and the scarcity data provided by the marketplace. There is no real time indication of admiration or desirability of a specific token. Having the ability for users to emote to the tokens adds the possibility of potential buyers and sellers gauging the value of the token based on the impressions the token has collected.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

```solidity
/// @title EIP-6381 Emotable Extension for Non-Fungible Tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-6381
/// @dev Note: the ERC-165 identifier for this interface is 0x580d1840.

pragma solidity ^0.8.16;

interface IEmotable is IERC165 {
    /**
     * @notice Used to notify listeners that the token with the specified ID has been emoted to or that the reaction has been revoked.
     * @dev The event SHOULD only be emitted if the state of the emote is changed.
     * @param emoter Address of the account that emoted or revoked the reaction to the token
     * @param tokenId ID of the token
     * @param emoji Unicode identifier of the emoji
     * @param on Boolean value signifying whether the token was emoted to (`true`) or if the reaction has been revoked (`false`)
     */
    event Emoted(
        address indexed emoter,
        uint256 indexed tokenId,
        bytes4 emoji,
        bool on
    );

    /**
     * @notice Used to get the number of emotes for a specific emoji on a token.
     * @param tokenId ID of the token to check for emoji count
     * @param emoji Unicode identifier of the emoji
     * @return Number of emotes with the emoji on the token
     */
    function emoteCountOf(
        uint256 tokenId,
        bytes4 emoji
    ) external view returns (uint256);

    /**
     * @notice Used to emote or undo an emote on a token.
     * @dev Does nothing if attempting to set a pre-existent state.
     * @dev When the state is being changed, the Emoted event MUST be emitted.
     * @param tokenId ID of the token being emoted
     * @param emoji Unicode identifier of the emoji
     * @param state Boolean value signifying whether to emote (`true`) or undo (`false`) emote
     */
    function emote(uint256 tokenId, bytes4 emoji, bool state) external;
}
```

## Rationale

Designing the proposal, we considered the following questions:

1. **Does the proposal support custom emotes or only the Unicode specified ones?**\
The proposal only accepts the Unicode identifier which is a `bytes4` value. This means that while we encourage implementers to add the reactions using standardized emojis, the values not covered by the Unicode standard can be used for custom emotes. The only drawback being that the interface displaying the reactions will have to know what kind of image to render and such additions will probably be limited to the interface or marketplace in which they were made.
2. **Should the proposal use emojis to relay the impressions of NFTs or some other method?**\
The impressions could have been done using user-supplied strings or numeric values, yet we decided to use emojis since they are a well established mean of relaying impressions and emotions.

## Backwards Compatibility

The Emotable token standard is fully compatible with [ERC-721](./eip-721.md) and with the robust tooling available for implementations of ERC-721 as well as with the existing ERC-721 infrastructure.

## Test Cases

Tests are included in [`emotable.ts`](../assets/eip-6381/test/emotable.ts).

To run them in terminal, you can use the following commands:

```
cd ../assets/eip-6381
npm install
npx hardhat test
```

## Reference Implementation

See [`Emotable.sol`](../assets/eip-6381/contracts/Emotable.sol).

## Security Considerations

The same security considerations as with [ERC-721](./eip-721.md) apply: hidden logic may be present in any of the functions, including burn, add asset, accept asset, and more.

Caution is advised when dealing with non-audited contracts.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
