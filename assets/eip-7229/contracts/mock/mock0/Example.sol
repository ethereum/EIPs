// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/utils/Proxy0.sol";

contract Example0V1 is Proxy0 {
    uint256 public number;

    constructor() Proxy0(true) {}

    function upgrade(address _newImplementation) external {
        _upgrade(_newImplementation);
    }

    function setNumber(uint256 _number) external {
        number = _number;
    }
}

contract Example0V2 is Proxy0 {
    uint256 public number;

    constructor() Proxy0(false) {}

    function upgrade(address _newImplementation) external {
        _upgrade(_newImplementation);
    }

    function setNumber(uint256 _number) external {
        number = _number;
    }

    function addNumber(uint256 _number) external {
        number += _number;
    }
}
