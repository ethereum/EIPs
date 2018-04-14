---
eip: <to be assigned>
title: ERC20 Extended to Support tokenURI Metadata
author: Tommy Nicholas (@tomasienrbc), Matt Russo (@mateofrancesco), Matt Condon (@shrugs)
discussions-to: thelab@rareart.io
status: Draft
type: Standards Track
category: ERC
created: 2018-04-13
requires: 20
---

## Simple Summary
ERC20 tokens need to be able to support the same tokenURI metadata standard as ERC721 tokens

## Abstract
The ERC721 standard introduced the "tokenURI" parameter for non-fungible tokens to handle metadata such as:

- thumbnail image
- title
- description
- properties

etc.

This particularly critical for crypto-collectibles and gaming assets. However, not all crypto-collectibles and gaming assets will be non-fungible. Therefore, it is critical to extend the ERC20 standard to support the same metadata standard to simplify platforms supporting both fungible and non-fungible collectibles, game assets, and more.

## Motivation
The ERC721 standard was created to support the creation of perfectly unique, 1-of-1, non-divisible tokens known as "non-fungible tokens".

The initial motivation behind creating this standard was to support crypto-collectibles and gaming assets, initially for the "Crypto Kitties" collectibles game. The success of Crypto Kitties has caused significant investment into platforms that support displaying ERC721 assets based on the metadata contained in the "tokenURI" metadata paramater.

However, not all crypto-collectibles and gaming assets need to be unique and non-fungible. Gaming assets such as weapons, crypto-artworks with non-unique "prints", and more will function more like traditional ERC20 tokens with a fungible "supply". Many platforms such as wallets, exchanges, games, etc will want to support both fungible and non-fungible assets with similar metadata. This proposal will extend the ERC20 standard to optionally include a nearly identical "tokenURI" parameter supporting the JSON metadata schema as the ERC721 standard.

## Specification

The **metadata extension** will be OPTIONAL for ERC-20 smart contracts. This allows your smart contract to be interrogated for its name and for details about the assets which your tokens represent.

```solidity
/// @title ERC-20 optional metadata extension
interface TokenMetaData /* is ERC20 */ {

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    ///  3986. The URI may point to a JSON file that conforms to the "Metadata JSON Schema".
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
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.

## Backwards Compatibility
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Implementation
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
