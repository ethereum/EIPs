// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/ZKNOX_keccak_prng.sol";

contract KeccakPRNGTest is Test {
    // Input and output provided by
    // https://github.com/zhenfeizhang/falcon-go/blob/main/c/keccak_prng.c

    // Test vector 1: extract(32)
    bytes input_1 = "test input";
    bytes output_1 = hex"5b9e99370fa4b753ac6bf0d246b3cec353c84a67839f5632cb2679b4ae565601";

    // Test vector 2: extract(64), last half
    bytes input_2 = "test input";
    bytes output_2 = hex"569857b781dd8b81dd9cb45d06999916742043ff52f1cf165e161bcc9938b705";

    // Test vector 3: extract(32)
    bytes input_3 = "testinput";
    bytes output_3 = hex"120f76b5b7198706bc294a942f8d17467aadb2bb1fa2cc1fecadbaba93c0dd74";

    // Test vectors 4: extract(32) three times (only 16 bytes)
    bytes input_4 = "test sequence";
    uint256 output_4_1 = 0x9e96b1e50719da6f0ea5b664ac8bbac5;
    uint256 output_4_2 = 0x1be071eca45961aca979e88e3784a751;
    uint256 output_4_3 = 0x5f19135442b6b848b2f51f7cb58bc583;

    function test_keccak_prng_test_vectors() public {
        // Test vector 1
        KeccakPRNG memory prng = initPRNG(input_1);
        bytes32 out = prng.pool;
        assertEq(output_1, abi.encodePacked(out));
        // Test vector 2
        prng = initPRNG(input_2);
        refill(prng);
        out = prng.pool;
        assertEq(output_2, abi.encodePacked(out));

        // Test vector 3
        prng = initPRNG(input_3);
        out = prng.pool;
        assertEq(output_3, abi.encodePacked(out));

        // Test vector 4
        prng = initPRNG(input_4);
        uint256 out_4_1 = uint256(prng.pool);
        assertEq(out_4_1 >> 128, output_4_1);

        refill(prng);
        uint256 out_4_2 = uint256(prng.pool);
        assertEq(out_4_2 >> 128, output_4_2);

        refill(prng);
        uint256 out_4_3 = uint256(prng.pool);
        assertEq(out_4_3 >> 128, output_4_3);
    }
}
