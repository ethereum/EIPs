// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is very untested, and very insecure. Do not use!

import './IDomain.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Storage.sol';

contract NaiveDomain is IDomain, ERC165Storage {
    //// States
    mapping(string => IDomain) public subdomains;
    mapping(string => bool) public subdomainsPresent;

    //// Constructor

    constructor() {
        _registerInterface(type(IDomain).interfaceId);
    }


    //// CRUD

    function hasDomain(string memory name) public view returns (bool) {
        return subdomainsPresent[name];
    }

    function getDomain(string memory name) public view returns (IDomain) {
        require(this.hasDomain(name));
        return subdomains[name];
    }

    function createDomain(string memory name, IDomain subdomain) public {
        require(!this.hasDomain(name));
        require(this.canCreateDomain(msg.sender, name, subdomain));
        
        subdomainsPresent[name] = true;
        subdomains[name] = subdomain;

        emit SubdomainCreate(msg.sender, name, subdomain);
    }

    function setDomain(string memory name, IDomain subdomain) public {
        require(this.hasDomain(name));
        require(this.canSetDomain(msg.sender, name, subdomain));

        IDomain oldSubdomain = subdomains[name];
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

    function canCreateDomain(address updater, string memory name, IDomain subdomain) public view returns (bool) {
        return subdomain.canPointSubdomain(updater, name, this);
    }

    function canSetDomain(address updater, string memory name, IDomain subdomain) public view returns (bool) {
        return subdomains[name].canMoveSubdomain(updater, name, this, subdomain) && subdomain.canPointSubdomain(updater, name, this);
    }

    function canDeleteDomain(address updater, string memory name) public view returns (bool) {
        return subdomains[name].canDeleteSubdomain(updater, name, this);
    }


    //// Subdomain Access Control

    function canPointSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return true;
    }

    function canMoveSubdomain(address updater, string memory name, IDomain parent, IDomain newSubdomain) public virtual view returns (bool) {
        return true;
    }

    function canDeleteSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return true;
    }
}
