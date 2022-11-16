// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import "./IDomain.sol";

/// @title          ERC-4835 Heirarchal Domains Standard (Access Control Extension)
/// @author         Pandapip1
/// @dev            https://eips.ethereum.org/EIPS/eip-4835
interface IDomainAccessControl is IDomain {
    /// @notice     Get if an account can move the subdomain away from the current domain
    /// @dev        May be called by `canSetDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may be moving the subdomain
    /// @param      name The subdomain name
    /// @param      parent The parent domain
    /// @param      newSubdomain The domain that will be set next
    /// @return     Whether an account can update the subdomain
    function canMoveSubdomain(address updater, string memory name, IDomain parent, address newSubdomain) external view returns (bool);

    /// @notice     Get if an account can unset this domain as a subdomain
    /// @dev        May be called by `canDeleteDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may or may not be able to delete a subdomain
    /// @param      name The subdomain to delete
    /// @param      parent The parent domain
    /// @return     Whether an account can delete the subdomain
    function canDeleteSubdomain(address updater, string memory name, IDomain parent) external view returns (bool);
}
