// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/utils/Proxy1.sol";

contract Example1V1 is Proxy1 {
    uint256 public number;

    constructor() Proxy1(true) {}

    function upgrade(address _newImplementation) external {
        _upgrade(_newImplementation);
    }

    function setNumber(uint256 _number) external {
        number = _number;
    }
}

contract Example1V2 is Proxy1 {
    uint256 public number;

    constructor() Proxy1(false) {}

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
