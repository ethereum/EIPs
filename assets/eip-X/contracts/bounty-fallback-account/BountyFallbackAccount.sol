// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../samples/SimpleAccount.sol";
import "../bounty-contracts/BountyContract.sol";

contract BountyFallbackAccount is SimpleAccount {
    using ECDSA for bytes32;

    BountyContract private bountyContract;
    bytes[][] private lamportKey;
    uint256 private numberOfTests;
    uint256 private testSizeInBytes;
    uint16 private ecdsaLength;

    constructor(IEntryPoint anEntryPoint) SimpleAccount(anEntryPoint) {
    }

    function initialize(address anOwner, bytes[][] memory publicKey, address payable bountyContractAddress) public initializer {
        _initialize(anOwner, publicKey, bountyContractAddress);
    }

    function _initialize(address anOwner, bytes[][] memory publicKey, address payable bountyContractAddress) internal {
        bountyContract = BountyContract(bountyContractAddress);

        lamportKey = publicKey;
        numberOfTests = publicKey[0].length;
        testSizeInBytes = publicKey[0][0].length;

        ecdsaLength = 65;

        SimpleAccount.initialize(anOwner);
    }

    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal override returns (uint256 validationData) {
        bytes32 userOpHashEthSigned = userOpHash.toEthSignedMessageHash();
        if (!_ecdsaSignaturePasses(userOp.signature, userOpHashEthSigned))
            return SIG_VALIDATION_FAILED;
        if (bountyContract.solved() && !_lamportSignaturePasses(userOp.signature, userOpHashEthSigned))
            return SIG_VALIDATION_FAILED;
        _updateLamportKeys(userOp.signature);
        return 0;
    }

    function _ecdsaSignaturePasses(bytes memory signature, bytes32 userOpHashEthSigned) private view returns (bool) {
        bytes memory ecdsaSignature = BytesLib.slice(signature, 0, ecdsaLength);
        return owner == userOpHashEthSigned.recover(ecdsaSignature);
    }

    function _lamportSignaturePasses(bytes memory signature, bytes32 userOpHashEthSigned) private view returns (bool) {
        bytes[] memory hashedSignatureBytes = _getHashedSignatureBytes(signature);
        return _hashedSignatureMatchesPublicKey(hashedSignatureBytes, userOpHashEthSigned);
    }

    function _getHashedSignatureBytes(bytes memory signature) private view returns (bytes[] memory) {
        bytes[] memory hashedSignatureBytes = new bytes[](numberOfTests);
        for (uint256 testNumber = 0; testNumber < numberOfTests; testNumber++) {
            bytes memory signatureByte = BytesLib.slice(signature, ecdsaLength + testSizeInBytes * testNumber, testSizeInBytes);
            bytes32 valueToTest = keccak256(signatureByte);
            hashedSignatureBytes[testNumber] = BytesLib.slice(_bytes32ToBytes(valueToTest), 0, testSizeInBytes);
        }
        return hashedSignatureBytes;
    }

    function _bytes32ToBytes(bytes32 bytesFrom) private pure returns (bytes memory) {
        return abi.encodePacked(bytesFrom);
    }

    function _hashedSignatureMatchesPublicKey(bytes[] memory hashedSignatureBytes, bytes32 userOpHashEthSigned) private view returns (bool) {
        uint256 hashInt = uint256(userOpHashEthSigned);
        for (uint256 testNumber = 0; testNumber < numberOfTests; testNumber++) {
            uint256 bit = (hashInt >> testNumber) & 1;
            bytes memory hashedSignatureByte = hashedSignatureBytes[testNumber];
            if (!BytesLib.equal(lamportKey[bit][testNumber], hashedSignatureByte))
                return false;
        }
        return true;
    }

    function _updateLamportKeys(bytes memory signature) private {
        uint256 sizeOfLamportKey = testSizeInBytes * testSizeInBytes;
        uint256 startOfNewLamport = ecdsaLength + sizeOfLamportKey;
        for (uint256 lamportKeyNumber = 0; lamportKeyNumber < lamportKey.length; lamportKeyNumber++) {
            uint256 startOfKey = startOfNewLamport + sizeOfLamportKey * lamportKeyNumber;
            for (uint256 testNumber = 0; testNumber < numberOfTests; testNumber++) {
                bytes memory signatureByte = BytesLib.slice(signature, startOfKey + testSizeInBytes * testNumber, testSizeInBytes);
                lamportKey[lamportKeyNumber][testNumber] = signatureByte;
            }
        }
    }
}
