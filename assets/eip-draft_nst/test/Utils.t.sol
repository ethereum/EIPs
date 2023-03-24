// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {PermissionlessERC_NMultiBarter} from "../contracts/mocks/PermissionlessERC_NMultiBarter.sol";
import {IERC_N} from "../contracts/IERC_N.sol";
import {ERC_NMultiBarter} from "../contracts/extensions/ERC_NMultiBarter.sol";

contract Utils {
    bytes32 internal constant EIP712_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 internal constant COMPONANT_TYPEHASH =
        keccak256(
            abi.encodePacked("Componant(address tokenAddr,uint256 tokenId)")
        );
    bytes32 internal constant MULTI_COMPONANT_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "MultiComponant(address tokenAddr,uint256[] tokenIds)"
            )
        );
    bytes32 internal constant BARTER_TERMS_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "BarterTerms(Componant bid,Componant ask,uint256 nonce,address owner,uint48 deadline)Componant(address tokenAddr,uint256 tokenId)"
            )
        );
    bytes32 internal constant MULTI_BARTER_TERMS_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "MultiBarterTerms(MultiComponant bid,MultiComponant ask,uint256 nonce,address owner,uint48 deadline)MultiComponant(address tokenAddr,uint256[] tokenIds)"
            )
        );

    function workaround_EIP712TypedData(
        bytes32 structHash,
        string memory name,
        string memory version,
        address bidtokenAddr
    ) internal view returns (bytes32) {
        bytes32 domainSeparator = workaround_BuildDomainSeparator(
            name,
            version,
            bidtokenAddr
        );

        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }

    function workaround_BuildDomainSeparator(
        string memory name,
        string memory version,
        address verifyingContract
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_TYPEHASH, // typeHash
                    keccak256(abi.encodePacked(name)), // nameHash
                    keccak256(abi.encodePacked(version)), // versionHash
                    block.chainid,
                    verifyingContract
                )
            );
    }

    function workaround_CreateBarterTerms(
        address bidTokenAddr,
        uint256 bidTokenId,
        address askTokenAddr,
        uint256 askTokenId,
        uint256 nonce,
        address owner,
        uint48 deadline
    )
        internal
        pure
        returns (
            PermissionlessERC_NMultiBarter.BarterTerms memory data,
            bytes32 structHash
        )
    {
        PermissionlessERC_NMultiBarter.Componant memory bid = IERC_N.Componant({
            tokenAddr: bidTokenAddr,
            tokenId: bidTokenId
        });
        PermissionlessERC_NMultiBarter.Componant memory ask = IERC_N.Componant({
            tokenAddr: askTokenAddr,
            tokenId: askTokenId
        });
        data = IERC_N.BarterTerms(bid, ask, nonce, owner, deadline);

        bytes32 bidStructHash = keccak256(
            abi.encode(COMPONANT_TYPEHASH, bidTokenAddr, bidTokenId)
        );
        bytes32 askStructHash = keccak256(
            abi.encode(COMPONANT_TYPEHASH, askTokenAddr, askTokenId)
        );
        structHash = keccak256(
            abi.encode(
                BARTER_TERMS_TYPEHASH,
                bidStructHash,
                askStructHash,
                nonce,
                owner,
                deadline
            )
        );
    }

    function workaround_CreateMultiBarterTerms(
        address bidTokenAddr,
        uint256[] memory bidTokenIds,
        address askTokenAddr,
        uint256[] memory askTokenIds,
        uint256 nonce,
        address owner,
        uint48 deadline
    )
        internal
        pure
        returns (
            PermissionlessERC_NMultiBarter.MultiBarterTerms memory data,
            bytes32 structHash
        )
    {
        PermissionlessERC_NMultiBarter.MultiComponant
            memory bid = ERC_NMultiBarter.MultiComponant({
                tokenAddr: bidTokenAddr,
                tokenIds: bidTokenIds
            });
        PermissionlessERC_NMultiBarter.MultiComponant
            memory ask = ERC_NMultiBarter.MultiComponant({
                tokenAddr: askTokenAddr,
                tokenIds: askTokenIds
            });
        data = ERC_NMultiBarter.MultiBarterTerms(
            bid,
            ask,
            nonce,
            owner,
            deadline
        );

        bytes32 bidStructHash = keccak256(
            abi.encode(
                MULTI_COMPONANT_TYPEHASH,
                bidTokenAddr,
                keccak256(abi.encodePacked(bidTokenIds))
            )
        );
        bytes32 askStructHash = keccak256(
            abi.encode(
                MULTI_COMPONANT_TYPEHASH,
                askTokenAddr,
                keccak256(abi.encodePacked(askTokenIds))
            )
        );
        structHash = keccak256(
            abi.encode(
                MULTI_BARTER_TERMS_TYPEHASH,
                bidStructHash,
                askStructHash,
                nonce,
                owner,
                deadline
            )
        );
    }
}
