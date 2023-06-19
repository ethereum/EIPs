// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IERC7007.sol";

/**
 * @title ERC7007 Token Standard, optional enumeration extension
 * Note: the ERC-165 identifier for this interface is 0xfa1a557a.
 */
interface IERC7007Enumerable is IERC7007 {
    /**
     * @dev Returns the token ID given `prompt`.
     */
    function tokenId(bytes calldata prompt) external view returns (uint256);

    /**
     * @dev Returns the prompt given `tokenId`.
     */
    function prompt(uint256 tokenId) external view returns (string calldata);
}
