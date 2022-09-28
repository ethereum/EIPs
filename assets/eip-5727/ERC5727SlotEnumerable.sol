//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ERC5727.sol";
import "./IERC5727SlotEnumerable.sol";

abstract contract ERC5727SlotEnumerable is ERC5727, IERC5727SlotEnumerable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct SlotData {
        uint256 slot;
        EnumerableSet.UintSet slotTokens;
    }

    SlotData[] private _allSlots;

    mapping(uint256 => uint256) private _allSlotsIndex;

    function slotCount() public view override returns (uint256) {
        return _allSlots.length;
    }

    function slotByIndex(uint256 index) public view override returns (uint256) {
        require(
            index < ERC5727SlotEnumerable.slotCount(),
            "ERC5727SlotEnumerable: slot index out of bounds"
        );
        return _allSlots[index].slot;
    }

    function _slotExists(uint256 slot) internal view virtual returns (bool) {
        return
            _allSlots.length != 0 &&
            _allSlots[_allSlotsIndex[slot]].slot == slot;
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
        return EnumerableSet.length(_allSlots[_allSlotsIndex[slot]].slotTokens);
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
        return
            EnumerableSet.at(_allSlots[_allSlotsIndex[slot]].slotTokens, index);
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
}
