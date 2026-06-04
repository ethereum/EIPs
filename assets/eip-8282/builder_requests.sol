// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.6.11;

// ───────────────────────────────────────────────────────────────────────────────
// EIP-8282: Builder Execution Requests
//
// Two EIP-7685 request predeploys for the EIP-7732 builder population, modelled
// on the EIP-7002 (withdrawals) / EIP-7251 (consolidations) "request bus":
//
//   * BuilderDepositContract  @ BUILDER_DEPOSIT_CONTRACT_ADDRESS  (request type 0x03)
//       deposit(pubkey, withdrawal_credentials, amount_gwei, signature) — appends
//       a deposit record to the in-state request queue. Serves BOTH first
//       deposits and top-ups: the consensus layer registers a builder on a
//       pubkey's first appearance (verifying the proof-of-possession) and credits
//       additional stake on later deposits to an existing builder, exactly as the
//       validator deposit contract does. The BLS signature is carried in the
//       record and verified by the consensus layer on dequeue.
//
//   * BuilderExitContract     @ BUILDER_EXIT_CONTRACT_ADDRESS     (request type 0x04)
//       exit(pubkey) — full exit of a builder, authorized by the caller being the
//       builder's execution_address (recorded as source_address). No signature,
//       no staked value — only the fee.
//
// Neither contract emits logs; both are thin queues over
// the shared `RequestQueue` base. A user call appends a record; at the end of the
// block a `SYSTEM_ADDRESS` call with empty calldata pops up to
// MAX_REQUESTS_PER_BLOCK records and returns them as the flat `request_data` for
// that predeploy's request type. The execution layer prepends the type byte and
// commits the result in the block `requests_hash` (EIP-7685). Each is a standard
// single-type request predeploy — exactly the withdrawals/consolidations model.
//
// Anti-spam is the EIP-1559-style request fee (see RequestQueue) plus, for
// deposits, the staked value (>= 1 ETH, locked and forfeited if the consensus
// layer's proof-of-possession check fails). The per-block cap bounds the
// consensus-layer verification work to MAX_REQUESTS_PER_BLOCK records per block.
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
// Like EIP-7002/7251, each contract is deployed by a transaction that can land
// before the activating fork, so the constructor initializes `excess` to
// EXCESS_INHIBITOR: `_getFee` reverts (and therefore no request can be enqueued)
// until the first end-of-block system call clears the inhibitor. That system
// call treats a current `excess` of EXCESS_INHIBITOR as 0, after which the fee
// mechanism operates normally.
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
    // Excess value that inhibits the fee getter before the first system call
    // (mirrors EIP-7002/7251). The constructor sets `excess` to this; the first
    // end-of-block system call clears it.
    uint constant EXCESS_INHIBITOR = type(uint256).max;

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

    // Deployed (like EIP-7002/7251) by a transaction that may precede the
    // activating fork, so start inhibited: no request can be enqueued until the
    // first end-of-block system call clears the inhibitor.
    constructor() public {
        excess = EXCESS_INHIBITOR;
    }

    // Current per-request fee (wei). Constant within a block: `excess` is only
    // updated by the end-of-block system call. Reverts while the inhibitor is
    // set (before the first system call), exactly as EIP-7002/7251's fee getter.
    function _getFee() internal view returns (uint) {
        require(excess != EXCESS_INHIBITOR, "RequestQueue: fee inhibited");
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

    // Append a request record and count it toward this block's demand. Called by
    // the derived entrypoint after it has validated the request and confirmed the
    // fee was paid.
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
        // (the system read-out, or a fee query) — `deposit`/`exit` have their own
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
        // A current value of EXCESS_INHIBITOR (set at deployment) counts as 0, so
        // the first system call clears the inhibitor (mirrors EIP-7002/7251).
        uint c = count;
        uint prevExcess = excess == EXCESS_INHIBITOR ? 0 : excess;
        excess = (prevExcess + c > TARGET_REQUESTS_PER_BLOCK)
            ? prevExcess + c - TARGET_REQUESTS_PER_BLOCK
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

// ───────────────────────────────────────────────────────────────────────────────
// Builder deposit predeploy — EIP-7685 request type 0x03, deployed at
// BUILDER_DEPOSIT_CONTRACT_ADDRESS. Serves both first deposits and top-ups.
//
// `deposit(...)` appends pubkey (48) ++ withdrawal_credentials (32) ++
// amount_gwei (8, LE) ++ signature (96) = 184 bytes. The consensus layer verifies
// the BLS proof-of-possession on dequeue, but only on a pubkey's first
// appearance; a later deposit to an existing builder is a stake top-up, and the
// consensus layer ignores its `withdrawal_credentials` and `signature`.
// ───────────────────────────────────────────────────────────────────────────────
contract BuilderDepositContract is RequestQueue {
    uint constant PUBLIC_KEY_LENGTH = 48;
    uint constant SIGNATURE_LENGTH  = 96;

    // EIP-7732 sets the builder minimum stake at 1 ETH; enforced at the EL
    // boundary so junk-amount transactions are rejected before the consensus layer.
    uint constant BUILDER_MIN_DEPOSIT = 1 ether;

    /// @notice Builder deposit (also serves as top-up). On success, appends a
    /// record to the request queue (no log). `amount_gwei` is the stake to
    /// credit; the caller MUST send `msg.value >= amount_gwei * 1 gwei + fee`,
    /// where `fee` is the current request fee (read it by calling this contract
    /// with empty calldata). Any value beyond the stake (the fee, plus any
    /// overpayment) is retained by the contract. The staked ETH is locked; the
    /// consensus layer credits the builder from the dequeued record — registering
    /// it on the pubkey's first appearance after verifying `signature`, or
    /// crediting stake to an existing builder (in which case it ignores
    /// `withdrawal_credentials` and `signature`).
    function deposit(
        bytes calldata pubkey,
        bytes32 withdrawal_credentials,
        uint64 amount_gwei,
        bytes calldata signature
    ) external payable {
        require(pubkey.length == PUBLIC_KEY_LENGTH,   "BuilderDeposit: invalid pubkey length");
        require(signature.length == SIGNATURE_LENGTH, "BuilderDeposit: invalid signature length");
        uint stake = uint(amount_gwei) * 1 gwei;
        require(stake >= BUILDER_MIN_DEPOSIT,         "BuilderDeposit: deposit value too low");
        require(msg.value >= stake + _getFee(),       "BuilderDeposit: insufficient value for stake + fee");

        _recordRequest(abi.encodePacked(
            pubkey, withdrawal_credentials, _le64(amount_gwei), signature
        ));
    }
}

// ───────────────────────────────────────────────────────────────────────────────
// Builder exit predeploy — EIP-7685 request type 0x04, deployed at
// BUILDER_EXIT_CONTRACT_ADDRESS.
//
// `exit(pubkey)` appends source_address (20) ++ pubkey (48) = 68 bytes, where
// source_address is `msg.sender`. The builder's execution_address authorizes the
// exit simply by being the caller; the consensus layer honours the record only
// when `source_address` equals the target builder's `execution_address`. No
// signature, no staked value — only the request fee.
// ───────────────────────────────────────────────────────────────────────────────
contract BuilderExitContract is RequestQueue {
    uint constant PUBLIC_KEY_LENGTH = 48;

    /// @notice Builder full exit. On success, appends a record to the request
    /// queue (no log). The caller MUST send `msg.value >= fee` (read the fee by
    /// calling this contract with empty calldata); no stake is moved. The record
    /// is `msg.sender ++ pubkey`; the consensus layer initiates the builder's
    /// exit only when the recorded `source_address` equals its `execution_address`.
    function exit(bytes calldata pubkey) external payable {
        require(pubkey.length == PUBLIC_KEY_LENGTH, "BuilderExit: invalid pubkey length");
        require(msg.value >= _getFee(),             "BuilderExit: insufficient value for fee");

        _recordRequest(abi.encodePacked(msg.sender, pubkey));
    }
}
