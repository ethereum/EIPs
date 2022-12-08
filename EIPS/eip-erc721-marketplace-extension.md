---
eip: <to be assigned>
title: Marketplace extension for ERC-721
description: We propose to add a basic marketplace functionality to the ERC721 standard.
author: Silvere Heraudeau (@lambdalf-dev), Martin McConnell (@offgridgecko)
discussions-to: https://ethereum-magicians.org/t/idea-a-marketplace-extension-to-erc721-standard/11975
status: Draft
type: Standards Track
category: ERC
created: 2022-12-02
requires: 721
---

## Simple Summary

"Not your marketplace, not your royalties"

## Abstract

We propose to add a basic marketplace functionality to the EIP-721[./eip-721.md] standard to allow project creators to gain back control of the distribution of their NFTs.

It includes:
- a method to list an item for sale or update an existing listing, whether private sale (only to a specific address) or public (to anyone),
- a method to delist an item that has previously been listed,
- a method to purchase a listed item,
- a method to view all items listed for sale, and
- a method to view a specific listing.

## Motivation

OpenSea’s latest code snippet gives them the ability to entirely control which platform your NFTs can (or cannot) be traded on. Our goal is to give that control back to the project creators.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Implementers of this standard **MUST** have all of the following functions:

```solidity
pragma solidity ^0.8.0;
import './IERC721.sol'

///
/// @dev Interface for the ERC721 Marketplace Extension
///
interface IERC721MarketplaceExtension {
	///
	///	@dev A structure representing a listed token
	///
	/// @param tokenId - the NFT asset being listed
	/// @param tokenPrice - the price the token is being sold for, regardless of currency
	/// @param to - address of who this listing is for, 
	///             can be address zero for a public listing,
	///             or non zero address for a private listing 
	///
	struct Listing {
		uint256 tokenId;
		uint256 tokenPrice;
		address to;
	}
	///
	/// @dev Emitted when a token is listed for sale.
	///
	/// @param tokenId - the NFT asset being listed
	/// @param from - address of who is selling the token
	/// @param to - address of who this listing is for, 
	///             can be address zero for a public listing,
	///             or non zero address for a private listing 
	/// @param price - the price the token is being sold for, regardless of currency
	///
	event Listed( uint256 indexed tokenId, address indexed from, address to, uint256 indexed price );
	///
	/// @dev Emitted when a token that was listed for sale is being delisted
	///
	/// @param tokenId - the NFT asset being delisted
	///
	event Delisted( uint256 indexed tokenId );
	///
	/// @dev Emitted when a token that was listed for sale is being purchased.
	///
	/// @param tokenId - the NFT asset being purchased
	/// @param from - address of who is selling the token
	/// @param to - address of who is buying the token 
	/// @param price - the price the token is being sold for, regardless of currency
	///
	event Purchased( uint256 indexed tokenId, address indexed from, address indexed to, uint256 price );
	///
	/// @dev Lists token `tokenId` for sale.
	///
	/// @param tokenId - the NFT asset being listed
	/// @param to - address of who this listing is for, 
	///             can be address zero for a public listing,
	///             or non zero address for a private listing 
	/// @param price - the price the token is being sold for, regardless of currency
	///
	/// Requirements:
	/// - `tokenId` must exist
	/// - Caller must own `tokenId`
	/// - Must emit a {Listed} event.
	///
	function listItem( uint256 tokenId, uint256 price, address to ) external;
	///
	/// @dev Delists token `tokenId` that was listed for sale
	///
	/// @param tokenId - the NFT asset being delisted
	///
	/// Requirements:
	/// - `tokenId` must exist and be listed for sale
	/// - Caller must own `tokenId`
	/// - Must emit a {Delisted} event.
	///
	function delistItem( uint256 tokenId ) external;
	///
	/// @dev Buys a token and transfers it to the caller.
	///
	/// @param tokenId - the NFT asset being purchased
	///
	/// Requirements:
	/// - `tokenId` must exist and be listed for sale
	/// - Caller must be able to pay the listed price for `tokenId`
	/// - Must emit a {Purchased} event.
	///
	function buyItem( uint256 tokenId ) external payable;
	///
	/// @dev Returns a list of all current listings.
	///
	/// @return the list of all currently listed tokens, 
	///         along with their price and intended recipient
	///
	function getAllListings() external view returns ( Listing[] memory );
	///
	/// @dev Returns the listing for `tokenId`
	///
	///	@return the specified listing (tokenId, price, intended recipient)
	///
	function getListing( uint256 tokenId ) external view returns ( Listing memory );
}
```

## Rationale

## Backwards Compatibility

This standard is compatible with current EIP-721[./eip-721.md] and EIP-2981[./eip-2981.md] standards.

## Reference Implementation

```solidity
pragma solidity ^0.8.0;
import './ERC721.sol';
import './ERC2981.sol';

contract Example is ERC721, ERC2981 {
	struct Listing{
		uint256 tokenid;
		uint256 tokenprice;
		address to;
	}
	event Listed( uint256 indexed tokenId, address indexed from, address to, uint256 indexed price );
	event Delisted( uint256 indexed tokenId );
	event Purchased( uint256 indexed tokenId, address indexed from, address indexed to, uint256 price );

	// list of all sale items by tokenId
	uint256[] private saleItems;

	// mappings are tied to tokenId
	mapping(uint256 => uint256) private tokenPrice;
	mapping(uint256 => bool) private isForSale;
	mapping(uint256 => address) private privateRecipient;

	// listing index location of each listed token
	mapping(uint256 => uint256) private listId;

	uint256 private itemsForSale;

	// INTERNAL
	function _listItem( uint256 tokenId, uint256 price ) internal {
		if ( isForSale[ tokenId ] ) {
			tokenPrice[ tokenId ] = price;
		}
		else {
			tokenPrice[ tokenId ] = price;
			isForSale[ tokenId ] = true;
			saleItems.push( tokenId );
			unchecked {
				++itemsForSale;
			}
		}
	}

	function _delistItem( uint256 tokenId ) internal {
		delete tokenPrice[ tokenId ];
		delete isForSale[ tokenId ];
		delete privateRecipient[ tokenId ];
		unchecked {
			--itemsForSale;
		}

		//update token list
		uint256 tempTokenId = saleItems[ itemsForSale ];
		if ( tempTokenId == tokenId ) {
			saleItems.pop();
		}
		else {
			//record the listId of the token we want to get rid of
			uint256 tempListId = listId[ tokenId ];

			//store the last tokenId from the array into the newly vacant slot
			saleItems[ tempListId ] = tempTokenId;

			//record the new index of said token
			listId[ tempTokenId ] = tempListId;

			//remove the last element from the array
			saleItems.pop();
		}
	}

	function _beforeTokenTransfer( address from, address to, uint256 tokenId ) internal override {
		super._beforeTokenTransfer( from, to, tokenId );

		// if the token is still marked as listed then we need to delist it
		if ( isForSale[ tokenId ] ) {
			_delistItem( tokenId );
		}

		emit Transfer( from, to, tokenId );
	}

	// PUBLIC
	function listItem( uint256 tokenId, uint256 price, address to ) external {
		address tokenOwner = ownerOf( tokenId );
		require( msg.sender == tokenOwner, "Invalid Lister" );
		_listItem( tokenId, price );
		privateRecipient[ tokenId ] = to;
		emit Listed( tokenId, tokenOwner, to, price );
	}

	function delistItem( uint256 tokenId ) external {
		require( isForSale[ tokenId ], "Item not for Sale" );
		require( msg.sender == ownerOf( tokenId ), "Invalid Lister" );
		_delistItem( tokenId );
		emit Delisted( tokenId );
	}

	function buyItem( uint256 tokenId ) external payable {
		require( isForSale[ tokenId ], "Item not for Sale" );
		uint256 totalPrice = tokenPrice[ tokenId ];
		require(msg.value == totalPrice, "Incorrect price");
		( address royaltyRecipient, uint256 royaltyPrice ) = royaltyInfo( tokenId, totalPrice );

		address buyer = msg.sender;
		if ( privateRecipient[ tokenId ] != address( 0 ) ) {
			require( buyer == privateRecipient[ tokenId ], "invalid sale address" );
		}

		address tokenOwner = ownerOf( tokenId );
		_delistItem( tokenId );
		emit Purchased( tokenId, tokenOwner, buyer, totalPrice );

		( bool success, ) = payable( tokenOwner ).call{ value: totalPrice - royaltyPrice }( "" );
		require( success, "Transaction Unsuccessful" );

		if (royalty > 0){
			// Can also be set to payout directly to specified wallet
			// alternately this block can be removed to save gas and 
			// royalties will be stored on the smart contract.
			( success, ) = payable( royaltyRecipient ).call{ value: royaltyPrice }( "" );
			require( success, "Transaction Unsuccessful" );
		}

		_transfer( tokenOwner, buyer, tokenId );
	}

	// VIEW
	function getAllListings() external view returns ( Listing[] memory ) {
		uint256 arraylen = saleItems.length;

		Listing[] memory activeSales = new Listing[]( arraylen );

		for( uint256 i; i < arraylen; ++i ) {
			uint256 tokenId = saleItems[ i ];
			activeSales[ i ].tokenid = tokenId;
			activeSales[ i ].tokenprice = tokenPrice[ tokenId ];
			activeSales[ i ].to = privateRecipient[ tokenId ];
		}

		return activeSales;
	}

	function getListing( uint256 tokenId ) external view returns ( Listing memory ) {
		Listing memory listing = Listing(
			tokenId,
			tokenPrice[ tokenId ],
			privateRecipient[ tokenId ]
		);
		return listing;
	}
}
```

## Security Considerations

There are no security considerations related directly to the implementation of this standard.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
