//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";
import "./IERC5727Enumerable.sol";

/**
 * @title ERC5727 Soulbound Token Slot Enumerable Interface
 * @dev This extension allows querying information about slots.
 */
interface IERC5727SlotEnumerable is IERC5727, IERC5727Enumerable {
    /**
     * @notice Get the total number of slots.
     * @return The total number of slots.
     */
    function slotCount() external view returns (uint256);

    /**
     * @notice Get the slot with `index` among all the slots.
     * @dev MUST revert if the `index` exceed the total number of slots.
     * @param index The index of the slot queried for
     * @return The slot is queried for
     */
    function slotByIndex(uint256 index) external view returns (uint256);

    /**
     * @notice Get the number of tokens in a slot.
     * @dev MUST revert if the slot does not exist.
     * @param slot The slot whose number of tokens is queried for
     * @return The number of tokens in the `slot`
     */
    function tokenSupplyInSlot(uint256 slot) external view returns (uint256);

    /**
     * @notice Get the tokenId with `index` of the `slot`.
     * @dev MUST revert if the `index` exceed the number of tokens in the `slot`.
     * @param slot The slot whose token is queried for.
     * @param index The index of the token queried for
     * @return The token is queried for
     */
    function tokenInSlotByIndex(uint256 slot, uint256 index)
        external
        view
        returns (uint256);
    
    /**
     * @notice Get the number of owners in a slot.
     * @dev MUST revert if the slot does not exist.
     * @param slot The slot whose number of owners is queried for
     * @return The number of owners in the `slot`
     */
    function ownersInSlot(uint256 slot) external view returns (uint256);

    /**
     * @notice Check if a owner is in a slot.
     * @dev MUST revert if the slot does not exist.
     * @param owner The owner whose existence in the slot is queried for
     * @param slot The slot whose existence of the owner is queried for
     * @return True if the `owner` is in the `slot`, false otherwise
     */
    function isOwnerInSlot(
        address owner,
        uint256 slot
    ) external view returns (bool);

    /**
     * @notice Get the owner with `index` of the `slot`.
     * @dev MUST revert if the `index` exceed the number of owners in the `slot`.
     * @param slot The slot whose owner is queried for.
     * @param index The index of the owner queried for
     * @return The owner is queried for
     */
    function ownerInSlotByIndex(
        uint256 slot,
        uint256 index
    ) external view returns (address);

    /**
     * @notice Get the number of slots of a owner.
     * @param owner The owner whose number of slots is queried for
     * @return The number of slots of the `owner`
     */
    function slotCountOfOwner(address owner) external view returns (uint256);

    /**
     * @notice Get the slot with `index` of the `owner`.
     * @dev MUST revert if the `index` exceed the number of slots of the `owner`.
     * @param owner The owner whose slot is queried for.
     * @param index The index of the slot queried for
     * @return The slot is queried for
     */
    function slotOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);
}
