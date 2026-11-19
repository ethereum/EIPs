// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {RegistrationQueue} from "./RegistrationQueue.sol";

/// @title PQBuilderRegistration
/// @notice EIP-8483's PQ registration request contract for builders, which also checks a
///         leanXMSS proof of possession. See `RegistrationQueue`.
/// @dev The request calldata is 2484 bytes:
///        builder_pubkey (48) ‖ pq_data (32) ‖ signature (2404)
///      where `pq_data` is the XMSS public key. The log and the system call output hold 100-byte
///      records:
///        source_address (20) ‖ builder_pubkey (48) ‖ pq_data (32)
///      Each request takes four slots. The target is 2 requests per block, with at most 16 added
///      and 16 dequeued per block.
contract PQBuilderRegistration is RegistrationQueue {
    function _inputLength() internal pure override returns (uint256) {
        return 80;
    }

    function _slotsPerRequest() internal pure override returns (uint256) {
        return 4;
    }

    function _targetRequestsPerBlock() internal pure override returns (uint256) {
        return 2;
    }

    function _maxRequestsAddedPerBlock() internal pure override returns (uint256) {
        return 16;
    }

    function _maxRequestsPerBlock() internal pure override returns (uint256) {
        return 16;
    }
}
