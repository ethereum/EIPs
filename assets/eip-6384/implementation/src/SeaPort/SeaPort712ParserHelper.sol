// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ItemType, OrderType, OfferItem, ConsiderationItem, OrderComponents} from "src/SeaPort/SeaPortStructs.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SeaPort712ParserHelper {
    bytes32 private domainSeperator = keccak256(
        abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    );

    string sigMessage =
        "This is a Seaport listing message, mostly used by OpenSea Dapp, be aware of the potential balance changes";

    struct BalanceOut {
        uint256 amount;
        address token;
    }

    struct BalanceIn {
        uint256 amount;
        address token;
    }

    function getTokenNameByAddress(address _token) private view returns (string memory) {
        if (_token == address(0)) {
            return "ETH";
        } else {
            (bool success, bytes memory returnData) = _token.staticcall(abi.encodeWithSignature("name()"));
            if (success && returnData.length > 0) {
                return string(returnData);
            } else {
                return "Unknown";
            }
        }
    }

    // need to manage array length because of the fact that default array values are 0x0 which represents 'native token'
    function getElementIndexInArray(address addressToSearch, uint256 arrayLength, address[] memory visitedAddresses)
        private
        pure
        returns (uint256)
    {
        for (uint256 i; i < arrayLength; i++) {
            if (addressToSearch == visitedAddresses[i]) {
                return i;
            }
        }
        return visitedAddresses.length + 1;
    }

    function parseSig(bytes memory signature) public view returns (string[] memory sigTranslatedMessage) {
        OrderComponents memory order = abi.decode(signature, (OrderComponents));
        BalanceOut[] memory tempBalanceOut = new BalanceOut[](order.offer.length);
        BalanceIn[] memory tempBalanceIn = new BalanceIn[](order.consideration.length);
        address[] memory outTokenAddresses = new address[](order.offer.length);
        address[] memory inTokenAddresses = new address[](order.consideration.length);

        uint256 outLength;
        for (uint256 i; i < order.offer.length; i++) {
            uint256 index = getElementIndexInArray(order.offer[i].token, outLength, outTokenAddresses);
            if (index != outTokenAddresses.length + 1) {
                tempBalanceOut[index].amount += order.offer[i].startAmount;
            } else {
                outTokenAddresses[outLength] = order.offer[i].token;
                tempBalanceOut[outLength] = BalanceOut(order.offer[i].startAmount, order.offer[i].token);
                outLength++;
            }
        }

        uint256 inLength;
        for (uint256 i; i < order.consideration.length; i++) {
            if (order.offerer == order.consideration[i].recipient) {
                uint256 index = getElementIndexInArray(order.consideration[i].token, inLength, inTokenAddresses);
                if (index != inTokenAddresses.length + 1) {
                    tempBalanceIn[index].amount += order.consideration[i].startAmount;
                } else {
                    inTokenAddresses[inLength] = order.consideration[i].token;
                    tempBalanceIn[inLength] =
                        BalanceIn(order.consideration[i].startAmount, order.consideration[i].token);
                    inLength++;
                }
            }
        }

        sigTranslatedMessage = new string[](outLength + inLength + 2);
        sigTranslatedMessage[0] = sigMessage;
        sigTranslatedMessage[1] =
            string(abi.encodePacked("The signature is valid until ", Strings.toString(order.endTime)));
        for (uint256 i; i < inLength; i++) {
            sigTranslatedMessage[i + 2] = string(
                abi.encodePacked(
                    "You will receive ",
                    Strings.toString(tempBalanceIn[i].amount),
                    " of ",
                    getTokenNameByAddress(tempBalanceIn[i].token)
                )
            );
        }

        for (uint256 i; i < outLength; i++) {
            sigTranslatedMessage[i + inLength + 2] = string(
                abi.encodePacked(
                    "You will send ",
                    Strings.toString(tempBalanceOut[i].amount),
                    " of ",
                    getTokenNameByAddress(tempBalanceOut[i].token)
                )
            );
        }
        return (sigTranslatedMessage);
    }
}
