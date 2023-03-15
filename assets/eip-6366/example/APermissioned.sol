// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;
import "../contracts/interfaces/IEIP6366Core.sol";
import "../contracts/interfaces/IEIP6366Error.sol";

/**
 * @dev Centralized definition of all possible permissions and roles
 */
contract APermissioned {
    IEIP6366Core private opt;

    /**
     * @dev No permission
     */
    uint256 internal constant PERMISSION_NONE = 0;

    /**
     * @dev Blacklisted
     */
    uint256 internal constant PERMISSION_DENIED = 2 ** 0;

    /**
     * @dev Permission to vote
     */
    uint256 internal constant PERMISSION_VOTE = 2 ** 1;

    /**
     * @dev Permission to transfer permission token
     */
    uint256 internal constant PERMISSION_TRANSFER = 2 ** 2;

    /**
     * @dev Permission to execute
     */
    uint256 internal constant PERMISSION_EXECUTE = 2 ** 3;

    /**
     * @dev Permission to create
     */
    uint256 internal constant PERMISSION_CREATE = 2 ** 4;

    /**
     * @dev Admin role
     */
    uint256 internal constant ROLE_ADMIN =
        PERMISSION_VOTE | PERMISSION_EXECUTE | PERMISSION_CREATE;

    /**
     * @dev Operator role
     */
    uint256 internal constant ROLE_OPERATOR =
        PERMISSION_EXECUTE | PERMISSION_VOTE;

    /**
     * @dev Allow the actor who has required permission
     */
    modifier allowOwner(uint256 _required) {
        if (!opt.permissionRequire(opt.permissionOf(msg.sender), _required)) {
            revert IEIP6366Error.AccessDenied(
                msg.sender,
                msg.sender,
                _required
            );
        }
        _;
    }

    /**
     * @dev Deny blacklisted address
     */
    modifier notBlacklisted() {
        if (
            opt.permissionRequire(
                opt.permissionOf(msg.sender),
                PERMISSION_DENIED
            )
        ) {
            revert IEIP6366Error.AccessDenied(
                msg.sender,
                msg.sender,
                PERMISSION_DENIED
            );
        }
        _;
    }

    /**
     * @dev Allow permission owner or delegatee
     */
    modifier allow(address _owner, uint256 _required) {
        // The actor should be the permission owner or delegatee
        if (!opt.hasPermission(_owner, msg.sender, _required)) {
            revert IEIP6366Error.AccessDenied(_owner, msg.sender, _required);
        }
        _;
    }

    /**
     * @dev Constructor
     */
    constructor(address _opt) {
        opt = IEIP6366Core(_opt);
    }
}
