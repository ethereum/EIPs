// SPDX-License-Identifier: CC0-1.0
// Author: Zainan Victor Zhou <ercref@zzn.im>
// DRAFTv1
// Source https://github.com/ercref/ercref-contracts/tree/main/ERCs/eip-5269
// Deployment https://goerli.etherscan.io/address/0x33F735852619E3f99E1AF069cCf3b9232b2806bE#code

pragma solidity ^0.8.9;

import "./IERC5269.sol";

contract ERC5269 is IERC5269 {
    bytes32 constant public EIP_STATUS = keccak256("DRAFTv1");
    constructor () {
        emit OnSupportEIP(address(0x0), 5269, bytes32(0), EIP_STATUS, "");
    }

    function _supportEIP(
        address /*caller*/,
        uint256 majorEIPIdentifier,
        bytes32 minorEIPIdentifier,
        bytes calldata /*extraData*/)
    internal virtual view returns (bytes32 eipStatus) {
        if (majorEIPIdentifier == 5269) {
            if (minorEIPIdentifier == bytes32(0)) {
                return EIP_STATUS;
            }
        }
        return bytes32(0);
    }

    function supportEIP(
        address caller,
        uint256 majorEIPIdentifier,
        bytes32 minorEIPIdentifier,
        bytes calldata extraData)
    external virtual view returns (bytes32 eipStatus) {
        return _supportEIP(caller, majorEIPIdentifier, minorEIPIdentifier, extraData);
    }
}
