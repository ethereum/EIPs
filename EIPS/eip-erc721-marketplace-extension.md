---
eip: erc721-marketplace-extension
title: Marketplace extension for EIP-721
description: We propose to add a basic marketplace functionality to the EIP-721.
author: Silvere Heraudeau (@lambdalf-dev), Martin McConnell (@offgridgecko)
discussions-to: https://ethereum-magicians.org/t/idea-a-marketplace-extension-to-erc721-standard/11975
status: Draft
type: Standards Track
category: ERC
created: 2022-12-02
requires: 721
---

"Not your marketplace, not your royalties"

## Abstract

We propose to add a basic marketplace functionality to the [EIP-721](./eip-721.md)
to allow project creators to gain back control of the distribution of their NFTs.

It includes:
- a method to list an item for sale or update an existing listing, whether
  private sale (only to a specific address) or public (to anyone),
- a method to delist an item that has previously been listed,
- a method to purchase a listed item,
- a method to view all items listed for sale, and
- a method to view a specific listing.

## Motivation

OpenSea’s latest code snippet gives them the ability to entirely control which
platform your NFTs can (or cannot) be traded on. Our goal is to give that
control back to the project creators.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY",
and "OPTIONAL" in this document are to be interpreted as described in RFC 2119
and RFC 8174.

Implementers of this standard **MUST** have all of the following functions:

```solidity
pragma solidity ^0.8.0;
import './IERC721.sol'

///
/// @dev Interface for the ERC721 Marketplace Extension
///
interface IERC721MarketplaceExtension {
  ///
  /// @dev A structure representing a listed token
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
  /// @return the specified listing (tokenId, price, intended recipient)
  ///
  function getListing( uint256 tokenId ) external view returns ( Listing memory );
}
```

## Rationale

## Backwards Compatibility

This standard is compatible with current [EIP-721](./eip-721.md) and [EIP-2981](./eip-2981.md) standards.

## Reference Implementation

```solidity
pragma solidity ^0.8.0;
import './ERC721.sol';
import './ERC2981.sol';

contract Example is IERC721MarketplaceExtension, ERC721, ERC2981 {
  // List of all items for sale
  Listing[] private _listings;

  // Mapping from token ID to sale status
  mapping( uint256 => bool ) private _isForSale;

  // Mapping from token ID to listing index
  mapping( uint256 => uint256 ) private _listingIndex;

  // INTERNAL
  /**
  * @dev Create or update a listing for `tokenId_`.
  * 
  * Note: Setting `buyer_` to the NULL address will create a public listing.
  * 
  * @param tokenId_    : identifier of the token being listed
  * @param price_      : the sale price of the token being listed
  * @param tokenOwner_ : current owner of the token
  * @param buyer_      : optional address the token is being sold too
  */
  function _listItem( uint256 tokenId_, uint256 price_, address tokenOwner_, address buyer_ ) internal {
    // Update existing listing or create a new listing
    if ( _isForSale[ tokenId_ ] ) {
      _listings[ _listingIndex[ tokenId_ ] ].tokenprice = price_;
      _listings[ _listingIndex[ tokenId_ ] ].to = buyer_;
    }
    else {
      Listing memory _listing_ = Listing( tokenId_, price_, buyer_ );
      _listings.push( _listing_ );
    }
    emit Listed( tokenId_, expiry_, tokenOwner_, price_ );
  }

  /**
  * @dev Removes the listing for `tokenId_`.
  * 
  * @param tokenId_ : identifier of the token being listed
  */
  function _removeListing( uint256 tokenId_ ) internal {
    uint256 _len_ = _listings.length;
    uint256 _index_ = _listingIndex[ tokenId_ ];
    if ( _index_ + 1 != _len_ ) {
      _listings[ _index_ ] = _listings[ _len_ - 1 ];
    }
    _listings.pop();
  }

  /**
  * @dev Processes an ether of `amount_` payment to `recipient_`.
  * 
  * @param amount_    : the amount to send
  * @param recipient_ : the payment recipient
  */
  function _processEthPayment( uint256 amount_, address recipient_ ) internal {
    ( boold _success_, ) = payable( recipient_ ).call{ value: amount_ }( "" );
    require( success, "Ether Transfer Fail" );
  }

  /**
  * @dev Transfers `tokenId_` from `fromAddress_` to `toAddress_`.
  *
  * This internal function can be used to implement alternative mechanisms to perform 
  * token transfer, such as signature-based, or token burning.
  * 
  * @param fromAddress_ : previous owner of the token
  * @param toAddress_   : new owner of the token
  * @param tokenId_     : identifier of the token being transferred
  * 
  * Emits a {Transfer} event.
  */
  function _transfer( address fromAddress_, address toAddress_, uint256 tokenId_ ) internal override {
    if ( _isForSale[ tokenId_ ] ) {
      _removeListing( tokenId_ );
    }
    super._transfer( fromAddress_, toAddress_, tokenId_ );
  }

  // PUBLIC
  function listItem( uint256 tokenId, uint256 price, address to ) external {
  /**
  * @notice Create or update a listing for `tokenId_`.
  * 
  * Note: Setting `buyer_` to the NULL address will create a public listing.
  * 
  * @param tokenId_ : identifier of the token being listed
  * @param price_   : the sale price of the token being listed
  * @param buyer_   : optional address the token is being sold too
  */
  function listItem( uint256 tokenId_, uint256 price_, address buyer_ ) external {
    address _tokenOwner_ = ownerOf( tokenId_ );
    require( _tokenOwner_ == ownerOf( tokenId_ ), "Not token owner" );

    _createListing( tokenId_, price_, _tokenOwner_, buyer_ );
  }

  /**
  * @notice Removes the listing for `tokenId_`.
  * 
  * @param tokenId_ : identifier of the token being listed
  */
  function delistItem( uint256 tokenId_ ) external {
    address _tokenOwner_ = ownerOf( tokenId_ );
    require( _tokenOwner_ == ownerOf( tokenId_ ), "Not token owner" );

    require( _isForSale[ tokenId_ ], "Invalid listing" );

    _removeListing( _index_ );
    emit Delisted( tokenId_ );
  }

  /**
  * @notice Purchases the listed token `tokenId_`.
  * 
  * @param tokenId_ : identifier of the token being purchased
  */
  function buyItem( uint256 tokenId_ ) external payable {
    require( _isForSale[ tokenId_ ], "Invalid listing" );
    require(
      msg.sender == _listings[ _listingIndex[ tokenId_ ] ].to ||
      _listings[ _listingIndex[ tokenId_ ] ].to == address( 0 ),
      "Invalid sale address"
    )
    require( msg.value == _listings[ _listingIndex[ tokenId_ ] ].price, "Incorrect price" );

    address _tokenOwner_ = ownerOf( tokenId_ );
    _tranfer( _tokenOwner_, msg.sender, tokenId_ );
    emit Purchased( tokenId_, _tokenOwner_, msg.sender, _listing_.price );

    // Handle royalties
    ( address _royaltyRecipient_, uint256 _royalties_ ) = royaltyInfo( tokenId_, msg.value );
    _processEthPayment( _royalties_, _royaltyRecipient_ );

    uint256 _payment_ = msg.value - _royalties_;
    _processEthPayment( _payment_, _tokenOwner_ );
  }

  // VIEW
  /**
  * @notice Returns the list of all existing listings.
  * 
  * @return the list of all existing listings
  */
  function getAllListings() external view returns ( Listing[] memory ) {
    return _listings;
  }

  /**
  * @notice returns the existing listing for `tokenId_`.
  * 
  * @return the existing listing for the requested token.
  */
  function getListing( uint256 tokenId ) external view returns ( Listing memory ) {
    return _listings[ _listingIndex[ tokenId_ ] ];
  }
}
```

## Security Considerations

There are no security considerations related directly to the implementation of this standard.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
