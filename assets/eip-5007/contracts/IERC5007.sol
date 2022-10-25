// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC5007 /* is IERC1155 */ {
    /**
     * @dev Returns the start time of the NFT.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function startTime(uint256 tokenId) external view returns (uint64);

    /**
     * @dev Returns the end time of the NFT.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function endTime(uint256 tokenId) external view returns (uint64);
}
