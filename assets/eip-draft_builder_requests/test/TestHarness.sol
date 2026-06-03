// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.6.11;

import "../builder_requests.sol";

/// @notice Test harness for the deposit predeploy. Inherits BuilderDepositContract
/// (so `deposit(...)` and the inherited `SYSTEM_ADDRESS` system-read `fallback`
/// are exercised as-is) and exposes the internal queue depth and fee.
contract BuilderDepositHarness is BuilderDepositContract {
    /// @notice Number of queued-but-not-yet-dequeued records.
    function pendingCount() external view returns (uint) {
        return queueTail - queueHead;
    }

    /// @notice Current per-request fee (wei).
    function feeWei() external view returns (uint) {
        return _getFee();
    }
}

/// @notice Test harness for the exit predeploy.
contract BuilderExitHarness is BuilderExitContract {
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
