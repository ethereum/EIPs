// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEvalEIP712Buffer {
    function evalEIP712Buffer(bytes32 domainHash, string memory primaryType, bytes memory signature)
        external
        view
        returns (string[] memory);
}
