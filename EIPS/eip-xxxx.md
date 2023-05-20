---
eip: xxxx
title: NFT Creator Provenance
description: An ERC-721 or ERC-1155 extension explicitly defiining creator provenance.
author: Shawn Price (@sprice)
discussions-to: https://ethereum-magicians.org/t/nft-creator-provenance-standard/14259
status: Draft
type: Standards Track
category: ERC
created: 2023-05-20
requires: 165, 721, 1155
---

## Abstract

This proposal aims to allows contracts, such as NFTs that support [ERC-721](./eip-721.md) and [ERC-1155](./eip-721.md) interfaces, to explicitly signal the creator a particular NFT.

## Motivation

Today’s NFT marketplaces, galleries, and platforms implicitly assume the creator based on the address of the contract deployer or the EOA address that mints the NFT. This lack of consistency creates confusion among consumers viewing the same NFT on different marketplaces or platforms. It also creates frustration among creators. This proposal allows a creator to explicitly prove their authorship of one or more NFTs on an NFT smart contract.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

**Every ERC-xxxx compliant contract must implement the `ERC165` and `ERC721` or `ERC1155` interfaces**

```solidity

interface IERCxxxx is IERC165 {
    function provenanceTokenInfo(
        uint256 _tokenId
    ) external view returns (address, bool);

    function verifyTokenProvenance(
        uint256 tokenId
    ) external;
}


interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
```

## Examples

```solidity
abstract contract ERCxxxx is IERCxxxx {
    struct Creator {
        address creator;
        bool isVerified;
    }

    mapping(uint256 => Creator) private _tokenCreators;

    function provenanceTokenInfo(
        uint256 tokenId
    ) public view returns (address, bool) {
        Creator memory creator = _tokenCreators[tokenId];
        return (creator.creator, creator.isVerified);
    }

    function verifyTokenProvenance(uint256 tokenId) public {
        require(
            msg.sender == _tokenCreators[tokenId].creator,
            "CreatorProvenance: not creator"
        );
        _tokenCreators[tokenId].isVerified = true;
    }

    /**
     * @dev Sets the creator information for a specific token id.
     *
     * Requirements:
     *
     * - `creator` cannot include a zero address.
     */
    function _setTokenCreator(
        uint256 tokenId,
        address creator
    ) internal virtual {
        require(creator != address(0), "CreatorProvenance: invalid creator");

        _tokenCreators[tokenId] = Creator(creator, false);
    }

    /**
     * @dev Deletes creator information for the specified token.
     */
    function _deleteTokenProvenance(uint256 tokenId) internal virtual {
        delete _tokenCreators[tokenId];
    }
}
```

## Rationale

### Contract Owner Creator Assignment

An NFT contract may be written to allow a particular role or the contract owner to specify the creator address for a particular NFT `tokenId`.

### Creator Approval

An NFT contract may be written to allow `verifyTokenProvenance` to be called while checking that only the Contract Owner approved creator address may successfully call this function for a given `tokenId`.

## Backwards Compatibility

This standard is compatible with current ERC-721 and ERC-1155 standards.

## Security Considerations

There are no security considerations related directly to the implementation of this standard.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
