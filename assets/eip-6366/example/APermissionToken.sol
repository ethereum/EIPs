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
     * @dev Permission to transfer permission token
     */
    uint256 private constant PERMISSION_TRANSFER = 2 ** 2;

    /**
     * @dev Permission to manage permission token
     */
    uint256 private constant PERMISSION_MASTER = 2 ** 255;

    /**
     * @dev Checking for require permissioned from the actor
     */
    modifier allow(uint256 required) {
        address owner = msg.sender;
        if (!_permissionRequire(required, _permissionOf(owner))) {
            revert IEIP6366Error.AccessDenied(owner, owner, required);
        }
        _;
    }

    /**
     * @dev Deny blacklisted address
     */
    modifier notBlacklisted() {
        if (_permissionRequire(PERMISSION_DENIED, _permissionOf(msg.sender))) {
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
        _setDescription(0, "PERMISSION_DENIED", "Blacklisted address");
        _setDescription(1, "PERMISSION_VOTE", "Permission owner able to vote");
        _setDescription(
            2,
            "PERMISSION_TRANSFER",
            "Permission owner able to transfer"
        );
        _setDescription(
            3,
            "PERMISSION_EXECUTE",
            "Permission owner able to execute"
        );
        _setDescription(
            4,
            "PERMISSION_CREATE",
            "Permission owner able to create"
        );
        _setDescription(
            255,
            "PERMISSION_MASTER",
            "Permission owner able to mint and update desscription"
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
