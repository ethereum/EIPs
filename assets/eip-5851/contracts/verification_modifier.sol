// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC5851.sol";

abstract contract verification_modifier {
    address private _authenticator;
    IERC5851.Requirement[] private _KYCRequirement;

    constructor(address authenticatorAddress, IERC5851.Requirement[] memory KYCStandards) {
        _KYCRequirement = KYCStandards;
        _authenticator = authenticatorAddress;
    }

    modifier KYCApproved(address verifying, uint256 SBTID) {
        IERC5851(_authenticator).ifVerified(verifying, SBTID);
        _;
    }
}