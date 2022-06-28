// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ERC5006.sol";

contract ERC5006Demo is ERC5006 {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        _mint(to, id, amount, "");
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        _burn(from, id, amount);
    }

    function getInterface() public pure  returns (bytes4) {
        return  type(IERC5006).interfaceId;
    }
    
}
