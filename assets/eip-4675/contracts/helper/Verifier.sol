// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

contract Verifier {
    
    function verifyOwnership(
        address token,
        uint256 tokenId
    ) internal {
        // bytes(keccak256(bytes('ownerOf(uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x6352211e, tokenId));
        require(
            success && (data.length == 32 && bytesToAddress(data) == address(this)),
            "Verifier::verifyOwnership: NFT ownership verification failed"
        );
    }

    function getOwner(
        address token,
        uint256 tokenId
    ) internal returns(address) {
        // bytes(keccak256(bytes('ownerOf(uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x6352211e, tokenId));
        require(
            success && (data.length == 32),
            "Verifier::getOwner: NFT ownership verification failed"
        );
        return bytesToAddress(data);
    }

    function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bys,32))
        } 
    }
}