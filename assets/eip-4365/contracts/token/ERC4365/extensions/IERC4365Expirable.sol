// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IERC4365.sol";

/**
 * @dev Proposal of an interface for ERC-4365 tokens with an expiry date.
 * NOTE: The dates are stored as unix timestamps in seconds.
 */
interface IERC4365Expirable is IERC4365 {
    /**
     * @dev Sets the expiry date for the token of token type `id`.
     */
    function setExpiryDate(uint256 id, uint256 date) external;

    /**
     * @dev [Batched] version of {setExpiryDate}.
     */
    function setBatchExpiryDates(uint256[] memory ids, uint256[] memory dates) external;
    
    /**
     * @dev Returns the expiry date for the token of token type `id`.
     */
    function expiryDate(uint256 id) external view returns (uint256);

    /**
     * @dev Returns `true` or `false` depending on if the token of token type `id` has expired 
     * by comparing the expiry date with `block.timestamp`.
     */
    function isExpired(uint256 id) external view returns (bool);
}