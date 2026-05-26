// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../builder_deposit_contract.sol";
import "./TestHarness.sol";
import "./Vectors.sol";

/// @notice Cross-verification tests for BuilderDepositContract.
///
/// Expected values come from py_ecc (see ../gen_vectors.py) and are baked
/// into ./Vectors.sol as Solidity literals.
///
/// The full deposit-verification tests require the EIP-2537 BLS precompiles
/// (foundry's default Prague EVM). The signing-root cross-check and the
/// length/amount/flag rejection tests do not — they exercise SHA-256 and
/// the EVM only.
contract BuilderDepositTest {

    BuilderDepositHarness internal harness;

    function setUp() public {
        harness = new BuilderDepositHarness();
    }

    // ── Cross-check: SSZ signing root ──────────────────────────────────────

    function testComputeSigningRoot() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            ,
            ,
            uint64 amount_gwei,
            ,
        ) = Vectors.depositCase();
        bytes32 expected = Vectors.depositSigningRoot();
        bytes32 got = harness.computeDepositSigningRoot(pubkey, wc, amount_gwei);
        require(got == expected, "signing root mismatch vs py_ecc");
    }

    // ── Happy path: verified deposit + top-up ──────────────────────────────

    function testDepositValid() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();

        uint64 before = harness.getDepositCount();
        harness.deposit{value: uint(amount_gwei) * 1 gwei}(
            pubkey, wc, signature, pubkey_y, signature_y
        );
        require(harness.getDepositCount() == before + 1, "deposit count did not increment");
    }

    function testTopUpValid() public {
        (bytes memory pubkey, , , , , , ) = Vectors.depositCase();
        uint64 before = harness.getDepositCount();
        harness.top_up{value: 2 ether}(pubkey);
        require(harness.getDepositCount() == before + 1, "top_up did not increment count");
    }

    function testMonotonicIndex() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();

        require(harness.getDepositCount() == 0, "expected initial count == 0");
        harness.deposit{value: uint(amount_gwei) * 1 gwei}(
            pubkey, wc, signature, pubkey_y, signature_y
        );
        require(harness.getDepositCount() == 1, "after first deposit count == 1");
        harness.top_up{value: 1 ether}(pubkey);
        require(harness.getDepositCount() == 2, "after top_up count == 2");
        harness.top_up{value: 1 ether}(pubkey);
        require(harness.getDepositCount() == 3, "after second top_up count == 3");
    }

    // ── Negative paths: BLS check ──────────────────────────────────────────

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
        // Sending a different msg.value puts a different `amount_gwei` into
        // the signing root, so the pairing check must reject.
        uint tamperedValue = (uint(amount_gwei) + 1) * 1 gwei;
        try harness.deposit{value: tamperedValue}(
            pubkey, wc, signature, pubkey_y, signature_y
        ) {
            require(false, "tampered amount should revert");
        } catch {}
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
        try harness.deposit{value: uint(amount_gwei) * 1 gwei}(
            pubkey, wc, tampered, pubkey_y, signature_y
        ) {
            require(false, "tampered signature should revert");
        } catch {}
    }

    // Regression test for the sign-bit binding (audit Finding 2). The valid
    // vector has pubkey sign flag == sign(pubkey_y). Flipping ONLY the pubkey's
    // sign flag (leaving X and the supplied pubkey_y unchanged) models an
    // attacker who verifies (X, +Y) but emits bytes that decompress to (X, -Y).
    // With the sign-bit consistency check in `_constructG1`, this must revert
    // BEFORE any pairing work. Without the check it would have passed.
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
        flipped[0] = flipped[0] ^ bytes1(uint8(0x20)); // flip sign flag only
        try harness.deposit{value: uint(amount_gwei) * 1 gwei}(
            flipped, wc, signature, pubkey_y, signature_y
        ) {
            require(false, "pubkey sign-bit flip should revert");
        } catch {}
    }

    // Same regression, signature side: flip the signature's sign flag while
    // keeping signature_y, exercising `_constructG2`'s sign-bit check.
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
        try harness.deposit{value: uint(amount_gwei) * 1 gwei}(
            pubkey, wc, flipped, pubkey_y, signature_y
        ) {
            require(false, "signature sign-bit flip should revert");
        } catch {}
    }

    // ── Negative paths: compressed-encoding flags ──────────────────────────

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
        bytes memory infPubkey = _copy(pubkey);
        infPubkey[0] = infPubkey[0] | bytes1(uint8(0x40)); // set infinity flag
        try harness.deposit{value: uint(amount_gwei) * 1 gwei}(
            infPubkey, wc, signature, pubkey_y, signature_y
        ) {
            require(false, "infinity pubkey should revert");
        } catch {}
    }

    function testDepositRejectsInfinitySignature() public {
        (
            bytes memory pubkey,
            bytes32 wc,
            bytes memory signature,
            ,
            uint64 amount_gwei,
            BuilderDepositContract.Fp memory pubkey_y,
            BuilderDepositContract.Fp2 memory signature_y
        ) = Vectors.depositCase();
        bytes memory infSig = _copy(signature);
        infSig[0] = infSig[0] | bytes1(uint8(0x40));
        try harness.deposit{value: uint(amount_gwei) * 1 gwei}(
            pubkey, wc, infSig, pubkey_y, signature_y
        ) {
            require(false, "infinity signature should revert");
        } catch {}
    }

    // ── Negative paths: input-shape validation ─────────────────────────────

    function testDepositRejectsTooSmallAmount() public {
        // BLS data doesn't matter — the amount check fires first.
        bytes memory pubkey = new bytes(48);
        bytes memory signature = new bytes(96);
        BuilderDepositContract.Fp memory zero_fp =
            BuilderDepositContract.Fp(0, 0);
        BuilderDepositContract.Fp2 memory zero_fp2 =
            BuilderDepositContract.Fp2(zero_fp, zero_fp);
        try harness.deposit{value: 0.5 ether}(
            pubkey, bytes32(0), signature, zero_fp, zero_fp2
        ) {
            require(false, "deposit < 1 ether should revert");
        } catch {}
    }

    function testDepositRejectsNonGweiAmount() public {
        bytes memory pubkey = new bytes(48);
        bytes memory signature = new bytes(96);
        BuilderDepositContract.Fp memory zero_fp =
            BuilderDepositContract.Fp(0, 0);
        BuilderDepositContract.Fp2 memory zero_fp2 =
            BuilderDepositContract.Fp2(zero_fp, zero_fp);
        // 1 ether + 1 wei is not a multiple of 1 gwei.
        try harness.deposit{value: 1 ether + 1}(
            pubkey, bytes32(0), signature, zero_fp, zero_fp2
        ) {
            require(false, "non-gwei value should revert");
        } catch {}
    }

    function testDepositRejectsWrongPubkeyLength() public {
        bytes memory pubkey = new bytes(47); // one short
        bytes memory signature = new bytes(96);
        BuilderDepositContract.Fp memory zero_fp =
            BuilderDepositContract.Fp(0, 0);
        BuilderDepositContract.Fp2 memory zero_fp2 =
            BuilderDepositContract.Fp2(zero_fp, zero_fp);
        try harness.deposit{value: 1 ether}(
            pubkey, bytes32(0), signature, zero_fp, zero_fp2
        ) {
            require(false, "47-byte pubkey should revert");
        } catch {}
    }

    function testDepositRejectsWrongSignatureLength() public {
        bytes memory pubkey = new bytes(48);
        bytes memory signature = new bytes(95); // one short
        BuilderDepositContract.Fp memory zero_fp =
            BuilderDepositContract.Fp(0, 0);
        BuilderDepositContract.Fp2 memory zero_fp2 =
            BuilderDepositContract.Fp2(zero_fp, zero_fp);
        try harness.deposit{value: 1 ether}(
            pubkey, bytes32(0), signature, zero_fp, zero_fp2
        ) {
            require(false, "95-byte signature should revert");
        } catch {}
    }

    function testTopUpRejectsTooSmallAmount() public {
        bytes memory pubkey = new bytes(48);
        try harness.top_up{value: 0.5 ether}(pubkey) {
            require(false, "top_up < 1 ether should revert");
        } catch {}
    }

    function testTopUpRejectsWrongPubkeyLength() public {
        bytes memory pubkey = new bytes(47);
        try harness.top_up{value: 1 ether}(pubkey) {
            require(false, "47-byte pubkey should revert");
        } catch {}
    }

    // ── helpers ────────────────────────────────────────────────────────────

    function _copy(bytes memory src) internal pure returns (bytes memory dst) {
        dst = new bytes(src.length);
        for (uint i = 0; i < src.length; i++) dst[i] = src[i];
    }
}
