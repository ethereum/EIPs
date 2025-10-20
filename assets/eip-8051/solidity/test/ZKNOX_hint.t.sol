// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {_2_gamma_2, useHint, decompose, reduceModPM} from "../src/ZKNOX_hint.sol";

contract HintTest is Test {
    function testUseHint() public pure {
        uint256 h = 2345433;
        uint256 r = 5432321;
        assertEq(useHint(h, r), 29); // obtained in python
    }

    function testDecompose() public pure {
        uint256 r = 5432321;
        int256 r0;
        int256 r1;
        (r0, r1) = decompose(r);
        assertEq(r0, 29); // obtained in python
        assertEq(r1, -91135); // obtained in python
    }

    function testReduceModPM() public pure {
        int256 rp = 5432321;
        int256 r0 = reduceModPM(rp);
        assertEq(r0, -91135); // obtained in python
    }
}
