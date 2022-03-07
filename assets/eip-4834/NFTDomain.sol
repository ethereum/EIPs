// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is very untested and not very well-implemented anyways. Do not use!

import './IDomain.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Storage.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';


contract NFTDomain is IDomain, ERC165Storage, ERC721Enumerable {
    //// States
    mapping(string => IDomain) public subdomains;
    mapping(string => bool) public subdomainsPresent;


    //// Constructor

    constructor() ERC721("Basic ERC721 Domain", "ERC4834") {
        _registerInterface(type(IDomain).interfaceId);
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        _registerInterface(type(IERC721Enumerable).interfaceId);
        _mint(msg.sender, 0);
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
        return ownerOf(0) == updater || subdomain.canPointSubdomain(updater, name, this);
    }

    function canSetDomain(address updater, string memory name, IDomain subdomain) public view returns (bool) {
        return ownerOf(0) == updater || subdomains[name].canMoveSubdomain(updater, name, this, subdomain) && subdomain.canPointSubdomain(updater, name, this);
    }

    function canDeleteDomain(address updater, string memory name) public view returns (bool) {
        return ownerOf(0) == updater || subdomains[name].canDeleteSubdomain(updater, name, this);
    }


    //// Subdomain Access Control

    function canPointSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return ownerOf(0) == updater;
    }

    function canMoveSubdomain(address updater, string memory name, IDomain parent, IDomain newSubdomain) public virtual view returns (bool) {
        return ownerOf(0) == updater;
    }

    function canDeleteSubdomain(address updater, string memory name, IDomain parent) public virtual view returns (bool) {
        return ownerOf(0) == updater;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165, ERC165Storage) returns (bool) {
        return ERC165Storage(this).supportsInterface(interfaceId);
    }
}
