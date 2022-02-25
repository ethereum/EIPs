// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import "./IERC165.sol";

// TODO: EIP-165 identifier

/// @title          ERC-4835 Heirarchal Domains Standard
/// @author         Pandapip1
/// @dev            https://eips.ethereum.org/EIPS/eip-4835
///                 The ERC-165 identifier for this interface is 0x1234 // TODO: ERC165
interface IDomain is IERC165 {
    //// Events
    
    /// @notice     Emitted when createDomain is called
    /// @param      sender msg.sender for createDomain
    /// @param      name name for createDomain
    /// @param      subdomain subdomain in createDomain
    event SubdomainCreate(address indexed sender, string name, IDomain subdomain);

    /// @notice     Emitted when setDomain is called
    /// @param      sender msg.sender for setDomain
    /// @param      name name for setDomain
    /// @param      subdomain subdomain in setDomain
    /// @param      oldSubdomain the old subdomain
    event SubdomainUpdate(address indexed sender, string name, IDomain subdomain, IDomain oldSubdomain);

    /// @notice     Emitted when deleteDomain is called
    /// @param      sender msg.sender for deleteDomain
    /// @param      name name for deleteDomain
    /// @param      subdomain the old subdomain
    event SubdomainDelete(address indexed sender, string name, IDomain subdomain);


    //// CRUD

    /// @notice     Query if a domain has a subdomain with a given name
    /// @param      name The subdomain to query
    /// @return     `true` if the domain has a subdomain with the given name, `false` otherwise
    function hasDomain(string memory name) external view returns (bool);

    /// @notice     Fetch the subdomain with a given name
    /// @dev        This should revert is `hasDomain(name)` is `false`
    /// @param      name The subdomain to fetch
    /// @return     The subdomain with the given name
    function getDomain(string memory name) external view returns (IDomain);

    /// @notice     Create a subdomain with a given name
    /// @dev        This should revert if `canCreateDomain(msg.sender, name, pointer)` is `false` or if the domain exists
    /// @param      name The subdomain name to be created
    /// @param      subdomain The subdomain to create
    function createDomain(string memory name, IDomain subdomain) external;

    /// @notice     Update a subdomain with a given name
    /// @dev        This should revert if `canSetDomain(msg.sender, name, pointer)` is `false` of if the domain doesn't exist
    /// @param      name The subdomain name to be updated
    /// @param      subdomain The subdomain to set
    function setDomain(string memory name, IDomain subdomain) external;

    /// @notice     Delete the subdomain with a given name
    /// @dev        This should revert if the domain doesn't exist or if
    ///             `canDeleteDomain(msg.sender, name, this)` is `false`
    /// @param      name The subdomain to delete
    function deleteDomain(string memory name) external;


    //// Parent Domain Access Control

    /// @notice     Get if an account can create a subdomain with a given name
    /// @dev        It is highly suggested to return `false` if `hasDomain(name)` is `true`
    ///             and `getDomain(name).canUpdateSubdomain(msg.sender, this, subdomain)` is `false`,
    ///             or if `subdomain.canPointSubdomain(msg.sender, name, this) is `false`
    /// @param      updater The account that may or may not be able to create/update a subdomain
    /// @param      name The subdomain name that would be created/updated
    /// @param      subdomain The subdomain that would be set
    /// @return     Whether an account can update or create the subdomain
    function canCreateDomain(address updater, string memory name, IDomain subdomain) external view returns (bool);

    /// @notice     Get if an account can update or create a subdomain with a given name
    /// @dev        It is highly suggested to return `false` if `hasDomain(name)` is `true`
    ///             and `getDomain(name).canUpdateSubdomain(msg.sender, this, subdomain)` is `false`,
    ///             or if `subdomain.canPointSubdomain(msg.sender, name, this) is `false`
    /// @param      updater The account that may or may not be able to create/update a subdomain
    /// @param      name The subdomain name that would be created/updated
    /// @param      subdomain The subdomain that would be set
    /// @return     Whether an account can update or create the subdomain
    function canSetDomain(address updater, string memory name, IDomain subdomain) external view returns (bool);

    /// @notice     Get if an account can delete the subdomain with a given name
    /// @dev        It is highly suggested to return `false` if `hasDomain(name)` is `true` and
    ///             `getDomain(name).canDeleteSubdomain(msg.sender, name, this)` is `false`
    /// @param      updater The account that may or may not be able to delete a subdomain
    /// @param      name The subdomain to delete
    /// @return     Whether an account can delete the subdomain
    function canDeleteDomain(address updater, string memory name) external view returns (bool);


    //// Subdomain Access Control

    /// @notice     Get if an account can point this domain as a subdomain
    /// @dev        May be called by `canSetDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may be moving the subdomain
    /// @param      name The subdomain name
    /// @param      parent The parent domain
    /// @return     Whether an account can update the subdomain
    function canPointSubdomain(address updater, string memory name, IDomain parent) external view returns (bool);

    /// @notice     Get if an account can move the subdomain away from the current domain
    /// @dev        May be called by `canSetDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may be moving the subdomain
    /// @param      name The subdomain name
    /// @param      parent The parent domain
    /// @param      newSubdomain The domain that will be set next
    /// @return     Whether an account can update the subdomain
    function canMoveSubdomain(address updater, string memory name, IDomain parent, IDomain newSubdomain) external view returns (bool);

    /// @notice     Get if an account can point this domain as a subdomain
    /// @dev        May be called by `canDeleteDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may or may not be able to delete a subdomain
    /// @param      name The subdomain to delete
    /// @param      parent The parent domain
    /// @return     Whether an account can delete the subdomain
    function canDeleteSubdomain(address updater, string memory name, IDomain parent) external view returns (bool);
}