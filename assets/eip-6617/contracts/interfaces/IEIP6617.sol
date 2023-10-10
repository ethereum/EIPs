//SPDX-License-Identifier: CC0

pragma solidity ^0.8.7;

interface IEIP6617 {

    event PermissionGranted(address indexed _grantor, uint256 indexed _permission, address indexed _user);
    event PermissionRevoked(address indexed _revoker, uint256 indexed _permission, address indexed _user);

    function hasPermission(address _user, uint256 _requiredPermission)
        external
        view
        returns (bool);

    function grantPermission(address _user, uint256 _permissionToAdd)
        external
        returns (bool);

    function revokePermission(address _user, uint256 _permissionToRemove)
        external
        returns (bool);
}