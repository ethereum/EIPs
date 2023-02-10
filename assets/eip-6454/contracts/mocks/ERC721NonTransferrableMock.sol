// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../INonTransferrable.sol";

error CannotTransferNonTransferrable();

/**
 * @title ERC721NonTransferrableMock
 * Used for tests
 */
contract ERC721NonTransferrableMock is INonTransferrable, ERC721 {
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

    function isNonTransferrable(uint256 tokenId) public view returns (bool) {
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
                if (isNonTransferrable(tokenId)) {
                    revert CannotTransferNonTransferrable();
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
        return interfaceId == type(INonTransferrable).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
