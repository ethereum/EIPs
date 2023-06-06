// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SDCToken is ERC20{
    constructor() ERC20("SDCToken", "SDCT") {

    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}