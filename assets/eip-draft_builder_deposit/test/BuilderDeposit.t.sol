// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../builder_deposit_contract.sol";
import "./TestHarness.sol";
import "./Vectors.sol";

/// @dev Minimal subset of the Foundry cheatcode interface (avoids a forge-std
/// dependency on this 0.6.11 project).
interface Vm {
    function prank(address) external;
}

/// @notice Tests for the EIP-7685 request-bus builder predeploys.
///
/// Expected values come from py_ecc (see ../gen_vectors.py) baked into
/// ./Vectors.sol. The full deposit-verification tests require the EIP-2537 BLS
/// precompiles (foundry's default Prague EVM); the queue / system-read / input
/// tests do not.
contract BuilderDepositTest {

    Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    address constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    uint constant DEPOSIT_RECORD_LEN = 88; // pubkey 48 + wc 32 + amount 8
    uint constant TOPUP_RECORD_LEN   = 56; // pubkey 48 + amount 8

    BuilderDepositHarness internal dep;
    BuilderTopUpHarness   internal top;

    function setUp() public {
        dep = new BuilderDepositHarness();
        top = new BuilderTopUpHarness();
    }

    // Drive the end-of-block system read: call the predeploy as SYSTEM_ADDRESS
    // with empty calldata; the fallback returns the flat request_data.
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

    // ── Cross-check: SSZ signing root ──────────────────────────────────────

    function testComputeSigningRoot() public {
        (bytes memory pubkey, bytes32 wc, , , uint64 amount_gwei, , ) = Vectors.depositCase();
        bytes32 got = dep.computeDepositSigningRoot(pubkey, wc, amount_gwei);
        require(got == Vectors.depositSigningRoot(), "signing root mismatch vs py_ecc");
    }

    // ── Happy path: verified deposit enqueues, system read emits the record ──

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

        require(dep.pendingCount() == 0, "starts empty");
        dep.deposit{value: uint(amount_gwei) * 1 gwei}(pubkey, wc, signature, pubkey_y, signature_y);
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

        top.top_up{value: 3 ether}(pubkey);
        require(top.pendingCount() == 1, "one top-up queued");

        bytes memory data = _systemRead(address(top));
        bytes memory expected = abi.encodePacked(pubkey, _le64(3_000_000_000));
        require(data.length == TOPUP_RECORD_LEN, "top-up record length");
        require(keccak256(data) == keccak256(expected), "top-up record bytes mismatch");
        require(top.pendingCount() == 0, "queue drained");
    }

    // ── System read access control + FIFO / per-block cap ──────────────────

    function testSystemReadRequiresSystemAddress() public {
        // Without the SYSTEM_ADDRESS prank, the fallback must revert.
        (bool ok, ) = address(dep).call("");
        require(!ok, "non-system system-read must revert");
    }

    function testPerBlockCapAndFifo() public {
        bytes memory pubkey = new bytes(48);
        // Enqueue MAX_REQUESTS_PER_BLOCK + 1 = 17 top-ups (unverified, so easy
        // to queue many without distinct signatures).
        for (uint i = 0; i < 17; i++) {
            top.top_up{value: 1 ether}(pubkey);
        }
        require(top.pendingCount() == 17, "17 queued");

        bytes memory first = _systemRead(address(top));
        require(first.length == 16 * TOPUP_RECORD_LEN, "first read drains the 16-record cap");
        require(top.pendingCount() == 1, "one remains after cap");

        bytes memory second = _systemRead(address(top));
        require(second.length == 1 * TOPUP_RECORD_LEN, "second read drains the remainder");
        require(top.pendingCount() == 0, "queue empty");
    }

    // ── Negative paths: BLS check (nothing should enqueue) ─────────────────

    function testDepositRejectsTamperedAmount() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();
        try dep.deposit{value: (uint(amount_gwei) + 1) * 1 gwei}(
            pubkey, wc, signature, pubkey_y, signature_y
        ) {
            require(false, "tampered amount should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
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
        try dep.deposit{value: uint(amount_gwei) * 1 gwei}(
            pubkey, wc, tampered, pubkey_y, signature_y
        ) {
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
        try dep.deposit{value: uint(amount_gwei) * 1 gwei}(
            flipped, wc, signature, pubkey_y, signature_y
        ) {
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
        try dep.deposit{value: uint(amount_gwei) * 1 gwei}(
            pubkey, wc, flipped, pubkey_y, signature_y
        ) {
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
        try dep.deposit{value: uint(amount_gwei) * 1 gwei}(
            inf, wc, signature, pubkey_y, signature_y
        ) {
            require(false, "infinity pubkey should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    // ── Negative paths: input-shape validation ─────────────────────────────

    function testDepositRejectsTooSmallAmount() public {
        bytes memory pubkey = new bytes(48);
        bytes memory signature = new bytes(96);
        BuilderDepositContract.Fp memory z = BuilderDepositContract.Fp(0, 0);
        BuilderDepositContract.Fp2 memory z2 = BuilderDepositContract.Fp2(z, z);
        try dep.deposit{value: 0.5 ether}(pubkey, bytes32(0), signature, z, z2) {
            require(false, "deposit < 1 ether should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testDepositRejectsWrongPubkeyLength() public {
        bytes memory pubkey = new bytes(47);
        bytes memory signature = new bytes(96);
        BuilderDepositContract.Fp memory z = BuilderDepositContract.Fp(0, 0);
        BuilderDepositContract.Fp2 memory z2 = BuilderDepositContract.Fp2(z, z);
        try dep.deposit{value: 1 ether}(pubkey, bytes32(0), signature, z, z2) {
            require(false, "47-byte pubkey should revert");
        } catch {}
        require(dep.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testTopUpRejectsTooSmallAmount() public {
        bytes memory pubkey = new bytes(48);
        try top.top_up{value: 0.5 ether}(pubkey) {
            require(false, "top_up < 1 ether should revert");
        } catch {}
        require(top.pendingCount() == 0, "nothing enqueued on reject");
    }

    function testTopUpRejectsWrongPubkeyLength() public {
        bytes memory pubkey = new bytes(47);
        try top.top_up{value: 1 ether}(pubkey) {
            require(false, "47-byte pubkey should revert");
        } catch {}
        require(top.pendingCount() == 0, "nothing enqueued on reject");
    }

    // ── helper ─────────────────────────────────────────────────────────────

    function _copy(bytes memory src) internal pure returns (bytes memory dst) {
        dst = new bytes(src.length);
        for (uint i = 0; i < src.length; i++) dst[i] = src[i];
    }
}
