// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../IERC6454.sol";
import "hardhat/console.sol";

error CannotTransferNonTransferable();

/**
 * @title ERC721TransferableMock
 * Used for tests
 */
contract ERC721TransferableMock is IERC6454, ERC721 {
    address public owner;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function isTransferable(uint256 tokenId, address from, address to) public view returns (bool) {
        if (from == address(0x0) && to == address(0x0)){
            return false;
        }
        // Only allow minting and burning
        if (from == address(0x0) || to == address(0x0)){
            return true;
        }
        _requireMinted(tokenId);
        return false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        uint256 lastTokenId = firstTokenId + batchSize;
        for (uint256 i = firstTokenId; i < lastTokenId; ) {
            if (!isTransferable(i, from, to)) {
                revert CannotTransferNonTransferable();
            }
            unchecked {
                i++;
            }
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IERC6454).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
