// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Enumerable is IERC4671 {
    /// @return Total number of badges emitted by the contract
    function total() external view returns (uint256);

    /// @notice Get the badgeId of a badge using its position in the owner's list
    /// @param owner Address for whom to get the badge
    /// @param index Index of the badge
    /// @return badgeId of the badge
    function badgeOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}