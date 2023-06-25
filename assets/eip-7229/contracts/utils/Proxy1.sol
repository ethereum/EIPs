// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxy1 {
    address private implementation;

    event Upgraded(address indexed implementation);

    constructor(bool _deployProxy) {
        if (_deployProxy) {
            uint256 slot;
            assembly {
                slot := implementation.slot
            }
            require(slot <= 255, "implementation.slot is not within 255");
            // deploy proxy contract by logic contract
            bytes memory code = abi.encodePacked(
                hex"60",
                getImplementSlot(),
                hex"73",
                address(this),
                hex"8155600960305f3960f81b60095260106039600a39601a5ff3365f5f375f5f365f60545af43d5f5f3e3d5f82601857fd5bf3"
            );
            assembly {
                // deploy proxy using create2
                let proxy := create2(0, add(code, 0x20), mload(code), 0x0)
                if iszero(extcodesize(proxy)) {
                    revert(0, 0)
                }
            }
        }
    }

    function getImplementSlot() public pure returns (bytes1 slot) {
        assembly {
            slot := implementation.slot
        }
    }

    function _upgrade(address _newImplementation) internal {
        _upgradeBefore(_newImplementation);

        implementation = _newImplementation;
        emit Upgraded(_newImplementation);

        _upgradeAfter(_newImplementation);
    }

    function _upgradeBefore(address _newImplementation) internal virtual {}

    function _upgradeAfter(address _newImplementation) internal virtual {}
}
