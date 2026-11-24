/// Pay path of the EIP-8141 canonical paymaster. `CanonicalPaymaster.sol` calls it through `DELEGATECALL`,
/// because Solidity cannot emit `PROOFPARAM` or `APPROVE`.
///
/// Calldata is three words: `proofIndex || owner || verifier`. The frame at `proofIndex` must be a proof frame
/// whose verifier is `verifier`, whose key is `owner` left-padded to 32 bytes, and whose `msg` is zero, i.e.
/// `owner`'s signature over the canonical signature hash. If it is, the helper calls `APPROVE(APPROVE_PAYMENT)`,
/// which under `DELEGATECALL` approves the calling paymaster as payer. Otherwise it reverts with `InvalidProof()`,
/// or halts if `proofIndex` is not a proof frame.
///
/// The helper refuses direct calls, so a balance it holds can never pay for a transaction.
object "CanonicalPaymasterPay" {
    code {
        let size := datasize("runtime")
        datacopy(0, dataoffset("runtime"), size)
        setimmutable(0, "self", address())
        return(0, size)
    }

    object "runtime" {
        code {
            if eq(address(), loadimmutable("self")) { revert(0, 0) }
            if iszero(eq(calldatasize(), 96)) { revert(0, 0) }

            let proofIndex := calldataload(0)
            if iszero(eq(proofParam(0x01, proofIndex), calldataload(64))) { invalidProof() }
            if iszero(eq(proofParam(0x00, proofIndex), calldataload(32))) { invalidProof() }
            if proofParam(0x02, proofIndex) { invalidProof() }

            // APPROVE(scope = APPROVE_PAYMENT, length = 0, offset = 0) approves payment and exits.
            verbatim_0i_0o(hex"600160006000aa")

            // PROOFPARAM takes frameIndex on top of the stack and param below it.
            function proofParam(param, frameIndex) -> value {
                value := verbatim_2i_1o(hex"b4", frameIndex, param)
            }

            function invalidProof() {
                mstore(0, shl(224, 0x09bde339)) // InvalidProof()
                revert(0, 4)
            }
        }
    }
}
