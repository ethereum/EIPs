// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;


interface IERC5007Composable /* is IERC5007 */ {
    /**
     * @dev Returns the ancestor token id of the NFT.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function rootTokenId(uint256 tokenId) external view returns (uint256);

    /**
     * @dev  Mint a new token from an old token.
     * The rootTokenId of the new token is the same as the rootTokenId of the old token
     *
     * Requirements:
     *
     * - `oldTokenId` must exist.
     * - `newTokenId` must not exist.
     * - `newTokenOwner` cannot be the zero address.
     * - `newTokenStartTime`  require(oldTokenStartTime < newTokenStartTime && newTokenStartTime <= oldTokenEndTime)
     */
    function split(
        uint256 oldTokenId,
        uint256 newTokenId,
        address newTokenOwner,
        int64 newTokenStartTime
    ) external;

    /**
     * @dev  Merge the first token and second token into the new token.
     *
     * Requirements:
     *
     * - `firstTokenId` must exist.
     * - `secondTokenId` must exist. require((firstToken.endTime + 1) == secondToken.startTime)
     * - `newTokenOwner` cannot be the zero address.
     * - `newTokenId` must not exist.
     */
    function merge(
        uint256 firstTokenId,
        uint256 secondTokenId,
        address newTokenOwner,
        uint256 newTokenId
    ) external;
}
