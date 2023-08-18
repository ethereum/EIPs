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

## Copyright and related rights waived via [CC0](../LICENSE.md).

eip: nnnn
title: NFT Redeemables
description: Extension to ERC-721 and ERC-1155 for onchain and offchain redeemables
author: Ryan Ghods (@ryanio), 0age (@0age), Adam Montgomery (@montasaurus)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-07-28
requires: 165, 721, 1155

---

## Abstract

This specification introduces a new interface that extends ERC-721 and ERC-1155 to enable onchain and offchain redeemables for NFTs.

## Motivation

Since the inception of NFTs, creators have used them to create redeemable entitlements for digital and physical goods. However, without a standard interface, it is challenging for users and websites to discover and interact with NFTs that have redeemable opportunities. By proposing this standard, the authors aim to create a reliable and predictable pattern for NFT redeemables.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

The token MUST have the following interface and MUST return `true` for EIP-165 supportsInterface for `0x12345678`, the 4 byte interfaceId of the below.

```solidity
interface IERC7NNN {
  /* Events */
  event CampaignUpdated(uint256 indexed campaignId, CampaignParams params, string URI);
  event Redemption(uint256 indexed campaignId, bytes32 redemptionHash, uint256[] tokenIds, address redeemedBy);

  /* Structs */
  struct CampaignParams {
      uint32 startTime;
      uint32 endTime;
      uint32 maxCampaignRedemptions;
      address manager; // the address that can modify the campaign
      address signer; // null address means no EIP-712 signature required
      OfferItem[] offer; // items to be minted, can be empty for offchain redeemable
      ConsiderationItem[] consideration; // the items you are transferring to recipient
  }
  struct TraitRedemption {
    uint8 substandard;
    address token;
    uint256 identifier;
    bytes32 traitKey;
    bytes32 traitValue;
    bytes32 substandardValue;
  }

  /* Getters */
  function getCampaign(uint256 campaignId) external view returns (CampaignParams memory params, string memory uri, uint256 totalRedemptions);

  /* Setters */
  function createCampaign(CampaignParams calldata params, string calldata uri) external returns (uint256 campaignId);
  function updateCampaign(uint256 campaignId, CampaignParams calldata params, string calldata uri) external;
  function redeem(uint256[] calldata tokenIds, bytes calldata extraData) external;
}

  ---

  /* Seaport structs (for reference in offer/consideration above) */
  enum ItemType {
      NATIVE,
      ERC20,
      ERC721,
      ERC1155
  }
  struct OfferItem {
      ItemType itemType;
      address token;
      uint256 identifierOrCriteria;
      uint256 startAmount;
      uint256 endAmount;
  }
  struct ConsiderationItem extends OfferItem {
      address payable recipient;
  }
  struct SpentItem {
      ItemType itemType;
      address token;
      uint256 identifier;
      uint256 amount;
  }
```

### Creating campaigns

When creating a new campaign, `createCampaign` MUST be used and MUST return the newly created `campaignId` along with the `CampaignUpdated` event. The `campaignId` MUST be an incrementing counter starting at `1`.

### Updating campaigns

Updates to campaigns MUST use `updateCampaign` and MUST emit the `CampaignUpdated` event. If an address other than the `manager` tries to update the campaign, it MUST revert with `NotManager()`. If the manager wishes to make the campaign immutable, the `manager` MAY be set to the null address.

### Offer

If tokens are set in the params `offer`, the tokens MUST implement the `IRedemptionMintable` interface in order to support minting new items. The implementation SHOULD be however the token mechanics are desired. The implementing token MUST return true for EIP-165 `supportsInterface` for the interfaceIds of: `IERC721RedemptionMintable: 0x12345678` or `IERC1155RedemptionMintable: 0x12345678`

```solidify
interface IERC721RedemptionMintable {
  function mintRedemption(address to, SpentItem[] calldata spent) external returns (uint256[] memory tokenIds);
}

interface IERC1155RedemptionMintable {
  function mintRedemption(address to, SpentItem[] calldata spent) external returns (uint256[] memory tokenIds, uint256[] amounts);
}
```

The array length return values of `tokenIds` and `amounts` for `IERC1155RedemptionMintable` MUST equal each other.

### Consideration

Any token may be used in the RedeemableParams `consideration`. This will ensure the token is transferred to the `recipient`. If the token is meant to be burned the recipient SHOULD be `0x000000000000000000000000000000000000dEaD`.

### Dynamic traits

If the token would like to enable trait redemptions, the token MUST include the ERC-7NNN Dynamic Traits interface.

### Signer

A signer MAY be specified to provide a signature to process the redemption. If the signer is NOT the null address, the signature MUST recover to the signer address via EIP-712 or EIP-1271.

The EIP-712 struct for signing MUST be as follows: `SignedRedeem(address owner,address redeemedToken, uint256[] tokenIds,bytes32 redemptionHash, uint256 salt)"`

### Redemption extraData

When calling the `redeem` function, the extraData layout MUST follow:

| bytes    | value             | description / notes                                              |
| -------- | ----------------- | ---------------------------------------------------------------- |
| 0-32     | campaignId        |                                                                  |
| 32-64    | redemptionHash    | hash of offchain order ids                                       |
| 64-\*    | TraitRedemption[] | see TraitRedemption struct. empty array for no trait redemptions |
| \*-(+32) | salt              | if signer != address(0)                                          |
| \*-(+\*) | signature         | if signer != address(0). can be for EIP-712 or EIP-1271          |

Upon redemption, the contract MUST check that the campaign is still active (using the same boundary check as Seaport, `startTime <= block.timestamp < endTime`). If it is, it MUST revert with `NotActive()`.

### Redeem

The `redeem` function MUST execute the transfers in the `consideration`. It MUST also call `mintRedemption` on the token specified in the `offer`. If any of the supplied tokenIds in `redeem` fail validation, the function MAY execute just the redemptions that were valid and ignore the failed redemptions. The `Redemption` event MUST be emitted emitted when any valid redemptions occur.

### Trait redemptions

The token MUST respect the TraitRedemption substandards as follows:

| substandard ID | description                     | substandard value                                                  |
| -------------- | ------------------------------- | ------------------------------------------------------------------ |
| 1              | set value to `traitValue`       | prior required value. if blank, cannot be the `traitValue` already |
| 2              | increment trait by `traitValue` | max value                                                          |
| 3              | decrement trait by `traitValue` | min value                                                          |

### Max campaign redemptions

The token MUST check that the `maxCampaignRedemptions` is not exceeded. If the redemption does exceed `maxCampaignRedemptions`, it MUST revert with `MaxCampaignRedemptionsReached(uint256 total, uint256 max)`

### Metadata URI

The metadata URI MUST follow the following JSON schema:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "description": {
      "type": "string",
      "description": "A one-line summary of the redeemable. Markdown is not supported."
    },
    "details": {
      "type": "string",
      "description": "A multi-line or multi-paragraph description of the details of the redeemable. Markdown is supported."
    },
    "imageUrls": {
      "type": "string",
      "description": "A list of image URLs for the redeemable. The first image will be used as the thumbnail. Will rotate in a carousel if multiple images are provided. Maximum 5 images."
    },
    "bannerUrl": {
      "type": "string",
      "description": "The banner image for the redeemable."
    },
    "faq": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "question": {
            "type": "string"
          },
          "answer": {
            "type": "string"
          },
          "required": ["question", "answer"]
        }
      }
    },
    "contentLocale": {
      "type": "string",
      "description": "The language tag for the content provided by this metadata. https://www.rfc-editor.org/rfc/rfc9110.html#name-language-tags"
    },
    "maxRedemptionsPerToken": {
      "type": "string",
      "description": "The maximum number of redemptions per token. When isBurn is true should be 1, else can be a number based on the trait redemptions limit."
    },
    "isBurn": {
      "type": "string",
      "description": "If the redemption burns the token."
    },
    "uuid": {
      "type": "string",
      "description": "A unique identifier for the campaign, for backends to identify when draft campaigns are published onchain."
    },
    "productLimitForRedemption": {
      "type": "number",
      "description": "The number of products which are able to be chosen from the products array for a single redemption."
    },
    "products": {
      "type": "object",
      "properties": "https://schema.org/Product",
      "required": ["name", "url", "description"]
    },
    "traitRedemptions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "substandard": {
            "type": "number"
          },
          "token": {
            "type": "string",
            "description": "The token address"
          },
          "traitKey": {
            "type": "string"
          },
          "traitValue": {
            "type": "string"
          },
          "substandardValue": {
            "type": "string"
          }
        },
        "required": [
          "substandard",
          "token",
          "traitKey",
          "traitValue",
          "substandardValue"
        ]
      }
    }
  },
  "required": ["name", "description", "isBurn"]
}
```

Future SIPs MAY inherit this one and add to the above metadata to add more features and functionality.

### ERC-1155 (Semi-fungibles)

This standard MAY be applied to ERC-1155 but the redemptions would apply to all token amounts for specific token identifiers. If the ERC-1155 contract only has tokens with amount of 1, then this specification MAY be used as written.

## Rationale

The intention of this EIP is to define a consistent standard to enable redeemable entitlements for tokens and onchain traits. This pattern allows for websites to discover, display, and interact with redeemable campaigns.

## Backwards Compatibility

As a new EIP, no backwards compatibility issues are present.

## Test Cases

Test cases can be found in [https://github.com/ProjectOpenSea/redeemables/tree/main/test](https://github.com/ProjectOpenSea/redeemables/tree/main/test)

## Reference Implementation

The reference implementation for ERC721Redeemable and ERC1155Redeemable can be found in [https://github.com/ProjectOpenSea/redeemables/tree/main/src](https://github.com/ProjectOpenSea/redeemables/tree/main/src)

## Security Considerations

Tokens must properly implement EIP-7NNN Dynamic Traits to allow for trait redemptions.

For tokens to be minted as part of the params `offer`, the `mintRedemption` function contained as part of `IRedemptionMintable` MUST be permissioned and ONLY allowed to be called by specified addresses.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
