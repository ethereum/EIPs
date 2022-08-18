// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0; 

import "../ERCX.sol";

contract ERCXTestCollection is ERCX {

    constructor(string memory name_, string memory symbol_) ERCX(name_,symbol_) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
} 
