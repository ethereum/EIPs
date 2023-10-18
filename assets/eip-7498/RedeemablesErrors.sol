// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {CampaignParams} from "./RedeemablesStructs.sol";

interface RedeemablesErrors {
    /// Configuration errors
    error NotManager();
    error InvalidTime();
    error ConsiderationItemRecipientCannotBeZeroAddress();
    error ConsiderationItemAmountCannotBeZero();
    error NonMatchingConsiderationItemAmounts(uint256 itemIndex, uint256 startAmount, uint256 endAmount);

    /// Redemption errors
    error InvalidCampaignId();
    error CampaignAlreadyExists();
    error InvalidCaller(address caller);
    error NotActive_(uint256 currentTimestamp, uint256 startTime, uint256 endTime);
    error MaxRedemptionsReached(uint256 total, uint256 max);
    error MaxCampaignRedemptionsReached(uint256 total, uint256 max);
    error NativeTransferFailed();
    error InvalidOfferLength(uint256 got, uint256 want);
    error InvalidNativeOfferItem();
    error InvalidOwner();
    error InvalidRequiredValue(bytes32 got, bytes32 want);
    //error InvalidSubstandard(uint256 substandard);
    error InvalidTraitRedemption();
    error InvalidTraitRedemptionToken(address token);
    error ConsiderationRecipientNotFound(address token);
    error RedemptionValuesAreImmutable();
    error RequirementsIndexOutOfBounds();
    error ConsiderationItemInsufficientBalance(address token, uint256 balance, uint256 amount);
    error EtherTransferFailed();
    error InvalidTxValue(uint256 got, uint256 want);
    error InvalidConsiderationTokenIdSupplied(address token, uint256 got, uint256 want);
    error TokenIdsDontMatchConsiderationLength(uint256 considerationLength, uint256 tokenIdsLength);
}
