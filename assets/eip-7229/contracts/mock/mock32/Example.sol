// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "contracts/utils/Proxy32.sol";

contract Example32V1 is Proxy32 {
    uint256 public number;

    constructor() Proxy32(true) {}

    function upgrade(address _newImplementation) external {
        _upgrade(_newImplementation);
    }

    function setNumber(uint256 _number) external {
        number = _number;
    }
}

contract Example32V2 is Proxy32 {
    uint256 public number;

    constructor() Proxy32(false) {}

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
