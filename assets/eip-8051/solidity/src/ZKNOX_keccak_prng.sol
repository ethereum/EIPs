// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct KeccakPRNG {
    bytes32 state; // keccak256(input)
    uint64 counter; // block counter
    bytes32 pool; // current 32-byte block
    uint8 remaining; // remaining bytes in pool [0..32]
}

// Initialize PRNG with keccak256(input).
function initPRNG(bytes memory input) pure returns (KeccakPRNG memory prng) {
    prng.state = keccak256(input);
    // Preload first block to make the first 32 bytes available immediately
    bytes32 blk = keccak256(abi.encodePacked(prng.state, uint64(0)));
    prng.pool = blk;
    prng.remaining = 32;
    prng.counter = 1;
}

// Pull next 32-byte block into the pool.
function refill(KeccakPRNG memory prng) pure {
    bytes32 blk = keccak256(abi.encodePacked(prng.state, prng.counter));
    prng.pool = blk;
    prng.remaining = 32;
    unchecked {
        prng.counter += 1;
    }
    assembly {
        // write-back struct (since prng is memory)
        mstore(prng, mload(prng)) // no-op to silence "unused" in some toolchains
    }
}

// Get one random byte (little-endian consumption from pool).
function nextByte(KeccakPRNG memory prng) pure returns (uint8 b) {
    if (prng.remaining == 0) {
        bytes32 blk = keccak256(abi.encodePacked(prng.state, prng.counter));
        prng.pool = blk;
        prng.remaining = 32;
        unchecked {
            prng.counter += 1;
        }
    }
    uint256 poolInt = uint256(prng.pool);
    b = uint8(poolInt >> 248);
    prng.pool = bytes32(poolInt << 8);

    unchecked {
        prng.remaining -= 1;
    }
    assembly {
        mstore(prng, mload(prng))
    } // write-back
}
