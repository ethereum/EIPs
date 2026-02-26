// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IVerifier {
    function verifyProof(
        bytes calldata proof,
        bytes calldata public_inputs
    ) external view returns (bool valid);
}
