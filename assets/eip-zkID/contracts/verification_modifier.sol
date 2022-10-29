// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC.sol";

abstract contract ERC6595 is IERC6595 {
    address private _authenticator;
    Requirement[] private _KYCRequirement;

    constructor(address authenticatorAddress, Requirement[] memory KYCStandards) {
        _KYCRequirement = KYCStandards;
        _authenticator = authenticatorAddress;
    }

    modifier KYCApproved(address verifying, uint256 SBTID) {
        IERC6595(_authenticator).ifVerified(verifying, SBTID);
        _;
    }
}