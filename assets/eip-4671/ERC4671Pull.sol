// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ERC4671.sol";
import "./IERC4671Pull.sol";

abstract contract ERC4671Pull is ERC4671, IERC4671Pull {
    using ECDSA for bytes32;

    /// @notice Pull a token from the owner wallet to the caller's wallet
    /// @param tokenId Identifier of the token to transfer
    /// @param owner Address that owns tokenId
    /// @param signature Signed data (tokenId, owner, recipient) by the owner of the token
    function pull(uint256 tokenId, address owner, bytes memory signature) public virtual override {
        Token storage token = _getTokenOrRevert(tokenId);
        require(token.owner == owner, "Provided owner does not own the token");

        address recipient = msg.sender;
        bytes32 messageHash = keccak256(abi.encodePacked(tokenId, owner, recipient));
        bytes32 signedHash = messageHash.toEthSignedMessageHash();
        require(signedHash.recover(signature) == owner, "Invalid signature");

        token.owner = recipient;
        if (token.valid) {
            _numberOfValidTokens[owner] -= 1;
            _numberOfValidTokens[recipient] += 1;
        }

        uint256[] storage tokenIds = _indexedTokenIds[owner];
        for (uint256 i=0; i<tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                if (i != tokenIds.length - 1) {
                    tokenIds[i] = tokenIds[tokenIds.length - 1];
                }
                tokenIds.pop();
                _indexedTokenIds[recipient].push(tokenId);
                return;
            }
        }

        revert();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC4671) returns (bool) {
        return 
            interfaceId == type(IERC4671Pull).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
