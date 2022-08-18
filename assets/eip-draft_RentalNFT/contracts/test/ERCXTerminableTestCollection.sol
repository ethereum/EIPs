// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0; 

import "../ERCXTerminable.sol";

contract ERCXTerminableTestCollection is ERCXTerminable {

    constructor(string memory name_, string memory symbol_) ERCXTerminable(name_,symbol_) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
