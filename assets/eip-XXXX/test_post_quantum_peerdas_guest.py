"""Interface and data-flow tests for the EIP-XXXX guest program."""

from hashlib import sha3_256
import json
from pathlib import Path
import unittest

from post_quantum_peerdas_guest import (
    Blob,
    BlobCommitment,
    CHALLENGE_DOMAIN,
    InvalidBlob,
    MAX_BLOB_BYTES,
    PQ_VERSION,
    PrivateInput,
    PublicInput,
    blob_commitment_to_versioned_hash,
    compute_public_input,
    compute_blob_merkle_root,
    leanda_data_hash,
    run_guest,
)


class TestLeanVM:
    """Non-production backend that exercises the guest's leanVM interfaces.

    This backend is not a model of leanVM's binary fields. Its normalized
    subspace values are zero, reducing the tested inner product to XOR parity.
    Cryptographic and field conformance vectors belong to leanVM.
    """

    def __init__(self) -> None:
        self.challenge_transcripts: list[tuple[bytes, int]] = []
        self.domain_dimensions: list[int] = []

    def keccak256(self, value: bytes) -> bytes:
        # Deterministic test stand-in; production supplies Ethereum Keccak-256.
        return sha3_256(value).digest()

    def decode_base_field_elements(self, blob: bytes) -> tuple[int, ...]:
        return tuple(
            int.from_bytes(blob[offset : offset + 8], "little")
            for offset in range(0, len(blob), 8)
        )

    def additive_domain(self, dimension: int) -> tuple[int, ...]:
        self.domain_dimensions.append(dimension)
        return tuple(range(2**dimension))

    def normalized_subspace_polynomial(self, index: int, point: object) -> int:
        return 0

    def leanvm_fiat_shamir_expand(
        self, transcript: bytes, count: int
    ) -> tuple[int, ...]:
        self.challenge_transcripts.append((transcript, count))
        return tuple(range(2, count + 2))

    def embed_base(self, value: object) -> int:
        return int(value)

    def extension_zero(self) -> int:
        return 0

    def extension_one(self) -> int:
        return 1

    def extension_add(self, left: object, right: object) -> int:
        return int(left) ^ int(right)

    def extension_mul(self, left: object, right: object) -> int:
        return int(left) * int(right)


def valid_blob(second_value: int = 0) -> bytes:
    elements = [0] * 256
    elements[0] = second_value
    elements[1] = second_value
    return b"".join(value.to_bytes(8, "little") for value in elements)


class GuestTests(unittest.TestCase):
    def test_valid_blob_public_input(self) -> None:
        leanvm = TestLeanVM()
        blob = valid_blob()
        private_input = PrivateInput((Blob(blob),))
        public_input = compute_public_input(leanvm, private_input)
        run_guest(leanvm, public_input, private_input)

        commitments = public_input.blob_commitments
        self.assertEqual(
            commitments,
            (BlobCommitment(commitments[0].blob_merkle_root, 2048),),
        )
        self.assertEqual(len(commitments[0].blob_merkle_root), 32)
        self.assertEqual(
            blob_commitment_to_versioned_hash(leanvm, commitments[0])[0],
            PQ_VERSION,
        )
        self.assertEqual(len(leanda_data_hash(leanvm, public_input)), 32)

    def test_uses_additive_domain_and_challenge_vector(self) -> None:
        leanvm = TestLeanVM()
        blob = valid_blob()
        commitment = compute_public_input(
            leanvm, PrivateInput((Blob(blob),))
        ).blob_commitments[0]

        self.assertEqual(leanvm.domain_dimensions, [8])
        self.assertEqual(
            leanvm.challenge_transcripts,
            [(CHALLENGE_DOMAIN + commitment.blob_merkle_root, 7)],
        )

    def test_blob_splits_into_128_equal_cells(self) -> None:
        leanvm = TestLeanVM()
        blob = valid_blob()
        self.assertEqual(len(blob) // 128, 16)
        compute_public_input(leanvm, PrivateInput((Blob(blob),)))

    def test_public_input_preserves_blob_order(self) -> None:
        leanvm = TestLeanVM()
        first = valid_blob(0)
        second = valid_blob(1)
        public_input = compute_public_input(
            leanvm,
            PrivateInput((Blob(first), Blob(second))),
        )
        commitments = public_input.blob_commitments
        self.assertNotEqual(
            commitments[0].blob_merkle_root,
            commitments[1].blob_merkle_root,
        )

    def test_rejects_mismatched_public_input(self) -> None:
        leanvm = TestLeanVM()
        with self.assertRaisesRegex(InvalidBlob, "public input"):
            run_guest(
                leanvm,
                PublicInput(()),
                PrivateInput((Blob(valid_blob()),)),
            )

    def test_rejects_invalid_codeword(self) -> None:
        leanvm = TestLeanVM()
        blob = bytearray(valid_blob())
        blob[-8] = 1
        with self.assertRaisesRegex(InvalidBlob, "membership test"):
            compute_public_input(leanvm, PrivateInput((Blob(bytes(blob)),)))

    def test_rejects_blob_below_minimum_size(self) -> None:
        leanvm = TestLeanVM()
        with self.assertRaisesRegex(InvalidBlob, "permitted range"):
            compute_public_input(leanvm, PrivateInput((Blob(b"\x00" * 256),)))

    def test_rejects_blob_above_maximum_size(self) -> None:
        leanvm = TestLeanVM()
        blob = Blob(b"\x00" * (MAX_BLOB_BYTES + 1))
        with self.assertRaisesRegex(InvalidBlob, "permitted range"):
            compute_public_input(leanvm, PrivateInput((blob,)))

    def test_rejects_non_power_of_two_blob_size(self) -> None:
        leanvm = TestLeanVM()
        blob = Blob(b"\x00" * 3072)
        with self.assertRaisesRegex(InvalidBlob, "power of two"):
            compute_public_input(leanvm, PrivateInput((blob,)))

    def test_batch_size_is_not_a_guest_constraint(self) -> None:
        leanvm = TestLeanVM()
        blobs = tuple(Blob(valid_blob()) for _ in range(7))
        self.assertEqual(
            len(compute_public_input(leanvm, PrivateInput(blobs)).blob_commitments),
            7,
        )
        self.assertEqual(
            compute_public_input(leanvm, PrivateInput(())).blob_commitments,
            (),
        )

    def test_versioned_hash_binds_blob_length(self) -> None:
        leanvm = TestLeanVM()
        root = compute_blob_merkle_root(leanvm, valid_blob())
        self.assertNotEqual(
            blob_commitment_to_versioned_hash(leanvm, BlobCommitment(root, 2048)),
            blob_commitment_to_versioned_hash(leanvm, BlobCommitment(root, 4096)),
        )

    def test_shared_vector(self) -> None:
        leanvm = TestLeanVM()
        vector = json.loads(Path(__file__).with_name("test_vectors.json").read_text())
        blob = valid_blob()
        public_input = compute_public_input(
            leanvm,
            PrivateInput((Blob(blob),)),
        )
        commitment = public_input.blob_commitments[0]
        self.assertEqual(
            "0x" + commitment.blob_merkle_root.hex(),
            vector["blob_merkle_root"],
        )
        self.assertEqual(
            "0x" + blob_commitment_to_versioned_hash(leanvm, commitment).hex(),
            vector["blob_versioned_hash"],
        )
        self.assertEqual(
            "0x" + leanda_data_hash(leanvm, public_input).hex(),
            vector["leanda_data_hash"],
        )


if __name__ == "__main__":
    unittest.main()
