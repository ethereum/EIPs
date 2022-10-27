// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0; 

import "../ERC5501Terminable.sol";

contract ERC5501TerminableTestCollection is ERC5501Terminable {

    constructor(string memory name_, string memory symbol_) ERC5501Terminable(name_,symbol_) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
