// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC6150.sol";

/**
 * @title ERC-6150 Hierarchical NFTs Token Standard, optional extension for access control
 * @dev See https://eips.ethereum.org/EIPS/eip-6150
 * Note: the ERC-165 identifier for this interface is 0x1d04f0b3.
 */
interface IERC6150AccessControl is IERC6150 {
    /**
     * @notice Check the account whether a admin of `tokenId` token.
     * @dev Each token can be set more than one admin. Admin have permission to do something to the token, like mint child token,
     * or burn token, or transfer parentship.
     * @param tokenId The specified token
     * @param account The account to be checked
     * @return If the account has admin permission, return true; otherwise, return false.
     */
    function isAdminOf(
        uint256 tokenId,
        address account
    ) external view returns (bool);

    /**
     * @notice Check whether the specified parent token and account can mint children tokens
     * @dev If the `parentId` is zero, check whether account can mint root nodes
     * @param parentId The specified parent token to be checked
     * @param account The specified account to be checked
     * @return If the token and account has mint permission, return true; otherwise, return false.
     */
    function canMintChildren(
        uint256 parentId,
        address account
    ) external view returns (bool);

    /**
     * @notice Check whether the specified token can be burnt by specified account
     * @param tokenId The specified token to be checked
     * @param account The specified account to be checked
     * @return If the tokenId can be burnt by account, return true; otherwise, return false.
     */
    function canBurnTokenByAccount(
        uint256 tokenId,
        address account
    ) external view returns (bool);
}
