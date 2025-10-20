// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import {StdConstants} from "../src/StdConstants.sol";
import {Test} from "../src/Test.sol";

contract StdConstantsTest is Test {
    function testVm() public view {
        assertEq(StdConstants.VM.getBlockNumber(), 1);
    }

    function testVmDerivation() public pure {
        assertEq(address(StdConstants.VM), address(uint160(uint256(keccak256("hevm cheat code")))));
    }

    function testConsoleDerivation() public pure {
        assertEq(StdConstants.CONSOLE, address(uint160(uint88(bytes11("console.log")))));
    }

    function testDefaultSender() public view {
        assertEq(StdConstants.DEFAULT_SENDER, msg.sender);
    }

    function testDefaultSenderDerivation() public pure {
        assertEq(StdConstants.DEFAULT_SENDER, address(uint160(uint256(keccak256("foundry default caller")))));
    }

    function testDefaultTestContract() public {
        assertEq(StdConstants.DEFAULT_TEST_CONTRACT, address(new Dummy()));
    }

    function testDefaultTestContractDerivation() public view {
        assertEq(address(this), StdConstants.VM.computeCreateAddress(StdConstants.DEFAULT_SENDER, 1));
        assertEq(StdConstants.DEFAULT_TEST_CONTRACT, StdConstants.VM.computeCreateAddress(address(this), 1));
    }
}

contract Dummy {}
