// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {LeanXmss} from "./LeanXmss.sol";

/// @notice EIP-8483's PQ registration request contract, which also checks a leanXMSS proof of
///         possession when a request is added.
/// @dev The contract behaves like the EIP's bytecode except for one thing: a request carries a
///      2404-byte leanXMSS signature after the EIP's input, and the contract rejects the request
///      unless that signature is a proof of possession. That is, a signature at leaf 0 by the
///      XMSS key in the first 32 bytes of `pq_data`, over
///        M = keccak256(POP_DOMAIN ‖ chain_id (32) ‖ bls_pubkey (48) ‖ xmss_public_key (32)).
///      The signature isn't stored or logged, so the queue, the log and the system call's output
///      are the same as the EIP's.
///
///      There is no Solidity ABI. As in the EIP, calls are dispatched on the caller and the
///      calldata size, and reverts carry no data:
///      - A call from `SYSTEM_ADDRESS` dequeues up to the per-block maximum and returns the
///        records. If it has calldata, it also disables the queue by setting the excess to
///        `EXCESS_INHIBITOR`. If it doesn't, it re-enables a disabled queue with a fresh fee
///        state.
///      - A call with empty calldata and no value returns the fee as a 32-byte word.
///      - A request (input ‖ signature) is added to the queue if it pays at least the fee. The
///        contract keeps the whole payment.
///
///      The storage layout is the EIP's. Slots 0 to 4 hold the excess, the number of requests
///      added in the last block that had any, the queue head and tail, and that block's number.
///      Request `i` takes `_slotsPerRequest()` slots starting at `5 + i * _slotsPerRequest()`:
///      the source address, then the input in 32-byte slots, with the last one zero-padded.
///      The arithmetic is unchecked and follows the EIP's order of operations, so the contract
///      matches the EIP's bytecode from any storage state.
abstract contract RegistrationQueue {
    address internal constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
    uint256 internal constant EXCESS_INHIBITOR = type(uint256).max;
    uint256 internal constant MIN_REQUEST_FEE = 1;
    uint256 internal constant REQUEST_FEE_UPDATE_FRACTION = 17;
    uint256 internal constant QUEUE_OFFSET = 5;

    uint256 internal constant BLS_PUBKEY_LENGTH = 48;
    uint256 internal constant XMSS_PUBKEY_LENGTH = 32;
    uint32 internal constant POP_LEAF_INDEX = 0;
    bytes32 internal constant POP_DOMAIN =
        keccak256("leanXMSS registration proof of possession v1");

    uint256 internal excess; // slot 0
    uint256 internal count; // slot 1
    uint256 internal queueHead; // slot 2
    uint256 internal queueTail; // slot 3
    uint256 internal lastBlock; // slot 4

    fallback(bytes calldata input) external payable returns (bytes memory) {
        if (msg.sender == SYSTEM_ADDRESS) _processSystemCall();

        (uint256 currentExcess, uint256 currentCount) = _feeState();
        uint256 fee = _fee(currentExcess, currentCount);
        if (input.length == 0) {
            if (msg.value != 0) revert();
            return abi.encode(fee);
        }

        if (input.length != _inputLength() + LeanXmss.SIGNATURE_LENGTH) revert();
        if (msg.value < fee) revert();
        if (currentCount >= _maxRequestsAddedPerBlock()) revert();
        _checkProofOfPossession(input);

        excess = currentExcess;
        count = currentCount + 1;
        lastBlock = block.number;
        _enqueue();
        return "";
    }

    /// @notice The message `M` that a proof of possession signs for the request `input`. It hashes
    ///         the domain, the chain ID as a 32-byte word, and the first 80 bytes of the input,
    ///         which are the BLS public key and the XMSS public key.
    function _popMessage(bytes calldata input) internal view returns (bytes32 m) {
        bytes32 domain = POP_DOMAIN;
        // Writes the preimage at the free memory pointer without allocating it, since nothing
        // reads it after the hash.
        assembly ("memory-safe") {
            let p := mload(0x40)
            mstore(p, domain)
            mstore(add(p, 0x20), chainid())
            calldatacopy(add(p, 0x40), input.offset, add(BLS_PUBKEY_LENGTH, XMSS_PUBKEY_LENGTH))
            m := keccak256(p, add(0x40, add(BLS_PUBKEY_LENGTH, XMSS_PUBKEY_LENGTH)))
        }
    }

    /// @dev Reverts unless the signature after the EIP's input is a proof of possession. It's
    ///      virtual only so the gas measurement can skip the check in a test contract
    ///      (`test/helpers/Unchecked.sol`). The bytecode is the same as with a private function.
    function _checkProofOfPossession(bytes calldata input) internal view virtual {
        bytes calldata signature = input[_inputLength():];
        bytes32 xmssPubkey =
            bytes32(input[BLS_PUBKEY_LENGTH:BLS_PUBKEY_LENGTH + XMSS_PUBKEY_LENGTH]);
        if (LeanXmss.signatureIndex(signature) != POP_LEAF_INDEX) revert();
        if (!LeanXmss.verify(xmssPubkey, _popMessage(input), signature)) revert();
    }

    /// @dev Returns the excess and the number of requests added in this block. If none was added
    ///      yet, it rolls the state forward first: the last block's count is added to the excess,
    ///      which then decays by the target for every block since.
    function _feeState() private view returns (uint256 currentExcess, uint256 currentCount) {
        currentExcess = excess;
        if (currentExcess == EXCESS_INHIBITOR) revert();
        currentCount = count;
        uint256 last = lastBlock;
        if (block.number != last) {
            unchecked {
                uint256 decay = _targetRequestsPerBlock() * (block.number - last);
                uint256 total = currentExcess + currentCount;
                currentExcess = total > decay ? total - decay : 0;
            }
            currentCount = 0;
        }
    }

    /// @dev The fee for the next request. Requests added in this block above the target count
    ///      toward the excess.
    function _fee(uint256 currentExcess, uint256 currentCount) private pure returns (uint256) {
        uint256 target = _targetRequestsPerBlock();
        unchecked {
            uint256 exponent =
                currentCount > target ? currentExcess + (currentCount - target) : currentExcess;
            return _fakeExponential(MIN_REQUEST_FEE, exponent, REQUEST_FEE_UPDATE_FRACTION);
        }
    }

    /// @dev Approximates `factor * e ** (numerator / denominator)`, as in EIP-7002.
    function _fakeExponential(uint256 factor, uint256 numerator, uint256 denominator)
        private
        pure
        returns (uint256 output)
    {
        unchecked {
            uint256 accum = factor * denominator;
            for (uint256 i = 1; accum > 0; i++) {
                output += accum;
                accum = (accum * numerator) / (denominator * i);
            }
            return output / denominator;
        }
    }

    /// @dev Stores the request at the queue's tail and logs its record: the caller followed by the
    ///      input.
    function _enqueue() private {
        uint256 inputLength = _inputLength();
        uint256 slots = _slotsPerRequest();
        assembly ("memory-safe") {
            let tail := sload(queueTail.slot)
            let slot := add(QUEUE_OFFSET, mul(tail, slots))
            sstore(slot, caller())
            // Stores the input in 32-byte slots. The signature follows the input in calldata,
            // so the last slot is masked to keep only the input's bytes.
            for { let k := 1 } lt(k, slots) { k := add(k, 1) } {
                let offset := shl(5, sub(k, 1))
                let word := calldataload(offset)
                let rest := sub(inputLength, offset)
                if lt(rest, 32) { word := and(word, not(shr(shl(3, rest), not(0)))) }
                sstore(add(slot, k), word)
            }

            let record := mload(0x40)
            mstore(record, shl(96, caller()))
            calldatacopy(add(record, 20), 0, inputLength)
            log0(record, add(20, inputLength))
            sstore(queueTail.slot, add(tail, 1))
        }
    }

    /// @dev Dequeues up to the per-block maximum, sets or clears the inhibitor, and returns the
    ///      dequeued records. It ends the call, so nothing after it runs.
    function _processSystemCall() private {
        uint256 slots = _slotsPerRequest();
        uint256 recordLength = 20 + _inputLength();
        uint256 max = _maxRequestsPerBlock();
        assembly ("memory-safe") {
            let tail := sload(queueTail.slot)
            let head := sload(queueHead.slot)
            let n := sub(tail, head)
            if iszero(gt(max, n)) { n := max }

            // Writes each record one word at a time. The last word's zero padding spills into
            // the next record, which then overwrites it, or past the end of the returned bytes.
            let records := mload(0x40)
            for { let i := 0 } iszero(eq(i, n)) { i := add(i, 1) } {
                let slot := add(QUEUE_OFFSET, mul(add(head, i), slots))
                let offset := add(records, mul(i, recordLength))
                mstore(offset, shl(96, sload(slot)))
                offset := add(offset, 20)
                for { let k := 1 } lt(k, slots) { k := add(k, 1) } {
                    mstore(offset, sload(add(slot, k)))
                    offset := add(offset, 32)
                }
            }

            let newHead := add(head, n)
            switch eq(newHead, tail)
            case 1 {
                sstore(queueHead.slot, 0)
                sstore(queueTail.slot, 0)
            }
            default { sstore(queueHead.slot, newHead) }

            switch calldatasize()
            case 0 {
                if eq(sload(excess.slot), not(0)) {
                    sstore(excess.slot, 0)
                    sstore(count.slot, 0)
                }
            }
            default { sstore(excess.slot, not(0)) }

            return(records, mul(n, recordLength))
        }
    }

    // --- Parameters ---------------------------------------------------------------------------

    /// @dev The length of the EIP's input: the BLS public key followed by `pq_data`.
    function _inputLength() internal pure virtual returns (uint256);

    function _slotsPerRequest() internal pure virtual returns (uint256);

    function _targetRequestsPerBlock() internal pure virtual returns (uint256);

    function _maxRequestsAddedPerBlock() internal pure virtual returns (uint256);

    function _maxRequestsPerBlock() internal pure virtual returns (uint256);
}
