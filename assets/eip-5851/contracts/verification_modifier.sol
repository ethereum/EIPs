// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC5851.sol";

abstract contract ERC5851 is IERC5851 {
    address private _authenticator;
    Requirement[] private _KYCRequirement;

    constructor(address authenticatorAddress, Requirement[] memory KYCStandards) {
        _KYCRequirement = KYCStandards;
        _authenticator = authenticatorAddress;
    }

    modifier KYCApproved(address verifying, uint256 SBTID) {
        IERC5851(_authenticator).ifVerified(verifying, SBTID);
        _;
    }
}