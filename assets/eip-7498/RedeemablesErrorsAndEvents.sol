// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {CampaignParams} from "./RedeemablesStructs.sol";

interface RedeemableErrorsAndEvents {
    /// Configuration errors
    error NotManager();
    error InvalidTime();
    error NoConsiderationItems();
    error ConsiderationItemRecipientCannotBeZeroAddress();

    /// Redemption errors
    error InvalidCampaignId();
    error CampaignAlreadyExists();
    error InvalidCaller(address caller);
    error NotActive(uint256 currentTimestamp, uint256 startTime, uint256 endTime);
    error MaxRedemptionsReached(uint256 total, uint256 max);
    error MaxCampaignRedemptionsReached(uint256 total, uint256 max);
    error NativeTransferFailed();
    error RedeemMismatchedLengths();
    error TraitValueUnchanged(bytes32 traitKey, bytes32 value);
    error InvalidConsiderationLength(uint256 got, uint256 want);
    error InvalidConsiderationItem(address got, address want);
    error InvalidOfferLength(uint256 got, uint256 want);
    error InvalidNativeOfferItem();
    error InvalidOwner();
    error InvalidRequiredValue(bytes32 got, bytes32 want);
    error InvalidSubstandard(uint256 substandard);
    error InvalidTraitRedemption();
    error InvalidTraitRedemptionToken(address token);
    error ConsiderationRecipientNotFound(address token);
    error RedemptionValuesAreImmutable();

    /// Events
    event CampaignUpdated(uint256 indexed campaignId, CampaignParams params, string uri);
    event Redemption(uint256 indexed campaignId, bytes32 redemptionHash);
}