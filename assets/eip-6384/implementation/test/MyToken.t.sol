// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {MyToken, IEvalEIP712Buffer} from "src/MyToken/MyToken.sol";
import {TransferParameters} from "src/MyToken/MyTokenStructs.sol";
import {MyToken712ParserHelper} from "src/MyToken/MyToken712ParserHelper.sol";
import {SigUtils} from "./SigUtils.sol";

contract MyTokenTest is Test {
    MyToken myToken;
    MyToken712ParserHelper myToken712ParserHelper;
    SigUtils sigUtils;
    uint256 internal ownerPrivateKey;
    uint256 internal toPrivateKey;

    address internal owner;
    address internal to;

    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    function setUp() public {
        myToken712ParserHelper = new MyToken712ParserHelper();
        myToken = new MyToken(address(myToken712ParserHelper));
        sigUtils = new SigUtils(myToken.DOMAIN_SEPARATOR());
        ownerPrivateKey = 0xA11CE;
        toPrivateKey = 0xB0B;
        owner = vm.addr(ownerPrivateKey);
        to = vm.addr(toPrivateKey);
        vm.prank(owner);
        myToken.mintToCaller();
    }

    function testNonce() public {
        uint256 currentNonce = myToken.nonces(address(this));
    }

    function test_Transfer() public {
        TransferParameters memory transfer = generateSigPayload();
        bytes32 digest = sigUtils.getTypedDataHash(transfer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        console.log(myToken.balanceOf(owner));

        myToken.transferWithSig(transfer.from, transfer.to, transfer.amount, transfer.deadline, v, r, s);
        console.log(myToken.balanceOf(owner));
        assertEq(myToken.balanceOf(owner), 0);
    }

    function testEvalEIP712BufferTransfer() public view {
        //SigUtils.Transfer memory transferPayload = generateSigPayload();
        TransferParameters memory transferPayload = generateSigPayload();
        bytes memory encodedTransfer = abi.encode(transferPayload);
        string[] memory translatedSig = myToken.evalEIP712Buffer(myToken.DOMAIN_SEPARATOR(), "Transfer", encodedTransfer);
        for (uint256 i = 0; i < translatedSig.length; i++) {
            console.log(translatedSig[i]);
        }
    }

    function generateSigPayload() public view returns (TransferParameters memory transfer) {
        transfer = TransferParameters({
            from: owner,
            to: to,
            amount: myToken.balanceOf(owner),
            nonce: myToken.nonces(owner),
            deadline: block.timestamp + 1000
        });
        //transfer = My
        return transfer;
    }
}
