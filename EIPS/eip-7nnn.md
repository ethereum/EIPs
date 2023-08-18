---
eip: 7nnn
title: NFT Dynamic Traits
description: Extension to ERC-721 and ERC-1155 for dynamic onchain traits
author: Adam Montgomery (@montasaurus), Ryan Ghods (@ryanio), 0age (@0age)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-07-28
requires: 165, 721
---

## Abstract

This specification introduces a new interface that extends ERC-721 and ERC-1155 that defines methods for setting and getting dynamic onchain traits associated with non-fungible tokens. These dynamic traits can be used to represent properties, characteristics, redeemable entitlements, or other attributes that can change over time. By defining these traits onchain, they can be used and modified by other onchain contracts.

## Motivation

Metadata for non-fungible tokens are often stored offchain. This makes it difficult to query and mutate these values in contract code. Specifying the ability to set and get traits onchain allows for new use cases like transacting based on a token's traits or redeeming onchain entitlements.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Contracts implementing this EIP MUST include the events, getters, and setters as defined below, and MUST return `true` for EIP-165 supportsInterface for `0x12345678`, the 4 byte interfaceId for IERC7NNN. The setters are optional to expose if the contract does not wish for others to modify their metadata, however it is RECOMMENDED to still implement them as permissioned methods to enable for external contract use cases like redemptions. If the contract does not implement the setters, the interfaceId including the setters MUST still be used to identify the contract as implementing this EIP.

```solidity
interface IERC7NNN {
    /* Events */
    event TraitUpdated(bytes32 indexed traitKey, uint256 indexed tokenId, bytes32 value);
    event TraitUpdatedBulkConsecutive(bytes32 indexed traitKeyPattern, uint256 fromTokenId, uint256 toTokenId);
    event TraitUpdatedBulkList(bytes32 indexed traitKeyPattern, uint256[] tokenIds);
    event TraitLabelsURIUpdated(string uri);

    /* Getters */
    function getTraitValue(bytes32 traitKey, uint256 tokenId) external view returns (bytes32);
    function getTraitValues(bytes32 traitKey, uint256[] calldata tokenIds) external view returns (bytes32[] memory);
    function getTraitKeys() external view returns (bytes32[] memory);
    function getTotalTraitKeys() external view returns (uint256);
    function getTraitKeyAt(uint256 index) external view returns (bytes32);
    function getTraitLabelsURI() external view returns (string memory);

    /* Setters */
    function setTrait(bytes32 traitKey, uint256 tokenId, bytes32 value) external;
    function setTraitLabelsURI(string calldata uri) external;
}
```

### Trait keys

The `traitKey` is used to identify a single trait. The `traitKey` can be any value, but it is recommended to express nested values in a dot-separated format. For example, `foo.bar.baz` could be used to represent the nested value `baz` in the object `bar` in the object `foo`. For longer or more complex key values, it is recommended to keccak256 hash the value and use the hash as the `traitKey`. The `traitKey` MUST NOT include a `*`.

If a trait key is queried that has not been set, it MUST revert with the error `UnknownTraitKey()`.

### Trait labels

Trait labels are used for user-facing websites to display human readable values for trait keys. The trait labels URI MAY point to an offchain location or an onchain data URI. The specification for the trait labels URI is as follows:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "traitKey": {
        "type": "string"
      },
      "fullTraitKey": {
        "type": "string"
      },
      "traitLabel": {
        "type": ["string"]
      },
      "displayType": {
        "type": ["number"]
      },
      "editors": {
        "type": "array",
        "items": {
          "type": "number"
        }
      },
      "editorsAddressList": {
        "type": "array",
        "items": {
          "type": "string"
        }
      },
      "acceptableValues": {
        "type": "array",
        "items": {
          "type": "string"
        }
      },
      "fullTraitValues": {
        "type": "object",
        "properties": {
          "traitValue": {
            "type": "string"
          },
          "fullTraitValue": {
            "type": "string"
          }
        }
      }
    },
    "required": ["traitKey", "traitLabel"]
  }
}
```

The `traitKey` SHOULD be the `bytes32` onchain key. The `fullTraitKey` MUST be defined if the `traitKey` is a keccak256 hashed value that does not directly decode to ASCII characters, so offchain indexers can understand the full `traitKey` value including its nesting.

The `displayType` is how the trait value MUST be displayed to front-end users. If the `displayType` is not defined, it MUST default to `0`. The following table defines the values for `displayType` and MAY be added to in future EIPs that require this one.

| Integer | Metadata Display Type |
| ------- | --------------------- |
| 0       | plain value           |
| 1       | number / percentage   |
| 2       | date                  |
| 3       | hidden                |

The `editors` field should specify an array of integers below mapping to the entities that can modify the trait.

| Integer | Editor                      |
| ------- | --------------------------- |
| 0       | internal (contract address) |
| 1       | contract owner              |
| 2       | token owner                 |
| 3       | custom address list         |

The `acceptableValues` are a set of predefined values that are acceptable to be set for the trait. If any value is accepted, the `*` character SHOULD be used. The `acceptableValues` MAY also define the validation in regex, and if so should start with `regex:`.

The `fullTraitValues` objects may specify the full trait value display if the desired trait value is larger than the supported bytes32 on the contract itself. The value SHOULD be an integer, that maps to the full trait value.

### Events

Updating traits MUST either emit the `TraitUpdated`, `TraitUpdatedBulkConsecutive` or `TraitUpdatedBulkList` event. For the event `TraitUpdatedBulkConsecutive`, the `fromTokenId` and `toTokenId` MUST be a consecutive range of tokens IDs and MUST be treated as an inclusive range. For the event `TraitUpdatedBulkList`, the `tokenIds` MAY be in any order. Updating the trait labels URI or the contents within the URI MUST emit the event `TraitLabelsURIUpdated` so offchain indexers can be notified to parse the changes.

The `traitKeyPattern` is used to identify a single trait or range of traits. If the `traitKeyPattern` does not contain a `*`, it is treated as a single trait. If the `traitKeyPattern` contains a `*`, then the pattern MUST be formatted in a dot-separated format and the `*` MUST express all potential values for the level it is nested at. For example, `foo.bar.*` could be used to represent all traits in the object `bar` in the object `foo`. The `traitKeyPattern` MUST NOT contain more than one `*` and the `*` MUST be the last character in the pattern.

### Conflicting values with metadata URIs

Traits specified via this specification MUST override any conflicting values specified by the ERC-721 metadata URIs. If the label of the trait has an exact match of the trait that is returned by tokenURI, then the value returned by this EIP MUST match, and if they do not match, the value returned by the onchain dynamic trait lookup MUST be displayed and used in precedence of the value over tokenURI, since that is what onchain contracts will use to guarantee the values.

If there is a difference in values between the onchain trait and data in the metadata URI, ingestors and websites SHOULD show a warning that there are conflicting values and the onchain trait is to be used for e.g. guaranteeing marketplace transactions.

### setTrait

If the methods `setTrait` and `setTraitLabelsURI` are public on the contract they MUST be permissioned and only be callable by authorized users (e.g. token owner or permissioned contract). This is so `setTrait` can be programmatically called, for example by a redeemable contract when a redemption occurs.

If `setTrait` does not modify the trait's existing value, it MUST revert with the custom error `TraitValueUnchanged()`.

### Registry functionality

If this EIP is being used as a "registry" to contain onchain metadata for multiple token addresses, for example to augment existing tokens that cannot have their code upgraded, the first 20 bytes of the `traitKey` MUST be the token address. The remaining `12` bytes can be used for the trait key, as ASCII characters OR as the first 12 bytes of the keccak256 hash of a longer key. When used in this format, the supportsInterface SHOULD NOT return for ERC-721 so external providers can understand that the traits are not for the contract's token address.

When implemented in a registry format, the trait labels URI JSON MAY specify the `traitKey` as only the last 12 bytes to simplify redundant labels for traitKeys across token addresses.

### ERC-1155 (Semi-fungibles)

This standard MAY be applied to ERC-1155 but the traits would apply to all token amounts for specific token identifiers. If the ERC-1155 contract only has tokens with amount of 1, then this specification MAY be used as written.

## Rationale

While offchain traits specified by metadata URIs in ERC-721 are useful, they do not provide the full benefits of having traits available onchain. Onchain traits can be used by internal and external contracts to get and mutate traits in a variety of different scenarios. For example, a contract that enables redeemables can check the value of a redemption and update the trait after the redemption is executed. This also allows onchain p2p marketplaces to guarantee certain trait values during order fulfillment, so trait properties cannot be modified before the sale through frontrunning.

## Backwards Compatibility

As a new EIP, no backwards compatibility issues are present, except for the point in the specification above that it is explicitly required that the onchain traits MUST override any conflicting values specified by the ERC-721 metadata URIs.

## Test Cases

## Test Cases

Test cases can be found in [https://github.com/ProjectOpenSea/dynamic-traits/tree/main/test](https://github.com/ProjectOpenSea/redeemables/tree/main/test)

## Reference Implementation

The reference implementation can be found at [https://github.com/ProjectOpenSea/dynamic-traits/blob/main/src/lib/DynamicTraits.sol](https://github.com/ProjectOpenSea/dynamic-traits/blob/main/src/lib/DynamicTraits.sol)

## Security Considerations

The set\* methods exposed externally MUST be permissioned so they are not callable by everyone but only by select roles or addresses.

Marketplaces SHOULD NOT trust offchain state of traits as they can be frontrunned. Marketplaces SHOULD check the current state of onchain traits at the time of transfer. Marketplaces MAY check certain traits that change the value of the NFT (e.g. redemption status) or they MAY hash all the trait values to guarantee the same state at the time of order creation.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
