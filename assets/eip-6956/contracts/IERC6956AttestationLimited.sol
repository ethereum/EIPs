// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./IERC6956.sol";

interface IERC6956AttestationLimited is IERC6956 {
    enum AttestationLimitUpdatePolicy {
        IMMUTABLE,
        INCREASE_ONLY,
        DECREASE_ONLY,
        FLEXIBLE
    }
    function updateGlobalAttestationLimit(uint256 _nrTransfers) external;
    function updateAttestationLimit(bytes32 anchor, uint256 _nrTransfers) external;
    function attestationUsagesLeft(bytes32 _anchor) external view returns (uint256 nrTransfersLeft);

    event GlobalAttestationLimitUpdate(uint256 indexed transferLimit, address updatedBy);
    event AttestationLimitUpdate(bytes32 indexed anchor, uint256 indexed tokenId, uint256 indexed transferLimit, address updatedBy);
    event AttestationLimitReached(bytes32 indexed anchor, uint256 indexed tokenId, uint256 indexed transferLimit);
}
