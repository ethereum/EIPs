// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SeaPort712ParserHelper} from "src/SeaPort/SeaPort712ParserHelper.sol";
import {IEvalEIP712Buffer, SeaPortMock} from "src/SeaPort/SeaPortMock.sol";
import "test/OrderGenerator.sol";
import "forge-std/Test.sol";

contract SeaPort712ParserTest is Test, OrderGenerator {
    SeaPortMock seaPortMock;
    SeaPort712ParserHelper seaPort712ParserHelper;

    function setUp() public {
        seaPort712ParserHelper = new SeaPort712ParserHelper();
        seaPortMock = new SeaPortMock(address(seaPort712ParserHelper));
    }

    function testEvalEIP712BufferSeaport() public view {
        OrderComponents memory order = generateOrder();
        bytes memory encodedOrder = abi.encode(order);
        string[] memory translatedSig = seaPortMock.evalEIP712Buffer(seaPortMock.DOMAIN_SEPARATOR(), "OrderComponents", encodedOrder);
        for (uint256 i = 0; i < translatedSig.length; i++) {
            console.log(translatedSig[i]);
        }
    }
}
