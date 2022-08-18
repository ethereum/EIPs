// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0; 

import "./extensions/ERC721PCloneable.sol";

contract ERC721PCloneableDemo is ERC721PCloneable {

    constructor(string memory name_, string memory symbol_)
    ERC721P(name_,symbol_)
    {

    }

    function mint(uint256 tokenId, address to) public {
        _mint(to, tokenId);
    }

    function setPrivilegeTotal(uint total) external {
        _setPrivilegeTotal(total);
    }

    function increasePrivileges(bool _cloneable) external {
        uint privId = privilegeTotal;
        _setPrivilegeTotal(privilegeTotal + 1);
        cloneable[privId] = _cloneable;
    }
}

