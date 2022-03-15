// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is very untested, and very insecure. Do not use!

import "./IDomain.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract NaiveDomain is IDomain, ERC165Storage, ERC165Checker {
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
        bool isPointable = !this.supportsInterface(subdomain, type(IDomain).interfaceId) || IDomain(subdomain).canPointSubdomain(updater, name, this);

        // Return
        return isPointable;
    }

    function canSetDomain(address updater, string memory name, address subdomain) public view returns (bool) {
        // Existence Check
        if (!this.hasDomain(name)) {
            return false;
        }

        // Pointable Check
        bool isPointable = !this.supportsInterface(subdomain, type(IDomain).interfaceId) || IDomain(subdomain).canPointSubdomain(updater, name, this);

        // Auth Check
        bool isMovable = this.supportsInterface(this.getDomain(name), type(IDomain).interfaceId) && IDomain(this.getDomain(name)).canMoveSubdomain(updater, name, this, subdomain);

        // Return
        return isMovable && isPointable;
    }

    function canDeleteDomain(address updater, string memory name) public view returns (bool) {
        // Existence Check
        if (!this.hasDomain(name)) {
            return false;
        }

        // Auth Check
        bool isDeletable = this.supportsInterface(this.getDomain(name), type(IDomain).interfaceId) && IDomain(this.getDomain(name)).canDeleteDomain(updater, name, this);

        // Return
        return isDeletable;
    }


    //// Subdomain Access Control
    
    function canMoveSubdomain(address updater, string memory name, IDomain parent, address newSubdomain) public virtual view returns (bool) {
        return true;
    }

    function canDeleteSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return true;
    }
}
