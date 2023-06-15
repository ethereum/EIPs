// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC6150.sol";

/**
 * @title ERC-6150 Hierarchical NFTs Token Standard, optional extension for parent transferable
 * @dev See https://eips.ethereum.org/EIPS/eip-6150
 * Note: the ERC-165 identifier for this interface is 0xfa574808.
 */
interface IERC6150ParentTransferable is IERC6150 {
    /**
     * @notice Emitted when the parent of `tokenId` token changed.
     * @param tokenId The token changed
     * @param oldParentId Previous parent token
     * @param newParentId New parent token
     */
    event ParentTransferred(
        uint256 tokenId,
        uint256 oldParentId,
        uint256 newParentId
    );

    /**
     * @notice Transfer parentship of `tokenId` token to a new parent token
     * @param newParentId New parent token id
     * @param tokenId The token to be changed
     */
    function transferParent(uint256 newParentId, uint256 tokenId) external;

    /**
     * @notice Batch transfer parentship of `tokenIds` to a new parent token
     * @param newParentId New parent token id
     * @param tokenIds Array of token ids to be changed
     */
    function batchTransferParent(
        uint256 newParentId,
        uint256[] memory tokenIds
    ) external;
}
