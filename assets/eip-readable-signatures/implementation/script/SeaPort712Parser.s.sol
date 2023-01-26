// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "src/SeaPort/SeaPort712ParserHelper.sol";
import {SeaPortMock} from "src/SeaPort/SeaPortMock.sol";

contract SeaPort712ParserScript is Script {
    SeaPortMock seaPortMock;
    SeaPort712ParserHelper seaPort712ParserHelper;

    function run() public {
        vm.startBroadcast();
        seaPort712ParserHelper = new SeaPort712ParserHelper();
        seaPortMock = new SeaPortMock(address(seaPort712ParserHelper));
        vm.stopBroadcast();
    }
}
