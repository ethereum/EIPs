/// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./interfaces/ERC5289Library.sol";
import "./interfaces/IERC165.sol";

contract ERC5289Library is IERC5289Library, IERC165 {
    uint16 private counter = 0;
    mapping(uint16 => bytes memory) private multihashes;
    mapping(uint16 => mapping(address => uint64)) signedAt;

    constructor() { }

    function registerDocument(bytes memory multihash) public {
        multihashes[counter++] = multihash;
    }

    function legalDocument(uint16 documentId) public view returns (bytes memory) {
        return multihashes[documentId];
    }

    function documentSigned(address user, uint16 documentId) public view returns (boolean isSigned) {
        return signedAt[documentId][user] != 0;
    }

    function documentSignedAt(address user, uint16 documentId) public view returns (uint64 timestamp) {
        return signedAt[documentId][user];
    }

    function signDocument() public {
        signedAt[documentId][msg.sender] = uint64(block.timestamp);
        emit DocumentSigned(msg.sender, documentId);
    }

    function supportsInterface(bytes4 _interfaceId) public view returns (bool) {
        return _interfaceId == type(IERC5289Library).interfaceId;
    }
}
