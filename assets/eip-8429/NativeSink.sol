// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.26;

/// @title NativeSink: the chain's half, held by nobody.
/// @notice On Ethereum this is the StakeVault of EIP-8429: ETH in, validator stake out, no
///         withdrawal address but itself. On a rollup there is no validator set to stake with,
///         so the sink holds. Nothing here can move it: no owner, no function, no fallback but
///         receive. What arrives is out of every market forever and still on the books.
contract NativeSink {
    event Sunk(address indexed from, uint256 amount);

    receive() external payable {
        emit Sunk(msg.sender, msg.value);
    }
}
