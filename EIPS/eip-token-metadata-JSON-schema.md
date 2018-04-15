---
eip: <to be assigned>
title: Token Metadata JSON Schema
author: Tommy Nicholas (@tomasienrbc)
discussions-to: tommy@rareart.io
status: Draft
type: Standards Track
category: ERC
created: 2018-04-13
---

## Simple Summary
A standard interface for token metadata

## Abstract
The ERC721 standard introduced the "tokenURI" parameter for non-fungible tokens to handle metadata such as:

- thumbnail image
- title
- description
- properties

etc.

This particularly critical for crypto-collectibles and gaming assets.

This standard includes a reference to metadata standard named "ERC721 Metadata JSON Schema". This schema is actually equally relevant to ERC20 tokens and therefore should be its own standard, separate from the ERC721 standard.

## Motivation
Metadata is critical for both ERC721 and ERC20 tokens representing things like crypto-collectibles, gaming assets, etc. Therefore, it is more logical and will be easier to maintain one Token Metadata JSON Schema rather than multiple schemas contained in their own EIPs. This should result in no code changes to the ERC721 standard or ERC20 standard and will serve only to simplify the process of maintaining and up to date JSON Schema for token metadata.

## Specification

This is the "Token Metadata JSON Schema" as it currently exists in the ERC721 standard. No changes are being recommended at this time.

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
One JSON schema standard will allow for simpler maintenance of this critical schema.

## Backwards Compatibility
Fully backwards compatible requiring no code changes at this time

## Test Cases
TO-DO

## Implementation
TO-DO

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
