// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

library MultiAssetLib {
    function indexOf(
        uint64[] memory A,
        uint64 a
    ) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i; i < length; ) {
            if (A[i] == a) {
                return (i, true);
            }
            unchecked {
                ++i;
            }
        }
        return (0, false);
    }

    //For reasource storage array
    function removeItemByIndex(uint64[] storage array, uint256 index) internal {
        //Check to see if this is already gated by require in all calls
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }
}
