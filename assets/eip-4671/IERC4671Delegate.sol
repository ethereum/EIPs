// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Delegate is IERC4671 {
    /// @notice Grant one-time minting right to `operator` for `owner`
    /// An allowed operator can call the function to transfer rights.
    /// @param operator Address allowed to mint a badge
    /// @param owner Address for whom `operator` is allowed to mint a badge
    function delegate(address operator, address owner) external;

    /// @notice Grant one-time minting right to a list of `operators` for a corresponding list of `owners`
    /// An allowed operator can call the function to transfer rights.
    /// @param operators Addresses allowed to mint
    /// @param owners Addresses for whom `operators` are allowed to mint a badge
    function delegateBatch(address[] memory operators, address[] memory owners) external;

    /// @notice Mint a badge. Caller must have the right to mint for the owner.
    /// @param owner Address for whom the badge is minted
    function mint(address owner) external;

    /// @notice Mint badges to multiple addresses. Caller must have the right to mint for all owners.
    /// @param owners Addresses for whom the badges are minted
    function mintBatch(address[] memory owners) external;

    /// @notice Get the issuer of a badge
    /// @param badgeId Identifier of the badge
    /// @return Address who minted `badgeId`
    function issuerOf(uint256 badgeId) external view returns (address);
}