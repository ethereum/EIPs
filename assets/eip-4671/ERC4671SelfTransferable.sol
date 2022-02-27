// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./ERC4671.sol";
import "./IERC4671SelfTransferable.sol";

abstract contract ERC4671SelfTransferable is ERC4671, IERC4671SelfTransferable {
    /// @notice Transfer a token to another wallet owned by the current token owner
    /// @param tokenId Identifier of the token to transfer
    /// @param recipient Address of the wallet owned by the current token owner
    /// @param signature Signed data (tokenId, recipient) by the current owner of the token
    function transfer(uint256 tokenId, address recipient, bytes memory signature) public virtual override {
        Token storage token = _getTokenOrRevert(tokenId);
        require(token.owner == msg.sender, "You don't own this token");

        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, tokenId, recipient));
        bytes32 signedHash = keccak256(abi.encodePackes("\x19Ethereum Signed Message:\n32", messageHash));
        require(signedHash.recover(signature) == msg.sender, "Invalid signature");

        token.owner = recipient;
        if (token.valid) {
            _numberOfValidTokens[msg.sender] -= 1;
            _numberOfValidTokens[recipient] += 1;
        }

        _indexedTokenIds[recipient].push(tokenId);

        uint256[] storage tokenIds = _indexedTokenIds[msg.sender];
        int tokenIndex = -1;
        for (int i=0; i<tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                tokenIndex = i;
                break;
            }
        }

        assert(tokenIndex != -1);
        if (tokenIndex != tokensIds.length - 1) {
            tokenIds[tokenIndex] = tokenIds[tokenIds.length - 1];
        }
        tokenIds.pop();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC4671) returns (bool) {
        return 
            interfaceId == type(IERC4671SelfTransferable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
