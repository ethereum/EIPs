// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

/// @notice Minimal canonical paymaster for EIP-8141-style frame transactions.
/// @dev VERIFY frame calldata is expected to be exactly:
///      r (32 bytes) || s (32 bytes) || v (1 byte)
///      The signature is checked against TXPARAM(0x08, 0), i.e. the canonical tx sig hash.
///      On success, the contract calls APPROVE(0x1) to approve payment.
contract CanonicalPaymaster {
    uint256 public constant WITHDRAWAL_DELAY = 12 hours;

    // secp256k1n / 2
    uint256 private constant SECP256K1N_DIV_2 =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    // Stored in contract storage instead of immutable so the deployed runtime code
    // is identical across all instances and can be recognized canonically by code match.
    address public owner;

    address payable public pendingWithdrawalTo;
    uint256 public pendingWithdrawalAmount;
    uint256 public pendingWithdrawalReadyAt;

    error NotOwner();
    error ZeroAddress();
    error InvalidSignature();
    error NoPendingWithdrawal();
    error WithdrawalNotReady();
    error TransferFailed();

    event WithdrawalRequested(address indexed to, uint256 amount, uint256 readyAt);
    event WithdrawalExecuted(address indexed to, uint256 amount);

    constructor(address owner_) payable {
        if (owner_ == address(0)) revert ZeroAddress();
        owner = owner_;
    }

    receive() external payable {}

    /// @dev Raw paymaster validation entrypoint.
    ///      Use as the target of the PAY/VERIFY frame.
    fallback() external payable {
        if (msg.data.length != 65) revert InvalidSignature();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := calldataload(0x00)
            s := calldataload(0x20)
            v := byte(0, calldataload(0x40))
        }

        if (uint256(s) > SECP256K1N_DIV_2) revert InvalidSignature();
        if (v != 27 && v != 28) revert InvalidSignature();

        if (ecrecover(_txSigHash(), v, r, s) != owner) {
            revert InvalidSignature();
        }

        _approvePayer();
    }

    function requestWithdrawal(address payable to, uint256 amount) external {
        if (msg.sender != owner) revert NotOwner();
        if (to == address(0)) revert ZeroAddress();

        pendingWithdrawalTo = to;
        pendingWithdrawalAmount = amount;
        pendingWithdrawalReadyAt = block.timestamp + WITHDRAWAL_DELAY;

        emit WithdrawalRequested(to, amount, pendingWithdrawalReadyAt);
    }

    function executeWithdrawal() external {
        if (msg.sender != owner) revert NotOwner();

        address payable to = pendingWithdrawalTo;
        uint256 amount = pendingWithdrawalAmount;
        uint256 readyAt = pendingWithdrawalReadyAt;

        if (readyAt == 0) revert NoPendingWithdrawal();
        if (block.timestamp < readyAt) revert WithdrawalNotReady();

        delete pendingWithdrawalTo;
        delete pendingWithdrawalAmount;
        delete pendingWithdrawalReadyAt;

        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit WithdrawalExecuted(to, amount);
    }

    function _txSigHash() internal returns (bytes32 sigHash) {
        assembly {
            // TXPARAM(0x08, 0) -> canonical frame transaction signature hash
            sigHash := verbatim_0i_1o(hex"60006008b0")
        }
    }

    function _approvePayer() internal {
        assembly {
            // APPROVE(scope=0x1, length=0, offset=0)
            // Push order: scope, length, offset
            verbatim_0i_0o(hex"600160006000aa")
        }
    }
}
