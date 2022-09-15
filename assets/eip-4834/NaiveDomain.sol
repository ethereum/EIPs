// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is very untested, and very insecure. Do not use!

import "./IDomain.sol";
import "./IDomainAccessControl.sol";
import "./IDomainEnumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract NaiveDomain is IDomain, IDomainAccessControl, IDomainEnumerable, ERC165Storage, ERC165Checker {
    //// States
    mapping(string => address) public subdomains;
    mapping(string => bool) public subdomainsPresent;
    mapping(string => uint) public subdomainIndeces;
    string[] public subdomainList;

    //// Constructor

    constructor() {
        _registerInterface(type(IDomain).interfaceId);
        _registerInterface(type(IDomainAccessControl).interfaceId);
        _registerInterface(type(IDomainEnumerable).interfaceId);
    }


    //// CRUD

    function hasDomain(string memory name) public view returns (bool) {
        return subdomainsPresent[name];
    }

    function getDomain(string memory name) public view returns (address) {
        require(this.hasDomain(name));
        return subdomains[name];
    }

    function listDomains() external view returns (string[] memory) {
        return subdomainList;
    }

    function createDomain(string memory name, IDomain subdomain) public {
        require(!this.hasDomain(name));
        require(this.canCreateDomain(msg.sender, name, subdomain));
        
        subdomainsPresent[name] = true;
        subdomains[name] = subdomain;

        subdomainIndeces[name] = subdomainList.length;
        subdomainList.push(name);

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
        delete subdomainList[subdomainIndeces[name]]; // Remove subdomain from list

        emit SubdomainDelete(msg.sender, name, subdomains[name]);
    }


    //// Parent Domain Access Control

    function canCreateDomain(address updater, string memory name, address subdomain) public view returns (bool) {
        // Existence Check
        if (this.hasDomain(name)) {
            return false;
        }

        // Return
        return true;
    }

    function canSetDomain(address updater, string memory name, address subdomain) public view returns (bool) {
        // Existence Check
        if (!this.hasDomain(name)) {
            return false;
        }

        // Auth Check
        bool isMovable = this.supportsInterface(this.getDomain(name), type(IDomainAccessControl).interfaceId) && IDomainAccessControl(this.getDomain(name)).canMoveSubdomain(updater, name, this, subdomain);

        // Return
        return isMovable;
    }

    function canDeleteDomain(address updater, string memory name) public view returns (bool) {
        // Existence Check
        if (!this.hasDomain(name)) {
            return false;
        }

        // Auth Check
        bool isDeletable = this.supportsInterface(this.getDomain(name), type(IDomainAccessControl).interfaceId) && IDomainAccessControl(this.getDomain(name)).canDeleteSubdomain(updater, name, this);

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
