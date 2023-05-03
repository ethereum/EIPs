// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;
import "./APermissioned.sol";

contract AEcosystem is APermissioned {
    constructor(address _permsionToken) APermissioned(_permsionToken) {
        // Constructor code
    }

    function createProposal(
        address _permissionOwner
    ) external notBlacklisted allow(_permissionOwner, PERMISSION_CREATE) {
        // Only allow owner or delegatee with PERMISSION_CREATE
    }

    function vote() external notBlacklisted allowOwner(PERMISSION_VOTE) {
        // Only allow permission owner with PERMISSION_VOTE
    }

    function execute() external notBlacklisted allowOwner(ROLE_OPERATOR) {
        // Only allow permission owner with ROLE_OPERATOR
    }

    function stopProposal() external notBlacklisted allowOwner(ROLE_ADMIN) {
        // Only allow permission owner with ROLE_ADMIN
    }

    function register() external notBlacklisted {
        // Permission Token is not only provide the ability to whitelist an address
        // but also provide the ability to blacklist an address.
        // In this case, blacklisted address wont able to register
    }
}
