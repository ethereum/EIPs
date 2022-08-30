---
eip: <to be assigned>
title: Redeemable
description: Redeemable NFT Extension
author: Olivier Fernandez (@fernandezOli), Frédéric Le Coidic (@FredLC29), Julien Béranger (@julienbrg)
discussions-to: [https://ethereum-magicians.org/t/eip-redeemable-nft-extension/10589](https://ethereum-magicians.org/t/eip-redeemable-nft-extension/10589)
status: Draft
type: Standards Track
category: ERC
created: 2022-08-30
requires: [165](https://eips.ethereum.org/EIPS/eip-165), [721](https://eips.ethereum.org/EIPS/eip-721)
---

## Simple Summary

A standardized way to link a physical object to an NFT.

## Abstract

The Redeemable NFT Extension adds a `redeem` function to the ERC-721. It can be implemented when an NFT issuer wants his/her NFT to be redeemed for a physical object.

## Motivation

As of now, one can't link a physical object to an NFT. This standard allows NFTs that support ERC-721 interfaces to have a standardized way of signalling information on reedemability and verify if the NFT was redeemed or not.

More and more NFT issuers such as artists, fine art galeries, auction houses, brands and others want to offer a physical object to the holder of a given NFT.

Enabling everyone to unify on a single redeemable NFT standard will benefit the entire Ethereum ecosystem.

## Specification

_The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119._

**ERC-721 compliant contracts MAY implement this ERC to provide a standard method of receiving information on redeemability.**

The NFT issuer **MUST** decide who is allowed to redeem the NFT, and restrict access to the `redeem()` function accordingly.

Anyone **MAY** access the `isRedeemable()` function to check the redeemability status: it returns `true` when the NFT redeemable, and `false` when already redeemed.

Third-party services that support this standard **MAY** use the `Redeem` event to listen to changes on the redeemable status of the NFT.

Implementers of this standard **MUST** have all of the following functions:

```solidity
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of Redeemable for ERC-721s
 *
 */

interface IRedeemable is ERC165 {
	/*
	 * ERC165 bytes to add to interface array - set in parent contract implementing this standard
	 *
	 * bytes4 private constant _INTERFACE_ID_ERC721REDEEM = 0x2f8ca953;
	 */

	/// @notice Returns the redeem status of a token
	/// @param tokenId Identifier of the token.
	function isRedeemable(uint256 _tokenId) external view returns (bool);

	/// @notice Redeeem a token
	/// @param tokenId Identifier of the token to redeeem
	function redeem(uint256 _tokenId) external;
}
```

The `Redeem` event is emitted when the `redeem()` function is called.

The `supportsInterface` method **MUST** return `true` when called with `0x2f8ca953`.

## Rationale

When the NFT contract is deployed, the `isRedeemable()` function returns `true` by default.

By default, the `redeem()` function visibility is public, so anyone can trigger it. It is **RECOMMENDED** to add a `require` to restrict the access:

```solidity
require(ownerOf(tokenId) == msg.sender, "ERC721Redeemable: You are not the owner of this token");
```

After the `redeem()` function is triggered, `isRedeemable()` function returns `false`.

### `Redeem` event

When the `redeem()` function is triggered, the following event is emitted:

```solidity
event Redeem(address indexed from, uint256 indexed tokenId);
```

## Backwards Compatibility

This standard is compatible with current ERC-721 standard.

## Reference Implementation

Here's an example of an ERC-721 that includes the Redeemable extension:

```solidity
contract ERC721Redeemable is ERC721, Redeemable {

	constructor(string memory name, string memory symbol) ERC721(name, symbol) {
	}

	function isRedeemable(uint256 tokenId) public view virtual override returns (bool) {
		require(_exists(tokenId), "ERC721Redeemable: Redeem query for nonexistent token");
		return super.isRedeemable(tokenId);
	}

	function redeem(uint256 tokenId) public virtual override {
		require(_exists(tokenId), "ERC721Redeemable: Redeem query for nonexistent token");
		require(ownerOf(tokenId) == msg.sender, "ERC721Redeemable: You are not the owner of this token");
		super.redeem(tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721, Redeemable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
```

## Security Considerations

There are no security considerations directly related to the implementation of this standard.

## Copyright

Copyright and related rights waived via [GPL-3.0](https://choosealicense.com/licenses/gpl-3.0/).
