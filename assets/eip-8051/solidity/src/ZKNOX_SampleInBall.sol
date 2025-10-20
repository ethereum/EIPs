// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ZKNOX_shake.sol";
import "./ZKNOX_keccak_prng.sol";

// SampleInBall as specified in Dilithium
function sampleInBallNIST(bytes memory c_tilde, uint256 tau, uint256 q) pure returns (uint256[] memory c) {
    ctx_shake memory ctx;
    ctx = shake_update(ctx, c_tilde);
    bytes memory sign_bytes = shake_digest(ctx, 8);
    uint256 sign_int = 0;
    for (uint256 i = 0; i < 8; i++) {
        sign_int |= uint256(uint8(sign_bytes[i])) << (8 * i);
    }

    // Now set tau values of c to be ±1
    c = new uint256[](256);
    uint256 j;
    bytes memory bytes_j;
    for (uint256 i = 256 - tau; i < 256; i++) {
        // Rejects values until a value j <= i is found
        while (true) {
            (ctx, bytes_j) = shake_squeeze(ctx, 1);
            j = uint256(uint8(bytes_j[0]));
            if (j <= i) {
                break;
            }
        }
        c[i] = c[j];
        if (sign_int & 1 == 1) {
            c[j] = q - 1;
        } else {
            c[j] = 1;
        }
        sign_int >>= 1;
    }
}

// SampleInBall with KeccakPRNG
function sampleInBallKeccakPRNG(bytes memory c_tilde, uint256 tau, uint256 q) pure returns (uint256[] memory c) {
    KeccakPRNG memory prng = initPRNG(c_tilde);

    // sign_int: 64 bits, little-endian (matches your SHAKE version)
    uint64 sign_int = 0;
    for (uint256 k = 0; k < 8; k++) {
        sign_int |= uint64(nextByte(prng)) << (8 * k);
    }

    uint256 j;
    c = new uint256[](256);
    // i runs from 256 - tau .. 255 inclusive
    for (uint256 i = 256 - tau; i < 256; i++) {
        // Rejection sample j in [0..i] from a byte
        while (true) {
            uint8 r = nextByte(prng);
            if (r <= i) {
                j = uint256(r);
                break;
            }
        }
        // Fisher-Yates style swap/placement
        c[i] = c[j];
        if ((sign_int & 1) == 1) {
            c[j] = q - 1; // -1 mod q
        } else {
            c[j] = 1;
        }
        sign_int >>= 1;
    }
}
