---
eip: 
title: ERC-721 Nonce Extension
description: Add a nonce property to ERC-721 tokens.
author: Anders (@0xanders), Lance (@LanceSnow), Shrug <shrug@emojidao.org>
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2022-04-10
requires: 165, 721
---

## Abstract

This standard is an extension of [ERC-721](./eip-721.md). It proposes adding an `nonce` property to ERC-721 tokens.

## Motivation


## Specification

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY" and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

```solidity
interface IERC721WithNonce  /* is IERC721 */ {

    // Logged when the nonce of a NFT is changed 
    /// @notice Emitted when the `nonce` of an NFT is changed
    event UpdateNonce(uint256 tokenId, uint256 newNonce);

    /// @notice Get the nonce of an NFT
    /// Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to get the nonce for
    /// @return The nonce of this NFT
    function nonce(uint256 tokenId) public view returns(uint256);
}
```

The `nonce(uint256 tokenId)` function MAY be implemented as `pure` or `view`.

The `UpdateNonce` event MUST be emitted when the nonce of a NFT is changed.


## Rationale



## Backwards Compatibility

This standard is compatible with current ERC-721 standards.

## Test Cases


## Reference Implementation

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721WithNonce.sol";

ERC721WithNonce is ERC721, IERC721WithNonce {
     mapping(uint256 => uint256) private tokenNonce;
      
     function nonce(uint256 tokenId) public view returns(uint256) {
        require(_exists(_tokenId), "Error: query for nonexistent token");

        return  tokenNonce[tokenId];
     }

     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        super._beforeTokenTransfer(from,to,tokenId);
        tokenNonce[tokenId]++;
        emit UpdateNonce(tokenId, tokenNonce[tokenId]);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721WithNonce).interfaceId || super.supportsInterface(interfaceId);
    }
     
}
```

## Security Considerations



## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

