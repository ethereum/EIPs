// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IERC7507.sol";

contract ERC7507 is ERC721, IERC7507 {

    mapping(uint256 => mapping(address => uint64)) private _expires;

    constructor(
        string memory name, string memory symbol
    ) ERC721(name, symbol) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC7507).interfaceId || super.supportsInterface(interfaceId);
    }

    function userExpires(
        uint256 tokenId, address user
    ) public view virtual override returns(uint256) {
        require(_exists(tokenId), "ERC7507: query for nonexistent token");
        return _expires[tokenId][user];
    }

    function setUser(
        uint256 tokenId, address user, uint64 expires
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC7507: caller is not owner or approved");
        _expires[tokenId][user] = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    // For test only
    function mint(
        address to, uint256 tokenId
    ) public virtual {
        _mint(to, tokenId);
    }

}
