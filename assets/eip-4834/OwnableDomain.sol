// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is very untested. Do not use!

import './IDomain.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Storage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract OwnableDomain is IDomain, ERC165Storage, Ownable {
    //// States
    mapping(string => address) public subdomains;
    mapping(string => bool) public subdomainsPresent;


    //// Constructor

    constructor() {
        _registerInterface(type(IDomain).interfaceId);
    }


    //// CRUD

    function hasDomain(string memory name) public view returns (bool) {
        return subdomainsPresent[name];
    }

    function getDomain(string memory name) public view returns (address) {
        require(this.hasDomain(name));
        return subdomains[name];
    }

    function createDomain(string memory name, address subdomain) public {
        require(!this.hasDomain(name));
        require(this.canCreateDomain(msg.sender, name, subdomain));
        
        subdomainsPresent[name] = true;
        subdomains[name] = subdomain;

        emit SubdomainCreate(msg.sender, name, subdomain);
    }

    function setDomain(string memory name, address subdomain) public {
        require(this.hasDomain(name));
        require(this.canSetDomain(msg.sender, name, subdomain));

        address oldSubdomain = subdomains[name];
        subdomains[name] = subdomain;

        emit SubdomainUpdate(msg.sender, name, subdomain, oldSubdomain);
    }

    function deleteDomain(string memory name) public {
        require(this.hasDomain(name));
        require(this.canDeleteDomain(msg.sender, name));

        subdomainsPresent[name] = false; // Only need to mark it as deleted

        emit SubdomainDelete(msg.sender, name, subdomains[name]);
    }


    //// Parent Domain Access Control

    function canCreateDomain(address updater, string memory name, address subdomain) public view returns (bool) {
        // Existence Check
        if (this.hasDomain(name)) {
            return false;
        }

        // Is user owner
        bool isTheOwner = this.owner() == updater;

        // Pointable Check
        IDomain subdomainAsDomain = subdomain;
        bool canPoint = true;
        try subdomainAsDomain.supportsInterface(type(IDomain).interfaceId) returns (bool isDomain) {
            if (isDomain) {
                canPoint = subdomainAsDomain.canPointSubdomain(updater, name, this);
            }
        } catch (bytes memory /*lowLevelData*/) { }
        if (!canPoint) {
            return false;
        }

        // Default
        return isTheOwner;
    }

    function canSetDomain(address updater, string memory name, address subdomain) public view returns (bool) {
        // Existence Check
        if (!this.hasDomain(name)) {
            return false;
        }

        // Is user owner
        bool isTheOwner = this.owner() == updater;

        // Pointable Check
        IDomain subdomainAsDomain = subdomain;
        bool canPoint = true;
        try subdomainAsDomain.supportsInterface(type(IDomain).interfaceId) returns (bool isDomain) {
            if (isDomain) {
                canPoint = subdomainAsDomain.canPointSubdomain(updater, name, this);
            }
        } catch (bytes memory /*lowLevelData*/) { }
        if (!canPoint) {
            return false;
        }

        // Permissions Check
        IDomain currentAsDomain = subdomains[name];
        bool canMove = isTheOwner;
        try currentAsDomain.supportsInterface(type(IDomain).interfaceId) returns (bool isDomain) {
            if (isDomain) {
                canMove = currentAsDomain.canMoveSubdomain(updater, name, this, subdomain);
            }
        } catch (bytes memory /*lowLevelData*/) { }
        if (!canMove) {
            return false;
        }

        // Default
        return true;
    }

    function canDeleteDomain(address updater, string memory name) public view returns (bool) {
        // Existence Check
        if (!this.hasDomain(name)) {
            return false;
        }

        // Is user owner
        bool isTheOwner = this.owner() == updater;

        // Permissions Check
        IDomain currentAsDomain = subdomains[name];
        bool canDel = isTheOwner;
        try currentAsDomain.supportsInterface(type(IDomain).interfaceId) returns (bool isDomain) {
            if (isDomain) {
                canDel = currentAsDomain.canDeleteSubdomain(updater, name, this);
            }
        } catch (bytes memory /*lowLevelData*/) { }
        if (!canDel) {
            return false;
        }

        // Default
        return true;
    }

    //// Subdomain Access Control

    function canPointSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return true;
    }

    function canMoveSubdomain(address updater, string memory name, IDomain parent, address newSubdomain) public virtual view returns (bool) {
        return this.owner() == updater;
    }

    function canDeleteSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return this.owner() == updater;
    }
}
