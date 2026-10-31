"""Interface-level guest program for EIP-XXXX Post-Quantum PeerDAS.

The guest follows leanVM's rate-1/2 additive Reed--Solomon membership test.
Concrete binary-field representations, additive-domain construction, normalized
subspace-polynomial evaluation, and Fiat--Shamir expansion are leanVM
interfaces. This file specifies the guest's data flow and assertions; it is not
an independent implementation of leanVM's fields or STARK verifier.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol, Sequence


NUMBER_OF_COLUMNS = 128
MIN_BLOB_BYTES = 2048
MAX_BLOB_BYTES = 524288
BASE_FIELD_BITS = 64
CHALLENGE_FIELD_BITS = 192
BASE_FIELD_ELEMENT_BYTES = BASE_FIELD_BITS // 8
PQ_VERSION = 0x02

CHALLENGE_DOMAIN = b"PQDA_CHALLENGE_V1"
LEANDA_PUBLIC_INPUT_V1 = b"LEANDA_PUBLIC_INPUT_V1"

H256 = bytes
BaseFieldElement = object
ExtensionFieldElement = object


class InvalidBlob(ValueError):
    """Raised when a blob does not satisfy the guest statement."""


class LeanVM(Protocol):
    """Consensus-critical operations supplied by leanVM."""

    def keccak256(self, value: bytes) -> H256: ...

    def decode_base_field_elements(
        self, blob: bytes
    ) -> Sequence[BaseFieldElement]: ...

    def additive_domain(self, dimension: int) -> Sequence[BaseFieldElement]: ...

    def normalized_subspace_polynomial(
        self, index: int, point: BaseFieldElement
    ) -> BaseFieldElement: ...

    def leanvm_fiat_shamir_expand(
        self, transcript: bytes, count: int
    ) -> Sequence[ExtensionFieldElement]: ...

    def embed_base(
        self, value: BaseFieldElement
    ) -> ExtensionFieldElement: ...

    def extension_zero(self) -> ExtensionFieldElement: ...

    def extension_one(self) -> ExtensionFieldElement: ...

    def extension_add(
        self, left: ExtensionFieldElement, right: ExtensionFieldElement
    ) -> ExtensionFieldElement: ...

    def extension_mul(
        self, left: ExtensionFieldElement, right: ExtensionFieldElement
    ) -> ExtensionFieldElement: ...


@dataclass(frozen=True)
class Blob:
    data: bytes


@dataclass(frozen=True)
class BlobCommitment:
    blob_merkle_root: H256
    blob_byte_length: int


@dataclass(frozen=True)
class PrivateInput:
    blobs: tuple[Blob, ...]


@dataclass(frozen=True)
class PublicInput:
    blob_commitments: tuple[BlobCommitment, ...]


def _is_power_of_two(value: int) -> bool:
    return value > 0 and value & (value - 1) == 0


def _merkleize(leanvm: LeanVM, leaves: Sequence[H256]) -> H256:
    if len(leaves) != NUMBER_OF_COLUMNS:
        raise InvalidBlob("Merkle tree must have exactly 128 leaves")

    layer = list(leaves)
    while len(layer) > 1:
        layer = [
            leanvm.keccak256(layer[index] + layer[index + 1])
            for index in range(0, len(layer), 2)
        ]
    return layer[0]


def compute_blob_merkle_root(leanvm: LeanVM, blob: bytes) -> H256:
    if not blob:
        raise InvalidBlob("blob must not be empty")
    if len(blob) % NUMBER_OF_COLUMNS != 0:
        raise InvalidBlob("blob does not split into 128 equal cells")

    cell_byte_length = len(blob) // NUMBER_OF_COLUMNS
    leaves = []
    for index in range(NUMBER_OF_COLUMNS):
        start = index * cell_byte_length
        cell = blob[start : start + cell_byte_length]
        leaves.append(leanvm.keccak256(cell))
    return _merkleize(leanvm, leaves)


def blob_commitment_to_versioned_hash(
    leanvm: LeanVM, commitment: BlobCommitment
) -> H256:
    if len(commitment.blob_merkle_root) != 32:
        raise ValueError("blob Merkle root must be 32 bytes")
    if not 0 <= commitment.blob_byte_length < 2**64:
        raise ValueError("blob byte length must fit in u64")

    digest = leanvm.keccak256(
        commitment.blob_merkle_root
        + commitment.blob_byte_length.to_bytes(8, "little")
    )
    return bytes([PQ_VERSION]) + digest[1:]


def verify_reed_solomon_relation(
    leanvm: LeanVM,
    blob: bytes,
    blob_merkle_root: H256,
) -> None:
    if len(blob) % BASE_FIELD_ELEMENT_BYTES != 0:
        raise InvalidBlob("blob is not canonically base-field aligned")

    codeword = tuple(leanvm.decode_base_field_elements(blob))
    if len(codeword) * BASE_FIELD_ELEMENT_BYTES != len(blob):
        raise InvalidBlob("invalid base-field element encoding")
    if len(codeword) % 2 != 0:
        raise InvalidBlob("codeword must have even length")

    systematic_length = len(codeword) // 2
    if not _is_power_of_two(systematic_length):
        raise InvalidBlob("systematic length must be a power of two")
    kappa = systematic_length.bit_length() - 1

    domain = tuple(leanvm.additive_domain(kappa + 1))
    if len(domain) != len(codeword):
        raise InvalidBlob("leanVM returned an invalid additive domain")

    challenges = tuple(
        leanvm.leanvm_fiat_shamir_expand(
            CHALLENGE_DOMAIN + blob_merkle_root,
            kappa,
        )
    )
    if len(challenges) != kappa:
        raise InvalidBlob("leanVM returned an invalid challenge vector")

    accumulator = leanvm.extension_zero()
    one = leanvm.extension_one()
    for point, value in zip(domain, codeword, strict=True):
        dual_weight = one
        for index, challenge in enumerate(challenges):
            normalized = leanvm.normalized_subspace_polynomial(index, point)
            term = leanvm.extension_add(
                one,
                leanvm.extension_mul(challenge, leanvm.embed_base(normalized)),
            )
            dual_weight = leanvm.extension_mul(dual_weight, term)

        accumulator = leanvm.extension_add(
            accumulator,
            leanvm.extension_mul(dual_weight, leanvm.embed_base(value)),
        )

    if accumulator != leanvm.extension_zero():
        raise InvalidBlob("blob fails the additive Reed-Solomon membership test")


def verify_blob(leanvm: LeanVM, blob: Blob) -> BlobCommitment:
    blob_byte_length = len(blob.data)
    if not MIN_BLOB_BYTES <= blob_byte_length <= MAX_BLOB_BYTES:
        raise InvalidBlob("blob byte length is outside the permitted range")
    if not _is_power_of_two(blob_byte_length):
        raise InvalidBlob("blob byte length must be a power of two")

    root = compute_blob_merkle_root(leanvm, blob.data)
    verify_reed_solomon_relation(leanvm, blob.data, root)
    return BlobCommitment(root, blob_byte_length)


def compute_public_input(
    leanvm: LeanVM, private_input: PrivateInput
) -> PublicInput:
    """Compute the public input claimed for an ordered batch of blobs."""

    return PublicInput(
        tuple(verify_blob(leanvm, blob) for blob in private_input.blobs)
    )


def run_guest(
    leanvm: LeanVM,
    public_input: PublicInput,
    private_input: PrivateInput,
) -> None:
    """Validate an ordered blob batch against its claimed public input."""

    if public_input != compute_public_input(leanvm, private_input):
        raise InvalidBlob("computed commitments do not match the public input")


def encode_leanda_public_input(public_input: PublicInput) -> bytes:
    """Return the canonical LeanDA public-input encoding."""

    commitments = public_input.blob_commitments
    if len(commitments) >= 2**64:
        raise ValueError("too many outputs for canonical encoding")
    encoded = bytearray(LEANDA_PUBLIC_INPUT_V1)
    encoded.extend(len(commitments).to_bytes(8, "little"))
    for commitment in commitments:
        if len(commitment.blob_merkle_root) != 32:
            raise ValueError("blob Merkle root must be 32 bytes")
        if not 0 <= commitment.blob_byte_length < 2**64:
            raise ValueError("blob byte length must fit in u64")
        encoded.extend(commitment.blob_merkle_root)
        encoded.extend(commitment.blob_byte_length.to_bytes(8, "little"))
    return bytes(encoded)


def leanda_data_hash(leanvm: LeanVM, public_input: PublicInput) -> H256:
    return leanvm.keccak256(encode_leanda_public_input(public_input))
