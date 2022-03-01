// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is an example for how canMoveDomain can be abused. Do not use this for an actual domain, it might work.

import './IDomain.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Storage.sol';

/// @title          ERC-4834 Demo Potential Exploit
/// @author         Pandapip1 (@Pandapip1)
/// @notice         https://eips.ethereum.org/EIPS/eip-4834
contract BlackHole is IDomain, ERC165Storage {
    //// Constructor

    constructor() {
        _registerInterface(0x1234); // TODO: ERC165
    }


    //// Well, "crud."

    function hasDomain(string memory name) public view returns (bool) {
        return true;
    }

    function getDomain(string memory name) public view returns (IDomain) {
        return this;
    }

    function createDomain(string memory name, IDomain subdomain) public {
        require(false);
    }

    function setDomain(string memory name, IDomain subdomain) public {
        require(false);
    }

    function deleteDomain(string memory name) public {
        require(false);
    }


    //// Parent Domain Access Control

    function canCreateDomain(address updater, string memory name, IDomain subdomain) public view returns (bool) {
        return false;
    }

    function canSetDomain(address updater, string memory name, IDomain subdomain) public view returns (bool) {
        return false;
    }

    function canDeleteDomain(address updater, string memory name) public view returns (bool) {
        return false;
    }


    //// Subdomain Access Control

    function canPointSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return true;
    }

    function canMoveSubdomain(address updater, string memory name, IDomain parent, IDomain newSubdomain) public virtual view returns (bool) {
        return false; // Exploit: part 1
    }

    function canDeleteSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return false; // Exploit: part 2
    }
}
