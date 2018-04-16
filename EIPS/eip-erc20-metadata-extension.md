---
eip: <to be assigned>
title: ERC20 Metadata Extension
author: Tommy Nicholas (@tomasienrbc), Matt Russo (@mateosu), Matt Condon (@shrugs)
discussions-to: thelab@rareart.io
status: Draft
type: Standards Track
category: ERC
created: 2018-04-13
requires: 20
---

## Simple Summary
Optionally extend ERC20 tokens to support the same metadata standard as ERC721 tokens

## Abstract
The ERC721 standard introduced the `tokenURI` parameter for non-fungible tokens to handle metadata such as:

- thumbnail image
- title
- description
- special asset properties

etc.

Metadata is critical for things like crypto-collectibles and gaming assets to have real utility and value. However, not all crypto-collectibles and gaming assets will be non-fungible. It critical for fungible ERC20 tokens to be able to use the same metadata standard as non-fungible tokens where applicable. Standardization of metadata across the ERC20 and ERC721 will make it easy for platforms to support both fungible and non-fungible collectibles, game assets, and more.

## Motivation
The ERC721 standard was created to support the creation of perfectly unique, 1-of-1, non-divisible tokens known as "non-fungible tokens".

The initial use case for the ERC721 standard was to support the creation of crypto-collectibles and gaming assets, initially for the ["Crypto Kitties"](https://www.cryptokitties.co/) collectibles game. The success of Crypto Kitties caused significant investment into platforms that support displaying ERC721 assets based on the metadata contained in the `tokenURI` metadata parameter.

However, not all crypto-collectibles and gaming assets need to be unique and non-fungible. Gaming assets (items, weapons, characters), crypto-artworks with non-unique "prints", and more will function more like traditional ERC20 tokens with a fungible `supply`. Many platforms such as wallets, exchanges, games, etc will want to support both fungible and non-fungible assets containing similar metadata. This proposal will extend the ERC20 standard to optionally include a nearly identical `tokenURI` parameter supporting the JSON metadata schema as the ERC721 standard.

## Specification

The **metadata extension** will be OPTIONAL for ERC-20 smart contracts. This allows your smart contract to be interrogated for its name and for details about the assets which your tokens represent.

```solidity
/// @title ERC-20 optional metadata extension
interface TokenMetaData /* is ERC20 */ {

    /// @notice A distinct Uniform Resource Identifier (URI) for a given token.
    /// The URI may point to a JSON file that conforms to the "Metadata JSON Schema".
    function tokenURI() external view returns (string);
}
```

This is the "Token Metadata JSON Schema" referenced above.

```json
{
    "title": "Asset Metadata",
    "type": "object",
    "properties": {
        "name": {
            "type": "string",
            "description": "Identifies the asset to which this token represents",
        },
        "description": {
            "type": "string",
            "description": "Describes the asset to which this NFT represents",
        },
        "image": {
            "type": "string",
            "description": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive.",
        }
    }
}
```
## Rationale
This proposal will make adding metadata to ERC20 tokens straightforward for developers with minimal-to-no disruption to the overall ecosystem. By using the same parameter name and by consolidating the underlying Token JSON Metadata Standard, developers will confidently understand how to add and interpret token metadata across ERC20 and ERC721 tokens.

## Backwards Compatibility
I believe this EIP is fully backwards compatible but I may be misunderstanding the definition of "backwards compatible". Help!

## Test Cases
TO-DO

## Implementation

- [Rare Art Labs](https://rareart.io) (WIP)
- [Open Zeppelin](https://github.com/OpenZeppelin/zeppelin-solidity) (WIP)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
