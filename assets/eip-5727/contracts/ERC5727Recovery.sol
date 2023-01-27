// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ERC5727.sol";
import "./interfaces/IERC5727Recovery.sol";
import "./ERC5727Enumerable.sol";

abstract contract ERC5727Recovery is ERC5727Enumerable, IERC5727Recovery {
    using ECDSA for bytes32;

    function recover(address owner, bytes memory signature)
        public
        virtual
        override
    {
        address recipient = _msgSender();
        bytes32 messageHash = keccak256(abi.encodePacked(owner, recipient));
        bytes32 signedHash = messageHash.toEthSignedMessageHash();
        require(signedHash.recover(signature) == owner, "Invalid signature");
        uint256[] memory tokenIds = _tokensOfOwner(owner);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Token storage token = _getTokenOrRevert(tokenIds[i]);
            address issuer = token.issuer;
            uint256 value = token.value;
            uint256 slot = token.slot;
            bool valid = token.valid;
            _destroy(tokenIds[i]);
            _mintUnsafe(issuer, recipient, tokenIds[i], value, slot, valid);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC5727Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC5727Recovery).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
