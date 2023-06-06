// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

import "./interfaces/IEIP6617Meta.sol";

/**
 * @dev Implement the metadata of EIP-6617
 */
contract EIP6617Meta is IEIP6617Meta {
    /**
     * @dev Mapping permission value to permission's name
     */
    mapping(uint256 => string) private permissionNames;

    /**
     * @dev Mapping permission value to permission's description
     */
    mapping(uint256 => string) private permissionDescriptions;

    /**
     * @dev Get permission's description by value
     * @param _permission  Value of the permission
     */
    function getDescription(
        uint256 _permission
    )
        external
        view
        virtual
        override
        returns (PermissionDescription memory description)
    {
        return _getDescription(_permission);
    }

    /**
     * @dev Set the description of given permission
     * @param _permission Value of the permission
     * @param _name Name of the permission
     * @param _description Description of the permission
     */
    function setDescription(
        uint256 _permission,
        string memory _name,
        string memory _description
    ) external virtual override returns (bool) {
        // This method is empty, you should override this in your implement
        // Don't forget to protect this function to prevent anyone
        // from modifying the description of a permission
    }

    function _getDescription(
        uint256 _permission
    ) internal view returns (PermissionDescription memory description) {
        return
            PermissionDescription({
                permission: _permission,
                name: permissionNames[_permission],
                description: permissionDescriptions[_permission]
            });
    }

    function _setDescription(
        uint256 _permission,
        string memory _name,
        string memory _description
    ) internal returns (bool success) {
        permissionNames[_permission] = _name;
        permissionDescriptions[_permission] = _description;
        return true;
    }
}
