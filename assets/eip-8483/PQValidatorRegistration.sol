// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {RegistrationQueue} from "./RegistrationQueue.sol";

/// @title PQValidatorRegistration
/// @notice EIP-8483's PQ registration request contract for validators, which also checks a
///         leanXMSS proof of possession. See `RegistrationQueue`.
/// @dev The request calldata is 2516 bytes:
///        validator_pubkey (48) ‖ pq_data (64) ‖ signature (2404)
///      where the XMSS public key is `pq_data[0:32]`. The log and the system call output hold
///      132-byte records:
///        source_address (20) ‖ validator_pubkey (48) ‖ pq_data (64)
///      Each request takes five slots. The target is 128 requests per block, with at most 256
///      added and 1024 dequeued per block.
contract PQValidatorRegistration is RegistrationQueue {
    function _inputLength() internal pure override returns (uint256) {
        return 112;
    }

    function _slotsPerRequest() internal pure override returns (uint256) {
        return 5;
    }

    function _targetRequestsPerBlock() internal pure override returns (uint256) {
        return 128;
    }

    function _maxRequestsAddedPerBlock() internal pure override returns (uint256) {
        return 256;
    }

    function _maxRequestsPerBlock() internal pure override returns (uint256) {
        return 1024;
    }
}
