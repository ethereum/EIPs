---
eip: xxxx
title: EIP-1155 Non Fungible Token extension
description: Allow EIP-1155 to represent Non Fungible Tokens (token who have a unique owner)
author: Ronan Sandford (@wighawag)
discussions-to: https://ethereum-magicians.org/t/eip-1155-ownerof
status: Draft
type: Standards Track
category: ERC
created: 2022-07-23
requires: 165, 1155
---

## Abstract

This standard is an extension of [EIP-1155](./eip-1155.md). It proposes an additional function, `ownerOf` to allow EIP-1155 to support Non Fungible Token (token who have a unique owner). By implementing this extra function, EIP-1155 can benefit from EIP-721 core functionality without the need to implement the full (and less efficient) EIP-721 spec in the same contract. In particular, this extension allow EIP-1155 token of supply one to have an owner and have it exposed.

## Motivation

Currently, EIP-1155 do not allow external caller to detect whether a token is truly unique (can have only one owner) or fungible. This is because EIP-1155 do not expose a mechanism to detect whether a token will have its supply remain to be "1". Furthermore, it does not let an external caller to retrieve the owner directly onchain.

The EIP-1155 spec does mention the use of splitted id to represent non fungible tokens but this require a pre-established convention which is not part of the standard. Plus it would not be as fully featured as the `ownerOf` function also present in the EIP-721 standard.

The ability to get the owner of a token offer great benefit, including the ability for the owner to associate data to it.

## Specification

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY" and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.


### Contract Interface

```solidity
interface IERC1155OwnerOf {

    /// @notice Find the owner of an NFT
    /// @dev The zero address indicates that there is no owner: either the token do not exist or it is not an NFT (supply potentially bigger than 1)
    /// @param tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 tokenId) external view returns (address);
}
```

The `ownerOf(uint256 tokenId)` function MAY be implemented as `pure` or `view`.

The `supportsInterface` method MUST return `true` when called with `0x6352211e`.

## Rationale

Having the ability to fetch the owner for EIP-1155 token that have one, allow to use them in most of the EIP-721 ecosystem, without the need to implement the whole EIP-721 spec which comes with inefficiencies.

`ownerOf` do not throw when a token does not exist (or does not have owner). This simplify the handling of such case. And since it would be a security risk to assume all ERC721 implementation would throw, it should not break compatibility with contract handling ERC721 when dealing with this ERC1155 extension.


## Backwards Compatibility

It is fully backward compatible with ERC1155.

As for ERC721, There is no intention to support ERC721 here, but the use of the same function `ownerOf` should allow many application tied to ERC721 to be compatible with ERC1155. Not all though.

## Reference Implementation


## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).

