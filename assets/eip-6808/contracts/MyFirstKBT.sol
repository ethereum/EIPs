// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "./KBT20.sol";

contract MyFirstKBT is KBT20 {
    uint256 private _secureAccounts = 0;
    uint256 private _secureAmount = 0;

    constructor() KBT20("MyFirstKBT", "FirstKBT") {
        _mint(msg.sender, 100_000_000 * 10 ** 18);
    }
}
