// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Test32 {
    address public owner;
    uint256 public number;
    address private implementation;

    event Upgraded(address indexed implementation);

    constructor(uint256 _number) {
        number = _number;
    }

    modifier OnlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function init() external {
        owner = msg.sender;
    }

    function getImplementSlot() external pure returns (uint256 slot) {
        assembly {
            slot := implementation.slot
        }
    }

    function upgrade(address _newImplementation) external OnlyOwner {
        implementation = _newImplementation;
        emit Upgraded(_newImplementation);
    }

    function setNumber(uint256 _number) external OnlyOwner {
        number = _number;
    }
}

contract DeployContract32 {
    function createContract(Test32 _logic) external returns (address proxy) {
        bytes memory code = abi.encodePacked(
            hex"7f",
            _logic.getImplementSlot(),
            hex"73",
            _logic,
            hex"81556009604c3d396009526010605560293960395ff3365f5f375f5f365f7f545af43d5f5f3e3d5f82603757fd5bf3"
        );
        assembly {
            proxy := create2(0, add(code, 0x20), mload(code), 0x0)
            if iszero(extcodesize(proxy)) {
                revert(0, 0)
            }
        }
    }

    function precomputeContract(Test32 _logic) external view returns (address) {
        bytes memory code = abi.encodePacked(
            hex"7f",
            _logic.getImplementSlot(),
            hex"73",
            _logic,
            hex"81556009604c3d396009526010605560293960395ff3365f5f375f5f365f7f545af43d5f5f3e3d5f82603757fd5bf3"
        );
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                uint256(0),
                                keccak256(code)
                            )
                        )
                    )
                )
            );
    }
}
