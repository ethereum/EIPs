from typing import Callable, Dict
from remerkleable.byte_arrays import ByteVector
from remerkleable.basic import uint8, uint32, uint64, uint256
from eth_hash.auto import keccak

from secp256k1 import PublicKey, ECDSA


# Registry setup


class AlgorithmEntry():
    ALG_TYPE: uint8
    SIZE: uint32
    gas_cost: Callable[[bytes], uint64]
    merge_detached_signature: Callable[[bytes, bytes], bytes]
    validate: Callable[[bytes], None]
    verify: Callable[[bytes, bytes], bytes]

algorithm_registry: Dict[uint8, AlgorithmEntry] = {}

# Secp256k1

SECP256K1_SIGNATURE_SIZE = 65

def secp256k1_unpack(signature: ByteVector[SECP256K1_SIGNATURE_SIZE]) -> tuple[uint256, uint256, uint8]:
    r = uint256.from_bytes(signature[0:32], 'big')
    s = uint256.from_bytes(signature[32:64], 'big')
    y_parity = signature[64]
    return (r, s, y_parity)


def secp256k1_validate(signature: ByteVector[SECP256K1_SIGNATURE_SIZE]):
    SECP256K1N = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
    r, s, y_parity = secp256k1_unpack(signature)
    assert 0 < r < SECP256K1N
    assert 0 < s <= SECP256K1N // 2
    assert y_parity in (0, 1)


class Secp256k1(AlgorithmEntry):
    ALG_TYPE = 0xFF
    SIZE = 66

    def gas_cost(signing_data: bytes) -> uint64:
        # This is an adaptation from the KECCAK256 opcode
        if len(signing_data) == 32:
            return uint64(0)
        else:
            minimum_word_size = (len(signing_data) + 31) // 32
            return uint64(30 + (6 * minimum_word_size))

    def validate(signature: bytes):
        secp256k1_validate(signature[1:])

    def verify(signature: bytes, signing_data: bytes) -> bytes:
        # Another compatibility shim to ensure passing a 32 byte hash still works.
        if len(signing_data) != 32:
            signing_data = bytes(keccak(signing_data))

        ecdsa = ECDSA()
        recover_sig = ecdsa.ecdsa_recoverable_deserialize(signature[1:65], signature[65])
        public_key = PublicKey(ecdsa.ecdsa_recover(signing_data, recover_sig, raw=True))
        uncompressed = public_key.serialize(compressed=False)
        return uncompressed
    
    def merge_detached_signature(detached_signature: bytes, _public_key: bytes) -> bytes:
        # Secp256k1 uses recoverable signatures, this is a no-op.
        return detached_signature


algorithm_registry[Secp256k1.ALG_TYPE] = Secp256k1
