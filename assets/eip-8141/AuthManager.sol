// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

/// @notice System contract for EIP-8141 authentication state.
/// @dev Per-account `signer` (uint64) selects a registered signer entry and a
/// nonce stream. `signer == 0` is reserved for the legacy ECDSA / account-nonce
/// path and never holds a stored entry.
contract AuthManager {
    address public constant SYSTEM_ADDRESS = address(0xfffffffffffffffffffffffffffffffffffffffe);

    struct SignerEntry {
        uint16 schemeId;
        bytes pubkey;
    }

    mapping(address => mapping(uint64 => SignerEntry)) private signers;
    mapping(address => mapping(uint64 => uint64)) private nonces;

    event SignerRegistered(address indexed account, uint64 indexed signer, uint16 schemeId, bytes pubkey);
    event SignerCleared(address indexed account, uint64 indexed signer);

    error NotSystem();
    error ReservedSigner();
    error ReservedScheme();
    error EmptyPubkey();
    error SignerNotRegistered();
    error NonceMismatch();
    error NonceExhausted();

    modifier onlySystem() {
        if (msg.sender != SYSTEM_ADDRESS) revert NotSystem();
        _;
    }

    function getNonce(address sender, uint64 signer) external view returns (uint64) {
        return nonces[sender][signer];
    }

    function checkNonce(address sender, uint64 signer, uint64 expectedNonce) external view returns (bool) {
        if (signer != 0 && signers[sender][signer].pubkey.length == 0) return false;
        return nonces[sender][signer] == expectedNonce;
    }

    function advanceNonce(address sender, uint64 signer, uint64 expectedNonce) external onlySystem {
        if (signer != 0 && signers[sender][signer].pubkey.length == 0) revert SignerNotRegistered();
        uint64 current = nonces[sender][signer];
        if (current != expectedNonce) revert NonceMismatch();
        if (current == type(uint64).max) revert NonceExhausted();
        nonces[sender][signer] = current + 1;
    }

    /// @notice Register or rotate a signer entry for `msg.sender` at `signer`.
    /// @dev Overwrites any existing entry at `(msg.sender, signer)`. The nonce
    ///      stream at `(msg.sender, signer)` is NOT touched on overwrite, so
    ///      pending txs using this signer keep their replay slot, but the
    ///      pubkey/scheme they verify against changes. Wallets that want a
    ///      clean rotation should use a fresh `signer` id.
    ///      `schemeId == 0` is reserved for the legacy secp256k1 default-code
    ///      path which never goes through `AuthManager`; registering it here
    ///      would be meaningless and is rejected.
    function registerSigner(uint64 signer, uint16 schemeId, bytes calldata pubkey) external {
        if (signer == 0) revert ReservedSigner();
        if (schemeId == 0) revert ReservedScheme();
        if (pubkey.length == 0) revert EmptyPubkey();
        signers[msg.sender][signer] = SignerEntry({schemeId: schemeId, pubkey: pubkey});
        emit SignerRegistered(msg.sender, signer, schemeId, pubkey);
    }

    /// @notice Clear the signer entry at `(msg.sender, signer)`.
    /// @dev The associated nonce stream at `(msg.sender, signer)` is also
    ///      cleared so the slot may be re-registered cleanly. Pending txs
    ///      using this signer become invalid (no signer entry to verify
    ///      against; pre-tx `checkNonce` returns false).
    function clearSigner(uint64 signer) external {
        if (signer == 0) revert ReservedSigner();
        delete signers[msg.sender][signer];
        delete nonces[msg.sender][signer];
        emit SignerCleared(msg.sender, signer);
    }

    function getSigner(address account, uint64 signer) external view returns (uint16 schemeId, bytes memory pubkey) {
        SignerEntry storage entry = signers[account][signer];
        return (entry.schemeId, entry.pubkey);
    }

    receive() external payable {
        assembly {
            revert(0, 0)
        }
    }
}
