// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import './interfaces/IEIP6366Meta.sol';
import './interfaces/IEIP6366Error.sol';

/**
 * @dev Implement the metadata of EIP-6366
 */
contract EIP6366Meta is IEIP6366Meta {
  /**
   * @dev Name of permission token
   */
  string private tname;

  /**
   * @dev Symbol of permission token
   */
  string private tsymbol;

  /**
   * @dev Mapping index to permission's name
   */
  mapping(uint256 => string) private permissionNames;

  /**
   * @dev Mapping index to permission's description
   */
  mapping(uint256 => string) private permissionDescriptions;

  /**
   * @dev Reverse mapping permission to index
   */
  mapping(uint256 => uint256) private permissionIndexs;

  /**
   * @dev Constructor of permission token
   */
  constructor(string memory _name, string memory _symbol) {
    tname = _name;
    tsymbol = _symbol;
  }

  /**
   * Get the name of permission token
   */
  function name() external view virtual override returns (string memory) {
    return tname;
  }

  /**
   * Get symbol of permission token
   */
  function symbol() external view virtual override returns (string memory) {
    return tsymbol;
  }

  /**
   * @dev Get permission's description by index
   * @param _index Index of description record
   */
  function getDescription(
    uint256 _index
  ) external view virtual override returns (PermissionDescription memory description) {
    return _getDescription(_index);
  }

  /**
   * @dev Set the description of given index
   * @param _index Description's index
   * @param _name Name of the permission
   * @param _description Description of the permission
   */
  function setDescription(
    uint256 _index,
    string memory _name,
    string memory _description
  ) external virtual override returns (bool) {
    // This method is empty, you should override this in your implement
  }

  function _getDescription(uint256 _index) internal view returns (PermissionDescription memory description) {
    return
      PermissionDescription({
        index: _index,
        permission: 2 ** _index,
        name: permissionNames[_index],
        description: permissionDescriptions[_index]
      });
  }

  function _setDescription(
    uint256 _index,
    string memory _name,
    string memory _description
  ) internal returns (bool success) {
    if (_index > 256) {
      revert IEIP6366Error.OutOfRange();
    }
    permissionIndexs[2 ** _index] = _index;
    permissionNames[_index] = _name;
    permissionDescriptions[_index] = _description;
    return true;
  }
}
