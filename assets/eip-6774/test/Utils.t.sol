// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {PermissionlessERC6774MultiBarter} from "../contracts/mocks/PermissionlessERC6774MultiBarter.sol";
import {IERC6774} from "../contracts/IERC6774.sol";
import {ERC6774MultiBarter} from "../contracts/extensions/ERC6774MultiBarter.sol";

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
            PermissionlessERC6774MultiBarter.BarterTerms memory data,
            bytes32 structHash
        )
    {
        PermissionlessERC6774MultiBarter.Componant memory bid = IERC6774
            .Componant({tokenAddr: bidTokenAddr, tokenId: bidTokenId});
        PermissionlessERC6774MultiBarter.Componant memory ask = IERC6774
            .Componant({tokenAddr: askTokenAddr, tokenId: askTokenId});
        data = IERC6774.BarterTerms(bid, ask, nonce, owner, deadline);

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
            PermissionlessERC6774MultiBarter.MultiBarterTerms memory data,
            bytes32 structHash
        )
    {
        PermissionlessERC6774MultiBarter.MultiComponant
            memory bid = ERC6774MultiBarter.MultiComponant({
                tokenAddr: bidTokenAddr,
                tokenIds: bidTokenIds
            });
        PermissionlessERC6774MultiBarter.MultiComponant
            memory ask = ERC6774MultiBarter.MultiComponant({
                tokenAddr: askTokenAddr,
                tokenIds: askTokenIds
            });
        data = ERC6774MultiBarter.MultiBarterTerms(
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
