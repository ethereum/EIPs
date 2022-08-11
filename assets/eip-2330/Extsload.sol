// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

abstract contract Extsload {
    function extsload(bytes32[] memory slots)
        external
        view
        returns (bytes32[] memory)
    {
        for (uint256 i; i < slots.length; i++) {
            bytes32 slot = slots[i];
            bytes32 val;
            assembly {
                val := sload(slot)
            }
            slots[i] = val;
        }
        return slots;
    }
}

// A contract who can make their state publicly accessible without EIP-2330
contract DeFiProtocol is Extsload {
    // code
}
