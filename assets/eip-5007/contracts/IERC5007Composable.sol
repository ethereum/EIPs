// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;


interface IERC5007Composable /* is IERC5007 */ {
    /**
     * @dev Returns the asset id of the time NFT.
     * Only NFTs with same asset id can be merged.
     * 
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function assetId(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Split an old token to two new tokens.
     * The assetId of the new token is the same as the assetId of the old token
     *
     * Requirements:
     *
     * - `oldTokenId` must exist.
     * - `newToken1Id` must not exist.
     * - `newToken1Owner` cannot be the zero address.
     * - `newToken2Id` must not exist.
     * - `newToken2Owner` cannot be the zero address.
     * - `splitTime`  require(oldToken.startTime <= splitTime && splitTime < oldToken.EndTime)
     */
    function split(
        uint256 oldTokenId,
        uint256 newToken1Id,
        address newToken1Owner,
        uint256 newToken2Id,
        address newToken2Owner,
        uint64 splitTime
    ) external;

    /**
     * @dev Merge the first token and second token into the new token.
     *
     * Requirements:
     *
     * - `firstTokenId` must exist.
     * - `secondTokenId` must exist.
     * - require((firstToken.endTime + 1) == secondToken.startTime)
     * - require((firstToken.assetId()) == secondToken.assetId())
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
