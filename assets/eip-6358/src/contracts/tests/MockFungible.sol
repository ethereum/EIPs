// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../SkywalkerFungible.sol";

contract MockFungible is SkywalkerFungible {
    constructor(uint8 _chainId, string memory _name, string memory _symbol) SkywalkerFungible(_chainId, _name, _symbol) {

    }
}