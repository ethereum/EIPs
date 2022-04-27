// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title          ERC-4835 Heirarchal Domains Standard
/// @author         Pandapip1
/// @dev            https://eips.ethereum.org/EIPS/eip-4835
interface IDomain is IERC165 {
    //// Events
    
    /// @notice     Must be emitted when a new subdomain is created (eg. through `createDomain`.)
    /// @param      sender msg.sender for createDomain
    /// @param      name name for createDomain
    /// @param      subdomain subdomain in createDomain
    event SubdomainCreate(address indexed sender, string name, address subdomain);

    /// @notice     Must be emitted when the resolved address for a domain is changed (eg. with `setDomain`)
    /// @param      sender msg.sender for setDomain
    /// @param      name name for setDomain
    /// @param      subdomain subdomain in setDomain
    /// @param      oldSubdomain the old subdomain
    event SubdomainUpdate(address indexed sender, string name, address subdomain, address oldSubdomain);

    /// @notice     Must be emitted when a domain is unmapped (eg. with `deleteDomain`)
    /// @param      sender msg.sender for deleteDomain
    /// @param      name name for deleteDomain
    /// @param      subdomain the old subdomain
    event SubdomainDelete(address indexed sender, string name, address subdomain);


    //// CRUD

    /// @notice     Query if a domain has a subdomain with a given name
    /// @param      name The subdomain to query
    /// @return     `true` if the domain has a subdomain with the given name, `false` otherwise
    function hasDomain(string memory name) external view returns (bool);

    /// @notice     Fetch the subdomain with a given name
    /// @dev        This should revert if `hasDomain(name)` is `false`
    /// @param      name The subdomain to fetch
    /// @return     The subdomain with the given name
    function getDomain(string memory name) external view returns (address);

    /// @notice     Query all subdomains. Must revert if the list of domains is unknown or infinite.
    /// @return     The list of all subdomains.
    function listDomains() external view returns (string[] memory);

    /// @notice     Create a subdomain with a given name
    /// @dev        This should revert if `canCreateDomain(msg.sender, name, pointer)` is `false` or if the domain exists
    /// @param      name The subdomain name to be created
    /// @param      subdomain The subdomain to create
    function createDomain(string memory name, address subdomain) external;

    /// @notice     Update a subdomain with a given name
    /// @dev        This should revert if `canSetDomain(msg.sender, name, pointer)` is `false` of if the domain does not exist
    /// @param      name The subdomain name to be updated
    /// @param      subdomain The subdomain to set
    function setDomain(string memory name, address subdomain) external;

    /// @notice     Delete the subdomain with a given name
    /// @dev        This should revert if the domain does not exist or if
    ///             `canDeleteDomain(msg.sender, name, this)` is `false`
    /// @param      name The subdomain to delete
    function deleteDomain(string memory name) external;


    //// Parent Domain Access Control

    /// @notice     Get if an account can create a subdomain with a given name
    /// @dev        This must return `false` if `hasDomain(name)` is `true`.
    /// @param      updater The account that may or may not be able to create/update a subdomain
    /// @param      name The subdomain name that would be created/updated
    /// @param      subdomain The subdomain that would be set
    /// @return     Whether an account can update or create the subdomain
    function canCreateDomain(address updater, string memory name, address subdomain) external view returns (bool);

    /// @notice     Get if an account can update or create a subdomain with a given name
    /// @dev        This must return `false` if `hasDomain(name)` is `false`.
    ///             If `getDomain(name)` is also a domain, this should return `false` if
    ///             `getDomain(name).canMoveSubdomain(msg.sender, this, subdomain)` is `false`.
    /// @param      updater The account that may or may not be able to create/update a subdomain
    /// @param      name The subdomain name that would be created/updated
    /// @param      subdomain The subdomain that would be set
    /// @return     Whether an account can update or create the subdomain
    function canSetDomain(address updater, string memory name, address subdomain) external view returns (bool);

    /// @notice     Get if an account can delete the subdomain with a given name
    /// @dev        This must return `false` if `hasDomain(name)` is `false`.
    ///             If `getDomain(name)` is a domain, this should return `false` if
    ///             `getDomain(name).canDeleteSubdomain(msg.sender, this, subdomain)` is `false`.
    /// @param      updater The account that may or may not be able to delete a subdomain
    /// @param      name The subdomain to delete
    /// @return     Whether an account can delete the subdomain
    function canDeleteDomain(address updater, string memory name) external view returns (bool);


    //// Subdomain Access Control

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