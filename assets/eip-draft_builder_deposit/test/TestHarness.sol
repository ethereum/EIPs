// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../builder_deposit_contract.sol";

/// @notice Test harness for the deposit predeploy. Inherits BuilderDepositContract
/// (so `deposit(...)` and the inherited `SYSTEM_ADDRESS` system-read `fallback`
/// are exercised as-is) and exposes the internal queue depth plus the SSZ
/// signing-root helper for cross-checking against py_ecc.
contract BuilderDepositHarness is BuilderDepositContract {
    /// @notice Number of queued-but-not-yet-dequeued records.
    function pendingCount() external view returns (uint) {
        return queueTail - queueHead;
    }

    /// @notice Current per-request fee (wei).
    function feeWei() external view returns (uint) {
        return _getFee();
    }

    function computeDepositSigningRoot(
        bytes calldata pubkey,
        bytes32 withdrawal_credentials
    ) external pure returns (bytes32) {
        return _computeDepositSigningRoot(pubkey, withdrawal_credentials);
    }
}

/// @notice Test harness for the top-up predeploy.
contract BuilderTopUpHarness is BuilderTopUpContract {
    function pendingCount() external view returns (uint) {
        return queueTail - queueHead;
    }

    function feeWei() external view returns (uint) {
        return _getFee();
    }

    /// @notice Raw head/tail indices, to assert the EIP-7002 reset-on-empty.
    function headIdx() external view returns (uint) { return queueHead; }
    function tailIdx() external view returns (uint) { return queueTail; }
}
