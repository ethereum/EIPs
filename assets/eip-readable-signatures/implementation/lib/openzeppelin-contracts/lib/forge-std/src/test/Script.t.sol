// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../Test.sol";

contract ScriptTest is Test
{
     function testGenerateCorrectAddress() external {
        address creation = computeCreateAddress(0x6C9FC64A53c1b71FB3f9Af64d1ae3A4931A5f4E9, 14);
        assertEq(creation, 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    }
}