// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {ERC721ConduitPreapproved_Solady} from "shipyard-core/src/tokens/erc721/ERC721ConduitPreapproved_Solady.sol";
import {ERC721} from "solady/src/tokens/ERC721.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {ERC7498NFTRedeemables} from "./lib/ERC7498NFTRedeemables.sol";
import {CampaignParams} from "./lib/RedeemablesStructs.sol";

contract ERC721ShipyardRedeemable is ERC721ConduitPreapproved_Solady, ERC7498NFTRedeemables, Ownable {
    constructor() ERC721ConduitPreapproved_Solady() {
        _initializeOwner(msg.sender);
    }

    function name() public pure override returns (string memory) {
        return "ERC721ShipyardRedeemable";
    }

    function symbol() public pure override returns (string memory) {
        return "SY-RDM";
    }

    function tokenURI(uint256 /* tokenId */ ) public pure override returns (string memory) {
        return "https://example.com/";
    }

    function createCampaign(CampaignParams calldata params, string calldata uri)
        public
        override
        onlyOwner
        returns (uint256 campaignId)
    {
        campaignId = ERC7498NFTRedeemables.createCampaign(params, uri);
    }

    function _useInternalBurn() internal pure virtual override returns (bool) {
        return true;
    }

    function _internalBurn(uint256 id, uint256 /* amount */ ) internal virtual override {
        _burn(id);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC7498NFTRedeemables)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || ERC7498NFTRedeemables.supportsInterface(interfaceId);
    }
}
