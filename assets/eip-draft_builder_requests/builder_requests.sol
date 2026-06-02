// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;  // for `Fp` / `Fp2` struct calldata in `deposit`

// ───────────────────────────────────────────────────────────────────────────────
// EIP-XXXX: Builder Execution Requests
//
// Three EIP-7685 request predeploys for the EIP-7732 builder population,
// modelled on the EIP-7002 (withdrawals) / EIP-7251 (consolidations) "request
// bus":
//
//   * BuilderDepositContract     @ BUILDER_DEPOSIT_CONTRACT_ADDRESS     (request type 0x03)
//       deposit(pubkey, wc, amount_gwei, signature, pubkey_y, signature_y) —
//       verifies the BLS proof-of-possession on chain via the EIP-2537
//       precompiles, then appends a deposit record to the in-state request queue.
//
//   * BuilderTopUpContract       @ BUILDER_TOPUP_CONTRACT_ADDRESS       (request type 0x04)
//       top_up(pubkey, amount_gwei) — unverified additional stake for an
//       already-registered builder; appends a top-up record to its queue. The
//       consensus layer rejects top-ups whose `pubkey` is not in the builder set.
//
//   * BuilderWithdrawalContract  @ BUILDER_WITHDRAWAL_CONTRACT_ADDRESS  (request type 0x05)
//       withdraw(pubkey, amount_gwei) — a semantic clone of the EIP-7002
//       withdrawal predeploy, retargeted at the builder set. The builder's
//       execution_address authorizes the request simply by being `msg.sender`,
//       so there is no BLS check and no staked value — only the fee. An
//       amount_gwei of 0 is a full exit, any amount_gwei > 0 a partial
//       withdrawal. The consensus layer ignores records whose recorded
//       source_address is not the target builder's execution_address.
//
// None of the contracts emit logs. All three share the `RequestQueue` base: a
// user call appends a record; at the end of the block a `SYSTEM_ADDRESS` call
// with empty calldata pops up to MAX_REQUESTS_PER_BLOCK records and returns them
// as the flat `request_data` for that predeploy's request type. The execution
// layer prepends the type byte and commits the result in the block
// `requests_hash` (EIP-7685). Each contract is a standard single-type request
// predeploy, so the EL needs no new read semantics — exactly the
// withdrawals/consolidations model.
//
// Anti-spam has two layers: every request carries the same EIP-1559-style
// request fee as EIP-7002/7251 (see RequestQueue), and deposits/top-ups
// additionally lock their staked value (>= 1 ETH), with a deposit also paying
// for gas-metered BLS verification. Withdrawals/exits move no ETH on this layer,
// so the fee alone meters them, exactly as in EIP-7002.
//
// Algorithms used (BuilderDepositContract):
//   * Signing root      — SSZ `hash_tree_root` of `DepositMessage` mixed with
//                         `DOMAIN_BUILDER_DEPOSIT` per `compute_signing_root`.
//   * Hash-to-curve     — `expand_message_xmd` + SSWU/3-isogeny via EIP-2537
//                         `MAP_FP2_TO_G2`, per IETF RFC 9380.
//   * Pairing check     — Negation trick: verify e(-G1, σ) · e(pk, H(m)) == 1
//                         via EIP-2537 `PAIRING_CHECK` (subgroup-checked).
//   * Fp reduction      — `MODEXP` precompile (0x05) with exponent 1.
//
// Design notes:
//   * Callers supply affine Y coordinates; there is no on-chain decompression
//     or Fp/Fp2 arithmetic kernel. The supplied Y is bound to the compressed
//     sign bit (see `_constructG1`/`_constructG2`), and a builder-specific
//     signing domain prevents cross-context replay with validator deposits.
//   * BLS verification gates entry into the deposit queue, so dequeued records
//     are pre-verified and carry no signature (the CL trusts the EL check).
// ───────────────────────────────────────────────────────────────────────────────

// EIP-7002 / EIP-7251 style request bus shared by both builder predeploys.
//
// A user call appends an opaque record (and increments the per-block request
// count). The end-of-block `SYSTEM_ADDRESS` system call drains up to
// MAX_REQUESTS_PER_BLOCK records (FIFO) and returns their concatenation as the
// predeploy's flat `request_data`, then updates the EIP-1559-style `excess`
// counter from the per-block count and resets the count.
//
// The queue is a head/tail ring over a `mapping(uint => bytes)`, matching
// EIP-7002's `dequeue_withdrawal_requests`: records are written at `queueTail`
// and read from `queueHead`, and BOTH pointers are reset to 0 once the queue
// empties (`new_queue_head_index == queue_tail_index` in EIP-7002), so the
// mapping slots are reused by later requests. Storage is therefore bounded by
// the peak in-flight queue depth, not by lifetime request volume — a plain
// growable array would leak a slot per request forever, since draining only
// advances the head.
//
// Each request carries a dynamic fee, computed exactly as in EIP-7002:
// `fee = fake_exponential(MIN_REQUEST_FEE, excess, REQUEST_FEE_UPDATE_FRACTION)`.
// When more than TARGET_REQUESTS_PER_BLOCK requests are submitted per block the
// excess grows and the fee rises super-linearly, throttling demand. The fee is
// charged on top of any staked value by the derived contract and is left locked
// in the contract (effectively burned).
//
// Unlike EIP-7002/7251 there is no EXCESS_INHIBITOR: those contracts are
// deployed before their activating fork and use the inhibitor to reject
// requests until the first system call. These predeploys are installed at the
// fork with empty storage (`excess == 0`, i.e. the minimum fee), so there are
// no pre-activation requests to inhibit.
contract RequestQueue {
    // Address used to invoke the end-of-block system operation (EIP-7002/7251).
    address constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    // Maximum records drained into a single block (mirrors EIP-7002); excess
    // records wait for later blocks.
    uint constant MAX_REQUESTS_PER_BLOCK = 16;
    // Per-block request count above which the fee starts to rise (mirrors EIP-7002).
    uint constant TARGET_REQUESTS_PER_BLOCK = 2;
    // Minimum request fee in wei, and the fee's update fraction (mirror EIP-7002).
    uint constant MIN_REQUEST_FEE = 1;
    uint constant REQUEST_FEE_UPDATE_FRACTION = 17;

    // FIFO queue of opaque request records: a head/tail ring over a mapping
    // (see the note above). `queueTail` is the next write index, `queueHead`
    // the next read index; both reset to 0 when the queue empties.
    mapping(uint => bytes) internal queue;
    uint internal queueHead;
    uint internal queueTail;

    // EIP-1559-style fee state: `excess` accumulates per-block demand above
    // TARGET; `count` is the number of requests added in the current block.
    uint internal excess;
    uint internal count;

    // Current per-request fee (wei). Constant within a block: `excess` is only
    // updated by the end-of-block system call.
    function _getFee() internal view returns (uint) {
        return _fakeExponential(MIN_REQUEST_FEE, excess, REQUEST_FEE_UPDATE_FRACTION);
    }

    // EIP-7002 fee curve: factor * e^(numerator / denominator), via the same
    // integer Taylor-series approximation used by EIP-1559 / EIP-4844.
    function _fakeExponential(uint factor, uint numerator, uint denominator)
        internal
        pure
        returns (uint)
    {
        uint i = 1;
        uint output = 0;
        uint numeratorAccum = factor * denominator;
        while (numeratorAccum > 0) {
            output += numeratorAccum;
            numeratorAccum = (numeratorAccum * numerator) / (denominator * i);
            i += 1;
        }
        return output / denominator;
    }

    // Append a request record and count it toward this block's demand. Called
    // by the derived entrypoint after it has validated (and, for deposits,
    // BLS-verified) the request and confirmed the fee was paid.
    function _recordRequest(bytes memory record) internal {
        queue[queueTail] = record;
        queueTail += 1;
        count += 1;
    }

    // 8-byte little-endian encoding of a uint64 (SSZ amount encoding).
    function _le64(uint64 v) internal pure returns (bytes memory r) {
        r = new bytes(8);
        for (uint i = 0; i < 8; i++) {
            r[i] = bytes1(uint8(v >> (8 * i)));
        }
    }

    // Empty-calldata entry point. Two modes, dispatched on caller (as EIP-7002):
    //   * SYSTEM_ADDRESS: end-of-block read-out — drain up to
    //     MAX_REQUESTS_PER_BLOCK records FIFO, update `excess` from `count`,
    //     reset `count`, and return the records as flat `request_data` (the EL
    //     prepends this predeploy's request-type byte).
    //   * any other caller: fee getter — return the current `_getFee()`.
    fallback() external {
        // Only the canonical empty-calldata call reaches the fallback meaningfully
        // (the system read-out, or a fee query) — `deposit`/`top_up` have their own
        // selectors. Reject any other calldata, as EIP-7002 does (it only treats
        // zero-length input as the fee getter).
        require(msg.data.length == 0, "RequestQueue: unexpected calldata");

        if (msg.sender != SYSTEM_ADDRESS) {
            // Fee getter.
            uint fee = _getFee();
            assembly {
                let p := mload(0x40)
                mstore(p, fee)
                return(p, 0x20)
            }
        }

        // Update the EIP-1559-style excess from this block's demand, then reset.
        uint c = count;
        excess = (excess + c > TARGET_REQUESTS_PER_BLOCK)
            ? excess + c - TARGET_REQUESTS_PER_BLOCK
            : 0;
        count = 0;

        // Drain up to MAX_REQUESTS_PER_BLOCK records (FIFO) from the head.
        uint head = queueHead;
        uint tail = queueTail;
        uint n = tail - head;
        if (n > MAX_REQUESTS_PER_BLOCK) {
            n = MAX_REQUESTS_PER_BLOCK;
        }

        // Concatenate the next `n` records into a single flat byte string.
        bytes memory out;
        for (uint i = 0; i < n; i++) {
            out = abi.encodePacked(out, queue[head + i]);
        }

        // EIP-7002 `dequeue_withdrawal_requests`: once the queue empties, reset
        // BOTH pointers to 0 so the mapping slots are reused by later requests;
        // otherwise just advance the head.
        uint newHead = head + n;
        if (newHead == tail) {
            queueHead = 0;
            queueTail = 0;
        } else {
            queueHead = newHead;
        }

        assembly {
            return(add(out, 0x20), mload(out))
        }
    }
}

contract BuilderDepositContract is RequestQueue {

    // ── Constants ──────────────────────────────────────────────────────────

    uint constant PUBLIC_KEY_LENGTH  = 48;
    uint constant SIGNATURE_LENGTH   = 96;

    // EIP-7732 sets the builder minimum stake at 1 ETH. The contract enforces
    // the same lower bound at the EL boundary so junk-amount transactions are
    // rejected before they reach the consensus layer.
    uint constant BUILDER_MIN_DEPOSIT = 1 ether;

    // EIP-2537 precompile addresses.
    uint8 constant BLS12_G2ADD             = 0x0d;
    uint8 constant BLS12_PAIRING_CHECK     = 0x0f;
    uint8 constant BLS12_MAP_FP2_TO_G2     = 0x11;
    // Pre-existing modexp precompile (used for hash_to_field's modular reduction).
    uint8 constant MOD_EXP_PRECOMPILE      = 0x05;

    // Gas forwarded to each precompile staticcall. Per EIP-2537 §"Gas burning
    // on error", an EIP-2537 precompile that rejects its input (malformed
    // encoding, off-curve, or wrong-subgroup point) burns ALL gas forwarded to
    // the call. Forwarding `gas()` would therefore let a single malformed point
    // drain a whole transaction. Because EIP-2537 pricing is deterministic
    // (a pure function of input length, no data-dependent loops), we instead
    // forward a fixed ceiling per precompile, bounding the worst-case burn on a
    // bad input to that ceiling. Each ceiling is ~2.5x the documented cost, a
    // margin chosen to tolerate a moderate future reprice while still capping
    // the loss far below a full transaction.
    //
    //   precompile          documented cost        ceiling
    //   MAP_FP2_TO_G2       23800                  60000
    //   G2ADD               600                    2000
    //   PAIRING_CHECK       32600*k + 37700        256000  (k = 2 -> 102900)
    //   MODEXP (0x05)       ~200 for our inputs    5000    (does not burn-all,
    //                                                       capped for uniformity)
    uint constant MAP_FP2_TO_G2_GAS = 60000;
    uint constant G2ADD_GAS         = 2000;
    uint constant PAIRING_CHECK_GAS = 256000;
    uint constant MODEXP_GAS        = 5000;

    // Canonical Eth2 BLS ciphersuite, used directly as the DST for
    // `expand_message_xmd` per IETF draft-irtf-cfrg-bls-signature-04.
    string constant BLS_SIG_DST = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_";

    // Mask used to clear the three flag bits from the top byte of a compressed
    // BLS12-381 point's X coordinate.
    bytes1 constant BLS_BYTE_WITHOUT_FLAGS_MASK = bytes1(0x1f);

    // (q - 1) / 2 in the (hi:128, lo:256) Fp packing — the IETF sign-bit
    // threshold for a field element: sign(y) == 1 iff y > (q-1)/2. Used to
    // bind the caller-supplied affine Y to the compressed sign flag.
    uint constant Q_MINUS_1_OVER_2_HI = 0x0d0088f51cbff34d258dd3db21a5d66b;
    uint constant Q_MINUS_1_OVER_2_LO = 0xb23ba5c279c2895fb39869507b587b120f55ffff58a9ffffdcff7fffffffd555;

    // Builder-deposit signing domain. Distinct from the validator deposit
    // domain (0x03000000…) so a proof-of-possession signature is NOT
    // interchangeable between this contract and the validator deposit contract
    // at 0x00000000219ab540356cbb839cbe05303d7705fa — without this separation a
    // public validator-deposit signature could be replayed here to force-enrol
    // a validator pubkey as a builder (and vice versa).
    //
    // Constructed as compute_domain(DOMAIN_BUILDER_DEPOSIT_TYPE,
    //   fork_version=GENESIS_FORK_VERSION=0x00000000, genesis_validators_root=0)
    // = DOMAIN_BUILDER_DEPOSIT_TYPE || sha256(64 zero bytes)[:28].
    //
    // DRAFT NOTE [EIP-XXXX]: the 4-byte domain type 0x0b000000 is a PLACEHOLDER.
    // The final value MUST be allocated in consensus-specs and MUST differ from
    // DOMAIN_DEPOSIT (0x03000000).
    bytes32 constant DOMAIN_BUILDER_DEPOSIT = 0x0b000000f5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a9;

    // ── Structs (EIP-2537 encoding) ────────────────────────────────────────

    // Fp: a base-field element in the EIP-2537 64-byte encoding, with the 16
    // zero pad-bytes folded into the top of `a`.
    struct Fp  { uint a; uint b; }

    // Fp2 = a + b·u with u² = -1.
    struct Fp2 { Fp a; Fp b; }

    // Point on BLS12-381 over Fp.
    struct G1Point { Fp X; Fp Y; }

    // Point on BLS12-381 over Fp2.
    struct G2Point { Fp2 X; Fp2 Y; }

    // ── Request record ─────────────────────────────────────────────────────
    //
    // EIP-7685 `request_data` for a builder deposit (request type 0x03) is the
    // concatenation of one record per dequeued deposit:
    //
    //   pubkey (48) ++ withdrawal_credentials (32) ++ amount_gwei (8, LE) = 88 bytes
    //
    // The signature is intentionally absent: it was verified at submission, so
    // the consensus layer trusts the record without re-pairing.

    // ── External entrypoint ────────────────────────────────────────────────

    /// @notice BLS-verified builder deposit. On success, appends a deposit
    /// record to the request queue (no log). `amount_gwei` is the stake to
    /// credit and is the amount bound into the signed `DepositMessage`; the
    /// caller MUST send `msg.value >= amount_gwei * 1 gwei + fee`, where `fee`
    /// is the current request fee (call this contract with empty calldata to
    /// read it). The staked ETH is locked in the contract; the consensus layer
    /// credits the builder `amount_gwei` from the dequeued request.
    function deposit(
        bytes calldata pubkey,
        bytes32 withdrawal_credentials,
        uint64 amount_gwei,
        bytes calldata signature,
        Fp calldata pubkey_y,
        Fp2 calldata signature_y
    ) external payable {
        require(pubkey.length == PUBLIC_KEY_LENGTH,    "BuilderDeposit: invalid pubkey length");
        require(signature.length == SIGNATURE_LENGTH,  "BuilderDeposit: invalid signature length");
        uint stake = uint(amount_gwei) * 1 gwei;
        require(stake >= BUILDER_MIN_DEPOSIT,          "BuilderDeposit: deposit value too low");
        // Fee is charged on top of the stake; overpayment of the fee is
        // forfeited, as in EIP-7002.
        require(msg.value >= stake + _getFee(),        "BuilderDeposit: insufficient value for stake + fee");
        require(!_isInfinityFlagSet(pubkey[0]),        "BuilderDeposit: infinity pubkey");
        require(!_isInfinityFlagSet(signature[0]),     "BuilderDeposit: infinity signature");

        // BLS proof-of-possession check. Performed before the record is queued
        // so an invalid signature reverts the whole call and never enqueues.
        // The amount is not part of the signed message (see
        // `_computeDepositSigningRoot`); it is recorded below as the credited stake.
        bytes32 signingRoot = _computeDepositSigningRoot(pubkey, withdrawal_credentials);
        G1Point memory pk        = _constructG1(pubkey, pubkey_y);
        G2Point memory sig       = _constructG2(signature, signature_y);
        G2Point memory msgPoint  = _hashToCurve(signingRoot);
        require(
            _blsPairingCheck(pk, msgPoint, sig),
            "BuilderDeposit: invalid BLS signature"
        );

        _recordRequest(abi.encodePacked(
            pubkey, withdrawal_credentials, _le64(amount_gwei)
        ));
    }

    // ── Signing-root computation ───────────────────────────────────────────

    // Algorithm: SSZ `hash_tree_root` (consensus-specs §SSZ Merkleization) +
    // `compute_signing_root` (consensus-specs §Beacon-chain helpers).
    //
    // The builder deposit message is the 2-field container
    // `(pubkey, withdrawal_credentials)` — the amount is deliberately NOT
    // signed (the unverified `top_up` already lets stake be added without a
    // signature, so binding it here would protect nothing). The signature is a
    // proof of possession that binds only the key and the withdrawal target.
    // Returns `sha256(hash_tree_root(pubkey, withdrawal_credentials) || DOMAIN_BUILDER_DEPOSIT)`.
    function _computeDepositSigningRoot(
        bytes memory pubkey,
        bytes32 withdrawal_credentials
    ) internal pure returns (bytes32) {
        // `pubkey` is 48 bytes; pad to 64 bytes and sha256 to get its SSZ root.
        bytes memory paddedPubkey = new bytes(64);
        for (uint i = 0; i < PUBLIC_KEY_LENGTH; i++) {
            paddedPubkey[i] = pubkey[i];
        }
        bytes32 pubkeyRoot = sha256(paddedPubkey);

        // hash_tree_root of the 2-field container = sha256(field0 || field1):
        //   sha256(pubkey_root || withdrawal_credentials).
        bytes32 messageRoot = sha256(abi.encodePacked(pubkeyRoot, withdrawal_credentials));

        return sha256(abi.encodePacked(messageRoot, DOMAIN_BUILDER_DEPOSIT));
    }

    // ── hash_to_curve (BLS12-381 G2) ───────────────────────────────────────

    // Algorithm: `expand_message_xmd` (RFC 9380 §5.3.1) with SHA-256, producing
    // 256 output bytes. Layout matches draft-irtf-cfrg-hash-to-curve-16.
    function _expandMessage(bytes32 message) internal pure returns (bytes memory) {
        // b0 = sha256(Z_pad(64) || message(32) || lib_str(2)=0x0100 ||
        //             I2OSP(0,1) || DST || DST_len(1)).
        // Lengths: 64 + 32 + 2 + 1 + 43 + 1 = 143 bytes.
        bytes memory b0Input = new bytes(143);
        for (uint i = 0; i < 32; i++) {
            b0Input[i + 64] = message[i];
        }
        b0Input[96] = 0x01;
        for (uint i = 0; i < 43; i++) {
            b0Input[i + 99] = bytes(BLS_SIG_DST)[i];
        }
        b0Input[142] = bytes1(uint8(43));
        bytes32 b0 = sha256(b0Input);

        // b1..b8: 8 chained sha256 invocations yielding 256 output bytes.
        bytes memory output = new bytes(256);
        bytes32 chunk = sha256(abi.encodePacked(b0, bytes1(uint8(1)), bytes(BLS_SIG_DST), bytes1(uint8(43))));
        assembly {
            mstore(add(output, 0x20), chunk)
        }
        for (uint i = 2; i < 9; i++) {
            bytes32 input;
            assembly {
                input := xor(b0, mload(add(output, add(0x20, mul(0x20, sub(i, 2))))))
            }
            chunk = sha256(abi.encodePacked(input, bytes1(uint8(i)), bytes(BLS_SIG_DST), bytes1(uint8(43))));
            assembly {
                mstore(add(output, add(0x20, mul(0x20, sub(i, 1)))), chunk)
            }
        }
        return output;
    }

    // Algorithm: `hash_to_field` (RFC 9380 §5.2) producing 2 Fp2 elements by
    // reducing 64-byte slices of `expand_message_xmd` output mod q.
    function _hashToField(bytes32 message) internal view returns (Fp2[2] memory result) {
        bytes memory expanded = _expandMessage(message);
        result[0] = Fp2(
            _convertSliceToFp(expanded, 0, 64),
            _convertSliceToFp(expanded, 64, 128)
        );
        result[1] = Fp2(
            _convertSliceToFp(expanded, 128, 192),
            _convertSliceToFp(expanded, 192, 256)
        );
    }

    // Algorithm: `hash_to_curve` (RFC 9380 §3, encode_to_curve for G2): two
    // `hash_to_field` outputs each mapped to G2 via SSWU + 3-isogeny (via
    // EIP-2537 `MAP_FP2_TO_G2`), summed in G2.
    function _hashToCurve(bytes32 message) internal view returns (G2Point memory) {
        Fp2[2] memory uvals = _hashToField(message);
        G2Point memory p0 = _mapToCurveG2(uvals[0]);
        G2Point memory p1 = _mapToCurveG2(uvals[1]);
        return _addG2(p0, p1);
    }

    // ── Field-arithmetic helper (modexp-based reduction) ───────────────────

    // Reduce data[start:end] mod q via the MODEXP precompile (exponent 1).
    // Returns a 48-byte big-endian result.
    function _reduceModulo(bytes memory data, uint start, uint end) internal view returns (bytes memory) {
        uint length = end - start;
        require(length <= data.length, "BuilderDeposit: slice out of range");
        bytes memory result = new bytes(48);
        bool success;
        assembly {
            let p := mload(0x40)
            mstore(p, length)             // length of base
            mstore(add(p, 0x20), 0x20)    // length of exponent
            mstore(add(p, 0x40), 48)      // length of modulus
            // base
            let ctr := length
            let src := add(add(data, 0x20), start)
            let dst := add(p, 0x60)
            for { } or(gt(ctr, 0x20), eq(ctr, 0x20)) { ctr := sub(ctr, 0x20) } {
                mstore(dst, mload(src))
                dst := add(dst, 0x20)
                src := add(src, 0x20)
            }
            let mask    := sub(exp(256, sub(0x20, ctr)), 1)
            let srcpart := and(mload(src), not(mask))
            let dstpart := and(mload(dst), mask)
            mstore(dst, or(dstpart, srcpart))
            // exponent: 1 (identity exponent — we only need a mod reduction)
            mstore(add(p, add(0x60, length)), 1)
            // modulus q (high 16 bytes ORed in, low 32 bytes as a full word)
            let modulusAddr := add(p, add(0x60, add(0x10, length)))
            mstore(modulusAddr, or(mload(modulusAddr), 0x1a0111ea397fe69a4b1ba7b6434bacd7))
            mstore(add(p, add(0x90, length)), 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab)
            success := staticcall(MODEXP_GAS, MOD_EXP_PRECOMPILE, p, add(0xB0, length), add(result, 0x20), 48)
            switch success case 0 { revert(0, 0) }
        }
        require(success, "BuilderDeposit: modexp failed");
        return result;
    }

    function _convertSliceToFp(bytes memory data, uint start, uint end) internal view returns (Fp memory) {
        bytes memory fe = _reduceModulo(data, start, end);
        return Fp(_sliceToUint(fe, 0, 16), _sliceToUint(fe, 16, 48));
    }

    function _sliceToUint(bytes memory data, uint start, uint end) internal pure returns (uint result) {
        uint length = end - start;
        require(length <= 32, "BuilderDeposit: bad slice");
        for (uint i = 0; i < length; i++) {
            result = result + (uint8(data[start + i]) * (2 ** (8 * (length - i - 1))));
        }
    }

    // ── EIP-2537 precompile wrappers ───────────────────────────────────────

    // Algorithm: simplified SWU map for BLS12-381 G2 (Wahby–Boneh 2019)
    // composed with the 3-isogeny back to G2, delegated to the EIP-2537
    // `MAP_FP2_TO_G2` precompile (address 0x11).
    function _mapToCurveG2(Fp2 memory fe) internal view returns (G2Point memory) {
        uint[4] memory input = [fe.a.a, fe.a.b, fe.b.a, fe.b.b];
        uint[8] memory output;
        bool success;
        assembly {
            success := staticcall(MAP_FP2_TO_G2_GAS, BLS12_MAP_FP2_TO_G2, input, 128, output, 256)
            switch success case 0 { revert(0, 0) }
        }
        require(success, "BuilderDeposit: map_fp2_to_g2 failed");
        return G2Point(
            Fp2(Fp(output[0], output[1]), Fp(output[2], output[3])),
            Fp2(Fp(output[4], output[5]), Fp(output[6], output[7]))
        );
    }

    // Algorithm: BLS12-381 G2 point addition, delegated to EIP-2537 `G2ADD`
    // (0x0d).
    function _addG2(G2Point memory a, G2Point memory b) internal view returns (G2Point memory) {
        uint[16] memory input = [
            a.X.a.a, a.X.a.b, a.X.b.a, a.X.b.b, a.Y.a.a, a.Y.a.b, a.Y.b.a, a.Y.b.b,
            b.X.a.a, b.X.a.b, b.X.b.a, b.X.b.b, b.Y.a.a, b.Y.a.b, b.Y.b.a, b.Y.b.b
        ];
        uint[8] memory output;
        bool success;
        assembly {
            success := staticcall(G2ADD_GAS, BLS12_G2ADD, input, 512, output, 256)
            switch success case 0 { revert(0, 0) }
        }
        require(success, "BuilderDeposit: g2_add failed");
        return G2Point(
            Fp2(Fp(output[0], output[1]), Fp(output[2], output[3])),
            Fp2(Fp(output[4], output[5]), Fp(output[6], output[7]))
        );
    }

    // Algorithm: BLS verification via the "fixed-(-G1)" pairing identity
    // (Boneh–Lynn–Shacham 2001, §3): instead of testing
    //   e(pk, H(m)) == e(G1, σ),
    // we test
    //   e(-G1, σ) · e(pk, H(m)) == 1,
    // which is a single multi-pairing call. Delegated to EIP-2537
    // `PAIRING_CHECK` (0x0f), which internally performs G1 and G2 subgroup
    // checks and returns 0/1.
    function _blsPairingCheck(G1Point memory pk, G2Point memory msgPoint, G2Point memory sig)
        internal
        view
        returns (bool)
    {
        uint[24] memory input;

        input[0]  = pk.X.a;
        input[1]  = pk.X.b;
        input[2]  = pk.Y.a;
        input[3]  = pk.Y.b;

        input[4]  = msgPoint.X.a.a;
        input[5]  = msgPoint.X.a.b;
        input[6]  = msgPoint.X.b.a;
        input[7]  = msgPoint.X.b.b;
        input[8]  = msgPoint.Y.a.a;
        input[9]  = msgPoint.Y.a.b;
        input[10] = msgPoint.Y.b.a;
        input[11] = msgPoint.Y.b.b;

        // -G1 = negation of the BLS12-381 G1 generator, in EIP-2537 encoding.
        input[12] = 31827880280837800241567138048534752271;
        input[13] = 88385725958748408079899006800036250932223001591707578097800747617502997169851;
        input[14] = 22997279242622214937712647648895181298;
        input[15] = 46816884707101390882112958134453447585552332943769894357249934112654335001290;

        input[16] = sig.X.a.a;
        input[17] = sig.X.a.b;
        input[18] = sig.X.b.a;
        input[19] = sig.X.b.b;
        input[20] = sig.Y.a.a;
        input[21] = sig.Y.a.b;
        input[22] = sig.Y.b.a;
        input[23] = sig.Y.b.b;

        uint[1] memory output;
        bool success;
        assembly {
            success := staticcall(PAIRING_CHECK_GAS, BLS12_PAIRING_CHECK, input, 768, output, 32)
            switch success case 0 { revert(0, 0) }
        }
        require(success, "BuilderDeposit: pairing_check failed");
        return output[0] == 1;
    }

    // ── Compressed-point construction (caller-supplied Y) ──────────────────

    // Parse a 48-byte compressed G1 X coordinate and pair it with the caller-
    // supplied Y.
    //
    // The supplied Y MUST agree with the compressed sign flag. This binds the
    // point used in the pairing check to the encoding that is emitted (and that
    // the consensus layer decompresses): without it, a caller controlling its
    // own key could verify (X, +Y) while the emitted bytes decompress to
    // (X, -Y), so the consensus layer would register a key whose proof-of-
    // possession was never actually verified. The pairing check alone does NOT
    // catch this, because the depositor jointly chooses the key, the emitted
    // sign bit, and the signature, keeping the pairing self-consistent.
    function _constructG1(bytes memory compressed, Fp memory y) internal pure returns (G1Point memory) {
        require(
            _fpSignBit(y) == _isSignFlagSet(compressed[0]),
            "BuilderDeposit: pubkey Y sign mismatch"
        );
        bytes memory rawX = _stripFlagBits(compressed);
        Fp memory X = Fp(_sliceToUint(rawX, 0, 16), _sliceToUint(rawX, 16, 48));
        return G1Point(X, y);
    }

    // Parse a 96-byte compressed G2 X coordinate and pair it with the caller-
    // supplied Y. BLS12-381 compressed G2 places the imaginary Fp coefficient
    // first (bytes [0..48]) and the real Fp coefficient second (bytes [48..96]).
    // As in `_constructG1`, the supplied Y MUST agree with the compressed sign
    // flag so the verified point binds to the emitted encoding.
    function _constructG2(bytes memory compressed, Fp2 memory y) internal pure returns (G2Point memory) {
        require(
            _fp2SignBit(y) == _isSignFlagSet(compressed[0]),
            "BuilderDeposit: signature Y sign mismatch"
        );
        bytes memory rawX = _stripFlagBits(compressed);
        uint bA = _sliceToUint(rawX, 0, 16);
        uint bB = _sliceToUint(rawX, 16, 48);
        uint aA = _sliceToUint(rawX, 48, 64);
        uint aB = _sliceToUint(rawX, 64, 96);
        Fp2 memory X = Fp2(Fp(aA, aB), Fp(bA, bB));
        return G2Point(X, y);
    }

    // ── Compressed-encoding flag handling ──────────────────────────────────

    // Algorithm: ZCash-style BLS12-381 serialization flag bits (also adopted
    // by IETF draft-irtf-cfrg-bls-signature Appendix A). The first byte
    // carries three flags in its top three bits — [compressed (0x80)]
    // [infinity (0x40)][sign (0x20)] — and five bits of X-coordinate payload.
    // We reject infinity-flagged inputs (the identity element is never a valid
    // pubkey or signature) and bind the sign flag to the caller-supplied Y
    // (see `_constructG1` / `_constructG2`).
    function _isInfinityFlagSet(bytes1 b) internal pure returns (bool) {
        return (uint8(b) & 0x40) != 0;
    }

    function _isSignFlagSet(bytes1 b) internal pure returns (bool) {
        return (uint8(b) & 0x20) != 0;
    }

    function _stripFlagBits(bytes memory enc) internal pure returns (bytes memory) {
        bytes memory copyOf = new bytes(enc.length);
        for (uint i = 0; i < enc.length; i++) {
            copyOf[i] = enc[i];
        }
        copyOf[0] = copyOf[0] & BLS_BYTE_WITHOUT_FLAGS_MASK;
        return copyOf;
    }

    // ── Sign bit of an affine Y coordinate ─────────────────────────────────
    //
    // The IETF "sign" of a field element y is 1 iff y > (q-1)/2. For Fp2, the
    // sign is that of the imaginary coefficient if non-zero, else that of the
    // real coefficient. These match the conventions used by the BLS12-381
    // (de)compression routines the consensus layer applies to the emitted
    // encoding.

    function _fpIsZero(Fp memory x) internal pure returns (bool) {
        return x.a == 0 && x.b == 0;
    }

    function _fpSignBit(Fp memory y) internal pure returns (bool) {
        if (y.a > Q_MINUS_1_OVER_2_HI) return true;
        if (y.a < Q_MINUS_1_OVER_2_HI) return false;
        return y.b > Q_MINUS_1_OVER_2_LO;
    }

    function _fp2SignBit(Fp2 memory y) internal pure returns (bool) {
        // Fp2 is `a + b·u`; `.a` is the real coefficient, `.b` the imaginary.
        if (!_fpIsZero(y.b)) return _fpSignBit(y.b);
        return _fpSignBit(y.a);
    }
}

// ───────────────────────────────────────────────────────────────────────────────
// Builder top-up predeploy — EIP-7685 request type 0x04, installed at
// BUILDER_TOPUP_CONTRACT_ADDRESS.
//
// Unverified: adds stake to an already-registered builder. There is no BLS
// check (a top-up does not register a new key), so this contract carries none
// of the cryptographic machinery — just the shared request queue. The consensus
// layer MUST reject top-ups whose pubkey is not already in the builder set.
//
// No `withdrawal_credentials`: a top-up only adds stake to an existing builder,
// whose credentials are fixed by its verified deposit. Omitting the field
// denies an unauthenticated caller any influence over a builder's withdrawal
// target.
//
// EIP-7685 `request_data` is the concatenation of one record per dequeued
// top-up: pubkey (48) ++ amount_gwei (8, LE) = 56 bytes.
// ───────────────────────────────────────────────────────────────────────────────
contract BuilderTopUpContract is RequestQueue {
    uint constant PUBLIC_KEY_LENGTH   = 48;
    uint constant BUILDER_MIN_DEPOSIT = 1 ether;

    /// @notice Unverified top-up. On success, appends a top-up record to the
    /// request queue (no log). `amount_gwei` is the stake to add; the caller
    /// MUST send `msg.value >= amount_gwei * 1 gwei + fee`, where `fee` is the
    /// current request fee (read it by calling this contract with empty
    /// calldata). The ETH is locked in the contract; the consensus layer
    /// credits the existing builder from the dequeued request.
    function top_up(bytes calldata pubkey, uint64 amount_gwei) external payable {
        require(pubkey.length == PUBLIC_KEY_LENGTH, "BuilderTopUp: invalid pubkey length");
        uint stake = uint(amount_gwei) * 1 gwei;
        require(stake >= BUILDER_MIN_DEPOSIT,       "BuilderTopUp: deposit value too low");
        require(msg.value >= stake + _getFee(),     "BuilderTopUp: insufficient value for stake + fee");

        _recordRequest(abi.encodePacked(pubkey, _le64(amount_gwei)));
    }
}

// ───────────────────────────────────────────────────────────────────────────────
// Builder withdrawal / exit predeploy — EIP-7685 request type 0x05, installed at
// BUILDER_WITHDRAWAL_CONTRACT_ADDRESS.
//
// A semantic clone of the EIP-7002 withdrawal-request predeploy, retargeted at
// the EIP-7732 builder set. A builder's `execution_address` (the 0x03 builder
// withdrawal credential) authorizes a request simply by being `msg.sender` —
// exactly as EIP-7002's 0x01 credential does — so this contract needs NO BLS
// verification and locks NO stake: unlike a deposit or top-up, a withdrawal
// moves no ETH on the execution layer, and the caller sends only the request
// fee. `amount_gwei == 0` requests a full exit (the "voluntary exit"); any
// `amount_gwei > 0` requests a partial withdrawal of that many gwei. The
// consensus layer interprets the amount-zero sentinel exactly as it does for
// validators under EIP-7002.
//
// EIP-7685 `request_data` is the concatenation of one record per dequeued
// request:
//   source_address (20) ++ pubkey (48) ++ amount_gwei (8, LE) = 76 bytes,
// identical in shape to EIP-7002's `ValidatorWithdrawalRequest`. As with the
// sibling builder predeploys this contract emits no logs (EIP-7002 emits a
// log0; the request bus does not need it). The consensus layer MUST ignore a
// record whose `source_address` does not match the target builder's
// `execution_address`, so a third party cannot withdraw or exit a builder it
// does not control.
// ───────────────────────────────────────────────────────────────────────────────
contract BuilderWithdrawalContract is RequestQueue {
    uint constant PUBLIC_KEY_LENGTH = 48;

    /// @notice Builder withdrawal / exit request. On success, appends a record
    /// to the request queue (no log). `amount_gwei == 0` requests a full exit;
    /// any `amount_gwei > 0` requests a partial withdrawal of that many gwei
    /// from the builder's beacon-chain balance. Unlike `deposit`/`top_up` this
    /// moves no ETH on the execution layer: the caller sends only
    /// `msg.value >= fee`, where `fee` is the current request fee (read it by
    /// calling this contract with empty calldata). The record's `source_address`
    /// is `msg.sender`; the consensus layer honours the request only if it
    /// equals the target builder's `execution_address`. There is intentionally
    /// no minimum-amount check — `0` is the exit sentinel, mirroring EIP-7002.
    function withdraw(bytes calldata pubkey, uint64 amount_gwei) external payable {
        require(pubkey.length == PUBLIC_KEY_LENGTH, "BuilderWithdrawal: invalid pubkey length");
        require(msg.value >= _getFee(),             "BuilderWithdrawal: insufficient value for fee");

        _recordRequest(abi.encodePacked(msg.sender, pubkey, _le64(amount_gwei)));
    }
}
