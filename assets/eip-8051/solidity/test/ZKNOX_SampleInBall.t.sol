// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
//  Code obtained from `generate_sample_in_ball_test_vectors.py` python file

import {Test, console} from "forge-std/Test.sol";
import {ZKNOX_ethdilithium} from "../src/ZKNOX_ethdilithium.sol";
import "../src/ZKNOX_dilithium_utils.sol";
import "../src/ZKNOX_SampleInBall.sol";

contract SampleInBallTest is Test {
    function testSampleInBallNIST() public {
        bytes memory c_tilde = hex"cc501e9f471a004d2d3f60894d12aad3114e8abf62e413a800b7e7987ec5100b";// forgefmt: disable-next-line
uint256[256] memory expected_c = [uint256(0),8380416,0,1,0,0,0,0,0,0,0,0,0,1,8380416,0,0,8380416,0,0,0,0,0,0,8380416,0,0,0,8380416,0,1,0,0,0,8380416,8380416,0,0,0,0,8380416,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,8380416,8380416,0,0,0,0,1,1,0,0,0,8380416,0,0,0,0,0,1,0,0,0,1,0,0,0,8380416,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,8380416,0,0,0,0,0,0,1,8380416,0,0,0,0,0,0,0,0,0,0,8380416,0,0,0,0,0,0,0,0,0,0,1,0,0,8380416,0,0,0,0,0,8380416,8380416,0,0,0,0,0,0,0,0,0,0,8380416,8380416,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8380416,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,8380416,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0];

        uint256 tau = 39;
        uint256 q = 8380417;
        uint256[] memory c = sampleInBallNIST(c_tilde, tau, q);
        for (uint256 i = 0; i < 256; i++) {
            assertEq(c[i], expected_c[i]);
        }
    }

    function testSampleInBallKeccakPRNG() public {
        bytes memory c_tilde = hex"cc501e9f471a004d2d3f60894d12aad3114e8abf62e413a800b7e7987ec5100b";// forgefmt: disable-next-line
uint256[256] memory expected_c = [uint256(0),0,0,0,0,0,1,0,0,8380416,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,8380416,0,0,0,0,0,0,8380416,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8380416,0,8380416,0,8380416,8380416,0,0,0,0,8380416,8380416,8380416,0,0,0,0,0,0,8380416,0,0,0,0,1,0,8380416,8380416,0,0,0,0,0,0,0,8380416,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8380416,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,8380416,0,0,0,8380416,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,8380416,8380416,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8380416,0,0,8380416,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,1,0,0,0];

        uint256 tau = 39;
        uint256 q = 8380417;
        uint256[] memory c = sampleInBallKeccakPRNG(c_tilde, tau, q);
        for (uint256 i = 0; i < 256; i++) {
            assertEq(c[i], expected_c[i]);
        }
    }
}
