// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../INonTransferable.sol";
import "hardhat/console.sol";

error CannotTransferNonTransferable();

/**
 * @title ERC721NonTransferableMock
 * Used for tests
 */
contract ERC721NonTransferableMock is INonTransferable, ERC721 {
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

    function isNonTransferable(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
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
                if (isNonTransferable(tokenId)) {
                    revert CannotTransferNonTransferable();
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
        return interfaceId == type(INonTransferable).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
