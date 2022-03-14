// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is very untested, and very insecure. Do not use!

import './IDomain.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Storage.sol';

contract NaiveDomain is IDomain, ERC165Storage {
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
        require(this.canCreateDomain(msg.sender, name, subdomain));
        
        subdomainsPresent[name] = true;
        subdomains[name] = subdomain;

        emit SubdomainCreate(msg.sender, name, subdomain);
    }

    function setDomain(string memory name, address subdomain) public {
        require(this.canSetDomain(msg.sender, name, subdomain));

        address oldSubdomain = subdomains[name];
        subdomains[name] = subdomain;

        emit SubdomainUpdate(msg.sender, name, subdomain, oldSubdomain);
    }

    function deleteDomain(string memory name) public {
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
        return true;
    }

    function canSetDomain(address updater, string memory name, address subdomain) public view returns (bool) {
        // Existence Check
        if (!this.hasDomain(name)) {
            return false;
        }

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
        bool canMove = true;
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

        // Permissions Check
        IDomain currentAsDomain = subdomains[name];
        bool canDel = true;
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
        return true;
    }

    function canDeleteSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return true;
    }
}
