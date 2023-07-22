// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IVerifier.sol";

contract MockVerifier is IVerifier {
    function verifyProof(
        bytes calldata proof,
        bytes calldata public_inputs
    ) external pure override returns (bool valid) {
        return
            public_inputs.length > 0 && keccak256(proof) == keccak256("valid");
    }
}
