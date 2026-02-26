// SPDX-License-Identifier: CC0
pragma solidity ^0.8.7;

import "./interfaces/IEIP6617.sol";
import "./interfaces/IEIP6617Meta.sol";

contract EIP6617 is IEIP6617, IEIP6617Meta {
    mapping (address => uint256) private _permissions;
    mapping (uint256 => PermissionDescription) private _metadata;

    function hasPermission(address _user, uint256 _requiredPermission)
        external
        view
        returns (bool) {
            return _permissions[_user] & _requiredPermission == _requiredPermission;
        }

    function grantPermission(address _user, uint256 _permissionToAdd)
        external
        returns (bool) {
            _permissions[_user] |= _permissionToAdd;

            emit PermissionGranted(msg.sender, _permissionToAdd, _user);

            return true;
        }

    function revokePermission(address _user, uint256 _permissionToRevoke)
        external
        returns (bool) {
            _permissions[_user] = (_permissions[_user] | _permissionToRevoke) ^ _permissionToRevoke;

            emit PermissionRevoked(msg.sender, _permissionToRevoke, _user);

            return true;
        }

    function getPermissionDescription(uint256 _permission) external view returns (PermissionDescription memory description) {
        return _metadata[_permission];
    }

    function setPermissionDescription(uint256 _permission, string memory _name, string memory _description)
        external
        returns (bool success) {
            _metadata[_permission] = PermissionDescription(_permission, _name,_description);
        
            emit UpdatePermissionDescription(_permission, _name, _description);

            return true;
  }
}