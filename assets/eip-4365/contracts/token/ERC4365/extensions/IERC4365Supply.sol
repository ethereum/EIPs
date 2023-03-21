// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IERC4365.sol";

/**
 * @dev Proposal of an interface for ERC-4365 tokens with a max supply.
 */
interface IERC4365Supply is IERC4365 {
    /**
     * @dev Sets the max supply for the token of token type `id`.
     */
    function setMaxSupply(uint256 id, uint256 amount) external;

    /**
     * @dev [Batched] version of {setMaxSupply}.
     */
    function setBatchMaxSupplies(uint256[] memory ids, uint256[] memory amounts) external;

    /**
     * @dev Returns the total supply for token of token type `id`.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Returns the max supply for token of token type `id`.
     */
    function maxSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token of token type `id` exists, or not.
     */
    function exists(uint256 id) external view returns (bool);
}