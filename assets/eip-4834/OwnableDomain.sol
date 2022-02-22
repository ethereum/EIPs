// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// NOTE: This is very untested!!!

contract Ownable
{
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor()
    public
  {
    owner = msg.sender;
  }

  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/// @title          ERC-TODO Hierarchical Domains Standard Implementation
/// @author         Pandapip1
/// @notice         https://eips.ethereum.org/EIPS/eip-TODO
contract IDomain is IDomain, Ownable {
    //// States
    mapping(string => IDomain) public subdomains;
    mapping(string => bool) public subdomainsPresent;

    //// CRUD

    function hasDomain(string memory name) external view returns (bool) {
        return subdomainsPresent[name];
    }

    function getDomain(string memory name) external view returns (IDomain) {
        require(hasDomain(name));
        return subdomains[name];
    }
    
    function setDomain(string memory name, IDomain subdomain) external {
        require(canSetDomain(msg.sender, name, subdomain));
        subdomains[name] = subdomain;
        subdomainsPresent[name] = true;
    }

    function deleteDomain(string memory name) external {
        require(canDeleteDomain(msg.sender, name));
        subdomainsPresent[name] = false;
    }


    //// Access Control

    function canSetDomain(address updater, string memory name, IDomain subdomain) external view returns (bool) {
        if (hasDomain(name)) {
            return (updater == this.owner || getDomain(name).canSetSubdomain(updater, name, this, subdomain)) && subdomain.canPointSubdomain(sender, name, this);
        } else {
            return msg.sender == this.owner && subdomain.canPointSubdomain(updater, name, this);
        }
    }
    
    function canSetSubdomain(address updater, string memory name, IDomain parent, IDomain newSubdomain) external view returns (bool) {
        return updater == this.owner;
    }

    function canPointSubdomain(address updater, string memory name, IDomain parent) external view returns (bool) {
        return true;
    }

    function canDeleteDomain(address updater, string memory name) external view returns (bool) {
        return hasDomain(name) && (updater == this.owner || getDomain(name).canDeleteSubdomain(updater, name, this));
    }
    
    function canDeleteSubdomain(address updater, string memory name, IDomain parent) external view returns (bool) {
        return updater == this.owner;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return interfaceID == 0xTODO;
    }
}
