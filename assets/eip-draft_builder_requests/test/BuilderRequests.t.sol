// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../builder_requests.sol";
import "./TestHarness.sol";
import "./Vectors.sol";

/// @dev Minimal subset of the Foundry cheatcode interface (avoids a forge-std
/// dependency on this 0.6.11 project).
interface Vm {
    function prank(address) external;
    function deal(address, uint256) external;
}

/// @notice Tests for the EIP-7685 request-bus builder predeploys, including the
/// EIP-1559-style request fee.
///
/// Expected BLS values come from py_ecc (see ../gen_vectors.py) baked into
/// ./Vectors.sol. The deposit-verification tests require the EIP-2537 BLS
/// precompiles (foundry's default Prague EVM); the queue / fee / system-read /
/// input tests do not.
contract BuilderRequestsTest {

    Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    address constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    uint constant DEPOSIT_RECORD_LEN    = 88; // pubkey 48 + wc 32 + amount 8
    uint constant TOPUP_RECORD_LEN      = 56; // pubkey 48 + amount 8
    uint constant WITHDRAWAL_RECORD_LEN = 76; // source 20 + pubkey 48 + amount 8

    BuilderDepositHarness    internal dep;
    BuilderTopUpHarness      internal top;
    BuilderWithdrawalHarness internal wd;

    function setUp() public {
        dep = new BuilderDepositHarness();
        top = new BuilderTopUpHarness();
        wd  = new BuilderWithdrawalHarness();
        // Each predeploy starts with excess == EXCESS_INHIBITOR (set in the
        // constructor, as EIP-7002/7251 do at deployment). The activation-block
        // system call clears the inhibitor; run it here so the fee/queue tests
        // below operate on an active contract.
        _systemRead(address(dep));
        _systemRead(address(top));
        _systemRead(address(wd));
    }

    function _systemRead(address target) internal returns (bytes memory) {
        vm.prank(SYSTEM_ADDRESS);
        (bool ok, bytes memory ret) = target.call("");
        require(ok, "system read reverted");
        return ret;
    }

    function _le64(uint64 v) internal pure returns (bytes memory r) {
        r = new bytes(8);
        for (uint i = 0; i < 8; i++) r[i] = bytes1(uint8(v >> (8 * i)));
    }

    function _copy(bytes memory src) internal pure returns (bytes memory dst) {
        dst = new bytes(src.length);
        for (uint i = 0; i < src.length; i++) dst[i] = src[i];
    }

    // ── Cross-check: SSZ signing root ──────────────────────────────────────

    function testComputeSigningRoot() public {
        (bytes memory pubkey, bytes32 wc, , , , , ) = Vectors.depositCase();
        bytes32 got = dep.computeDepositSigningRoot(pubkey, wc);
        require(got == Vectors.depositSigningRoot(), "signing root mismatch vs py_ecc");
    }

    // ── Happy path: deposit / top-up enqueue, system read emits the record ──

    function testDepositEnqueuesAndReads() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();

        uint value = uint(amount_gwei) * 1 gwei + dep.feeWei();
        dep.deposit{value: value}(pubkey, wc, amount_gwei, signature, pubkey_y, signature_y);
        require(dep.pendingCount() == 1, "one record queued");

        bytes memory data = _systemRead(address(dep));
        bytes memory expected = abi.encodePacked(pubkey, wc, _le64(amount_gwei));
        require(data.length == DEPOSIT_RECORD_LEN, "deposit record length");
        require(keccak256(data) == keccak256(expected), "deposit record bytes mismatch");
        require(dep.pendingCount() == 0, "queue drained");
    }

    function testTopUpEnqueuesAndReads() public {
        bytes memory pubkey = new bytes(48);
        for (uint i = 0; i < 48; i++) pubkey[i] = bytes1(uint8(i + 1));

        uint64 amount_gwei = 3_000_000_000; // 3 ETH
        top.top_up{value: uint(amount_gwei) * 1 gwei + top.feeWei()}(pubkey, amount_gwei);
        require(top.pendingCount() == 1, "one top-up queued");

        bytes memory data = _systemRead(address(top));
        bytes memory expected = abi.encodePacked(pubkey, _le64(amount_gwei));
        require(data.length == TOPUP_RECORD_LEN, "top-up record length");
        require(keccak256(data) == keccak256(expected), "top-up record bytes mismatch");
        require(top.pendingCount() == 0, "queue drained");
    }

    // ── EIP-1559-style request fee ─────────────────────────────────────────

    function testFeeStartsAtMinimum() public {
        require(dep.feeWei() == 1, "min fee is 1 wei at excess 0");
        require(top.feeWei() == 1, "min fee is 1 wei at excess 0");
    }

    function testFeeRisesWithExcess() public {
        // 18 top-ups in one block → count 18. The next system call sets
        // excess = 18 - TARGET(2) = 16, and fake_exponential(1, 16, 17) == 2.
        bytes memory pubkey = new bytes(48);
        uint64 amount_gwei = 1_000_000_000; // 1 ETH
        for (uint i = 0; i < 18; i++) {
            top.top_up{value: uint(amount_gwei) * 1 gwei + top.feeWei()}(pubkey, amount_gwei);
        }
        require(top.feeWei() == 1, "fee unchanged until the system call updates excess");
        _systemRead(address(top));
        require(top.feeWei() == 2, "fee rises after a block above target");
    }

    function testFeeGetterFallbackMatches() public {
        // A non-system empty-calldata call returns the current fee.
        (bool ok, bytes memory ret) = address(top).call("");
        require(ok, "fee getter call failed");
        require(ret.length == 32, "fee getter returns a word");
        require(abi.decode(ret, (uint)) == top.feeWei(), "fee getter mismatch");
    }

    function testDepositRejectsInsufficientValue() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();
        // Exactly the stake, with nothing left for the fee: must revert.
        try dep.deposit{value: uint(amount_gwei) * 1 gwei}(
            pubkey, wc, amount_gwei, signature, pubkey_y, signature_y
        ) {
            require(false, "stake without fee should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    // ── System read access control + FIFO / per-block cap ──────────────────

    function testSystemReadRequiresSystemAddress() public {
        // A non-system empty-calldata call is the fee getter, not a drain: it
        // returns the fee and must NOT advance the queue.
        bytes memory pubkey = new bytes(48);
        uint64 amount_gwei = 1_000_000_000;
        top.top_up{value: uint(amount_gwei) * 1 gwei + top.feeWei()}(pubkey, amount_gwei);
        (bool ok, ) = address(top).call("");
        require(ok, "fee getter should succeed");
        require(top.pendingCount() == 1, "non-system call must not drain the queue");
    }

    function testPerBlockCapAndFifo() public {
        bytes memory pubkey = new bytes(48);
        uint64 amount_gwei = 1_000_000_000;
        for (uint i = 0; i < 17; i++) {
            top.top_up{value: uint(amount_gwei) * 1 gwei + top.feeWei()}(pubkey, amount_gwei);
        }
        require(top.pendingCount() == 17, "17 queued");

        bytes memory first = _systemRead(address(top));
        require(first.length == 16 * TOPUP_RECORD_LEN, "first read drains the 16-record cap");
        require(top.pendingCount() == 1, "one remains after cap");

        bytes memory second = _systemRead(address(top));
        require(second.length == 1 * TOPUP_RECORD_LEN, "second read drains the remainder");
        require(top.pendingCount() == 0, "queue empty");
    }

    // Audit Finding 1 regression: when the queue fully drains, both head and
    // tail reset to 0 (EIP-7002 behavior), so storage is bounded by peak depth
    // and the next request reuses index 0.
    function testQueueResetsWhenDrained() public {
        bytes memory pubkey = new bytes(48);
        uint64 amount_gwei = 1_000_000_000;
        for (uint i = 0; i < 3; i++) {
            top.top_up{value: uint(amount_gwei) * 1 gwei + top.feeWei()}(pubkey, amount_gwei);
        }
        require(top.headIdx() == 0 && top.tailIdx() == 3, "3 queued at indices [0,3)");

        _systemRead(address(top)); // drains all 3 (<= cap)
        require(top.headIdx() == 0 && top.tailIdx() == 0, "head and tail reset to 0 on empty");
        require(top.pendingCount() == 0, "queue empty");

        // Next request reuses index 0 rather than advancing forever.
        top.top_up{value: uint(amount_gwei) * 1 gwei + top.feeWei()}(pubkey, amount_gwei);
        require(top.tailIdx() == 1, "tail restarts at 1 (slot reused)");
    }

    // Audit Finding 3 regression: the fallback only accepts empty calldata.
    function testFallbackRejectsNonEmptyCalldata() public {
        (bool ok, ) = address(top).call(hex"deadbeefdeadbeef");
        require(!ok, "non-empty junk calldata must revert");
        // Empty calldata still works (fee getter), confirming the guard is scoped.
        (bool ok2, ) = address(top).call("");
        require(ok2, "empty-calldata fee getter still works");
    }

    // ── Negative paths: BLS check (nothing should enqueue) ─────────────────

    // The amount is NOT part of the signed message, so the same signature is
    // valid for any amount. Depositing with an amount different from the
    // vector's must SUCCEED, and the queued record must reflect the amount that
    // was actually passed.
    function testDepositAmountNotBoundToSignature() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();
        uint64 differentAmount = amount_gwei + 5_000_000_000; // +5 ETH, unsigned
        uint value = uint(differentAmount) * 1 gwei + dep.feeWei();
        dep.deposit{value: value}(pubkey, wc, differentAmount, signature, pubkey_y, signature_y);
        require(dep.pendingCount() == 1, "deposit with a different amount is accepted");

        bytes memory data = _systemRead(address(dep));
        bytes memory expected = abi.encodePacked(pubkey, wc, _le64(differentAmount));
        require(keccak256(data) == keccak256(expected), "record reflects the passed amount");
    }

    function testDepositRejectsTamperedSignature() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();
        bytes memory tampered = _copy(signature);
        tampered[10] = tampered[10] ^ bytes1(uint8(1));
        uint value = uint(amount_gwei) * 1 gwei + dep.feeWei();
        try dep.deposit{value: value}(pubkey, wc, amount_gwei, tampered, pubkey_y, signature_y) {
            require(false, "tampered signature should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    // Regression for audit Finding 2: flip only the pubkey sign flag (keep Y).
    function testDepositRejectsPubkeySignBitFlip() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();
        bytes memory flipped = _copy(pubkey);
        flipped[0] = flipped[0] ^ bytes1(uint8(0x20));
        uint value = uint(amount_gwei) * 1 gwei + dep.feeWei();
        try dep.deposit{value: value}(flipped, wc, amount_gwei, signature, pubkey_y, signature_y) {
            require(false, "pubkey sign-bit flip should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testDepositRejectsSignatureSignBitFlip() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();
        bytes memory flipped = _copy(signature);
        flipped[0] = flipped[0] ^ bytes1(uint8(0x20));
        uint value = uint(amount_gwei) * 1 gwei + dep.feeWei();
        try dep.deposit{value: value}(pubkey, wc, amount_gwei, flipped, pubkey_y, signature_y) {
            require(false, "signature sign-bit flip should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testDepositRejectsInfinityPubkey() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();
        bytes memory inf = _copy(pubkey);
        inf[0] = inf[0] | bytes1(uint8(0x40));
        uint value = uint(amount_gwei) * 1 gwei + dep.feeWei();
        try dep.deposit{value: value}(inf, wc, amount_gwei, signature, pubkey_y, signature_y) {
            require(false, "infinity pubkey should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    // ── Negative paths: input-shape validation ─────────────────────────────

    function testDepositRejectsTooSmallStake() public {
        bytes memory pubkey = new bytes(48);
        bytes memory signature = new bytes(96);
        BuilderDepositContract.Fp memory z = BuilderDepositContract.Fp(0, 0);
        BuilderDepositContract.Fp2 memory z2 = BuilderDepositContract.Fp2(z, z);
        // 0.5 ETH stake (< 1 ETH minimum).
        try dep.deposit{value: 1 ether}(pubkey, bytes32(0), 500_000_000, signature, z, z2) {
            require(false, "stake < 1 ether should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testDepositRejectsWrongPubkeyLength() public {
        bytes memory pubkey = new bytes(47);
        bytes memory signature = new bytes(96);
        BuilderDepositContract.Fp memory z = BuilderDepositContract.Fp(0, 0);
        BuilderDepositContract.Fp2 memory z2 = BuilderDepositContract.Fp2(z, z);
        try dep.deposit{value: 2 ether}(pubkey, bytes32(0), 1_000_000_000, signature, z, z2) {
            require(false, "47-byte pubkey should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testTopUpRejectsTooSmallStake() public {
        bytes memory pubkey = new bytes(48);
        try top.top_up{value: 1 ether}(pubkey, 500_000_000) {
            require(false, "top_up stake < 1 ether should revert");
        } catch {}
        require(top.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testTopUpRejectsWrongPubkeyLength() public {
        bytes memory pubkey = new bytes(47);
        try top.top_up{value: 2 ether}(pubkey, 1_000_000_000) {
            require(false, "47-byte pubkey should revert");
        } catch {}
        require(top.pendingCount() == 0, "nothing enqueued on reject");
    }

    // ── Withdrawal / exit predeploy (EIP-7002-shaped, request type 0x05) ────

    // A partial withdrawal (amount > 0) records source_address(msg.sender) ++
    // pubkey ++ amount; the system read returns the exact 76-byte record.
    function testWithdrawalEnqueuesAndReads() public {
        bytes memory pubkey = new bytes(48);
        for (uint i = 0; i < 48; i++) pubkey[i] = bytes1(uint8(i + 1));

        uint64 amount_gwei = 4_000_000_000; // 4 ETH partial withdrawal
        wd.withdraw{value: wd.feeWei()}(pubkey, amount_gwei);
        require(wd.pendingCount() == 1, "one withdrawal queued");

        bytes memory data = _systemRead(address(wd));
        bytes memory expected = abi.encodePacked(address(this), pubkey, _le64(amount_gwei));
        require(data.length == WITHDRAWAL_RECORD_LEN, "withdrawal record length");
        require(keccak256(data) == keccak256(expected), "withdrawal record bytes mismatch");
        require(wd.pendingCount() == 0, "queue drained");
    }

    // amount_gwei == 0 is the full-exit sentinel: it MUST be accepted (there is
    // no minimum-amount check) and recorded with a zero amount, like EIP-7002.
    function testExitEnqueuesWithZeroAmount() public {
        bytes memory pubkey = new bytes(48);
        for (uint i = 0; i < 48; i++) pubkey[i] = bytes1(uint8(0xa0 + i));

        wd.withdraw{value: wd.feeWei()}(pubkey, 0);
        require(wd.pendingCount() == 1, "exit (amount 0) is accepted and queued");

        bytes memory data = _systemRead(address(wd));
        bytes memory expected = abi.encodePacked(address(this), pubkey, _le64(0));
        require(data.length == WITHDRAWAL_RECORD_LEN, "exit record length");
        require(keccak256(data) == keccak256(expected), "exit record bytes mismatch");
    }

    // The recorded source_address is the caller, not a parameter: a withdrawal
    // from a different address records that address (the builder's
    // execution_address), which is what the CL checks for authorization. The
    // fee is read before `vm.prank` so the prank applies to `withdraw`, not to
    // the `feeWei()` argument call.
    function testWithdrawalRecordsCaller() public {
        address builderExecAddr = 0xb0b1DE7c0fFeE0000000000000000000000B5511;
        bytes memory pubkey = new bytes(48);
        for (uint i = 0; i < 48; i++) pubkey[i] = bytes1(uint8(i + 7));

        uint64 amount_gwei = 1_500_000_000;
        uint fee = wd.feeWei();
        vm.deal(builderExecAddr, 1 ether); // fund the caller so it can pay the fee
        vm.prank(builderExecAddr);
        wd.withdraw{value: fee}(pubkey, amount_gwei);

        bytes memory data = _systemRead(address(wd));
        bytes memory expected = abi.encodePacked(builderExecAddr, pubkey, _le64(amount_gwei));
        require(keccak256(data) == keccak256(expected), "source_address must be the caller");
    }

    // Unlike deposit/top-up, a withdrawal sends no stake — only the fee. A large
    // amount_gwei with msg.value equal to just the (1 wei) fee must succeed.
    function testWithdrawalRequiresNoStake() public {
        bytes memory pubkey = new bytes(48);
        uint64 amount_gwei = 1_000_000_000_000; // 1000 ETH, but no value is sent for it
        wd.withdraw{value: wd.feeWei()}(pubkey, amount_gwei);
        require(wd.pendingCount() == 1, "withdrawal needs only the fee, no staked value");
    }

    function testWithdrawalRejectsInsufficientFee() public {
        bytes memory pubkey = new bytes(48);
        // excess == 0 → fee is 1 wei; sending 0 cannot cover it.
        try wd.withdraw{value: 0}(pubkey, 1_000_000_000) {
            require(false, "withdrawal below the fee should revert");
        } catch {}
        require(wd.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testWithdrawalRejectsWrongPubkeyLength() public {
        bytes memory pubkey = new bytes(47);
        try wd.withdraw{value: wd.feeWei()}(pubkey, 1_000_000_000) {
            require(false, "47-byte pubkey should revert");
        } catch {}
        require(wd.pendingCount() == 0, "nothing enqueued on reject");
    }

    // ── EXCESS_INHIBITOR (pre-activation), as in EIP-7002/7251 ─────────────

    // A freshly deployed contract starts inhibited (excess == EXCESS_INHIBITOR),
    // so the fee getter reverts until the first system call. setUp() already
    // activated dep/top/wd, so these tests use a fresh instance.
    function testFeeGetterRevertsWhileInhibited() public {
        BuilderTopUpHarness fresh = new BuilderTopUpHarness();
        try fresh.feeWei() {
            require(false, "fee getter must revert while inhibited");
        } catch {}
    }

    // No request can be enqueued before activation: the entrypoint reverts when
    // it reads the inhibited fee, even with ample value; nothing is queued.
    function testRequestRevertsWhileInhibited() public {
        BuilderTopUpHarness fresh = new BuilderTopUpHarness();
        bytes memory pubkey = new bytes(48);
        try fresh.top_up{value: 2 ether}(pubkey, 1_000_000_000) {
            require(false, "request must revert while inhibited");
        } catch {}
        require(fresh.pendingCount() == 0, "nothing enqueued while inhibited");
    }

    // The first SYSTEM_ADDRESS call clears the inhibitor; the fee is then
    // MIN_REQUEST_FEE (excess == 0).
    function testFirstSystemCallClearsInhibitor() public {
        BuilderTopUpHarness fresh = new BuilderTopUpHarness();
        _systemRead(address(fresh));
        require(fresh.feeWei() == 1, "fee is MIN_REQUEST_FEE once the inhibitor clears");
    }
}
