// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ICatalog
 * @author RMRK team
 * @notice An interface Catalog for equippable module.
 */
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
