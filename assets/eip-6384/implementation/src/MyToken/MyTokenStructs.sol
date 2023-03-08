// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct TransferParameters {
    address from;
    address to;
    uint256 amount;
    uint256 nonce;
    uint256 deadline;
}
