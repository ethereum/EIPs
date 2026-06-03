// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.6.11;

import "../builder_requests.sol";
import "./TestHarness.sol";

/// @dev Minimal subset of the Foundry cheatcode interface (avoids a forge-std
/// dependency on this 0.6.11 project).
interface Vm {
    function prank(address) external;
    function deal(address, uint256) external;
}

/// @notice Tests for the EIP-7685 request-bus builder predeploys (deposit/top-up
/// and exit), the EIP-1559-style request fee, and the EXCESS_INHIBITOR. Neither
/// contract performs on-chain BLS verification, so no precompiles or fixtures are
/// needed — the deposit's signature is opaque calldata carried into the record
/// for the consensus layer to verify on dequeue.
contract BuilderRequestsTest {

    Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    address constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    uint constant DEPOSIT_RECORD_LEN = 184; // pubkey 48 + wc 32 + amount 8 + signature 96
    uint constant EXIT_RECORD_LEN    = 68;  // source 20 + pubkey 48

    BuilderDepositHarness internal dep;
    BuilderExitHarness    internal ex;

    function setUp() public {
        dep = new BuilderDepositHarness();
        ex  = new BuilderExitHarness();
        // Each predeploy starts with excess == EXCESS_INHIBITOR (set in the
        // constructor, as EIP-7002/7251 do at deployment). The activation-block
        // system call clears the inhibitor; run it here so the fee/queue tests
        // below operate on an active contract.
        _systemRead(address(dep));
        _systemRead(address(ex));
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

    function _filled(uint len, uint8 seed) internal pure returns (bytes memory b) {
        b = new bytes(len);
        for (uint i = 0; i < len; i++) b[i] = bytes1(uint8(uint(seed) + i));
    }

    // ── Deposit (request type 0x03): deposit + top-up, carries the signature ──

    function testDepositEnqueuesAndReads() public {
        bytes memory pubkey = _filled(48, 1);
        bytes32 wc = 0x0300000000000000000000000000000000000000000000000000000000abcdef;
        bytes memory signature = _filled(96, 100);
        uint64 amount_gwei = 2_000_000_000; // 2 ETH

        uint value = uint(amount_gwei) * 1 gwei + dep.feeWei();
        dep.deposit{value: value}(pubkey, wc, amount_gwei, signature);
        require(dep.pendingCount() == 1, "one record queued");

        bytes memory data = _systemRead(address(dep));
        bytes memory expected = abi.encodePacked(pubkey, wc, _le64(amount_gwei), signature);
        require(data.length == DEPOSIT_RECORD_LEN, "deposit record length");
        require(keccak256(data) == keccak256(expected), "deposit record bytes mismatch");
        require(dep.pendingCount() == 0, "queue drained");
    }

    function testDepositRejectsTooSmallStake() public {
        bytes memory pubkey = _filled(48, 1);
        bytes memory signature = _filled(96, 100);
        // 0.5 ETH stake (< 1 ETH minimum); ample value so the stake check, not
        // the value check, is what reverts.
        try dep.deposit{value: 1 ether}(pubkey, bytes32(0), 500_000_000, signature) {
            require(false, "stake < 1 ether should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testDepositRejectsInsufficientValue() public {
        bytes memory pubkey = _filled(48, 1);
        bytes memory signature = _filled(96, 100);
        uint64 amount_gwei = 2_000_000_000;
        // Exactly the stake, with nothing left for the fee: must revert.
        try dep.deposit{value: uint(amount_gwei) * 1 gwei}(pubkey, bytes32(0), amount_gwei, signature) {
            require(false, "stake without fee should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testDepositRejectsWrongPubkeyLength() public {
        bytes memory pubkey = _filled(47, 1);
        bytes memory signature = _filled(96, 100);
        try dep.deposit{value: 2 ether}(pubkey, bytes32(0), 1_000_000_000, signature) {
            require(false, "47-byte pubkey should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testDepositRejectsWrongSignatureLength() public {
        bytes memory pubkey = _filled(48, 1);
        bytes memory signature = _filled(95, 100);
        try dep.deposit{value: 2 ether}(pubkey, bytes32(0), 1_000_000_000, signature) {
            require(false, "95-byte signature should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    // ── Exit (request type 0x04) ───────────────────────────────────────────

    function testExitEnqueuesAndReads() public {
        bytes memory pubkey = _filled(48, 1);
        ex.exit{value: ex.feeWei()}(pubkey);
        require(ex.pendingCount() == 1, "one exit queued");

        bytes memory data = _systemRead(address(ex));
        bytes memory expected = abi.encodePacked(address(this), pubkey);
        require(data.length == EXIT_RECORD_LEN, "exit record length");
        require(keccak256(data) == keccak256(expected), "exit record bytes mismatch");
        require(ex.pendingCount() == 0, "queue drained");
    }

    // The recorded source_address is the caller (the builder's execution_address),
    // which is what the CL checks for authorization. Fee is read before
    // `vm.prank` so the prank applies to `exit`, not to the `feeWei()` call.
    function testExitRecordsCaller() public {
        address builderExecAddr = 0xb0b1DE7c0fFeE0000000000000000000000B5511;
        bytes memory pubkey = _filled(48, 7);
        uint fee = ex.feeWei();
        vm.deal(builderExecAddr, 1 ether);
        vm.prank(builderExecAddr);
        ex.exit{value: fee}(pubkey);

        bytes memory data = _systemRead(address(ex));
        bytes memory expected = abi.encodePacked(builderExecAddr, pubkey);
        require(keccak256(data) == keccak256(expected), "source_address must be the caller");
    }

    function testExitRejectsInsufficientFee() public {
        bytes memory pubkey = _filled(48, 1);
        // excess == 0 → fee is 1 wei; sending 0 cannot cover it.
        try ex.exit{value: 0}(pubkey) {
            require(false, "exit below the fee should revert");
        } catch {}
        require(ex.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testExitRejectsWrongPubkeyLength() public {
        bytes memory pubkey = _filled(47, 1);
        try ex.exit{value: ex.feeWei()}(pubkey) {
            require(false, "47-byte pubkey should revert");
        } catch {}
        require(ex.pendingCount() == 0, "nothing enqueued on reject");
    }

    // ── EIP-1559-style request fee ─────────────────────────────────────────

    function testFeeStartsAtMinimum() public {
        require(dep.feeWei() == 1, "min fee is 1 wei at excess 0");
        require(ex.feeWei() == 1, "min fee is 1 wei at excess 0");
    }

    function testFeeRisesWithExcess() public {
        // 18 exits in one block → count 18. The next system call sets
        // excess = 18 - TARGET(2) = 16, and fake_exponential(1, 16, 17) == 2.
        bytes memory pubkey = _filled(48, 1);
        for (uint i = 0; i < 18; i++) {
            ex.exit{value: ex.feeWei()}(pubkey);
        }
        require(ex.feeWei() == 1, "fee unchanged until the system call updates excess");
        _systemRead(address(ex));
        require(ex.feeWei() == 2, "fee rises after a block above target");
    }

    function testFeeGetterFallbackMatches() public {
        (bool ok, bytes memory ret) = address(ex).call("");
        require(ok, "fee getter call failed");
        require(ret.length == 32, "fee getter returns a word");
        require(abi.decode(ret, (uint)) == ex.feeWei(), "fee getter mismatch");
    }

    // ── System read access control + FIFO / per-block cap ──────────────────

    function testSystemReadRequiresSystemAddress() public {
        bytes memory pubkey = _filled(48, 1);
        ex.exit{value: ex.feeWei()}(pubkey);
        (bool ok, ) = address(ex).call("");
        require(ok, "fee getter should succeed");
        require(ex.pendingCount() == 1, "non-system call must not drain the queue");
    }

    function testPerBlockCapAndFifo() public {
        bytes memory pubkey = _filled(48, 1);
        for (uint i = 0; i < 17; i++) {
            ex.exit{value: ex.feeWei()}(pubkey);
        }
        require(ex.pendingCount() == 17, "17 queued");

        bytes memory first = _systemRead(address(ex));
        require(first.length == 16 * EXIT_RECORD_LEN, "first read drains the 16-record cap");
        require(ex.pendingCount() == 1, "one remains after cap");

        bytes memory second = _systemRead(address(ex));
        require(second.length == 1 * EXIT_RECORD_LEN, "second read drains the remainder");
        require(ex.pendingCount() == 0, "queue empty");
    }

    // When the queue fully drains, both head and tail reset to 0 (EIP-7002
    // behavior), so storage is bounded by peak depth and the next request reuses
    // index 0.
    function testQueueResetsWhenDrained() public {
        bytes memory pubkey = _filled(48, 1);
        for (uint i = 0; i < 3; i++) {
            ex.exit{value: ex.feeWei()}(pubkey);
        }
        require(ex.headIdx() == 0 && ex.tailIdx() == 3, "3 queued at indices [0,3)");

        _systemRead(address(ex)); // drains all 3 (<= cap)
        require(ex.headIdx() == 0 && ex.tailIdx() == 0, "head and tail reset to 0 on empty");
        require(ex.pendingCount() == 0, "queue empty");

        ex.exit{value: ex.feeWei()}(pubkey);
        require(ex.tailIdx() == 1, "tail restarts at 1 (slot reused)");
    }

    // The fallback only accepts empty calldata.
    function testFallbackRejectsNonEmptyCalldata() public {
        (bool ok, ) = address(ex).call(hex"deadbeefdeadbeef");
        require(!ok, "non-empty junk calldata must revert");
        (bool ok2, ) = address(ex).call("");
        require(ok2, "empty-calldata fee getter still works");
    }

    // ── EXCESS_INHIBITOR (pre-activation), as in EIP-7002/7251 ─────────────

    // A freshly deployed contract starts inhibited (excess == EXCESS_INHIBITOR),
    // so the fee getter reverts until the first system call. setUp() already
    // activated dep/ex, so these tests use a fresh instance.
    function testFeeGetterRevertsWhileInhibited() public {
        BuilderExitHarness fresh = new BuilderExitHarness();
        try fresh.feeWei() {
            require(false, "fee getter must revert while inhibited");
        } catch {}
    }

    // No request can be enqueued before activation: the entrypoint reverts when
    // it reads the inhibited fee, even with ample value; nothing is queued.
    function testRequestRevertsWhileInhibited() public {
        BuilderExitHarness fresh = new BuilderExitHarness();
        bytes memory pubkey = _filled(48, 1);
        try fresh.exit{value: 1 ether}(pubkey) {
            require(false, "request must revert while inhibited");
        } catch {}
        require(fresh.pendingCount() == 0, "nothing enqueued while inhibited");
    }

    // The first SYSTEM_ADDRESS call clears the inhibitor; the fee is then
    // MIN_REQUEST_FEE (excess == 0).
    function testFirstSystemCallClearsInhibitor() public {
        BuilderExitHarness fresh = new BuilderExitHarness();
        _systemRead(address(fresh));
        require(fresh.feeWei() == 1, "fee is MIN_REQUEST_FEE once the inhibitor clears");
    }
}
