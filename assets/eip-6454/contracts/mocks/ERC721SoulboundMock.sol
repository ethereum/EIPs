// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../ISoulbound.sol";

error CannotTransferSoulbound();

/**
 * @title ERC721SoulboundMock
 * Used for tests
 */
contract ERC721SoulboundMock is ISoulbound, ERC721 {
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function isSoulbound(uint256 tokenId) public view returns (bool) {
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        // exclude minting and burning
        if ( from != address(0) && to != address(0)) {
            uint256 lastTokenId = firstTokenId + batchSize;
            for (uint256 i = firstTokenId; i < lastTokenId; i++) {
                uint256 tokenId = firstTokenId + i;
                if (isSoulbound(tokenId)) {
                    revert CannotTransferSoulbound();
                }
                unchecked {
                    i++;
                }
            }
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(ISoulbound).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
