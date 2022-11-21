//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Expirable Interface
 * @dev This extension allows soulbound tokens to be expired.
 */
interface IERC5727Expirable is IERC5727 {
    /**
     * @notice Get the expire date of a token.
     * @dev MUST revert if the `tokenId` token does not exist.
     * @param tokenId The token for which the expiry date is queried
     * @return The expiry date of the token
     */
    function expiryDate(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get if a token is expired.
     * @dev MUST revert if the `tokenId` token does not exist.
     * @param tokenId The token for which the expired status is queried
     * @return If the token is expired
     */
    function isExpired(uint256 tokenId) external view returns (bool);

    /**
     * @notice Set the expiry date of a token.
     * @dev MUST revert if the `tokenId` token does not exist.
     *   MUST revert if the `date` is in the past.
     * @param tokenId The token whose expiry date is set
     * @param date The expire date to set
     */
    function setExpiryDate(uint256 tokenId, uint256 date) external;

    /**
     * @notice Set the expiry date of multiple tokens.
     * @dev MUST revert if the `tokenIds` tokens does not exist.
     *   MUST revert if the `dates` is in the past.
     *   MUST revert if the length of `tokenIds` and `dates` do not match.
     * @param tokenIds The tokens whose expiry dates are set
     * @param dates The expire dates to set
     */
    function setBatchExpiryDates(
        uint256[] memory tokenIds,
        uint256[] memory dates
    ) external;
}
