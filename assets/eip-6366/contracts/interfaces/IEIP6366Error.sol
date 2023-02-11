// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

/**
 * @dev Define all possible errors that's RECOMMENDED to be implemented
 */
interface IEIP6366Error {
    error AccessDenied(address _owner, address _actor, uint256 _permission);

    error DuplicatedPermission(uint256 _permission);

    error OutOfRange();
}
