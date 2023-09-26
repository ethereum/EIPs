// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Solarray} from "solarray/Solarray.sol";
import {TestERC721} from "./utils/mocks/TestERC721.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType, OrderType, Side} from "seaport-sol/src/SeaportEnums.sol";
import {CampaignParams, TraitRedemption} from "../src/lib/RedeemableStructs.sol";
import {RedeemableErrorsAndEvents} from "../src/lib/RedeemableErrorsAndEvents.sol";
import {ERC721RedemptionMintable} from "../src/lib/ERC721RedemptionMintable.sol";
import {ERC7498NFTRedeemables} from "../src/lib/ERC7498NFTRedeemables.sol";
import {Test} from "forge-std/Test.sol";

contract RedeemVia7498 is RedeemableErrorsAndEvents, Test {
    error InvalidContractOrder(bytes32 orderHash);

    ERC7498NFTRedeemables redeemableToken;
    ERC721RedemptionMintable redemptionToken;

    address constant _BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    function setUp() public {
        redeemableToken = new ERC7498NFTRedeemables();
        redemptionToken = new ERC721RedemptionMintable(
            address(redeemableToken),
            address(redeemableToken)
        );
        vm.label(address(redeemableToken), "redeemableToken");
        vm.label(address(redemptionToken), "redemptionToken");
    }

    function testBurnInternalToken() public {
        uint256 tokenId = 2;
        redeemableToken.mint(address(this), tokenId);

        redeemableToken.setApprovalForAll(address(redeemableToken), true);

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        {
            CampaignParams memory params = CampaignParams({
                offer: offer,
                consideration: consideration,
                signer: address(0),
                startTime: uint32(block.timestamp),
                endTime: uint32(block.timestamp + 1000),
                maxCampaignRedemptions: 5,
                manager: address(this)
            });

            redeemableToken.createCampaign(params, "");
        }

        {
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1
            });
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.ERC721,
                token: address(redeemableToken),
                identifierOrCriteria: tokenId,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            assertGt(uint256(consideration[0].itemType), uint256(considerationFromEvent[0].itemType));

            bytes memory extraData = abi.encode(1, bytes32(0)); // campaignId, redemptionHash
            consideration[0].identifierOrCriteria = tokenId;

            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = tokenId;

            redeemableToken.redeem(tokenIds, address(this), extraData);

            assertEq(redeemableToken.ownerOf(tokenId), _BURN_ADDRESS);
            assertEq(redemptionToken.ownerOf(tokenId), address(this));
        }
    }
}