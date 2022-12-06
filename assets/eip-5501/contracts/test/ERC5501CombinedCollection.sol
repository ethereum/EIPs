// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0; 

import "../ERC5501Combined.sol";

contract ERC5501CombinedTestCollection is ERC5501Combined {

    constructor(string memory name_, string memory symbol_) ERC5501Combined(name_,symbol_) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
} 
