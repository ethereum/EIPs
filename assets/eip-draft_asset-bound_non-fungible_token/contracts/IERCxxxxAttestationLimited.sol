// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./IERCxxxx.sol";

interface IERCxxxxAttestationLimited is IERCxxxx {
    enum AttestedTransferLimitUpdatePolicy {
        IMMUTABLE,
        INCREASE_ONLY,
        DECREASE_ONLY,
        FLEXIBLE
    }
    function updateGlobalAttestedTransferLimit(uint256 _nrTransfers) external;
    function attestatedTransfersLeft(bytes32 _anchor) external view returns (uint256 nrTransfersLeft);

    event GlobalAttestedTransferLimitUpdate(
        uint256 indexed transferLimit,
        address updatedBy
    );

    event AttestedTransferLimitUpdate(
        uint256 indexed transferLimit,
        bytes32 indexed anchor,
        address updatedBy
    );
}
