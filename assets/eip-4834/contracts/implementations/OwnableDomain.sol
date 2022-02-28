// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is very untested. Do not use!

import '../interfaces/IDomain.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Storage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @title          ERC-4834 Ownable Implementation
/// @author         Pandapip1 (@Pandapip1)
/// @notice         https://eips.ethereum.org/EIPS/eip-4834
contract OwnableDomain is IDomain, ERC165Storage, Ownable {
    //// States
    mapping(string => IDomain) public subdomains;
    mapping(string => bool) public subdomainsPresent;


    //// Constructor

    constructor() {
        _registerInterface(0x1234); // TODO: ERC165
    }


    //// CRUD

    /// @notice     Query if a domain has a subdomain with a given name
    /// @param      name The subdomain to query
    /// @return     `true` if the domain has a subdomain with the given name, `false` otherwise
    function hasDomain(string memory name) external view returns (bool) {
        return subdomainsPresent[name];
    }

    /// @notice     Fetch the subdomain with a given name
    /// @dev        This should revert is `hasDomain(name)` is `false`
    /// @param      name The subdomain to fetch
    /// @return     The subdomain with the given name
    function getDomain(string memory name) external view returns (IDomain) {
        require(this.hasDomain(name));
        return subdomains[name];
    }

    /// @notice     Create a subdomain with a given name
    /// @dev        This should revert if `canCreateDomain(msg.sender, name, pointer)` is `false`
    /// @param      name The subdomain name to be created
    /// @param      subdomain The subdomain to create
    function createDomain(string memory name, IDomain subdomain) external {
        require(!this.hasDomain(name));
        require(this.canCreateDomain(msg.sender, name, subdomain));
        
        subdomainsPresent[name] = true;
        subdomains[name] = subdomain;

        emit SubdomainCreate(msg.sender, name, subdomain);
    }

    /// @notice     Update a subdomain with a given name
    /// @dev        This should revert if `canSetDomain(msg.sender, name, pointer)` is `false`
    /// @param      name The subdomain name to be updated
    /// @param      subdomain The subdomain to set
    function setDomain(string memory name, IDomain subdomain) external {
        require(this.hasDomain(name));
        require(this.canSetDomain(msg.sender, name, subdomain));

        IDomain oldSubdomain = subdomains[name];
        subdomains[name] = subdomain;

        emit SubdomainUpdate(msg.sender, name, subdomain, oldSubdomain);
    }

    /// @notice     Delete the subdomain with a given name
    /// @dev        This should revert is `hasDomain(name)` is `false` or if
    ///             `canDeleteDomain(msg.sender, name, this)` is `false`
    /// @param      name The subdomain to delete
    function deleteDomain(string memory name) external {
        require(this.hasDomain(name));
        require(this.canDeleteDomain(msg.sender, name));

        subdomainsPresent[name] = false; // Only need to mark it as deleted

        emit SubdomainDelete(msg.sender, name, subdomains[name]);
    }


    //// Pare   nt Domain Access Control

    /// @notice     Get if an account can create a subdomain with a given name
    /// @dev        It is highly suggested to return `false` if `hasDomain(name)` is `true`
    ///             and `getDomain(name).canUpdateSubdomain(msg.sender, this, subdomain)` is `false`,
    ///             or if `subdomain.canPointSubdomain(msg.sender, name, this) is `false`
    /// @param      updater The account that may or may not be able to create/update a subdomain
    /// @param      name The subdomain name that would be created/updated
    /// @param      subdomain The subdomain that would be set
    /// @return     Whether an account can update or create the subdomain
    function canCreateDomain(address updater, string memory name, IDomain subdomain) external view returns (bool) {
        return owner() == updater || subdomain.canPointSubdomain(updater, name, this);
    }

    /// @notice     Get if an account can update or create a subdomain with a given name
    /// @dev        It is highly suggested to return `false` if
    ///             `subdomains[name].canUpdateSubdomain(msg.sender, this, subdomain)` is `false`,
    ///             or if `subdomain.canPointSubdomain(msg.sender, name, this) is `false`
    /// @param      updater The account that may or may not be able to create/update a subdomain
    /// @param      name The subdomain name that would be created/updated
    /// @param      subdomain The subdomain that would be set
    /// @return     Whether an account can update or create the subdomain
    function canSetDomain(address updater, string memory name, IDomain subdomain) external view returns (bool) {
        return owner() == updater || subdomains[name].canMoveSubdomain(updater, name, this, subdomain) && subdomain.canPointSubdomain(updater, name, this);
    }

    /// @notice     Get if an account can delete the subdomain with a given name
    /// @dev        It is highly suggested to return `false` if `getDomain(name).canDeleteSubdomain(msg.sender, name, this)` is `false`
    /// @param      updater The account that may or may not be able to delete a subdomain
    /// @param      name The subdomain to delete
    /// @return     Whether an account can delete the subdomain
    function canDeleteDomain(address updater, string memory name) external view returns (bool) {
        return owner() == updater || subdomains[name].canDeleteSubdomain(updater, name, this);
    }


    //// Subdomain Access Control

    /// @notice     Get if an account can point this domain as a subdomain
    /// @dev        May be called by `canSetDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may be moving the subdomain
    /// @param      name The subdomain name
    /// @param      parent The parent domain
    /// @return     Whether an account can update the subdomain
    function canPointSubdomain(address updater, string memory name, IDomain parent) external virtual view returns (bool) {
        return owner() == updater;
    }

    /// @notice     Get if an account can move the subdomain away from the current domain
    /// @dev        May be called by `canSetDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may be moving the subdomain
    /// @param      name The subdomain name
    /// @param      parent The parent domain
    /// @param      newSubdomain The domain that will be set next
    /// @return     Whether an account can update the subdomain
    function canMoveSubdomain(address updater, string memory name, IDomain parent, IDomain newSubdomain) external virtual view returns (bool) {
        return owner() == updater;
    }

    /// @notice     Get if an account can point this domain as a subdomain
    /// @dev        May be called by `canDeleteDomain` of the parent domain - implement access control here!!!
    /// @param      updater The account that may or may not be able to delete a subdomain
    /// @param      name The subdomain to delete
    /// @param      parent The parent domain
    /// @return     Whether an account can delete the subdomain
    function canDeleteSubdomain(address updater, string memory name, IDomain parent) external virtual view returns (bool) {
        return owner() == updater;
    }
}
