// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0; 

import "../ERCXEnumerable.sol";

contract ERCXEnumerableTestCollection is ERCXEnumerable {

    constructor(string memory name_, string memory symbol_) ERCXEnumerable(name_,symbol_) {}

    function getUserBalances(address user) external view returns (uint256[] memory) {
        return _userBalances[user];
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
