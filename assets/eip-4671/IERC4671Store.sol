// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC4671Store is IERC165 {
    // Event emitted when a IERC4671Enumerable contract is added to the owner's records
    event Added(address owner, address badge);

    // Event emitted when a IERC4671Enumerable contract is removed from the owner's records
    event Removed(address owner, address badge);

    /// @notice Add a IERC4671Enumerable contract address to the caller's record
    /// @param badge Address of the IERC4671Enumerable contract to add
    function add(address badge) external;

    /// @notice Remove a IERC4671Enumerable contract from the caller's record
    /// @param badge Address of the IERC4671Enumerable contract to remove
    function remove(address badge) external;

    /// @notice Get all the IERC4671Enumerable contracts for a given owner
    /// @param owner Address for which to retrieve the IERC4671Enumerable contracts
    function get(address owner) external view returns (address[] memory);
}