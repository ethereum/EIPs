//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ERC5727.sol";
import "./interfaces/IERC5727SlotEnumerable.sol";

abstract contract ERC5727SlotEnumerable is ERC5727, IERC5727SlotEnumerable {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint256 => EnumerableSet.UintSet) private _tokensInSlot;

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

    function tokenSupplyInSlot(uint256 slot)
        public
        view
        override
        returns (uint256)
    {
        if (!_slotExists(slot)) {
            return 0;
        }
        return _tokensInSlot[slot].length();
    }

    function tokenInSlotByIndex(uint256 slot, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(
            index < ERC5727SlotEnumerable.tokenSupplyInSlot(slot),
            "ERC5727SlotEnumerable: slot token index out of bounds"
        );
        return _tokensInSlot[slot].at(index);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC5727)
        returns (bool)
    {
        return
            interfaceId == type(IERC5727SlotEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenMint(
        address issuer,
        address soul,
        uint256 tokenId,
        uint256 value,
        uint256 slot,
        bool valid
    ) internal virtual override {
        if (!_slotExists(slot)) {
            _allSlots.add(slot);
        }
        _tokensInSlot[slot].add(tokenId);
        //unused
        issuer;
        soul;
        value;
        valid;
    }

    function _beforeTokenDestroy(uint256 tokenId) internal virtual override {
        uint256 slot = _getTokenOrRevert(tokenId).slot;
        _tokensInSlot[slot].remove(tokenId);
        if (_tokensInSlot[slot].length() == 0) {
            _allSlots.remove(slot);
        }
    }
}
