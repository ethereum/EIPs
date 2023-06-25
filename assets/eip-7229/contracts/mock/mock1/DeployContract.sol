// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Test1 {
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

    function getImplementSlot() external pure returns (uint8 slot) {
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

contract DeployContract1 {
    function createContract(Test1 _logic) external returns (address proxy) {
        bytes memory code = abi.encodePacked(
            hex"60",
            _logic.getImplementSlot(),
            hex"73",
            _logic,
            hex"8155600960305f3960f81b60095260106039600a39601a5ff3365f5f375f5f365f60545af43d5f5f3e3d5f82601857fd5bf3"
        );
        assembly {
            proxy := create2(0, add(code, 0x20), mload(code), 0x0)
            if iszero(extcodesize(proxy)) {
                revert(0, 0)
            }
        }
    }

    function precomputeContract(Test1 _logic) external view returns (address) {
        bytes memory code = abi.encodePacked(
            hex"60",
            _logic.getImplementSlot(),
            hex"73",
            _logic,
            hex"8155600960305f3960f81b60095260106039600a39601a5ff3365f5f375f5f365f60545af43d5f5f3e3d5f82601857fd5bf3"
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
