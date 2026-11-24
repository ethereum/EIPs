/// Canonical paymaster for EIP-8141 frame transactions.
///
/// A `pay` frame that targets an instance carries exactly one byte of data: the index of a proof frame
/// whose verifier is `SECP256K1_VERIFIER`, whose key is the owner's address left-padded to 32 bytes, and
/// whose `msg` is zero, i.e. the owner's secp256k1 signature over the canonical signature hash. The
/// protocol verifies every claim before any other frame executes, so the paymaster only reads the claim
/// with `PROOFPARAM` and approves payment.
///
/// Ether leaves an instance only as payment for a transaction, or through a withdrawal that the owner
/// requests and, after `WITHDRAWAL_DELAY`, executes.
///
/// The owner is kept in storage so that every instance has the same runtime code and nodes recognize it
/// by code match. The `SECP256K1_VERIFIER` address, which EIP-8141 has yet to assign, is an immutable:
/// canonical instances are deployed with that address, so they too share their runtime code.
///
/// Written in Yul because `PROOFPARAM` and `APPROVE` are emitted with `verbatim`, which inline assembly
/// does not offer. The constructor takes `(address owner, address secp256k1Verifier)`, ABI-encoded after
/// the initcode. The external interface is:
///
///   requestWithdrawal(address to, uint256 amount)
///   executeWithdrawal()
///   owner(), secp256k1Verifier(), pendingWithdrawalTo(), pendingWithdrawalAmount(),
///   pendingWithdrawalReadyAt(), WITHDRAWAL_DELAY()
///
/// Errors: NotOwner(), ZeroAddress(), InvalidProof(), NoPendingWithdrawal(), WithdrawalNotReady(),
/// TransferFailed(). Events: WithdrawalRequested(address indexed to, uint256 amount, uint256 readyAt),
/// WithdrawalExecuted(address indexed to, uint256 amount).
///
/// Storage: slot 0 owner, slot 1 pending withdrawal recipient, slot 2 its amount, slot 3 the time it is
/// ready.
object "CanonicalPaymaster" {
    code {
        // The constructor arguments are the last 64 bytes of the initcode.
        codecopy(0, sub(codesize(), 64), 64)
        let owner := mload(0)
        let verifier := mload(32)
        if or(shr(160, owner), shr(160, verifier)) { revert(0, 0) }
        if or(iszero(owner), iszero(verifier)) {
            mstore(0, shl(224, 0xd92e233d)) // ZeroAddress()
            revert(0, 4)
        }
        sstore(0, owner)

        let size := datasize("runtime")
        datacopy(0, dataoffset("runtime"), size)
        setimmutable(0, "secp256k1Verifier", verifier)
        return(0, size)
    }

    object "runtime" {
        code {
            switch calldatasize()
            case 0 {
                // Receive ether.
                stop()
            }
            case 1 {
                // The pay frame. PROOFPARAM halts unless the byte names a proof frame.
                let proofIndex := shr(248, calldataload(0))
                if iszero(eq(proofParam(0x01, proofIndex), loadimmutable("secp256k1Verifier"))) {
                    fail(0x09bde339) // InvalidProof()
                }
                if iszero(eq(proofParam(0x00, proofIndex), sload(0))) {
                    fail(0x09bde339) // InvalidProof()
                }
                if proofParam(0x02, proofIndex) {
                    fail(0x09bde339) // InvalidProof()
                }
                // APPROVE(scope = APPROVE_PAYMENT, length = 0, offset = 0) approves payment and exits.
                verbatim_0i_0o(hex"600160006000aa")
            }
            default {
                if callvalue() { revert(0, 0) }
                switch shr(224, calldataload(0))
                case 0xda95ebf7 { requestWithdrawal() }
                case 0xfa45aa00 { executeWithdrawal() }
                case 0x8da5cb5b { returnWord(sload(0)) } // owner()
                case 0x4e969475 { returnWord(loadimmutable("secp256k1Verifier")) }
                case 0xb21ab01f { returnWord(sload(1)) } // pendingWithdrawalTo()
                case 0x2c5b1066 { returnWord(sload(2)) } // pendingWithdrawalAmount()
                case 0x9d060f01 { returnWord(sload(3)) } // pendingWithdrawalReadyAt()
                case 0x0ebb172a { returnWord(43200) } // WITHDRAWAL_DELAY(), 12 hours
                default { revert(0, 0) }
            }

            // requestWithdrawal(address to, uint256 amount)
            function requestWithdrawal() {
                onlyOwner()
                if lt(calldatasize(), 68) { revert(0, 0) }
                let to := calldataload(4)
                if shr(160, to) { revert(0, 0) }
                if iszero(to) { fail(0xd92e233d) } // ZeroAddress()
                let amount := calldataload(36)
                let readyAt := add(timestamp(), 43200)
                sstore(1, to)
                sstore(2, amount)
                sstore(3, readyAt)
                mstore(0, amount)
                mstore(32, readyAt)
                // WithdrawalRequested(address indexed to, uint256 amount, uint256 readyAt)
                log2(0, 64, 0x24b91f4f47caf44230a57777a9be744924e82bf666f2d5702faf97df35e60f9f, to)
                stop()
            }

            // executeWithdrawal()
            function executeWithdrawal() {
                onlyOwner()
                let to := sload(1)
                let amount := sload(2)
                let readyAt := sload(3)
                if iszero(readyAt) { fail(0x9121b84f) } // NoPendingWithdrawal()
                if lt(timestamp(), readyAt) { fail(0x0f2ca6e7) } // WithdrawalNotReady()
                sstore(1, 0)
                sstore(2, 0)
                sstore(3, 0)
                if iszero(call(gas(), to, amount, 0, 0, 0, 0)) { fail(0x90b8ec18) } // TransferFailed()
                mstore(0, amount)
                // WithdrawalExecuted(address indexed to, uint256 amount)
                log2(0, 32, 0x1131c2afe9ce72c59360d085f89bfdd088fcf4a3c93eec6cc5ff42f5d6b0801f, to)
                stop()
            }

            function onlyOwner() {
                if iszero(eq(caller(), sload(0))) { fail(0x30cd7471) } // NotOwner()
            }

            // PROOFPARAM takes frameIndex on top of the stack and param below it.
            function proofParam(param, frameIndex) -> value {
                value := verbatim_2i_1o(hex"b4", frameIndex, param)
            }

            function returnWord(value) {
                mstore(0, value)
                return(0, 32)
            }

            function fail(selector) {
                mstore(0, shl(224, selector))
                revert(0, 4)
            }
        }
    }
}
