// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    uint8 private _decimals;

    constructor(uint256 supply_, uint8 decimals_, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, supply_);
        _decimals = decimals_;
    }

    function mint(uint256 amount, address to) public {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
