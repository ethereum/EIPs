//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Enumerable Interface
 * @dev This extension allows querying the tokens of a owner.
 */
interface IERC5727Enumerable is IERC5727 {
    /**
     * @notice Get the total number of tokens tracked by this contract.
     * @return The total number of tokens tracked by this contract
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Get the total number of owners.
     * @return The total number of owners
     */
    function ownersCount() external view returns (uint256);

    /**
     * @notice Get the tokenId with `index` of the `owner`.
     * @dev MUST revert if the `index` exceed the number of tokens owned by the `owner`.
     * @param owner The owner whose token is queried for.
     * @param index The index of the token queried for
     * @return The token is queried for
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
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
     * @notice Get the number of tokens owned by the `owner`.
     * @dev MUST revert if the `owner` does not have any token.
     * @param owner The owner whose balance is queried for
     * @return The number of tokens of the `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Get if the `owner` owns any valid tokens.
     * @param owner The owner whose valid token infomation is queried for
     * @return if the `owner` owns any valid tokens
     */
    function hasValid(address owner) external view returns (bool);
}
