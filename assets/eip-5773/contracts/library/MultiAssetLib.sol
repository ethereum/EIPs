// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

library MultiAssetLib {
    function removeItemByValue(uint64[] storage array, uint64 value)
        internal
        returns (bool)
    {
        uint64[] memory memArr = array; //Copy array to memory, check for gas savings here
        uint256 length = memArr.length; //gas savings
        for (uint256 i; i < length; ) {
            if (memArr[i] == value) {
                removeItemByIndex(array, i);
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    //For reasource storage array
    function removeItemByIndex(uint64[] storage array, uint256 index) internal {
        //Check to see if this is already gated by require in all calls
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }
}
