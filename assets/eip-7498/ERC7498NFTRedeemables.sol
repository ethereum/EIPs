// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721ConduitPreapproved_Solady} from "shipyard-core/src/tokens/erc721/ERC721ConduitPreapproved_Solady.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
import {ERC1155} from "solady/src/tokens/ERC1155.sol";
import {IERC7498} from "../interfaces/IERC7498.sol";
import {OfferItem, ConsiderationItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {IERC721RedemptionMintable} from "../interfaces/IERC721RedemptionMintable.sol";
import {CampaignParams} from "./RedeemablesStructs.sol";
import {RedeemableErrorsAndEvents} from "./RedeemablesErrorsAndEvents.sol";

contract ERC7498NFTRedeemables is ERC721ConduitPreapproved_Solady, IERC7498, RedeemableErrorsAndEvents {
    /// @dev Counter for next campaign id.
    uint256 private _nextCampaignId = 1;

    /// @dev The campaign parameters by campaign id.
    mapping(uint256 campaignId => CampaignParams params) private _campaignParams;

    /// @dev The campaign URIs by campaign id.
    mapping(uint256 campaignId => string campaignURI) private _campaignURIs;

    /// @dev The total current redemptions by campaign id.
    mapping(uint256 campaignId => uint256 count) private _totalRedemptions;

    constructor() ERC721ConduitPreapproved_Solady() {}

    function name() public pure override returns (string memory) {
        return "ERC7498NFTRedeemables";
    }

    function symbol() public pure override returns (string memory) {
        return "RDMBL";
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return "https://example.com/";
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function redeem(uint256[] calldata tokenIds, address recipient, bytes calldata extraData) public payable {
        // Get the campaign.
        uint256 campaignId = uint256(bytes32(extraData[0:32]));
        CampaignParams storage params = _campaignParams[campaignId];
        ConsiderationItem[] memory consideration = params.consideration;

        // Revert if campaign is inactive.
        if (_isInactive(params.startTime, params.endTime)) {
            revert NotActive(block.timestamp, params.startTime, params.endTime);
        }

        // Revert if max total redemptions would be exceeded.
        if (_totalRedemptions[campaignId] + tokenIds.length > params.maxCampaignRedemptions) {
            revert MaxCampaignRedemptionsReached(_totalRedemptions[campaignId] + 1, params.maxCampaignRedemptions);
        }

        // Iterate over the token IDs and check if caller is the owner or approved operator.
        // Redeem the token if the caller is valid.
        for (uint256 i; i < tokenIds.length;) {
            // Get the identifier.
            uint256 identifier = tokenIds[i];

            // Get the token owner.
            address owner = ownerOf(identifier);

            // Check the caller is either the owner or approved operator.
            if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
                revert InvalidCaller(msg.sender);
            }

            // Iterate over campaign consideration items.
            for (uint256 j; j < consideration.length;) {
                // If the consideration item is the internal token and recipient is zero address, burn the token.
                if (consideration[j].token == address(this) && consideration[j].recipient == address(0)) {
                    _burn(identifier);

                    // Else if the consideration item is the internal token and recipient is not zero address, transfer the token.
                } else if (consideration[j].token == address(this) && consideration[j].recipient != address(0)) {
                    // Transfer the token to the consideration recipient.
                    ERC721ConduitPreapproved_Solady(consideration[j].token).safeTransferFrom(
                        owner, consideration[j].recipient, identifier
                    );
                }

                unchecked {
                    ++j;
                }
            }

            // Mint the redemption token.
            IERC721RedemptionMintable(params.offer[0].token).mintRedemption(recipient, identifier);

            unchecked {
                ++i;
            }
        }
    }

    function getCampaign(uint256 campaignId)
        external
        view
        override
        returns (CampaignParams memory params, string memory uri, uint256 totalRedemptions)
    {}

    function createCampaign(CampaignParams calldata params, string calldata uri)
        external
        override
        returns (uint256 campaignId)
    {
        // Revert if there are no consideration items, since the redemption should require at least something.
        if (params.consideration.length == 0) revert NoConsiderationItems();

        // Revert if startTime is past endTime.
        if (params.startTime > params.endTime) revert InvalidTime();

        // Set the campaign params for the next campaignId.
        _campaignParams[_nextCampaignId] = params;

        // Set the campaign URI for the next campaignId.
        _campaignURIs[_nextCampaignId] = uri;

        // Set the correct current campaignId to return before incrementing
        // the next campaignId.
        campaignId = _nextCampaignId;

        // Increment the next campaignId.
        _nextCampaignId++;

        emit CampaignUpdated(campaignId, params, _campaignURIs[campaignId]);
    }

    function updateCampaign(uint256 campaignId, CampaignParams calldata params, string calldata uri)
        external
        override
    {}

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }

    function _isInactive(uint256 startTime, uint256 endTime) internal view returns (bool inactive) {
        // Using the same check for time boundary from Seaport.
        // startTime <= block.timestamp < endTime
        assembly {
            inactive := or(iszero(gt(endTime, timestamp())), gt(startTime, timestamp()))
        }
    }
}