// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ERC721Full is ERC721Enumerable, ERC721URIStorage {
    /// @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
    /// @param name is a non-empty string
    /// @param symbol is a non-empty string
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /// @dev Hook that is called before any token transfer. This includes minting and burning. `from`'s `tokenId` will be transferred to `to`
    /// @param from is an non-zero address
    /// @param to is an non-zero address
    /// @param tokenId is an uint256 which determine token transferred from `from` to `to`
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Interface of the ERC165 standard
    /// @param interfaceId is a byte4 which determine interface used
    /// @return true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    /// @notice the Uniform Resource Identifier (URI) for `tokenId` token
    /// @param tokenId is unit256
    /// @return string of (URI) for `tokenId` token
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorage, ERC721)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {}
}
