// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IEIP712Visualizer} from "./IEIP712Visualizer.sol";

contract SeaPortEIP712Visualizer is IEIP712Visualizer {
    bytes32 public constant DOMAIN_SEPARATOR =
        0xb50c8913581289bd2e066aeef89fceb9615d490d673131fd1a7047436706834e; //v1.1

    enum OrderType {
        FULL_OPEN,
        PARTIAL_OPEN,
        FULL_RESTRICTED,
        PARTIAL_RESTRICTED,
        CONTRACT
    }

    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }
    struct OrderComponents {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 counter;
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    constructor() {}

    function visualizeEIP712Message(
        bytes memory encodedMessage,
        bytes32 domainHash
    ) external view returns (Result memory) {
        require(
            domainHash == DOMAIN_SEPARATOR,
            "SeaPortEIP712Visualizer: unsupported domain"
        );

        OrderComponents memory order = abi.decode(
            encodedMessage,
            (OrderComponents)
        );

        UserAssetMovement[] memory assetsOut = new UserAssetMovement[](
            order.offer.length
        );

        for (uint256 i = 0; i < order.offer.length; ) {
            uint256[] memory amounts = extractAmounts(order.offer[i]);
            assetsOut[i] = UserAssetMovement({
                assetTokenAddress: order.offer[i].token,
                id: order.offer[i].identifierOrCriteria,
                amounts: amounts
            });

            unchecked {
                ++i;
            }
        }

        ConsiderationItem[] memory userConsiderations = fliterByRecepient(
            order.consideration,
            order.offerer
        );
        UserAssetMovement[] memory assetsIn = new UserAssetMovement[](
            userConsiderations.length
        );

        for (uint256 i = 0; i < userConsiderations.length; ) {
            uint256[] memory amounts = extractAmounts(userConsiderations[i]);

            assetsIn[i] = UserAssetMovement({
                assetTokenAddress: userConsiderations[i].token,
                id: userConsiderations[i].identifierOrCriteria,
                amounts: amounts
            });

            unchecked {
                ++i;
            }
        }

        return
            Result({
                assetsIn: assetsIn,
                assetsOut: assetsOut,
                liveness: Liveness({from: order.startTime, to: order.endTime})
            });
    }

    function fliterByRecepient(
        ConsiderationItem[] memory consideration,
        address recepient
    ) private view returns (ConsiderationItem[] memory) {
        uint256 recepientItemsCount;
        for (uint256 i = 0; i < consideration.length; ) {
            if (consideration[i].recipient == recepient) {
                unchecked {
                    ++recepientItemsCount;
                }
            }

            unchecked {
                ++i;
            }
        }
        ConsiderationItem[] memory result = new ConsiderationItem[](
            recepientItemsCount
        );
        uint256 resultIndex;
        for (uint256 i = 0; i < recepientItemsCount; ) {
            if (consideration[i].recipient == recepient) {
                result[resultIndex] = consideration[i];
                unchecked {
                    ++resultIndex;
                }
            }

            unchecked {
                ++i;
            }
        }

        return result;
    }

    function extractAmounts(
        OfferItem memory offer
    ) private pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        if (offer.endAmount == offer.startAmount) {
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = offer.startAmount;
            return amounts;
        } else if (offer.endAmount > offer.startAmount) {
            amounts[0] = offer.startAmount;
            amounts[1] = offer.endAmount;
        } else if (offer.endAmount < offer.startAmount) {
            amounts[0] = offer.endAmount;
            amounts[1] = offer.startAmount;
        }

        return amounts;
    }

    function extractAmounts(
        ConsiderationItem memory consideration
    ) private pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        if (consideration.endAmount == consideration.startAmount) {
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = consideration.startAmount;
            return amounts;
        } else if (consideration.endAmount > consideration.startAmount) {
            amounts[0] = consideration.startAmount;
            amounts[1] = consideration.endAmount;
        } else {
            amounts[0] = consideration.endAmount;
            amounts[1] = consideration.startAmount;
        }
        return amounts;
    }
}
