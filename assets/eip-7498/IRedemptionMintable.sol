// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {TraitRedemption} from "./RedeemablesStructs.sol";

interface IRedemptionMintable {
    function mintRedemption(
        uint256 campaignId,
        address recipient,
        ConsiderationItem[] calldata consideration,
        TraitRedemption[] calldata traitRedemptions
    ) external;
}
