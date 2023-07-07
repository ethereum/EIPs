// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';


contract AgentRoleFund is OwnableUpgradeable, AccessControlUpgradeable {

    bytes32 public constant SubAdmin_Role = keccak256("SubAdmin_Role");
    bytes32 public constant Agent_Role = keccak256("Agent_Role");

    event AgentAdded(address indexed _agent);
    event AgentRemoved(address indexed _agent);


    modifier onlyAgent() {
        require(isAgent(msg.sender), 'AgentRole: caller does not have the Agent role');
        _;
    }

    modifier onlyAdmins {
        require(hasRole(SubAdmin_Role, _msgSender()) || owner() == _msgSender(), 'You Dont Have Admin Role');
        _;
    }

    function _msgSender() internal view virtual override returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        return msg.data;
    }

    function addSubAdmin(address _user) virtual public onlyAdmins {
        _setupRole(SubAdmin_Role, _user);
    }

    function revokeSubAdmin(address _user) virtual public onlyAdmins {
        require(isSubAdmin(_user), "Doesn't have Owner Role");
        _revokeRole(SubAdmin_Role, _user);
    }

    function isSubAdmin (address _user) public view returns (bool){
        return hasRole(SubAdmin_Role, _user);
    }

    function isAgent(address _user) public view returns (bool) {
        return hasRole(Agent_Role, _user);
    }

    function addAgent(address _user) public onlyAdmins {
        _setupRole(Agent_Role, _user);
        emit AgentAdded(_user);
    }

    function removeAgent(address _user) public onlyAdmins {
        _revokeRole(Agent_Role, _user);
        emit AgentRemoved(_user);
    }
}