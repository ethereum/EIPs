// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

contract CredentialDepositContract {
    address internal constant SYSTEM_ADDRESS =
        0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    uint8 internal constant DEPOSIT_MODE_DISABLED = 0;
    uint8 internal constant DEPOSIT_MODE_BLS_ENABLED = 1;
    uint8 internal constant DEPOSIT_MODE_BLS_RETIRED = 2;

    bytes1 internal constant ENABLE_DEPOSITS_COMMAND = 0x00;
    bytes1 internal constant RETIRE_BLS_COMMAND = 0x01;

    uint8 internal constant BLS_CREDENTIAL_SCHEME = 0;
    uint256 internal constant BLS_PUBKEY_LENGTH = 48;
    uint256 internal constant BLS_CREDENTIAL_METADATA_LENGTH = 96;

    uint256 internal constant MIN_DEPOSIT_AMOUNT = 1_000_000_000;
    uint256 internal constant MAX_PUBKEY_LENGTH = 8192;
    uint256 internal constant MAX_CREDENTIAL_METADATA_LENGTH = 8192;

    uint8 private depositMode;

    event CredentialDepositEvent(
        uint8 scheme,
        bytes pubkey,
        bytes32 withdrawal_credentials,
        uint64 amount,
        bytes credential_metadata
    );

    error InvalidAmount();
    error InvalidLength();
    error InvalidBLSLength();
    error InvalidMode();
    error InvalidSystemCall();
    error BLSDepositsRetired();

    function deposit(
        uint8 scheme,
        bytes calldata pubkey,
        bytes32 withdrawal_credentials,
        bytes calldata credential_metadata
    ) external payable {
        if (depositMode == DEPOSIT_MODE_DISABLED) {
            revert InvalidMode();
        }

        if (
            depositMode == DEPOSIT_MODE_BLS_RETIRED
                && scheme == BLS_CREDENTIAL_SCHEME
        ) {
            revert BLSDepositsRetired();
        }

        if (
            scheme == BLS_CREDENTIAL_SCHEME
                && (
                    pubkey.length != BLS_PUBKEY_LENGTH
                        || credential_metadata.length
                            != BLS_CREDENTIAL_METADATA_LENGTH
                )
        ) {
            revert InvalidBLSLength();
        }

        if (
            pubkey.length > MAX_PUBKEY_LENGTH
                || credential_metadata.length
                    > MAX_CREDENTIAL_METADATA_LENGTH
        ) {
            revert InvalidLength();
        }

        if (msg.value % 1 gwei != 0) {
            revert InvalidAmount();
        }

        uint256 amount = msg.value / 1 gwei;
        if (amount < MIN_DEPOSIT_AMOUNT || amount > type(uint64).max) {
            revert InvalidAmount();
        }

        emit CredentialDepositEvent(
            scheme,
            pubkey,
            withdrawal_credentials,
            uint64(amount),
            credential_metadata
        );
    }

    receive() external payable {
        revert InvalidSystemCall();
    }

    fallback() external payable {
        if (
            msg.sender != SYSTEM_ADDRESS
                || msg.value != 0
                || msg.data.length != 1
        ) {
            revert InvalidSystemCall();
        }

        bytes1 command = msg.data[0];
        if (
            command == ENABLE_DEPOSITS_COMMAND
                && depositMode == DEPOSIT_MODE_DISABLED
        ) {
            depositMode = DEPOSIT_MODE_BLS_ENABLED;
            return;
        }

        if (
            command == RETIRE_BLS_COMMAND
                && depositMode == DEPOSIT_MODE_BLS_ENABLED
        ) {
            depositMode = DEPOSIT_MODE_BLS_RETIRED;
            return;
        }

        revert InvalidSystemCall();
    }
}
