// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

interface INonTransferable {

    /**
     * @notice Used to check whether the given token is nonTransferable or not.
     * @param tokenId ID of the token being checked
     * @return Boolean value indicating whether the given token is nonTransferable
     */
    function isNonTransferable(uint256 tokenId) external view returns (bool);
}