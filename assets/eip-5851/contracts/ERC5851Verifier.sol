// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC5851.sol";

abstract contract ERC5851Verifier is IERC5851 {
    address private _issuer;

    constructor(address issuer) {
        _issuer = issuer;
    }

    modifier KYCApproved(address claimer, uint256 SBTID) {
        IERC5851(_issuer).ifVerified(claimer, SBTID);
        _;
    }

}
