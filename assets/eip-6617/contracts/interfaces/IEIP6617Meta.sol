// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

/**
 * @dev Defined the interface of the metadata of EIP6617, MAY NOT be implemented
 */
interface IEIP6617Meta {
  /**
   * Structure of permission description
   * @param _permission     Permission
   * @param _name           Name of the permission
   * @param _description    Description of the permission
   */
  struct PermissionDescription {
    uint256 permission;
    string name;
    string description;
  }

  /**
   * MUST trigger when the description is updated.
   * @param _permission     Permission
   * @param _name           Name of the permission
   * @param _description    Description of the permission
   */
  event UpdatePermissionDescription(uint256 indexed _permission, string indexed _name, string indexed _description);

  /**
   * Returns the description of a given `_permission`.
   * @param _permission     Permission
   */
  function getDescription(uint256 _permission) external view returns (PermissionDescription memory description);

  /**
   * Return `true` if the description was set otherwise return `false`. It MUST emit `UpdatePermissionDescription` event.
   * @param _permission     Permission
   * @param _name           Name of the permission
   * @param _description    Description of the permission
   */
  function setDescription(
    uint256 _permission,
    string memory _name,
    string memory _description
  ) external returns (bool success);
}