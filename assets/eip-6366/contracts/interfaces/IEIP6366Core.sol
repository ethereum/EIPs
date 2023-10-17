// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

/**
 * @dev Defined the interface of the core of EIP6366 that MUST to be implemented
 */
interface IEIP6366Core {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _permission
    );

    event Approval(
        address indexed _owner,
        address indexed _delegatee,
        uint256 indexed _permission
    );

    function transfer(
        address _to,
        uint256 _permission
    ) external returns (bool success);

    function approve(
        address _delegatee,
        uint256 _permission
    ) external returns (bool success);

    function permissionOf(
        address _owner
    ) external view returns (uint256 permission);

    function permissionRequire(
        uint256 _permission,
        uint256 _required
    ) external view returns (bool isPermissioned);

    function hasPermission(
        address _owner,
        address _actor,
        uint256 _required
    ) external view returns (bool isPermissioned);

    function delegated(
        address _owner,
        address _delegatee
    ) external view returns (uint256 permission);
}
