// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "../ERC7231.sol";

contract ERC7231Mock is ERC7231 {
    
    constructor(
        string memory name,
        string memory symbol
    ) ERC7231(name, symbol) {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function transfer(address to, uint256 tokenId) external {
        _transfer(msg.sender, to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}
