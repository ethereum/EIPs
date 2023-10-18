// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import {OfferItem, ConsiderationItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {DynamicTraits} from "shipyard-core/src/dynamic-traits/DynamicTraits.sol";
import {IERC7498} from "./IERC7498.sol";
import {IRedemptionMintable} from "./IRedemptionMintable.sol";
import {RedeemablesErrors} from "./RedeemablesErrors.sol";
import {CampaignParams, CampaignRequirements, TraitRedemption} from "./RedeemablesStructs.sol";

contract ERC7498NFTRedeemables is IERC7498, RedeemablesErrors {
    /// @dev Counter for next campaign id.
    uint256 private _nextCampaignId = 1;

    /// @dev The campaign parameters by campaign id.
    mapping(uint256 campaignId => CampaignParams params) private _campaignParams;

    /// @dev The campaign URIs by campaign id.
    mapping(uint256 campaignId => string campaignURI) private _campaignURIs;

    /// @dev The total current redemptions by campaign id.
    mapping(uint256 campaignId => uint256 count) private _totalRedemptions;

    /// @dev The burn address.
    address constant _BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    struct RedemptionParams {
        uint256[] considerationTokenIds;
        address recipient;
        bytes extraData;
    }

    function multiRedeem(RedemptionParams[] calldata params) external payable {
        for (uint256 i; i < params.length;) {
            redeem(params[i].considerationTokenIds, params[i].recipient, params[i].extraData);
            unchecked {
                ++i;
            }
        }
    }

    function redeem(uint256[] calldata considerationTokenIds, address recipient, bytes calldata extraData)
        public
        payable
    {
        // Get the campaign id and requirementsIndex from extraData.
        uint256 campaignId = uint256(bytes32(extraData[0:32]));
        uint256 requirementsIndex = uint256(bytes32(extraData[32:64]));

        // Get the campaign params.
        CampaignParams storage params = _campaignParams[campaignId];

        // Validate the campaign time and total redemptions.
        _validateRedemption(campaignId, params);

        // Increment totalRedemptions.
        ++_totalRedemptions[campaignId];

        // Get the campaign requirements.
        if (requirementsIndex >= params.requirements.length) {
            revert RequirementsIndexOutOfBounds();
        }
        CampaignRequirements storage requirements = params.requirements[requirementsIndex];

        // Process the redemption.
        _processRedemption(campaignId, requirements, considerationTokenIds, recipient);

        // TODO: decode traitRedemptionTokenIds from extraData.
        uint256[] memory traitRedemptionTokenIds;

        // Emit the Redemption event.
        emit Redemption(
            campaignId, requirementsIndex, bytes32(0), considerationTokenIds, traitRedemptionTokenIds, msg.sender
        );
    }

    function getCampaign(uint256 campaignId)
        external
        view
        override
        returns (CampaignParams memory params, string memory uri, uint256 totalRedemptions)
    {
        // Revert if campaign id is invalid.
        if (campaignId >= _nextCampaignId) revert InvalidCampaignId();

        // Get the campaign params.
        params = _campaignParams[campaignId];

        // Get the campaign URI.
        uri = _campaignURIs[campaignId];

        // Get the total redemptions.
        totalRedemptions = _totalRedemptions[campaignId];
    }

    function createCampaign(CampaignParams calldata params, string calldata uri)
        public
        virtual
        returns (uint256 campaignId)
    {
        // Validate the campaign params, reverts if invalid.
        _validateCampaignParams(params);

        // Set the campaignId and increment the next one.
        campaignId = _nextCampaignId;
        ++_nextCampaignId;

        // Set the campaign params.
        _campaignParams[campaignId] = params;

        // Set the campaign URI.
        _campaignURIs[campaignId] = uri;

        emit CampaignUpdated(campaignId, params, uri);
    }

    function updateCampaign(uint256 campaignId, CampaignParams calldata params, string calldata uri) external {
        // Revert if the campaign id is invalid.
        if (campaignId == 0 || campaignId >= _nextCampaignId) {
            revert InvalidCampaignId();
        }

        // Revert if msg.sender is not the manager.
        address existingManager = _campaignParams[campaignId].manager;
        if (params.manager != msg.sender && (existingManager != address(0) && existingManager != params.manager)) {
            revert NotManager();
        }

        // Validate the campaign params and revert if invalid.
        _validateCampaignParams(params);

        // Set the campaign params.
        _campaignParams[campaignId] = params;

        // Update the campaign uri if it was provided.
        if (bytes(uri).length != 0) {
            _campaignURIs[campaignId] = uri;
        }

        emit CampaignUpdated(campaignId, params, _campaignURIs[campaignId]);
    }

    function _validateCampaignParams(CampaignParams memory params) internal pure {
        // Revert if startTime is past endTime.
        if (params.startTime > params.endTime) {
            revert InvalidTime();
        }

        // Iterate over the requirements.
        for (uint256 i = 0; i < params.requirements.length;) {
            CampaignRequirements memory requirements = params.requirements[i];

            // Validate each consideration item.
            for (uint256 j = 0; j < requirements.consideration.length;) {
                ConsiderationItem memory c = requirements.consideration[j];

                // Revert if any of the consideration item recipients is the zero address.
                // 0xdead address should be used instead.
                // For internal burn, override _internalBurn and set _useInternalBurn to true.
                if (c.recipient == address(0)) {
                    revert ConsiderationItemRecipientCannotBeZeroAddress();
                }

                if (c.startAmount == 0) {
                    revert ConsiderationItemAmountCannotBeZero();
                }

                // Revert if startAmount != endAmount, as this requires more complex logic.
                if (c.startAmount != c.endAmount) {
                    revert NonMatchingConsiderationItemAmounts(i, c.startAmount, c.endAmount);
                }

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function _validateRedemption(uint256 campaignId, CampaignParams memory params) internal view {
        if (_isInactive(params.startTime, params.endTime)) {
            revert NotActive_(block.timestamp, params.startTime, params.endTime);
        }

        // Revert if max total redemptions would be exceeded.
        if (_totalRedemptions[campaignId] + 1 > params.maxCampaignRedemptions) {
            revert MaxCampaignRedemptionsReached(_totalRedemptions[campaignId] + 1, params.maxCampaignRedemptions);
        }
    }

    function _transferConsiderationItem(uint256 id, ConsiderationItem memory c) internal {
        // If consideration item is this contract, recipient is burn address, and _useInternalBurn() fn returns true,
        // call the internal burn function and return.
        if (c.token == address(this) && c.recipient == payable(_BURN_ADDRESS) && _useInternalBurn()) {
            _internalBurn(id, c.startAmount);
            return;
        }

        // Transfer the token to the consideration recipient.
        if (c.itemType == ItemType.ERC721 || c.itemType == ItemType.ERC721_WITH_CRITERIA) {
            // ERC721_WITH_CRITERIA with identifier 0 is wildcard: any id is valid.
            // Criteria is not yet implemented, for that functionality use the contract offerer.
            if (c.itemType == ItemType.ERC721 && id != c.identifierOrCriteria) {
                revert InvalidConsiderationTokenIdSupplied(c.token, id, c.identifierOrCriteria);
            }
            IERC721(c.token).safeTransferFrom(msg.sender, c.recipient, id);
        } else if ((c.itemType == ItemType.ERC1155 || c.itemType == ItemType.ERC1155_WITH_CRITERIA)) {
            // ERC1155_WITH_CRITERIA with identifier 0 is wildcard: any id is valid.
            // Criteria is not yet implemented, for that functionality use the contract offerer.
            if (c.itemType == ItemType.ERC1155 && id != c.identifierOrCriteria) {
                revert InvalidConsiderationTokenIdSupplied(c.token, id, c.identifierOrCriteria);
            }
            IERC1155(c.token).safeTransferFrom(msg.sender, c.recipient, id, c.startAmount, "");
        } else if (c.itemType == ItemType.ERC20) {
            IERC20(c.token).transferFrom(msg.sender, c.recipient, c.startAmount);
        } else {
            // ItemType.NATIVE
            (bool success,) = c.recipient.call{value: msg.value}("");
            if (!success) revert EtherTransferFailed();
        }
    }

    /// @dev Override this function to return true if `_internalBurn` is used.
    function _useInternalBurn() internal pure virtual returns (bool) {
        return false;
    }

    /// @dev Function that is called to burn amounts of a token internal to this inherited contract.
    ///      Override with token implementation calling internal burn.
    function _internalBurn(uint256 id, uint256 amount) internal virtual {
        // Override with your token implementation calling internal burn.
    }

    function _isInactive(uint256 startTime, uint256 endTime) internal view returns (bool inactive) {
        // Using the same check for time boundary from Seaport.
        // startTime <= block.timestamp < endTime
        assembly {
            inactive := or(iszero(gt(endTime, timestamp())), gt(startTime, timestamp()))
        }
    }

    function _processRedemption(
        uint256 campaignId,
        CampaignRequirements memory requirements,
        uint256[] memory tokenIds,
        address recipient
    ) internal {
        // Get the campaign consideration.
        ConsiderationItem[] memory consideration = requirements.consideration;

        // Revert if the tokenIds length does not match the consideration length.
        if (consideration.length != tokenIds.length) {
            revert TokenIdsDontMatchConsiderationLength(consideration.length, tokenIds.length);
        }

        // Keep track of the total native value to validate.
        uint256 totalNativeValue;

        // Iterate over the consideration items.
        for (uint256 j; j < consideration.length;) {
            // Get the consideration item.
            ConsiderationItem memory c = consideration[j];

            // Get the identifier.
            uint256 id = tokenIds[j];

            // Get the token balance.
            uint256 balance;
            if (c.itemType == ItemType.ERC721 || c.itemType == ItemType.ERC721_WITH_CRITERIA) {
                balance = IERC721(c.token).ownerOf(id) == msg.sender ? 1 : 0;
            } else if (c.itemType == ItemType.ERC1155 || c.itemType == ItemType.ERC1155_WITH_CRITERIA) {
                balance = IERC1155(c.token).balanceOf(msg.sender, id);
            } else if (c.itemType == ItemType.ERC20) {
                balance = IERC20(c.token).balanceOf(msg.sender);
            } else {
                // ItemType.NATIVE
                totalNativeValue += c.startAmount;
                // Total native value is validated after the loop.
            }

            // Ensure the balance is sufficient.
            if (balance < c.startAmount) {
                revert ConsiderationItemInsufficientBalance(c.token, balance, c.startAmount);
            }

            // Transfer the consideration item.
            _transferConsiderationItem(id, c);

            // Get the campaign offer.
            OfferItem[] memory offer = requirements.offer;

            // Mint the new tokens.
            for (uint256 k; k < offer.length;) {
                IRedemptionMintable(offer[k].token).mintRedemption(
                    campaignId, recipient, requirements.consideration, requirements.traitRedemptions
                );

                unchecked {
                    ++k;
                }
            }

            unchecked {
                ++j;
            }
        }

        // Validate the correct native value is sent with the transaction.
        if (msg.value != totalNativeValue) {
            revert InvalidTxValue(msg.value, totalNativeValue);
        }

        // Process trait redemptions.
        // TraitRedemption[] memory traitRedemptions = requirements.traitRedemptions;
        // _setTraits(traitRedemptions);
    }

    function _setTraits(TraitRedemption[] calldata traitRedemptions) internal {
        /*
        // Iterate over the trait redemptions and set traits on the tokens.
        for (uint256 i; i < traitRedemptions.length;) {
            // Get the trait redemption token address and place on the stack.
            address token = traitRedemptions[i].token;

            uint256 identifier = traitRedemptions[i].identifier;

            // Declare a new block to manage stack depth.
            {
                // Get the substandard and place on the stack.
                uint8 substandard = traitRedemptions[i].substandard;

                // Get the substandard value and place on the stack.
                bytes32 substandardValue = traitRedemptions[i].substandardValue;

                // Get the trait key and place on the stack.
                bytes32 traitKey = traitRedemptions[i].traitKey;

                bytes32 traitValue = traitRedemptions[i].traitValue;

                // Get the current trait value and place on the stack.
                bytes32 currentTraitValue = getTraitValue(traitKey, identifier);

                // If substandard is 1, set trait to traitValue.
                if (substandard == 1) {
                    // Revert if the current trait value does not match the substandard value.
                    if (currentTraitValue != substandardValue) {
                        revert InvalidRequiredValue(currentTraitValue, substandardValue);
                    }

                    // Set the trait to the trait value.
                    _setTrait(traitRedemptions[i].traitKey, identifier, traitValue);
                    // If substandard is 2, increment trait by traitValue.
                } else if (substandard == 2) {
                    // Revert if the current trait value is greater than the substandard value.
                    if (currentTraitValue > substandardValue) {
                        revert InvalidRequiredValue(currentTraitValue, substandardValue);
                    }

                    // Increment the trait by the trait value.
                    uint256 newTraitValue = uint256(currentTraitValue) + uint256(traitValue);

                    _setTrait(traitRedemptions[i].traitKey, identifier, bytes32(newTraitValue));
                } else if (substandard == 3) {
                    // Revert if the current trait value is less than the substandard value.
                    if (currentTraitValue < substandardValue) {
                        revert InvalidRequiredValue(currentTraitValue, substandardValue);
                    }

                    uint256 newTraitValue = uint256(currentTraitValue) - uint256(traitValue);

                    // Decrement the trait by the trait value.
                    _setTrait(traitRedemptions[i].traitKey, traitRedemptions[i].identifier, bytes32(newTraitValue));
                }
            }

            unchecked {
                ++i;
            }
        }
        */
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC7498).interfaceId;
    }
}
