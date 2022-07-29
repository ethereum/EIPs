/// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC165Storage.sol";
import "./SignatureChecker.sol";

contract ERC5289Library is IERC5289Library, ERC165Storage {
    uint48 private counter = 0;
    mapping(uint48 => bytes memory) private multihashes;
    mapping(uint48 => bytes32) private signatureHashes;
    mapping(uint48 => mapping(address => bool)) signed;
    mapping(uint48 => mapping(address => uint64)) signedAt;

    constructor() {
        _registerInterface(type(IERC5289Library).interfaceId);
    }

    function registerDocument(bytes memory multihash) public {
        uint48 documentId = counter++;
        multihashes[documentId] = multihash;
        signatureHashes[documentId] = keccak256(abi.encodePacked(bytes("\x19Sign Legal Document:"), multihash));
    }

    function legalDocument(uint48 documentId) public view returns (bytes memory) {
        return multihash[documentId];
    }

    function documentSigned(address user, uint48 documentId) public view returns (boolean signed, uint64 timestamp) {
        return signed[documentId][user], signedAt[documentId][user];
    }

    function signDocument(address signer, bytes memory signature) public {
        require(SignatureChecker.isValidSignatureNow(signer, signatureHash[documentId], signature), "Invalid signature");
        signed[documentId][signer] = true;
        signedAt[documentId][signer] = uint64(block.timestamp);
        emit DocumentSigned(signer, documentId);
    }
}
