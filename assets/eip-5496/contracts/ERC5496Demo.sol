// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0; 

import "./ERC5496.sol";

contract ERC5496Demo is ERC5496 {

    constructor(string memory name_, string memory symbol_)
    ERC5496(name_,symbol_)
    {

    }

    function mint(uint256 tokenId, address to) public {
        _mint(to, tokenId);
    }

    function setPrivilegeTotal(uint total) external {
        _setPrivilegeTotal(total);
    }

    function increasePrivileges(bool ) external {
        _setPrivilegeTotal(privilegeTotal + 1);
    }
}
