// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is an example for how canMoveDomain can be abused. Do not use this for an actual domain, it might work.

import "./IDomain.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract BlackHole is IDomain, ERC165Storage {
    //// Constructor

    constructor() {
        _registerInterface(type(IDomain).interfaceId);
    }


    //// Well, "crud."

    function hasDomain(string memory name) public view returns (bool) {
        return true;
    }

    function getDomain(string memory name) public view returns (address) {
        return this;
    }
    
    function listDomains() external view returns (string[] memory) {
        return [];
    }

    function createDomain(string memory name, address subdomain) public {
        require(false);
    }

    function setDomain(string memory name, address subdomain) public {
        require(false);
    }

    function deleteDomain(string memory name) public {
        require(false);
    }


    //// Parent Domain Access Control

    function canCreateDomain(address updater, string memory name, address subdomain) public view returns (bool) {
        return false;
    }

    function canSetDomain(address updater, string memory name, address subdomain) public view returns (bool) {
        return false;
    }

    function canDeleteDomain(address updater, string memory name) public view returns (bool) {
        return false;
    }


    //// Subdomain Access Control

    function canMoveSubdomain(address updater, string memory name, IDomain parent, address newSubdomain) public virtual view returns (bool) {
        return false; // Exploit: part 1
    }

    function canDeleteSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return false; // Exploit: part 2
    }
}
