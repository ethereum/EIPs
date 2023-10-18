// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {OfferItem, ConsiderationItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {CampaignParams, TraitRedemption} from "./RedeemablesStructs.sol";

interface IERC7498 {
    event CampaignUpdated(uint256 indexed campaignId, CampaignParams params, string uri);
    event Redemption(
        uint256 indexed campaignId,
        uint256 requirementsIndex,
        bytes32 redemptionHash,
        uint256[] considerationTokenIds,
        uint256[] traitRedemptionTokenIds,
        address redeemedBy
    );

    function createCampaign(CampaignParams calldata params, string calldata uri)
        external
        returns (uint256 campaignId);

    function updateCampaign(uint256 campaignId, CampaignParams calldata params, string calldata uri) external;

    function getCampaign(uint256 campaignId)
        external
        view
        returns (CampaignParams memory params, string memory uri, uint256 totalRedemptions);

    function redeem(uint256[] calldata considerationTokenIds, address recipient, bytes calldata extraData)
        external
        payable;
}
