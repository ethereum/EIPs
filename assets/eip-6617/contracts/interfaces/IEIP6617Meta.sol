//SPDX-License-Identifier: CC0
pragma solidity ^0.8.7;

interface IEIP6617Meta {
  struct PermissionDescription {
    uint256 permission;
    string name;
    string description;
  }

  event UpdatePermissionDescription(uint256 indexed _permission, string indexed _name, string indexed _description);

  function getPermissionDescription(uint256 _permission) external view returns (PermissionDescription memory description);

  function setPermissionDescription(
    uint256 _permission,
    string memory _name,
    string memory _description
  ) external returns (bool success);
}