// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "src/IEvalEIP712Buffer.sol";
import {ItemType, OrderType, OfferItem, ConsiderationItem, OrderComponents} from "src/SeaPort/SeaPortStructs.sol";
import {SeaPort712ParserHelper} from "src/SeaPort/SeaPort712ParserHelper.sol";

contract SeaPortMock is IEvalEIP712Buffer {
    address public immutable eip712TransalatorContract;

    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    constructor(address _translator) {
        eip712TransalatorContract = _translator;
    }

    // SeaPort logic

    function evalEIP712Buffer(
        bytes32 domainSeparator,
        string memory primaryType,
        bytes memory typedDataBuffer
    ) public view override returns (string[] memory) {
        require(
            keccak256(abi.encodePacked(primaryType)) == keccak256(abi.encodePacked("OrderComponents")),
            "SeaPortMock: Invalid primary type"
        );
        require(domainSeparator == DOMAIN_SEPARATOR(), "SeaPortMock: Invalid domain");
        return SeaPort712ParserHelper(eip712TransalatorContract).parseSig(encodedSignature);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        // prettier-ignore
        return keccak256(
            abi.encode(TYPE_HASH, keccak256(bytes("Seaport")), keccak256(bytes("1.1")), block.chainid, address(this))
        );
    }
}
