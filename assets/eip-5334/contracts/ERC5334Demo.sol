// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0; 

import "./ERC5334.sol";

contract ERC5334Demo is ERC5334 {

    constructor(string memory name_, string memory symbol_)
     ERC4907(name_,symbol_)
     {         
     }

    function mint(uint256 tokenId, address to) public {
        _mint(to, tokenId);
    }

} 

