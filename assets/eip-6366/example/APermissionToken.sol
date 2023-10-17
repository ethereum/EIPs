// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;
import "../contracts/EIP6366Core.sol";
import "../contracts/EIP6366Meta.sol";
import "../contracts/interfaces/IEIP6366Error.sol";

/**
 * @dev An example for mintable permission token
 */
contract APermissionToken is EIP6366Core, EIP6366Meta {
    /**
     * @dev Blacklisted
     */
    uint256 private constant PERMISSION_DENIED = 2 ** 0;

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
     * @dev Permission to manage permission token
     */
    uint256 private constant PERMISSION_MASTER = 2 ** 255;

    /**
     * @dev Checking for require permissioned from the actor
     */
    modifier allow(uint256 required) {
        address owner = msg.sender;
        if (!_permissionRequire(_permissionOf(owner), required)) {
            revert IEIP6366Error.AccessDenied(owner, owner, required);
        }
        _;
    }

    /**
     * @dev Deny blacklisted address
     */
    modifier notBlacklisted() {
        if (_permissionRequire(_permissionOf(msg.sender), PERMISSION_DENIED)) {
            revert IEIP6366Error.AccessDenied(
                msg.sender,
                msg.sender,
                PERMISSION_DENIED
            );
        }
        _;
    }

    /**
     * @dev Construct ERC-6366
     */
    constructor() EIP6366Meta("Ecosystem A Permission Token", "APT") {
        _setDescription(
            PERMISSION_DENIED,
            "PERMISSION_DENIED",
            "Blacklisted address"
        );
        _setDescription(
            PERMISSION_VOTE,
            "PERMISSION_VOTE",
            "Permission owner can vote"
        );
        _setDescription(
            PERMISSION_TRANSFER,
            "PERMISSION_TRANSFER",
            "Permission owner can transfer"
        );
        _setDescription(
            PERMISSION_EXECUTE,
            "PERMISSION_EXECUTE",
            "Permission owner can execute"
        );
        _setDescription(
            PERMISSION_CREATE,
            "PERMISSION_CREATE",
            "Permission owner can create"
        );
        _setDescription(
            PERMISSION_MASTER,
            "PERMISSION_MASTER",
            "Permission owner can mint and update description"
        );
        _setDescription(
            ROLE_ADMIN,
            "ROLE_ADMIN",
            "Admin role can vote, execute and create"
        );
        _setDescription(
            ROLE_OPERATOR,
            "ROLE_OPERATOR",
            "Operator role can execute and vote"
        );

        // Assign master permission to deployer
        _mint(msg.sender, PERMISSION_MASTER);
    }

    /**
     * @dev Mint a set of permission to a given target address
     */
    function mint(
        address _to,
        uint256 _permission
    ) external allow(PERMISSION_MASTER) returns (bool result) {
        return _mint(_to, _permission);
    }

    /**
     * @dev Burn all permission of a given target address
     */
    function burn(
        address _to
    ) external allow(PERMISSION_MASTER) returns (bool result) {
        return _burn(_to);
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
    ) external virtual override allow(PERMISSION_MASTER) returns (bool) {
        // This method is empty, you should override this in your implement
    }

    /**
     * @dev Transfer a subset of permission to a given target address
     */
    function transfer(
        address _to,
        uint256 _permission
    )
        external
        override
        allow(PERMISSION_TRANSFER)
        notBlacklisted
        returns (bool result)
    {
        return _transfer(_to, _permission);
    }
}
