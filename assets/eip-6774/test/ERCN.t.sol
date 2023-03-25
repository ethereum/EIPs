// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Utils} from "./Utils.t.sol";
import {PermissionlessERC_NMultiBarter} from "../contracts/mocks/PermissionlessERC_NMultiBarter.sol";
import {IERC_N} from "../contracts/IERC_N.sol";

contract ERCN_test is Test, Utils {
    using stdStorage for StdStorage;

    // tokens
    PermissionlessERC_NMultiBarter internal ticket;
    address internal TICKET;
    PermissionlessERC_NMultiBarter internal discount;
    address internal DISCOUNT;

    // users and their private keys
    uint256 internal constant USER1_PK = 0x111;
    uint256 internal constant USER2_PK = 0x222;
    uint256 internal constant USER3_PK = 0x333;
    uint256 internal constant USER4_PK = 0x444;
    address internal USER1 = vm.addr(USER1_PK);
    address internal USER2 = vm.addr(USER2_PK);
    address internal USER3 = vm.addr(USER3_PK);
    address internal USER4 = vm.addr(USER4_PK);

    function setUp() public {
        // deploy tokens
        ticket = new PermissionlessERC_NMultiBarter("Ticket", "00", "");
        TICKET = address(ticket);
        discount = new PermissionlessERC_NMultiBarter("Discount", "01", "");
        DISCOUNT = address(discount);

        // enable barters
        ticket.enableBarterWith(DISCOUNT);
        discount.enableBarterWith(TICKET);

        // label address
        vm.label(TICKET, "TICKET");
        vm.label(DISCOUNT, "DISCOUNT");
        vm.label(USER1, "USER1");
        vm.label(USER2, "USER2");
        vm.label(USER3, "USER3");
        vm.label(USER4, "USER4");
    }

    function test_constructor_SetDomainSeparators() public {
        assertEq(
            ticket.domainSeparator(),
            workaround_BuildDomainSeparator("Ticket", "1", TICKET)
        );
        assertEq(
            discount.domainSeparator(),
            workaround_BuildDomainSeparator("Discount", "1", DISCOUNT)
        );
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                            TEST CASES One-to-one
    ////////////////////////////////////////////////////////////////////////////////////////////////*/

    function test_barter_OneToOneBarter() public {
        ticket.mint(USER1, 25);
        discount.mint(USER2, 12);

        (
            IERC_N.BarterTerms memory data,
            bytes memory signature
        ) = workaround_User1Ask(DISCOUNT, 12);

        assertEq(ticket.ownerOf(25), USER1);
        assertEq(discount.ownerOf(12), USER2);

        vm.prank(USER2);
        discount.barter(data, signature);

        assertEq(ticket.ownerOf(25), USER2);
        assertEq(discount.ownerOf(12), USER1);
    }

    function test_barter_RevertBartersNotAllowed() public {
        ticket.mint(USER1, 25);
        discount.mint(USER2, 12);

        (
            IERC_N.BarterTerms memory data,
            bytes memory signature
        ) = workaround_User1Ask(DISCOUNT, 12);

        // one way
        ticket.stopBarterWith(DISCOUNT);
        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSignature("BarterNotEnabled(address)", DISCOUNT)
        );
        discount.barter(data, signature);

        // other way
        discount.stopBarterWith(TICKET);
        ticket.enableBarterWith(DISCOUNT);
        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSignature("BarterNotEnabled(address)", TICKET)
        );
        discount.barter(data, signature);

        // both
        ticket.stopBarterWith(DISCOUNT);
        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSignature("BarterNotEnabled(address)", TICKET)
        );
        discount.barter(data, signature);
    }

    function test_barter_EnableBarterOnSameContractIsRequired() public {
        ticket.mint(USER1, 25);
        ticket.mint(USER2, 50);

        (
            IERC_N.BarterTerms memory data,
            bytes memory signature
        ) = workaround_User1Ask(TICKET, 50);

        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSignature("BarterNotEnabled(address)", TICKET)
        );
        ticket.barter(data, signature);
    }

    function test_barter_BarterOnSameContract() public {
        ticket.mint(USER1, 25);
        ticket.mint(USER2, 50);
        ticket.enableBarterWith(TICKET);

        (
            IERC_N.BarterTerms memory data,
            bytes memory signature
        ) = workaround_User1Ask(TICKET, 50);

        vm.prank(USER2);
        ticket.barter(data, signature);

        assertEq(ticket.ownerOf(25), USER2);
        assertEq(ticket.ownerOf(50), USER1);
    }

    function test_barter_NoncePreventSignatureReuse() public {
        ticket.mint(USER1, 25);
        discount.mint(USER2, 12);

        (
            IERC_N.BarterTerms memory data,
            bytes memory signature
        ) = workaround_User1Ask(DISCOUNT, 12);

        // execute the barter
        vm.prank(USER2);
        discount.barter(data, signature);
        assertEq(ticket.ownerOf(25), USER2);
        assertEq(discount.ownerOf(12), USER1);

        // rollback last barter with cheats
        stdstore
            .target(TICKET)
            .sig("ownerOf(uint256)")
            .with_key(25)
            .checked_write(USER1);
        stdstore
            .target(DISCOUNT)
            .sig("ownerOf(uint256)")
            .with_key(12)
            .checked_write(USER2);
        assertEq(ticket.ownerOf(25), USER1);
        assertEq(discount.ownerOf(12), USER2);

        // try a new barter
        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSignature("InvalidNonce(address,uint256)", USER1, 1)
        );
        discount.barter(data, signature);
    }

    function test_barter_CannotUseAnExpiredSignature() public {
        vm.warp(1000);
        (
            IERC_N.BarterTerms memory data,
            bytes32 structHash
        ) = workaround_CreateBarterTerms({
                bidTokenAddr: TICKET,
                bidTokenId: 25,
                askTokenAddr: DISCOUNT,
                askTokenId: 12,
                nonce: ticket.nonce(USER1),
                owner: USER1,
                deadline: 2000
            });
        bytes32 typedDataHash = workaround_EIP712TypedData(
            structHash,
            ticket.name(),
            "1",
            TICKET
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER1_PK, typedDataHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));

        vm.warp(3000);

        vm.prank(USER2);
        vm.expectRevert(abi.encodeWithSignature("SignatureExpired()"));
        discount.barter(data, signature);
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                              TEST CASES -Multi
    ////////////////////////////////////////////////////////////////////////////////////////////////*/

    function test_barterMulti_BarterCorrectly() public {
        ticket.mint(USER3, 5);
        ticket.mint(USER3, 10);
        ticket.mint(USER3, 15);
        ticket.mint(USER3, 20);
        discount.mint(USER4, 1);
        discount.mint(USER4, 2);
        discount.mint(USER4, 3);
        discount.mint(USER4, 4);

        (
            PermissionlessERC_NMultiBarter.MultiBarterTerms memory data,
            bytes memory signature
        ) = workaround_User3Ask();

        assertEq(ticket.ownerOf(5), USER3);
        assertEq(ticket.ownerOf(10), USER3);
        assertEq(ticket.ownerOf(15), USER3);
        assertEq(ticket.ownerOf(20), USER3);
        assertEq(discount.ownerOf(1), USER4);
        assertEq(discount.ownerOf(2), USER4);
        assertEq(discount.ownerOf(3), USER4);
        assertEq(discount.ownerOf(4), USER4);

        vm.prank(USER4);
        discount.barter(data, signature);

        assertEq(ticket.ownerOf(5), USER4);
        assertEq(ticket.ownerOf(10), USER3);
        assertEq(ticket.ownerOf(15), USER4);
        assertEq(ticket.ownerOf(20), USER4);
        assertEq(discount.ownerOf(1), USER3);
        assertEq(discount.ownerOf(2), USER3);
        assertEq(discount.ownerOf(3), USER3);
        assertEq(discount.ownerOf(4), USER3);
    }

    function test_barterMulti_CannotBarterEmptyArray() public {
        ticket.mint(USER3, 5);
        ticket.mint(USER3, 10);
        ticket.mint(USER3, 15);
        ticket.mint(USER3, 20);
        discount.mint(USER4, 1);
        discount.mint(USER4, 2);
        discount.mint(USER4, 3);
        discount.mint(USER4, 4);

        (
            PermissionlessERC_NMultiBarter.MultiBarterTerms memory data,
            bytes memory signature
        ) = workaround_User4TryWithEmptyBid();

        vm.prank(USER3);
        vm.expectRevert(abi.encodeWithSignature("EmptyMultiComponant()"));
        ticket.barter(data, signature);
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                              WORKAROUND
    ////////////////////////////////////////////////////////////////////////////////////////////////*/
    function workaround_User1Ask(
        address tokenAddr,
        uint256 tokenId
    ) internal view returns (IERC_N.BarterTerms memory, bytes memory) {
        (
            IERC_N.BarterTerms memory data,
            bytes32 structHash
        ) = workaround_CreateBarterTerms({
                bidTokenAddr: TICKET,
                bidTokenId: 25,
                askTokenAddr: tokenAddr,
                askTokenId: tokenId,
                nonce: ticket.nonce(USER1),
                owner: USER1,
                deadline: type(uint48).max
            });

        bytes32 typedDataHash = workaround_EIP712TypedData(
            structHash,
            ticket.name(),
            "1",
            TICKET
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER1_PK, typedDataHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));

        return (data, signature);
    }

    function workaround_User3Ask()
        internal
        view
        returns (
            PermissionlessERC_NMultiBarter.MultiBarterTerms memory data,
            bytes memory
        )
    {
        uint256[] memory bidIds = new uint256[](3);
        uint256[] memory askIds = new uint256[](4);
        bidIds[0] = 5;
        bidIds[1] = 15;
        bidIds[2] = 20;
        askIds[0] = 1;
        askIds[1] = 2;
        askIds[2] = 3;
        askIds[3] = 4;
        bytes32 structHash;
        (data, structHash) = workaround_CreateMultiBarterTerms({
            bidTokenAddr: TICKET,
            bidTokenIds: bidIds,
            askTokenAddr: DISCOUNT,
            askTokenIds: askIds,
            nonce: ticket.nonce(USER3),
            owner: USER3,
            deadline: type(uint48).max
        });

        bytes32 typedDataHash = workaround_EIP712TypedData(
            structHash,
            ticket.name(),
            "1",
            TICKET
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER3_PK, typedDataHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));

        return (data, signature);
    }

    function workaround_User4TryWithEmptyBid()
        internal
        view
        returns (
            PermissionlessERC_NMultiBarter.MultiBarterTerms memory data,
            bytes memory
        )
    {
        uint256[] memory bidIds = new uint256[](0);
        uint256[] memory askIds = new uint256[](3);
        askIds[0] = 5;
        askIds[1] = 15;
        askIds[2] = 20;
        bytes32 structHash;
        (data, structHash) = workaround_CreateMultiBarterTerms({
            bidTokenAddr: DISCOUNT,
            bidTokenIds: bidIds,
            askTokenAddr: TICKET,
            askTokenIds: askIds,
            nonce: discount.nonce(USER4),
            owner: USER4,
            deadline: type(uint48).max
        });

        bytes32 typedDataHash = workaround_EIP712TypedData(
            structHash,
            discount.name(),
            "1",
            DISCOUNT
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER4_PK, typedDataHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));

        return (data, signature);
    }
}
