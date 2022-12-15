// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC5851.sol";

abstract contract ERC5851Verifier is IERC5851 {
    address private _authenticator;
    Verification[] private _KYCClaim;

    constructor(address issuer, Verification[] memory KYCStandards) {
        _KYCClaim = KYCStandards;
        _issuer = issuer;
    }

    modifier KYCApproved(address claimer) {
        IERC5851(_issuer).ifVerified(claimer, uint256 SBTID);
        _;
    }
}
