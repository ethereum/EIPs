// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import {ERC_N, IERC_N} from "../ERC_N.sol";

contract ERC_NMultiBarter is ERC_N {
    struct MultiComponant {
        address tokenAddr;
        uint256[] tokenIds;
    }

    struct MultiBarterTerms {
        MultiComponant bid;
        MultiComponant ask;
        uint256 nonce;
        address owner;
        uint48 deadline;
    }

    /// @dev restrict barter with an empty {MultiComponant.tokenIds} array
    error EmptyMultiComponant();

    bytes32 public immutable MULTI_BARTER_TERMS_TYPEHASH;
    bytes32 public immutable MULTI_COMPONANT_TYPEHASH;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC_N(_name, _symbol) {
        MULTI_COMPONANT_TYPEHASH = keccak256(
            abi.encodePacked(
                "MultiComponant(address tokenAddr,uint256[] tokenIds)"
            )
        );
        MULTI_BARTER_TERMS_TYPEHASH = keccak256(
            abi.encodePacked(
                "MultiBarterTerms(MultiComponant bid,MultiComponant ask,uint256 nonce,address owner,uint48 deadline)MultiComponant(address tokenAddr,uint256[] tokenIds)"
            )
        );
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                              PUBLIC FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////////////////////////*/

    function barter(
        MultiBarterTerms memory data,
        bytes memory signature
    ) external onlyExchangeable(data.bid.tokenAddr) {
        ERC_NMultiBarter(data.bid.tokenAddr).transferFor(
            data,
            msg.sender,
            signature
        );
        if (data.ask.tokenIds.length == 0) revert EmptyMultiComponant();

        for (uint256 i; i < data.ask.tokenIds.length; ) {
            if (!_isApprovedOrOwner(msg.sender, data.ask.tokenIds[i]))
                revert NotOwnerNorApproved(msg.sender, data.ask.tokenIds[i]);
            _transfer(msg.sender, data.owner, data.ask.tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    function transferFor(
        MultiBarterTerms memory data,
        address to,
        bytes memory signature
    ) external onlyExchangeable(msg.sender) {
        if (data.bid.tokenIds.length == 0) revert EmptyMultiComponant();
        // reconstruct the hash of signed message and use nonce
        bytes32 structHash = _checkAndDisgestData(data);

        address signer = _checkMessageSignature(
            structHash,
            data.owner,
            signature
        );

        for (uint256 i; i < data.bid.tokenIds.length; ) {
            if (!_isApprovedOrOwner(signer, data.bid.tokenIds[i]))
                revert NotOwnerNorApproved(signer, data.bid.tokenIds[i]);
            _transfer(data.owner, to, data.bid.tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                          INTERNAL FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////////////////////////*/

    function _checkAndDisgestData(
        MultiBarterTerms memory data
    ) private returns (bytes32) {
        _commitMessageData(data.nonce, data.owner, data.deadline);

        // disgest data following EIP712
        bytes32 bidStructHash = keccak256(
            abi.encode(
                MULTI_COMPONANT_TYPEHASH,
                data.bid.tokenAddr,
                keccak256(abi.encodePacked(data.bid.tokenIds))
            )
        );
        bytes32 askStructHash = keccak256(
            abi.encode(
                MULTI_COMPONANT_TYPEHASH,
                data.ask.tokenAddr,
                keccak256(abi.encodePacked(data.ask.tokenIds))
            )
        );

        return
            keccak256(
                abi.encode(
                    MULTI_BARTER_TERMS_TYPEHASH,
                    bidStructHash,
                    askStructHash,
                    data.nonce,
                    data.owner,
                    data.deadline
                )
            );
    }
}
