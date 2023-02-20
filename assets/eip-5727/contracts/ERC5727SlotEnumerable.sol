//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ERC5727.sol";
import "./interfaces/IERC5727SlotEnumerable.sol";

abstract contract ERC5727SlotEnumerable is ERC5727, IERC5727SlotEnumerable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => EnumerableSet.UintSet) private _tokensInSlot;

    mapping(uint256 => EnumerableSet.AddressSet) private _ownersInSlot;

    mapping(address => EnumerableSet.UintSet) private _slotsOfOwner;

    EnumerableSet.UintSet private _allSlots;

    function slotCount() public view override returns (uint256) {
        return _allSlots.length();
    }

    function slotByIndex(uint256 index) public view override returns (uint256) {
        require(
            index < ERC5727SlotEnumerable.slotCount(),
            "ERC5727SlotEnumerable: slot index out of bounds"
        );
        return _allSlots.at(index);
    }

    function _slotExists(uint256 slot) internal view virtual returns (bool) {
        return _allSlots.length() != 0 && _allSlots.contains(slot);
    }

    function tokenSupplyInSlot(
        uint256 slot
    ) public view override returns (uint256) {
        if (!_slotExists(slot)) {
            return 0;
        }
        return _tokensInSlot[slot].length();
    }

    function tokenInSlotByIndex(
        uint256 slot,
        uint256 index
    ) public view override returns (uint256) {
        require(
            index < ERC5727SlotEnumerable.tokenSupplyInSlot(slot),
            "ERC5727SlotEnumerable: slot token index out of bounds"
        );
        return _tokensInSlot[slot].at(index);
    }

    function ownersInSlot(uint256 slot) public view override returns (uint256) {
        if (!_slotExists(slot)) {
            return 0;
        }
        return _ownersInSlot[slot].length();
    }

    function ownerInSlotByIndex(
        uint256 slot,
        uint256 index
    ) public view override returns (address) {
        require(
            index < ERC5727SlotEnumerable.ownersInSlot(slot),
            "ERC5727SlotEnumerable: slot owner index out of bounds"
        );
        return _ownersInSlot[slot].at(index);
    }

    function slotCountOfOwner(
        address owner
    ) public view override returns (uint256) {
        return _slotsOfOwner[owner].length();
    }

    function slotOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view override returns (uint256) {
        require(
            index < ERC5727SlotEnumerable.slotCountOfOwner(owner),
            "ERC5727SlotEnumerable: owner slot index out of bounds"
        );
        return _slotsOfOwner[owner].at(index);
    }

    function isOwnerInSlot(
        address owner,
        uint256 slot
    ) public view virtual override returns (bool) {
        return _ownersInSlot[slot].contains(owner);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC5727) returns (bool) {
        return
            interfaceId == type(IERC5727SlotEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenMint(
        address issuer,
        address owner,
        uint256 tokenId,
        uint256 value,
        uint256 slot,
        bool valid
    ) internal virtual override {
        if (!_slotExists(slot)) {
            _allSlots.add(slot);
        }
        _tokensInSlot[slot].add(tokenId);
        if (!_ownersInSlot[slot].contains(owner)) {
            _ownersInSlot[slot].add(owner);
        }
        _slotsOfOwner[owner].add(slot);
    }

    function _addSlot(uint256 slot) internal virtual {
        if (!_slotExists(slot)) {
            _allSlots.add(slot);
        }
    }

    function _beforeTokenDestroy(uint256 tokenId) internal virtual override {
        uint256 slot = _getTokenOrRevert(tokenId).slot;
        _tokensInSlot[slot].remove(tokenId);
        if (_tokensInSlot[slot].length() == 0) {
            _allSlots.remove(slot);
        }
    }

    function slotURI(
        uint256 slot
    ) public view virtual override returns (string memory) {
        require(
            _slotExists(slot),
            "ERC5727SlotEnumerable: slot does not exist"
        );
        return super.slotURI(slot);
    }
}
