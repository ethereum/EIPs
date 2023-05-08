// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ItemType, OrderType, OfferItem, ConsiderationItem, OrderComponents} from "src/SeaPort/SeaPortStructs.sol";

contract OrderGenerator {
    function generateOrder() public view returns (OrderComponents memory) {
        OrderComponents memory order;
        order.orderType = OrderType.FULL_OPEN;
        order.offerer = msg.sender;
        order.zone = address(0);
        order.startTime = block.timestamp;
        order.endTime = block.timestamp + 1000;
        order.salt = 100;
        order.conduitKey = bytes32(0);
        order.counter = 1;

        order.offer = new OfferItem[](1);
        order.offer[0].token = 0x696383fc9C5C8568C2E7aF8731279b58B9201394;
        order.offer[0].itemType = ItemType.ERC721;
        order.offer[0].startAmount = 1;
        order.offer[0].endAmount = 1;
        order.offer[0].identifierOrCriteria = 9243;

        order.consideration = new ConsiderationItem[](1);
        order.consideration[0].itemType = ItemType.NATIVE;
        order.consideration[0].token = address(0);
        order.consideration[0].identifierOrCriteria = 0;
        order.consideration[0].startAmount = 0;
        order.consideration[0].endAmount = 0;
        order.consideration[0].recipient = payable(msg.sender);
        return order;
    }
}
