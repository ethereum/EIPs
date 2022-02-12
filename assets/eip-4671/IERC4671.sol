// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC4671 is IERC165 {
    /// Event emitted when a badge `badgeId` is minted for `owner`
    event Minted(address owner, uint256 badgeId);

    /// Event emitted when badge `badgeId` of `owner` is invalidated
    event Invalidated(address owner, uint256 badgeId);

    /// @notice Count all badges assigned to an owner
    /// @param owner Address for whom to query the balance
    /// @return Number of badges owned by `owner`
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Get owner of a badge
    /// @param badgeId Identifier of the badge
    /// @return Address of the owner of `badgeId`
    function ownerOf(uint256 badgeId) external view returns (address);

    /// @notice Check if a badge hasn't been invalidated
    /// @param badgeId Identifier of the badge
    /// @return True if the badge is valid, false otherwise
    function isValid(uint256 badgeId) external view returns (bool);

    /// @notice Check if an address owns a valid badge in the contract
    /// @param owner Address for whom to check the ownership
    /// @return True if `owner` has a valid badge, false otherwise
    function hasValid(address owner) external view returns (bool);
}