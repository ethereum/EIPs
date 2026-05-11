// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

/// @notice Minimal canonical paymaster for EIP-8141-style frame transactions.
/// @dev The contract has two VERIFY-frame code paths, selected by the current
///      frame's `allowed_scope` (APPROVE_PAYMENT = paymaster mode, APPROVE_GUARANTEE
///      = guarantor mode), and one DEFAULT-frame entrypoint for the guarantor-mode
///      nonce bump. In both modes, the VERIFY frame's calldata is exactly
///      `r (32) || s (32) || v (1)` (65 bytes).
///
///      **Paymaster mode** (`allowed_scope == APPROVE_PAYMENT`): the signature is
///      checked against TXPARAM(0x08), i.e. the canonical tx sig hash. On success,
///      the contract calls APPROVE(APPROVE_PAYMENT). Replay protection comes from
///      the sender's nonce, which is incremented by the protocol when
///      `sender_approved` is set.
///
///      **Guarantor mode** (`allowed_scope == APPROVE_GUARANTEE`): the frame
///      introspects the bump_nonce frame at `current + 2` (skipping the sender
///      validation frame at `current + 1`) to confirm it is a DEFAULT call to
///      `bumpNonce(tx.sender, payer_nonce)` with `gas_limit` sufficient for a
///      cold-slot SSTORE. It reads `payer_nonce` from the bump_nonce frame's
///      data (no separate copy is needed in calldata), verifies
///      `guarantor_nonce[tx.sender] == payer_nonce`, and authenticates the signer
///      over TXPARAM(0x09) (the frame-elide sig hash). TXPARAM(0x09) binds both
///      the sender's VERIFY data (preventing sig-mutation grief) and the
///      bump_nonce frame's `payer_nonce` (via its DEFAULT-frame `data`), so no
///      extra commitment to `payer_nonce` is required in the signed message. On
///      success, it calls APPROVE(APPROVE_GUARANTEE), which alone satisfies the
///      transaction validity condition without requiring `sender_approved`.
///
///      **bumpNonce**: called by the DEFAULT frame that follows the sender
///      validation frame (at `current + 2` from the guarantee). It checks
///      via FRAMEPARAM that the guarantee frame at `current - 2` was a
///      successful self-targeted VERIFY with `approved_scope == APPROVE_GUARANTEE`,
///      then reads the sender validation frame's status at `current - 1`. If
///      sender validation failed, it increments `guarantor_nonce[sender]` as
///      fallback replay protection. If sender validation succeeded, it is a
///      no-op (the protocol increments the sender's nonce instead).
///
///      Only a single secp256k1 signer (recovered via ecrecover) is supported.
///      ERC-1271 and other contract-signature schemes are not supported.
contract CanonicalPaymaster {
    uint256 public constant WITHDRAWAL_DELAY = 12 hours;

    // secp256k1n / 2
    uint256 private constant SECP256K1N_DIV_2 =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    // EIP-8141 ENTRY_POINT constant. DEFAULT and VERIFY frames observe
    // msg.sender == ENTRY_POINT.
    address private constant ENTRY_POINT = address(0xaa);

    // EIP-8141 frame modes.
    uint256 private constant MODE_DEFAULT = 0;
    uint256 private constant MODE_VERIFY = 1;

    // APPROVE scope constants.
    uint256 private constant APPROVE_PAYMENT = 0x01;
    uint256 private constant APPROVE_GUARANTEE = 0x04;

    // Minimum gas_limit the guarantor VERIFY frame requires on the bump_nonce
    // frame. Must cover a cold-slot SSTORE (~22,100) plus DEFAULT-frame overhead
    // and a safety margin. Chosen concretely for this canonical implementation;
    // not a protocol-level constant.
    uint256 private constant MIN_BUMP_NONCE_GAS = 40_000;

    // ABI-encoded length of bumpNonce(address,uint256): 4-byte selector + two
    // 32-byte words.
    uint256 private constant BUMP_NONCE_DATA_LEN = 68;

    // Stored in contract storage instead of immutable so the deployed runtime
    // code is identical across all instances and can be recognized canonically
    // by code match. This is the authorized secp256k1 signer address, not a
    // generic contract-signature authority.
    address public owner;

    address payable public pendingWithdrawalTo;
    uint256 public pendingWithdrawalAmount;
    uint256 public pendingWithdrawalReadyAt;

    // Guarantor-mode per-sender fallback replay nonce. Only incremented when
    // sender validation fails. Keyed by `tx.sender` so that the failure of
    // one guaranteed transaction localizes invalidation to a single
    // (paymaster, sender) pair.
    mapping(address sender => uint256 nonce) public guarantor_nonce;

    error NotOwner();
    error NotEntryPoint();
    error ZeroAddress();
    error InvalidSignature();
    error InvalidNonce();
    error InvalidBumpNonceFrame();
    error NotInDefaultFrame();
    error NoPrecedingGuarantee();
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

    /// @dev Raw paymaster validation entrypoint. Use as the target of the
    ///      `pay`/`guarantee` VERIFY frame. The code path is selected by the
    ///      current frame's `allowed_scope`:
    ///      APPROVE_PAYMENT   => paymaster mode,
    ///      APPROVE_GUARANTEE => guarantor mode.
    fallback() external payable {
        if (msg.data.length != 65) revert InvalidSignature();

        uint256 currentFrame = _currentFrameIndex();
        uint256 allowedScope = _frameAllowedScope(currentFrame);

        if (allowedScope == APPROVE_PAYMENT) {
            _handlePaymasterMode();
        } else if (allowedScope == APPROVE_GUARANTEE) {
            _handleGuarantorMode(currentFrame);
        } else {
            revert InvalidSignature();
        }
    }

    function _handlePaymasterMode() internal {
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

        _approvePayment();
    }

    function _handleGuarantorMode(uint256 currentFrame) internal {
        // Calldata: r (32) || s (32) || v (1) = 65 bytes
        // (length already checked in fallback)
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

        // 1. Introspect the bump_nonce frame at current + 2 (skipping the
        //    sender validation frame at current + 1). It MUST be a DEFAULT
        //    call back to this contract invoking bumpNonce(tx.sender,
        //    payer_nonce) with enough gas for a cold-slot SSTORE. DEFAULT
        //    frame data is not elided from TXPARAM(0x09), so these checks
        //    bind the bump_nonce frame's exact shape — including payer_nonce
        //    — to the guarantor's signature.
        uint256 nextFrame;
        unchecked {
            nextFrame = currentFrame + 2;
        }
        if (nextFrame >= _numFrames()) revert InvalidBumpNonceFrame();
        if (_frameTarget(nextFrame) != address(this)) revert InvalidBumpNonceFrame();
        if (_frameMode(nextFrame) != MODE_DEFAULT) revert InvalidBumpNonceFrame();
        if (_frameGasLimit(nextFrame) < MIN_BUMP_NONCE_GAS) revert InvalidBumpNonceFrame();
        if (_frameDataLen(nextFrame) != BUMP_NONCE_DATA_LEN) revert InvalidBumpNonceFrame();

        address txSender = _txSender();

        // Selector (bytes 0-3) lives in the high 4 bytes of the first 32-byte
        // word of the next frame's data.
        bytes32 firstWord = _frameDataLoad(nextFrame, 0);
        if (bytes4(firstWord) != this.bumpNonce.selector) revert InvalidBumpNonceFrame();

        // sender argument occupies bytes [4..36); nonce argument occupies
        // bytes [36..68).
        if (address(uint160(uint256(_frameDataLoad(nextFrame, 4)))) != txSender) {
            revert InvalidBumpNonceFrame();
        }
        uint256 payerNonce = uint256(_frameDataLoad(nextFrame, 36));

        // 2. Nonce match. The bump itself happens in the following DEFAULT
        //    frame; this check ensures the bump will not spuriously revert.
        if (guarantor_nonce[txSender] != payerNonce) revert InvalidNonce();

        // 3. Authenticate the signer over TXPARAM(0x09), the frame-elide sig
        //    hash. It elides only the current frame's data and preserves
        //    every other frame's data — including the sender's VERIFY data
        //    (preventing sig-mutation grief) and the bump_nonce frame's data
        //    (which carries payer_nonce). So payer_nonce is already bound by
        //    this hash via the bump_nonce frame; no extra commitment needed.
        if (ecrecover(_txFrameSigHash(), v, r, s) != owner) revert InvalidSignature();

        // 4. Approve as guarantor. This sets guarantor_approved = true, which
        //    alone satisfies the transaction validity condition without
        //    requiring sender_approved.
        _approveGuarantee();
    }

    /// @notice Conditionally increment the guarantor nonce for `sender`.
    ///         Must be invoked from the DEFAULT frame at position current,
    ///         where current - 2 is a successful guarantor VERIFY targeting
    ///         this contract and current - 1 is the sender validation frame.
    ///         If sender validation succeeded, no-op (the protocol bumps the
    ///         sender's nonce). If it failed, increment guarantor_nonce as
    ///         fallback replay protection.
    function bumpNonce(address sender, uint256 payerNonce) external {
        if (msg.sender != ENTRY_POINT) revert NotEntryPoint();

        uint256 currentFrame = _currentFrameIndex();

        // Reject dispatch that accidentally lands on this selector while
        // executing in a non-DEFAULT frame (e.g. a VERIFY frame whose raw
        // calldata happens to begin with this selector).
        if (_frameMode(currentFrame) != MODE_DEFAULT) revert NotInDefaultFrame();

        // Need at least 2 preceding frames: guarantee (current-2) and
        // sender validation (current-1).
        if (currentFrame < 2) revert NoPrecedingGuarantee();

        uint256 guaranteeFrame;
        unchecked {
            guaranteeFrame = currentFrame - 2;
        }

        // Verify the guarantee frame at current - 2.
        if (_frameTarget(guaranteeFrame) != address(this)) revert NoPrecedingGuarantee();
        if (_frameMode(guaranteeFrame) != MODE_VERIFY) revert NoPrecedingGuarantee();
        if (_frameStatus(guaranteeFrame) != 1) revert NoPrecedingGuarantee();
        if (_frameApprovedScope(guaranteeFrame) != APPROVE_GUARANTEE) revert NoPrecedingGuarantee();

        // Check the sender validation frame at current - 1.
        uint256 senderFrame;
        unchecked {
            senderFrame = currentFrame - 1;
        }

        // If sender validation succeeded, the protocol increments the
        // sender's nonce. No guarantor nonce bump needed.
        if (_frameStatus(senderFrame) == 1) return;

        // Sender validation failed. Bump the guarantor nonce as fallback
        // replay protection.
        if (guarantor_nonce[sender] != payerNonce) revert InvalidNonce();

        unchecked {
            guarantor_nonce[sender] = payerNonce + 1;
        }
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

    // =========================================================================
    // EIP-8141 opcode wrappers
    // =========================================================================

    function _txSigHash() internal returns (bytes32 sigHash) {
        assembly {
            // TXPARAM(0x08) -> canonical frame transaction signature hash
            sigHash := verbatim_0i_1o(hex"6008b0")
        }
    }

    function _txFrameSigHash() internal returns (bytes32 sigHash) {
        assembly {
            // TXPARAM(0x09) -> frame-elide signature hash (elides only current frame's data)
            sigHash := verbatim_0i_1o(hex"6009b0")
        }
    }

    function _txSender() internal returns (address s) {
        assembly {
            // TXPARAM(0x02) -> tx.sender
            s := verbatim_0i_1o(hex"6002b0")
        }
    }

    function _numFrames() internal returns (uint256 n) {
        assembly {
            // TXPARAM(0x0A) -> len(frames)
            n := verbatim_0i_1o(hex"600ab0")
        }
    }

    function _currentFrameIndex() internal returns (uint256 idx) {
        assembly {
            // TXPARAM(0x0B) -> currently executing frame index
            idx := verbatim_0i_1o(hex"600bb0")
        }
    }

    function _frameTarget(uint256 idx) internal returns (address t) {
        assembly {
            // FRAMEPARAM(0x00, idx) -> frame.target
            // verbatim input `idx` is pushed first (bottom), then the literal
            // bytecode PUSH1 0x00 puts 0x00 on top. FRAMEPARAM pops param=0x00
            // and frameIndex=idx in that order.
            t := verbatim_1i_1o(hex"6000b3", idx)
        }
    }

    function _frameGasLimit(uint256 idx) internal returns (uint256 g) {
        assembly {
            // FRAMEPARAM(0x01, idx) -> frame.gas_limit
            g := verbatim_1i_1o(hex"6001b3", idx)
        }
    }

    function _frameMode(uint256 idx) internal returns (uint256 m) {
        assembly {
            // FRAMEPARAM(0x02, idx) -> frame.mode
            m := verbatim_1i_1o(hex"6002b3", idx)
        }
    }

    function _frameDataLen(uint256 idx) internal returns (uint256 len) {
        assembly {
            // FRAMEPARAM(0x04, idx) -> len(frame.data)
            len := verbatim_1i_1o(hex"6004b3", idx)
        }
    }

    function _frameAllowedScope(uint256 idx) internal returns (uint256 s) {
        assembly {
            // FRAMEPARAM(0x06, idx) -> frame.flags & APPROVE_SCOPE_MASK
            s := verbatim_1i_1o(hex"6006b3", idx)
        }
    }

    function _frameStatus(uint256 idx) internal returns (uint256 st) {
        assembly {
            // FRAMEPARAM(0x05, idx) -> frame.status (0 failure, 1 success)
            st := verbatim_1i_1o(hex"6005b3", idx)
        }
    }

    function _frameApprovedScope(uint256 idx) internal returns (uint256 s) {
        assembly {
            // FRAMEPARAM(0x09, idx) -> frame.approved_scope (the scope value
            // used in the frame's successful APPROVE call, or 0 if APPROVE
            // wasn't called).
            s := verbatim_1i_1o(hex"6009b3", idx)
        }
    }

    function _frameDataLoad(uint256 idx, uint256 offset) internal returns (bytes32 w) {
        assembly {
            // FRAMEDATALOAD(offset, idx)
            // verbatim_2i_1o pushes idx first (bottom), offset second (top).
            // FRAMEDATALOAD pops offset then frameIndex=idx.
            w := verbatim_2i_1o(hex"b1", idx, offset)
        }
    }

    function _approvePayment() internal {
        assembly {
            // APPROVE(scope=APPROVE_PAYMENT=0x1, length=0, offset=0)
            // Stack must be (bottom -> top): scope, length, offset.
            // Push order: PUSH1 0x01, PUSH1 0x00, PUSH1 0x00.
            verbatim_0i_0o(hex"600160006000aa")
        }
    }

    function _approveGuarantee() internal {
        assembly {
            // APPROVE(scope=APPROVE_GUARANTEE=0x4, length=0, offset=0)
            // Stack must be (bottom -> top): scope, length, offset.
            // Push order: PUSH1 0x04, PUSH1 0x00, PUSH1 0x00.
            verbatim_0i_0o(hex"600460006000aa")
        }
    }
}
