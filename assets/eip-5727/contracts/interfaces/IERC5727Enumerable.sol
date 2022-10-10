//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Enumerable Interface
 * @dev This extension allows querying the tokens of a soul.
 */
interface IERC5727Enumerable is IERC5727 {
    /**
     * @notice Get the total number of tokens emitted.
     * @return The total number of tokens emitted
     */
    function emittedCount() external view returns (uint256);

    /**
     * @notice Get the total number of souls.
     * @return The total number of souls
     */
    function soulsCount() external view returns (uint256);

    /**
     * @notice Get the tokenId with `index` of the `soul`.
     * @dev MUST revert if the `index` exceed the number of tokens owned by the `soul`.
     * @param soul The soul whose token is queried for.
     * @param index The index of the token queried for
     * @return The token is queried for
     */
    function tokenOfSoulByIndex(address soul, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @notice Get the tokenId with `index` of all the tokens.
     * @dev MUST revert if the `index` exceed the total number of tokens.
     * @param index The index of the token queried for
     * @return The token is queried for
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    /**
     * @notice Get the number of tokens owned by the `soul`.
     * @dev MUST revert if the `soul` does not have any token.
     * @param soul The soul whose balance is queried for
     * @return The number of tokens of the `soul`
     */
    function balanceOf(address soul) external view returns (uint256);

    /**
     * @notice Get if the `soul` owns any valid tokens.
     * @param soul The soul whose valid token infomation is queried for
     * @return if the `soul` owns any valid tokens
     */
    function hasValid(address soul) external view returns (bool);
}
