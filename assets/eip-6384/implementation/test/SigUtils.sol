// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TransferParameters} from "src/MyToken/MyTokenStructs.sol";

contract SigUtils {
    bytes32 internal DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    //bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256("Transfer(address from,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    // computes the hash of a permit
    function getStructHash(TransferParameters memory _transfer) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TRANSFER_TYPEHASH, _transfer.from, _transfer.to, _transfer.amount, _transfer.nonce, _transfer.deadline
            )
        );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(TransferParameters memory _transfer) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(_transfer)));
    }
}
