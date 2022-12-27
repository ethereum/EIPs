---
eip: eip-xxxx
title: Composable NFTs utilizing Equippable Parts
description: An interface for Composable non-fungible tokens through fixed and slot parts equipping.
author: Bruno Škvorc (@Swader), Cicada (@CicadaNCR), Steven Pineda (@steven2308), Stevan Bogosavljevic (@stevyhacker), Jan Turk (@ThunderDeliverer)
discussions-to:
status: Draft
type: Standards Track
category: ERC
created: 2022-12-20
requires: 165, 721, 5773, 6059
---

## Abstract

The Composable NFTs utilizing equippable parts standard extends [EIP-721](./eip-721.md) by allowing the NFTs to selectively add parts to themselves via equipping.

Tokens are able to equip the parts by cherry picking the list of parts from a Catalog for that NFT instance. Catalogs contain parts from which NFTs can be composed.

This proposal introduces two types of parts; slot type of parts and fixed type of parts. The slot type of parts allow for other NFT collections to be equipped into them, while fixed parts are full components with their own metadata.

Equipping a part into an NFT doesn't generate a new token, but rather adds another component to be rendered when retrieving the token.

## Motivation

With NFTs being a widespread form of tokens in the Ethereum ecosystem and being used for a variety of use cases, it is time to standardize additional utility for them. Having the ability for tokens to own other tokens allows for greater utility, usability and forward compatibility.

In the four years since [EIP-721](./eip-721.md) was published, the need for additional functionality has resulted in countless extensions. This EIP improves upon EIP-721 in the following areas:

- [Composing](#composing)
- [Token progression](#token-progression)
- [Merit tracking](#merit-tracking)
- [Portfolio organization](#portfolio-organization)

### Composing

NFTs can work together to create a greater construct. Prior to this proposal, multiple NFTs could be composed into a single construct either by checking all of the compatible NFTs associated with a given account and used indiscriminately (which could result in unexpected result if there was more than one NFT intended to be used in the same slot), or by keeping a custom ledger of parts to compose together (either in a smart contract or an off-chain database). This proposal establishes a standrardized framework for composable NFTs, where a single NFT can select which parts should be a part of the whole. Composing NFTs in such a way allows for virtually unbounded customization of the base NFT. An example of this could be a movie NFT. Some parts, like credits, should be fixed. Other parts, like scenes, should be interchangeable, so that various releases (base version, extended cuts, anniversary editions,...) can be replaced.

### Token progression

As the token progresses through various stages of its existence, it can attain or be awarded various parts. This can be explained in terms of gaming. A character could be represented by an NFT utilizing this proposal and would be able to equip gear acquired through the gameplay activities and as it progresses further in the game, better items would be available. In stead of having numerous NFTs representing the items collected through its progression, equippable parts can be unlocked and the NFT owner would be able to decide which items to equip and which to keep in the inventory (not equipped).

### Merit tracking

An equippable NFT can also be used to track merit. An example of this is academic merit. The equippable NFT in this case would represent a sort of digital portfolio of academic achievements, where the owner would be able to equip their diplomas, published articles and awards for all to see.

### Portfolio organization

Many use cases that use utility NFTs eventually award holders of the tokens with additional tokens that provide additional utility. Gaming NFTs often use other NFTs to represent items owned by the base NFT. Both of the examples can mean that, in a long term scenario, the NFT owner's wallet could contain hundredths NFTs for a single use case. Not only does this mean that the wallet is cluttered, but the interface may soon become virtually unusable and NFTs might get buried within the wallet. By supporting NFTs outlined in this proposal use cases can only use a single NFT to track virtually unbounded utility and in turn allow the owner of the token to easily traverse owned NFTs.

A great example of this is a DAO membership NFT. As a DAO grows, it could grow into multiple factions and sub-factions which would each require its own access NFT in order to access them. An equippable base NFT would allow the access NFTs to be replaced by equippable access passes, thus reducing clutter of one's NFT inventory.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

### Equippable tokens

The interface of the core smart contract of the equippable tokens.

```solidity
/// @title EIP-X Composable NFTs utilizing Equippable Parts
/// @dev See https://eips.ethereum.org/EIPS/eip-x
/// @dev Note: the ERC-165 identifier for this interface is 0xd239c420.

pragma solidity ^0.8.16;

import "./IERC5773.sol";

interface IEquippable is IERC5773 {
    /**
     * @notice Used to store the core structure of the `Equippable` component.
     * @return assetId The ID of the asset equipping a child
     * @return childAssetId The ID of the asset used as equipment
     * @return childId The ID of token that is equipped
     * @return childEquippableAddress Address of the collection to which the child asset belongs to
     */
    struct Equipment {
        uint64 assetId;
        uint64 childAssetId;
        uint256 childId;
        address childEquippableAddress;
    }

    /**
     * @notice Used to provide a struct for inputing equip data.
     * @dev Only used for input and not storage of data.
     * @return tokenId ID of the token we are managing
     * @return childIndex Index of a child in the list of token's active children
     * @return assetId ID of the asset that we are equipping into
     * @return slotPartId ID of the slot part that we are using to equip
     * @return childAssetId ID of the asset that we are equipping
     */
    struct IntakeEquip {
        uint256 tokenId;
        uint256 childIndex;
        uint64 assetId;
        uint64 slotPartId;
        uint64 childAssetId;
    }

    /**
     * @notice Used to notify listeners that a child's asset has been equipped into one of its parent assets.
     * @param tokenId ID of the token that had an asset equipped
     * @param assetId ID of the asset associated with the token we are equipping into
     * @param slotPartId ID of the slot we are using to equip
     * @param childId ID of the child token we are equipping into the slot
     * @param childAddress Address of the child token's collection
     * @param childAssetId ID of the asset associated with the token we are equipping
     */
    event ChildAssetEquipped(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed slotPartId,
        uint256 childId,
        address childAddress,
        uint64 childAssetId
    );

    /**
     * @notice Used to notify listeners that a child's asset has been unequipped from one of its parent assets.
     * @param tokenId ID of the token that had an asset unequipped
     * @param assetId ID of the asset associated with the token we are unequipping out of
     * @param slotPartId ID of the slot we are unequipping from
     * @param childId ID of the token being unequipped
     * @param childAddress Address of the collection that a token that is being unequipped belongs to
     * @param childAssetId ID of the asset associated with the token we are unequipping
     */
    event ChildAssetUnequipped(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed slotPartId,
        uint256 childId,
        address childAddress,
        uint64 childAssetId
    );

    /**
     * @notice Used to notify listeners that the assets belonging to a `equippableGroupId` have been marked as
     *  equippable into a given slot and parent
     * @param equippableGroupId ID of the equippable group being marked as equippable into the slot associated with
     *  `slotPartId` of the `parentAddress` collection
     * @param slotPartId ID of the slot part of the catalog into which the parts belonging to the equippable group
     *  associated with `equippableGroupId` can be equipped
     * @param parentAddress Address of the collection into which the parts belonging to `equippableGroupId` can be
     *  equipped
     */
    event ValidParentEquippableGroupIdSet(
        uint64 indexed equippableGroupId,
        uint64 indexed slotPartId,
        address parentAddress
    );

    /**
     * @notice Used to check whether the token has a given child equipped.
     * @dev This is used to prevent from transferring a child that is equipped.
     * @param tokenId ID of the parent token for which we are querying for
     * @param childAddress Address of the child token's smart contract
     * @param childId ID of the child token
     * @return bool The boolean value indicating whether the child token is equipped into the given token or not
     */
    function isChildEquipped(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) external view returns (bool);

    /**
     * @notice Used to verify whether a token can be equipped into a given parent's slot.
     * @param parent Address of the parent token's smart contract
     * @param tokenId ID of the token we want to equip
     * @param assetId ID of the asset associated with the token we want to equip
     * @param slotId ID of the slot that we want to equip the token into
     * @return bool The boolean indicating whether the token with the given asset can be equipped into the desired
     *  slot
     */
    function canTokenBeEquippedWithAssetIntoSlot(
        address parent,
        uint256 tokenId,
        uint64 assetId,
        uint64 slotId
    ) external view returns (bool);

    /**
     * @notice Used to get the Equipment object equipped into the specified slot of the desired token.
     * @dev The `Equipment` struct consists of the following data:
     *  [
     *      assetId,
     *      childAssetId,
     *      childId,
     *      childEquippableAddress
     *  ]
     * @param tokenId ID of the token for which we are retrieving the equipped object
     * @param targetCatalogAddress Address of the `Catalog` associated with the `Slot` part of the token
     * @param slotPartId ID of the `Slot` part that we are checking for equipped objects
     * @return struct The `Equipment` struct containing data about the equipped object
     */
    function getEquipment(
        uint256 tokenId,
        address targetCatalogAddress,
        uint64 slotPartId
    ) external view returns (Equipment memory);

    /**
     * @notice Used to get the asset and equippable data associated with given `assetId`.
     * @param tokenId ID of the token for which to retrieve the asset
     * @param assetId ID of the asset of which we are retrieving
     * @return metadataURI The metadata URI of the asset
     * @return equippableGroupId ID of the equippable group this asset belongs to
     * @return catalogAddress The address of the catalog the part belongs to
     * @return partIds An array of IDs of parts included in the asset
     */
    function getAssetAndEquippableData(uint256 tokenId, uint64 assetId)
        external
        view
        returns (
            string memory metadataURI,
            uint64 equippableGroupId,
            address catalogAddress,
            uint64[] calldata partIds
        );
}
```

### Catalog

The interface of the Catalog containing the equippable parts.

```solidity
/**
 * @title ICatalog
 * @notice An interface Catalog for equippable module.
 * @dev Note: the ERC-165 identifier for this interface is 0xd912401f.
 */

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ICatalog is IERC165 {
    /**
     * @notice Event to announce addition of a new part.
     * @dev It is emitted when a new part is added.
     * @param partId ID of the part that was added
     * @param itemType Enum value specifying whether the part is `None`, `Slot` and `Fixed`
     * @param zIndex An uint specifying the z value of the part. It is used to specify the depth which the part should
     *  be rendered at
     * @param equippableAddresses An array of addresses that can equip this part
     * @param metadataURI The metadata URI of the part
     */
    event AddedPart(
        uint64 indexed partId,
        ItemType indexed itemType,
        uint8 zIndex,
        address[] equippableAddresses,
        string metadataURI
    );

    /**
     * @notice Event to announce new equippables to the part.
     * @dev It is emitted when new addresses are marked as equippable for `partId`.
     * @param partId ID of the part that had new equippable addresses added
     * @param equippableAddresses An array of the new addresses that can equip this part
     */
    event AddedEquippables(
        uint64 indexed partId,
        address[] equippableAddresses
    );

    /**
     * @notice Event to announce the overriding of equippable addresses of the part.
     * @dev It is emitted when the existing list of addresses marked as equippable for `partId` is overwritten by a new
     *  one.
     * @param partId ID of the part whose list of equippable addresses was overwritten
     * @param equippableAddresses The new, full, list of addresses that can equip this part
     */
    event SetEquippables(uint64 indexed partId, address[] equippableAddresses);

    /**
     * @notice Event to announce that a given part can be equipped by any address.
     * @dev It is emitted when a given part is marked as equippable by any.
     * @param partId ID of the part marked as equippable by any address
     */
    event SetEquippableToAll(uint64 indexed partId);

    /**
     * @notice Used to define a type of the item. Possible values are `None`, `Slot` or `Fixed`.
     * @dev Used for fixed and slot parts.
     */
    enum ItemType {
        None,
        Slot,
        Fixed
    }

    /**
     * @notice The integral structure of a standard RMRK catalog item defining it.
     * @dev Requires a minimum of 3 storage slots per catalog item, equivalent to roughly 60,000 gas as of Berlin hard fork
     *  (April 14, 2021), though 5-7 storage slots is more realistic, given the standard length of an IPFS URI. This
     *  will result in between 25,000,000 and 35,000,000 gas per 250 assets--the maximum block size of Ethereum
     *  mainnet is 30M at peak usage.
     * @return itemType The item type of the part
     * @return z The z value of the part defining how it should be rendered when presenting the full NFT
     * @return equippable The array of addresses allowed to be equipped in this part
     * @return metadataURI The metadata URI of the part
     */
    struct Part {
        ItemType itemType; //1 byte
        uint8 z; //1 byte
        address[] equippable; //n Collections that can be equipped into this slot
        string metadataURI; //n bytes 32+
    }

    /**
     * @notice The structure used to add a new `Part`.
     * @dev The part is added with specified ID, so you have to make sure that you are using an unused `partId`,
     *  otherwise the addition of the part vill be reverted.
     * @dev The full `IntakeStruct` looks like this:
     *  [
     *          partID,
     *      [
     *          itemType,
     *          z,
     *          [
     *               permittedCollectionAddress0,
     *               permittedCollectionAddress1,
     *               permittedCollectionAddress2
     *           ],
     *           metadataURI
     *       ]
     *   ]
     * @return partId ID to be assigned to the `Part`
     * @return part A `Part` to be added
     */
    struct IntakeStruct {
        uint64 partId;
        Part part;
    }

    /**
     * @notice Used to return the metadata URI of the associated catalog.
     * @return string Base metadata URI
     */
    function getMetadataURI() external view returns (string memory);

    /**
     * @notice Used to return the `itemType` of the associated catalog
     * @return string `itemType` of the associated catalog
     */
    function getType() external view returns (string memory);

    /**
     * @notice Used to check whether the given address is allowed to equip the desired `Part`.
     * @dev Returns true if a collection may equip asset with `partId`.
     * @param partId The ID of the part that we are checking
     * @param targetAddress The address that we are checking for whether the part can be equipped into it or not
     * @return bool The status indicating whether the `targetAddress` can be equipped into `Part` with `partId` or not
     */
    function checkIsEquippable(uint64 partId, address targetAddress)
        external
        view
        returns (bool);

    /**
     * @notice Used to check if the part is equippable by all addresses.
     * @dev Returns true if part is equippable to all.
     * @param partId ID of the part that we are checking
     * @return bool The status indicating whether the part with `partId` can be equipped by any address or not
     */
    function checkIsEquippableToAll(uint64 partId) external view returns (bool);

    /**
     * @notice Used to retrieve a `Part` with id `partId`
     * @param partId ID of the part that we are retrieving
     * @return struct The `Part` struct associated with given `partId`
     */
    function getPart(uint64 partId) external view returns (Part memory);

    /**
     * @notice Used to retrieve multiple parts at the same time.
     * @param partIds An array of part IDs that we want to retrieve
     * @return struct An array of `Part` structs associated with given `partIds`
     */
    function getParts(uint64[] calldata partIds)
        external
        view
        returns (Part[] memory);
}
```

## Rationale

Designing the proposal, we considered the following questions:

1. **Why are we using a Catalog in stead of supporting direct NFT equipping?**

If NFTs could be directly equipped into other NFTs without any oversight, the resulting composite would be unpredictable. Catalog allows for parts to be pre-verified in order to result in a composite that composes as expected.

2. **Why do we propose two types of parts?**

Some parts, that are the same for all of the tokens, don't make sense to be represented by individual NFTs. This reduces the clutter of the owner's wallet as well as introduces an efficient way of disseminating repetitive assets tied to NFTs.

The slot parts allow for equipping NFTs into them. This provides the ability to equip unrelated NFT collections into the base NFT after the unrelated collection has been verified to compose properly.

Having two parts allows for support of numerous use cases and, since the proposal doesn't enforce the use of both it can be applied in any configuration needed.

3. **Why is a method to get all of the equipped parts not included?**

Getting all parts might not be an operation necessary for all implementers. Additionally, it can be added either as an extension, doable with hooks, or can be emulated using an indexer.

## Backwards Compatibility

The Equippable token standard has been made compatible with [EIP-721](./eip-721.md) in order to take advantage of the robust tooling available for implementations of EIP-721 and to ensure compatibility with existing EIP-721 infrastructure.

## Test Cases

Tests are included in [`equippable.ts`](../assets/eip-xxxx/test/equippable.ts).

To run them in terminal, you can use the following commands:

```
cd ../assets/eip-xxxx
npm install
npx hardhat test
```

## Reference Implementation

See [`EquippableToken.sol`](../assets/eip-xxxx/contracts/EquippableToken.sol).


## Security Considerations

The same security considerations as with [EIP-721](./eip-721.md) apply: hidden logic may be present in any of the functions, including burn, add resource, accept resource, and more.

Caution is advised when dealing with non-audited contracts.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).