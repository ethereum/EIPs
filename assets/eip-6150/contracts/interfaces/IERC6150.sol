// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC165.sol";

/**
 * @title ERC-6150 Hierarchical NFTs Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-6150
 * Note: the ERC-165 identifier for this interface is 0x897e2c73.
 */
interface IERC6150 is IERC721, IERC165 {
    /**
     * @notice Emitted when `tokenId` token under `parentId` is minted.
     * @param minter The address of minter
     * @param to The address received token
     * @param parentId The id of parent token, if it's zero, it means minted `tokenId` is a root token.
     * @param tokenId The id of minted token, required to be greater than zero
     */
    event Minted(
        address indexed minter,
        address indexed to,
        uint256 parentId,
        uint256 tokenId
    );

    /**
     * @notice Get the parent token of `tokenId` token.
     * @param tokenId The child token
     * @return parentId The Parent token found
     */
    function parentOf(uint256 tokenId) external view returns (uint256 parentId);

    /**
     * @notice Get the children tokens of `tokenId` token.
     * @param tokenId The parent token
     * @return childrenIds The array of children tokens
     */
    function childrenOf(
        uint256 tokenId
    ) external view returns (uint256[] memory childrenIds);

    /**
     * @notice Check the `tokenId` token if it is a root token.
     * @param tokenId The token want to be checked
     * @return Return `true` if it is a root token; if not, return `false`
     */
    function isRoot(uint256 tokenId) external view returns (bool);

    /**
     * @notice Check the `tokenId` token if it is a leaf token.
     * @param tokenId The token want to be checked
     * @return Return `true` if it is a leaf token; if not, return `false`
     */
    function isLeaf(uint256 tokenId) external view returns (bool);
}
