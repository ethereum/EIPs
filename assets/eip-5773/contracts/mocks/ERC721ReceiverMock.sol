// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

contract ERC721ReceiverMock {
    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public returns (bytes4) {
        return ERC721_RECEIVED;
    }
}
