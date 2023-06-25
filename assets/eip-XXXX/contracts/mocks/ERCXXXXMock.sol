// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "../ERCXXXX.sol";

contract ERCXXXXMock is ERCXXXX {
    
    constructor(
        string memory name,
        string memory symbol
    ) ERCXXXX(name, symbol) {}

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
