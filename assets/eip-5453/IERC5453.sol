// SPDX-License-Identifier: CC0.0 OR Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// See a full runnable hardhat project in https://github.com/ercref/ercref-contracts/tree/main/ERCs/eip-5453
pragma solidity ^0.8.9;

struct ValidityBound {
    bytes32 functionParamStructHash;
    uint256 validSince;
    uint256 validBy;
    uint256 nonce;
}

struct SingleEndorsementData {
    address endorserAddress; // 32
    bytes sig; // dynamic = 65
}

struct GeneralExtensionDataStruct {
    bytes32 erc5453MagicWord;
    uint256 erc5453Type;
    uint256 nonce;
    uint256 validSince;
    uint256 validBy;
    bytes endorsementPayload;
}

interface IERC5453EndorsementCore {
    function eip5453Nonce(address endorser) external view returns (uint256);
    function isEligibleEndorser(address endorser) external view returns (bool);
}

interface IERC5453EndorsementDigest {
    function computeValidityDigest(
        bytes32 _functionParamStructHash,
        uint256 _validSince,
        uint256 _validBy,
        uint256 _nonce
    ) external view returns (bytes32);

    function computeFunctionParamHash(
        string memory _functionName,
        bytes memory _functionParamPacked
    ) external view returns (bytes32);
}

interface IERC5453EndorsementDataTypeA {
    function computeExtensionDataTypeA(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address endorserAddress,
        bytes calldata sig
    ) external view returns (bytes memory);
}


interface IERC5453EndorsementDataTypeB {
    function computeExtensionDataTypeB(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address[] calldata endorserAddress,
        bytes[] calldata sigs
    ) external view returns (bytes memory);
}
