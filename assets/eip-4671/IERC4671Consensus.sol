// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Consensus is IERC4671 {
    /// @notice Get voters addresses for this consensus contract
    /// @return Addresses of the voters
    function voters() external view returns (address[] memory);

    /// @notice Cast a vote to mint a badge for a specific address
    /// @param owner Address for whom to mint the badge
    function approveMint(address owner) external;

    /// @notice Cast a vote to invalidate a specific badge
    /// @param badgeId Identifier of the badge to invalidate
    function approveInvalidate(uint256 badgeId) external;
}