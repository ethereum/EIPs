// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

struct FunctionCall {
    bytes4 functionSignature;
    address target;
    address caller;
    bytes parameters;
}

struct AccessToken {
    uint256 expiry;
    FunctionCall functionCall;
}

interface IAccessTokenVerifier {
    function verify(
        AccessToken calldata token,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool);
}
