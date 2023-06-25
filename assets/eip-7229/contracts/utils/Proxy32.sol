// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxy32 {
    // keccak256("xiaobaiskill") - 1
    bytes32 private constant implementationSlot =
        0x62ea9ce5af089814ac46703c0a7a1a722768852e79429df8440425302a1dddcb;

    event Upgraded(address indexed implementation);

    constructor(bool _deployProxy) {
        if (_deployProxy) {
            // deploy proxy contract by logic contract
            bytes memory code = abi.encodePacked(
                hex"7f",
                getImplementSlot(),
                hex"73",
                address(this),
                hex"81556009604c3d396009526010605560293960395ff3365f5f375f5f365f7f545af43d5f5f3e3d5f82603757fd5bf3"
            );
            assembly {
                let proxy := create2(0, add(code, 0x20), mload(code), 0x0)
                if iszero(extcodesize(proxy)) {
                    revert(0, 0)
                }
            }
        }
    }

    function getImplementSlot() public pure returns (bytes32) {
        return implementationSlot;
    }

    function _upgrade(address _newImplementation) internal {
        _upgradeBefore(_newImplementation);

        bytes32 slot = implementationSlot;
        assembly {
            sstore(slot, _newImplementation)
        }
        emit Upgraded(_newImplementation);

        _upgradeAfter(_newImplementation);
    }

    function _upgradeBefore(address _newImplementation) internal virtual {}

    function _upgradeAfter(address _newImplementation) internal virtual {}
}
