// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;
import "./interfaces/IEIP6366Meta.sol";
import "./interfaces/IEIP6366Error.sol";

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
     * @dev Mapping permission value to permission's name
     */
    mapping(uint256 => string) private permissionNames;

    /**
     * @dev Mapping permission value to permission's description
     */
    mapping(uint256 => string) private permissionDescriptions;

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
