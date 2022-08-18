// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0; 

import "../ERCXCombined.sol";

contract ERCXCombinedTestCollection is ERCXCombined {

    constructor(string memory name_, string memory symbol_) ERCXCombined(name_,symbol_) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
} 
