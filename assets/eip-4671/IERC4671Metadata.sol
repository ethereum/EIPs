// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Metadata is IERC4671 {
    /// @return Descriptive name of the badges in this contract
    function name() external view returns (string memory);

    /// @return An abbreviated name of the badges in this contract
    function symbol() external view returns (string memory);

    /// @notice URI to query to get the badge's metadata
    /// @param badgeId Identifier of the badge
    /// @return URI for the badge
    function badgeURI(uint256 badgeId) external view returns (string memory);
}