// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../builder_deposit_contract.sol";

/// @notice Test harness that inherits BuilderDepositContract and exposes
/// the internal helpers and storage slots needed for unit tests.
/// `deposit(...)` and `top_up(...)` are inherited as-is — the harness does
/// not override them — so tests exercise the same external entrypoints
/// that the real predeploy exposes.
contract BuilderDepositHarness is BuilderDepositContract {
    /// @notice Read access to the monotonic deposit counter, used by tests
    /// to check that successful entrypoints increment it by exactly one.
    function getDepositCount() external view returns (uint64) {
        return deposit_count;
    }

    /// @notice Exposes the SSZ signing-root computation so the test suite
    /// can cross-check it against the canonical Python (py_ecc) reference.
    function computeDepositSigningRoot(
        bytes calldata pubkey,
        bytes32 withdrawal_credentials,
        uint64 amount_gwei
    ) external pure returns (bytes32) {
        return _computeDepositSigningRoot(pubkey, withdrawal_credentials, amount_gwei);
    }
}
