// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;
import "./interfaces/IEIP6366Error.sol";
import "./interfaces/IEIP6366Core.sol";

/**
 * @dev Implement the core of EIP-6366
 */
contract EIP6366Core is IEIP6366Core {
    /**
     * @dev Stored permission of an address
     */
    mapping(address => uint256) private permissions;

    /**
     * @dev Stored delegation information
     */
    mapping(bytes32 => uint256) private delegations;

    /**
     * @dev Transfer a subset of owning permission to a target address
     * @param _to New permission owner's address
     * @param _permission A subset of owning permission
     */
    function transfer(
        address _to,
        uint256 _permission
    ) external virtual override returns (bool success) {
        return _transfer(_to, _permission);
    }

    /**
     * @dev Allowed a delegatee to act for permission owner's behalf
     * @param _delegatee Delegatee address
     * @param _permission A subset of permission
     */
    function approve(
        address _delegatee,
        uint256 _permission
    ) external virtual override returns (bool success) {
        return _approve(_delegatee, _permission);
    }

    /**
     * @dev Get all owning permission of an address
     * @param _owner Permission owner's address
     */
    function permissionOf(
        address _owner
    ) external view virtual override returns (uint256 permission) {
        return _permissionOf(_owner);
    }

    /**
     * @dev Checking the existance of required permission on a given permission set
     * @param _required Required permission set
     * @param _permission Checking permission set
     */
    function permissionRequire(
        uint256 _permission,
        uint256 _required
    ) external view virtual override returns (bool isPermissioned) {
        return _permissionRequire(_permission, _required);
    }

    /**
     * @dev Checking if an actor has sufficient permission, by himself or from a delegation, on a given permission set
     * @param _owner Permission owner's address
     * @param _actor Actor's address
     * @param _required Required permission set
     */
    function hasPermission(
        address _owner,
        address _actor,
        uint256 _required
    ) external view override returns (bool isPermissioned) {
        return _hasPermission(_owner, _actor, _required);
    }

    /**
     * @dev Get delegated permission that owner approved to delegatee
     * @param _owner Permission owner's address
     * @param _delegatee Delegatee's address
     */
    function delegated(
        address _owner,
        address _delegatee
    ) external view virtual override returns (uint256 permission) {
        return _delegated(_owner, _delegatee);
    }

    /**
     * @dev Mint a new set of permission to a new owner
     * @param _owner New permission owner
     * @param _permission Permission
     */
    function _mint(
        address _owner,
        uint256 _permission
    ) internal returns (bool) {
        permissions[_owner] = _permission;
        emit Transfer(address(0x0), _owner, _permission);
        return true;
    }

    /**
     * @dev Burn all permission of the owner
     * @param _owner New permission owner
     */
    function _burn(address _owner) internal returns (bool) {
        emit Transfer(_owner, address(0x0), permissions[_owner]);
        permissions[_owner] = 0;
        return true;
    }

    /**
     * @dev Create an unique key that linked permission owner and delegatee
     * @param _owner Permission owner's address
     * @param _delegatee Delegate's address
     */
    function _uniqueKey(
        address _owner,
        address _delegatee
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner, _delegatee));
    }

    function _transfer(
        address _to,
        uint256 _permission
    ) internal returns (bool success) {
        address owner = msg.sender;
        // Prevent permission to be burnt
        if (permissions[_to] & _permission > 0) {
            revert IEIP6366Error.DuplicatedPermission(_permission);
        }
        // Clean subset of permission from owner
        permissions[owner] = permissions[owner] ^ _permission;
        // Set subset of permission to new owner
        permissions[_to] = permissions[_to] | _permission;
        emit Transfer(owner, _to, _permission);
        return true;
    }

    function _approve(
        address _delegatee,
        uint256 _permission
    ) internal returns (bool success) {
        address owner = msg.sender;
        delegations[_uniqueKey(owner, _delegatee)] = _permission;
        emit Approval(owner, _delegatee, _permission);
        return true;
    }

    function _permissionOf(
        address _owner
    ) internal view returns (uint256 permission) {
        return permissions[_owner];
    }

    function _permissionRequire(
        uint256 _permission,
        uint256 _required
    ) internal pure returns (bool isPermissioned) {
        return _required == _permission & _required;
    }

    function _hasPermission(
        address _owner,
        address _actor,
        uint256 _required
    ) internal view returns (bool isPermissioned) {
        return
            _permissionRequire(
                _permissionOf(_actor) | _delegated(_owner, _actor),
                _required
            );
    }

    function _delegated(
        address _owner,
        address _delegatee
    ) internal view returns (uint256 permission) {
        // Delegated permission can't be the superset of owner's permission
        return
            delegations[_uniqueKey(_owner, _delegatee)] & permissions[_owner];
    }
}
