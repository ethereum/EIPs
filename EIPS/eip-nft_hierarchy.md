---
eip: <TBA>
title: Cross-Contract Hierarchical NFT
description: An extension of ERC-721 to maintain hierarchical relationship between tokens from different contracts.
author: Ming Jiang (@minkyn), Zheng Han (@hanbsd), Fan Yang (@fayang)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-08-24
requires: 721
---

## Abstract

This standard is an extension of [ERC-721](./eip-721.md). It proposes a way to maintain hierarchical relationship between tokens from different contracts. This standard provides an interface to query the parent tokens of an NFT or whether the parent relation exists between two NFTs.

## Motivation

Some NFTs want to generate derivative assets as new NFTs. For example, a 2D NFT image would like to publish its 3D model as a new derivative NFT. An NFT may also be derived from multiple parent NFTs. Such cases include a movie NFT featuring multiple characters from other NFTs. This standard is proposed to record such hierarchical relationship between derivative NFTs.

Existing [ERC-6150](./eip-6150.md) introduces a similar feature, but it only builds hierarchy between tokens within the same contract. More than often we need to create a new NFT collection with the derivative tokens. Therefore the cross-contract relationship establishment is required.

## Specification

```solidity
/// @notice The struct used to reference a token in an NFT contract
struct Token {
    address collection;
    uint256 id;
}

interface IDerivable {

    /// @notice Emitted when the parent tokens for an NFT is updated
    event UpdateParentTokens(uint256 indexed tokenId);

    /// @notice Get the parent tokens of an NFT
    /// @param tokenId The NFT to get the parent tokens for
    /// @return An array of parent tokens for this NFT
    function parentTokensOf(uint256 tokenId) external view returns (Token[] memory);

    /// @notice Check if another token is a parent of an NFT
    /// @param tokenId The NFT to check its parent for
    /// @param otherToken Another token to check as a parent or not
    /// @return Whether `otherToken` is a parent of `tokenId`
    function isParentToken(uint256 tokenId, Token memory otherToken) external view returns (bool);

}
```

## Rationale

This standard differs from [ERC-6150](./eip-6150.md) in mainly two aspects: supporting cross-contract token reference, and allowing multiple parents. But we try to keep the naming consistent overall.

In addition, we didn't include `child` relation in the interface. An original NFT exists before its derivative NFTs. Therefore we know what parent tokens to include when minting derivative NFTs, but we wouldn't know the children tokens when minting the original NFT. If we have to record the children, that means whenever we mint a derivative NFT, we need to call on its original NFT to add it as a child. However, those two NFTs may belong to different contracts and thus require different write permissions, making it impossible to combine the two operations into a single transaction in practice. As a result, we decide to only record the `parent` relation from the derivative NFTs.

## Backwards Compatibility

No backwards compatibility issues found.

## Test Cases

Test cases available in the repository: [comoco-labs/laicense-contracts](https://github.com/comoco-labs/laicense-contracts)

## Reference Implementation

Reference implementation available in the repository: [comoco-labs/laicense-contracts](https://github.com/comoco-labs/laicense-contracts)

## Security Considerations

No security considerations found.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
