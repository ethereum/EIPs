// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IERCXXXX.sol";

contract ERCXXXX is ERC721, IERCXXXX {

    mapping(uint256 => Token[]) private _parentTokens;
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) private _isParentToken;

    constructor(
        string memory name, string memory symbol
    ) ERC721(name, symbol) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERCXXXX).interfaceId || super.supportsInterface(interfaceId);
    }

    function parentTokensOf(
        uint256 tokenId
    ) public view virtual override returns (Token[] memory) {
        require(_exists(tokenId), "ERCXXXX: query for nonexistent token");
        return _parentTokens[tokenId];
    }

    function isParentToken(
        uint256 tokenId,
        Token memory otherToken
    ) public view virtual override returns (bool) {
        require(_exists(tokenId), "ERCXXXX: query for nonexistent token");
        return _isParentToken[tokenId][otherToken.collection][otherToken.id];
    }

    function setParentTokens(
        uint256 tokenId, Token[] memory parentTokens
    ) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERCXXXX: caller is not owner or approved");
        _clear(tokenId);
        for (uint256 i = 0; i < parentTokens.length; i++) {
            _parentTokens[tokenId].push(parentTokens[i]);
            _isParentToken[tokenId][parentTokens[i].collection][parentTokens[i].id] = true;
        }
        emit UpdateParentTokens(tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal virtual override {
        super._burn(tokenId);
        _clear(tokenId);
    }

    function _clear(
        uint256 tokenId
    ) private {
        Token[] storage parentTokens = _parentTokens[tokenId];
        for (uint256 i = 0; i < parentTokens.length; i++) {
            delete _isParentToken[tokenId][parentTokens[i].collection][parentTokens[i].id];
        }
        delete _parentTokens[tokenId];
    }

    // For test only
    function mint(
        address to, uint256 tokenId
    ) public virtual {
        _mint(to, tokenId);
    }

    // For test only
    function burn(
        uint256 tokenId
    ) public virtual {
        _burn(tokenId);
    }

}
