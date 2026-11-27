"""Run with python3 -m unittest discover -s assets/eip-8425.

Set EIP8425_VERIFIER to the compiled eip8425 executable for the proof fixture.
"""

import hmac
import os
import struct
import unittest
from dataclasses import replace
from hashlib import sha256
from pathlib import Path
from unittest.mock import Mock, patch

from eth_hash.auto import keccak

from witness import encode_witness

from recovery import (
    Account, Context, FrameGas, InvalidRecoveryFrame, OutOfGas, PROOF_BYTES,
    RecoveryRevert, SEED_PROOF_GAS, recover,
)


ACCOUNT = bytes.fromhex("9858effd232b4033e47d90003d41ec34ecaeda94")
SOURCE = b"\x11" * 20
SPONSOR = b"\x22" * 20
DELEGATION = b"\xef\x01\x00" + b"\x33" * 20
CODE = b"\x00"  # One STOP byte suffices to test code adoption.
TAG = bytes.fromhex("7569b0d2192c429516d9c6a701322c51a72c3f6e8e5c296d0cdc86a85f239fd4")
PREFIX = bytes(8) + SOURCE + keccak(CODE) + TAG
UNVERIFIED_FRAME = PREFIX + bytes(PROOF_BYTES)
CONTEXT = Context(chain_id=1, recovery_active=True, payer=SPONSOR)
SOURCE_ACCOUNT = Account(nonce=1, code=CODE, storage={1: 100})
REQUEST = CONTEXT.chain_id.to_bytes(32, "big") + ACCOUNT + PREFIX
CLAIM_DIGEST = bytes.fromhex("d0494cc8a16bf559c47bfaeed1c1e304552a0a7a67b9ef4fd0dd3e832e3e8b6c")
ZK_DIR = Path(__file__).resolve().parent / "zk"


def frame_gas():
    # Values supplied by the fork and frame for these tests.
    return FrameGas(execution=3_000_000, state=100_000, warm_access=100,
                    cold_access=3000, account_write=9000, create_account_state=50_000)


def unexpected_verification(request, proof):
    raise AssertionError("the recovery eligibility check should fail before verification")


class WalletInputTests(unittest.TestCase):
    def test_mnemonic_request_vector(self):
        words = " ".join(["abandon"] * 11 + ["about"])
        witness = encode_witness(words, "", 0, 0, 0, 1, 0, SOURCE, keccak(CODE))
        seed = bytes.fromhex(
            "5eb00bbddcf069084889a8ab9155568165f5c453ccb85e70811aaed6f6da5fc1"
            "9a5ac40b389cd370d086206dec8aa6c43daea6690f20ad3d8d48b2d2ce9e38e4"
        )
        self.assertEqual(witness, seed + bytes(12) + (1).to_bytes(32, "big") + PREFIX[:60])
        intent = b"EIP-8425/recover/v1" + witness[76:108] + ACCOUNT + witness[108:]
        tag = hmac.digest(seed, intent, "sha256")
        self.assertEqual(tag, TAG)
        self.assertEqual(keccak(intent + tag).hex(),
                         "252419d58526576f175dce2f379c279d357d335871beb2a2c29f9a46fedb32d8")

    def test_bip39_passphrase(self):
        words = " ".join(["abandon"] * 11 + ["about"])
        witness = encode_witness(words, "TREZOR", 0, 0, 0, 1, 0, SOURCE, keccak(CODE))
        self.assertEqual(witness[:64].hex(),
                         "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e5349553"
                         "1f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04")

    def test_receipt_claim_vector(self):
        def tagged(label, children, words=()):
            data = sha256(label.encode("ascii")).digest() + b"".join(children)
            data += b"".join(struct.pack("<I", word) for word in words)
            return sha256(data + struct.pack("<H", len(children))).digest()

        journal = ACCOUNT + TAG + keccak(b"EIP-8425/recover/v1" + REQUEST)
        image_id = bytes.fromhex((ZK_DIR / "image-id.hex").read_text().strip())
        zero = bytes(32)
        post = tagged("risc0.SystemState", [zero], [0])
        output = tagged("risc0.Output", [sha256(journal).digest(), zero])
        claim = tagged("risc0.ReceiptClaim", [zero, image_id, post, output], [0, 0])
        self.assertEqual(claim, CLAIM_DIGEST)


class EligibilityTests(unittest.TestCase):
    def test_invalid_envelope(self):
        for active, target, data in (
            (False, ACCOUNT, UNVERIFIED_FRAME),
            (True, None, UNVERIFIED_FRAME),
            (True, ACCOUNT[1:], UNVERIFIED_FRAME),
            (True, ACCOUNT, PREFIX[:-1]),
            (True, ACCOUNT, PREFIX),
            (True, ACCOUNT, UNVERIFIED_FRAME[:-1]),
            (True, ACCOUNT, UNVERIFIED_FRAME + b"x"),
        ):
            with self.subTest(active=active, length=len(data), target=target):
                state = {SOURCE: SOURCE_ACCOUNT}
                gas = frame_gas()
                with self.assertRaises(InvalidRecoveryFrame):
                    recover(state, replace(CONTEXT, recovery_active=active), target,
                            data, gas, unexpected_verification)
                self.assertEqual(state, {SOURCE: SOURCE_ACCOUNT})
                self.assertEqual(gas.execution, 3_000_000)

    def test_invalid_frame_placement_flags_and_value(self):
        for frame in ({"is_last": False}, {"previous_frame_flags": 4},
                      {"flags": 1}, {"flags": 4}, {"value": 1}):
            with self.subTest(frame=frame):
                state = {SOURCE: SOURCE_ACCOUNT}
                gas = frame_gas()
                with self.assertRaises(InvalidRecoveryFrame):
                    recover(state, CONTEXT, ACCOUNT, UNVERIFIED_FRAME, gas,
                            unexpected_verification, **frame)
                self.assertEqual(state, {SOURCE: SOURCE_ACCOUNT})
                self.assertEqual(gas, frame_gas())

    def test_ineligible_targets_and_sources(self):
        for reason, context, account, source in (
            ("already migrated", CONTEXT, Account(code=CODE), SOURCE_ACCOUNT),
            ("malformed delegation", CONTEXT, Account(code=DELEGATION + b"x"), SOURCE_ACCOUNT),
            ("nonce changed", CONTEXT, Account(nonce=1), SOURCE_ACCOUNT),
            ("no payer", replace(CONTEXT, payer=None), Account(), SOURCE_ACCOUNT),
            ("reserved", replace(CONTEXT, reserved_targets=frozenset([ACCOUNT])), Account(), SOURCE_ACCOUNT),
            ("created target", replace(CONTEXT, created_in_transaction=frozenset([ACCOUNT])), Account(), SOURCE_ACCOUNT),
            ("created source", replace(CONTEXT, created_in_transaction=frozenset([SOURCE])), Account(), SOURCE_ACCOUNT),
            ("missing source", CONTEXT, Account(), None),
            ("empty source", CONTEXT, Account(), Account()),
            ("delegated source", CONTEXT, Account(), Account(code=DELEGATION)),
            ("changed code hash", CONTEXT, Account(), Account(code=b"\x01")),
        ):
            with self.subTest(reason):
                state = {ACCOUNT: account}
                if source is not None:
                    state[SOURCE] = source
                before = state.copy()
                with self.assertRaises(RecoveryRevert):
                    recover(state, context, ACCOUNT, UNVERIFIED_FRAME, frame_gas(),
                            unexpected_verification)
                self.assertEqual(state, before)

    def test_local_verifier_failure_is_not_a_revert(self):
        state = {SOURCE: SOURCE_ACCOUNT}
        with patch.dict(os.environ, EIP8425_VERIFIER="/dev/null/missing-verifier"):
            with self.assertRaises(OSError):
                recover(state, CONTEXT, ACCOUNT, UNVERIFIED_FRAME, frame_gas())
        self.assertNotIn(ACCOUNT, state)

    def test_charge_before_verifying(self):
        state = {SOURCE: SOURCE_ACCOUNT}
        gas = replace(frame_gas(), execution=SEED_PROOF_GAS)
        with self.assertRaises(OutOfGas):
            recover(state, CONTEXT, ACCOUNT, UNVERIFIED_FRAME, gas, unexpected_verification)
        self.assertEqual(gas.execution, 0)
        self.assertNotIn(ACCOUNT, state)


class StateTransitionTests(unittest.TestCase):
    def test_source_hash_at_frame_entry(self):
        # An earlier frame tried to replace 0x01 with the authorized runtime.
        target = Account(code=DELEGATION)
        restored = {ACCOUNT: target, SOURCE: replace(SOURCE_ACCOUNT, code=b"\x01")}
        self.assertEqual(restored[SOURCE].code_hash, keccak(b"\x01"))
        with self.assertRaisesRegex(RecoveryRevert, "source code hash changed"):
            recover(restored, CONTEXT, ACCOUNT, UNVERIFIED_FRAME, frame_gas(), unexpected_verification)
        self.assertEqual(restored[ACCOUNT], target)

        adopted = {ACCOUNT: target, SOURCE: SOURCE_ACCOUNT}
        with patch("recovery.keccak", side_effect=AssertionError("RECOVER rehashed account code")):
            recover(adopted, CONTEXT, ACCOUNT, UNVERIFIED_FRAME, frame_gas(), Mock(return_value=True))
        self.assertEqual(adopted[ACCOUNT].code, CODE)
        self.assertEqual(adopted[ACCOUNT].code_hash, keccak(CODE))

    def test_install_and_replay(self):
        for old, payer, expected_state_gas_left in (
            (None, SPONSOR, 50_000),
            (Account(), SPONSOR, 50_000),
            (Account(balance=5), b"\x44" * 20, 100_000),
            (Account(balance=10, code=DELEGATION, storage={1: 7}), SPONSOR, 100_000),
        ):
            with self.subTest(old=old):
                state = {SOURCE: SOURCE_ACCOUNT}
                if old is not None:
                    state[ACCOUNT] = old
                context = replace(CONTEXT, payer=payer)
                gas = frame_gas()
                verifier = Mock(return_value=True)
                recover(state, context, ACCOUNT, UNVERIFIED_FRAME, gas, verifier)
                verifier.assert_called_once_with(REQUEST, bytes(PROOF_BYTES))
                self.assertEqual(state[ACCOUNT], replace(old or Account(), code=CODE))
                self.assertEqual(state[SOURCE], SOURCE_ACCOUNT)
                self.assertEqual(gas.execution, 3_000_000 - 6100 - SEED_PROOF_GAS - 9100)
                self.assertEqual(gas.warm_addresses, {ACCOUNT, SOURCE})
                self.assertEqual(gas.state, expected_state_gas_left)
                before = state.copy()
                with self.assertRaises(RecoveryRevert):
                    recover(state, context, ACCOUNT, UNVERIFIED_FRAME, frame_gas(),
                            unexpected_verification)
                self.assertEqual(state, before)

    def test_rejected_proof_rolls_back(self):
        state = {SOURCE: SOURCE_ACCOUNT}
        gas = replace(frame_gas(), warm_addresses=frozenset([SPONSOR]))
        with self.assertRaises(RecoveryRevert):
            recover(state, CONTEXT, ACCOUNT, UNVERIFIED_FRAME, gas, Mock(return_value=False))
        self.assertEqual(state, {SOURCE: SOURCE_ACCOUNT})
        self.assertEqual(gas.execution, 3_000_000 - 6100 - SEED_PROOF_GAS)
        self.assertEqual(gas.warm_addresses, {SPONSOR})

    def test_installation_out_of_state_gas(self):
        state = {SOURCE: SOURCE_ACCOUNT}
        gas = replace(frame_gas(), state=0)
        with self.assertRaises(OutOfGas):
            recover(state, CONTEXT, ACCOUNT, UNVERIFIED_FRAME, gas, Mock(return_value=True))
        self.assertEqual(state, {SOURCE: SOURCE_ACCOUNT})
        self.assertEqual(gas.execution, 0)


class GeneratedProofTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        request = ZK_DIR / "vectors/request.bin"
        proof = ZK_DIR / "vectors/proof.bin"
        missing = [path.name for path in (request, proof) if not path.exists()]
        generate = "run python3 generate_vector.py in assets/eip-8425"
        if len(missing) == 2:
            raise unittest.SkipTest(generate)
        if missing:
            raise FileNotFoundError(f"incomplete test vector (missing {missing[0]}), {generate}")
        cls.request = request.read_bytes()
        cls.proof = proof.read_bytes()

    def test_seal_claim_matches_specification(self):
        prime = 15 * 2**27 + 1
        from_montgomery = pow(2**32, -1, prime)
        raw_limbs = struct.unpack_from("<16I", self.proof, 16 * 4)
        limbs = [word * from_montgomery % prime for word in raw_limbs]
        self.assertEqual(struct.pack("<16H", *limbs), CLAIM_DIGEST)

    def test_generated_proof_installs_code(self):
        self.assertEqual(self.request, REQUEST)
        state = {SOURCE: SOURCE_ACCOUNT}
        recover(state, CONTEXT, ACCOUNT, PREFIX + self.proof, frame_gas())
        self.assertEqual(state[ACCOUNT], Account(code=CODE))

    def test_bad_proof_or_statement_reverts(self):
        for chain_id, tag, proof in (
            (2, TAG, self.proof),
            (1, bytes(32), self.proof),
            (1, TAG, self.proof[:-4] + bytes([self.proof[-4] ^ 1]) + self.proof[-3:]),
        ):
            with self.subTest(chain_id=chain_id, tag=tag, length=len(proof)):
                state = {SOURCE: SOURCE_ACCOUNT}
                data = PREFIX[:-32] + tag + proof
                gas = replace(frame_gas(), warm_addresses=frozenset([SPONSOR]))
                with self.assertRaises(RecoveryRevert):
                    recover(state, replace(CONTEXT, chain_id=chain_id),
                            ACCOUNT, data, gas)
                self.assertNotIn(ACCOUNT, state)
                self.assertEqual(gas.execution, 3_000_000 - 6100 - SEED_PROOF_GAS)
                self.assertEqual(gas.warm_addresses, {SPONSOR})


if __name__ == "__main__":
    unittest.main()
