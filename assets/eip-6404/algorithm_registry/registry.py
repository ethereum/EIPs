from typing import Callable, Dict
from eth_typing import Hash32
from remerkleable.byte_arrays import ByteVector
from remerkleable.basic import uint8, uint256, uint

from secp256k1 import PublicKey, ECDSA


# Registry setup


class AlgorithmEntry:
    ALG_TYPE: uint8
    GAS_PENALTY: uint
    verify: Callable[[bytes, Hash32], bytes]


algorithm_registry: Dict[uint8, AlgorithmEntry] = {}

# Secp256k1

SECP256K1_SIGNATURE_SIZE = 65


def secp256k1_unpack(
    signature: ByteVector[SECP256K1_SIGNATURE_SIZE],
) -> tuple[uint256, uint256, uint8]:
    r = uint256.from_bytes(signature[0:32], "big")
    s = uint256.from_bytes(signature[32:64], "big")
    y_parity = signature[64]
    return (r, s, uint8(y_parity))


def secp256k1_validate(signature: ByteVector[SECP256K1_SIGNATURE_SIZE]):
    SECP256K1N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
    r, s, y_parity = secp256k1_unpack(signature)
    assert 0 < r < SECP256K1N
    assert 0 < s <= SECP256K1N // 2
    assert y_parity in (0, 1)


class Secp256k1(AlgorithmEntry):
    ALG_TYPE = uint8(0xFF)
    GAS_PENALTY = uint256(0)

    def verify(signature_info: bytes, payload_hash: Hash32) -> bytes:
        assert len(signature_info) == (SECP256K1_SIGNATURE_SIZE + 1)
        secp256k1_validate(signature_info[1:])

        ecdsa = ECDSA()
        recover_sig = ecdsa.ecdsa_recoverable_deserialize(
            signature_info[1:65], signature_info[65]
        )
        public_key = PublicKey(ecdsa.ecdsa_recover(payload_hash, recover_sig, raw=True))
        uncompressed = public_key.serialize(compressed=False)
        return uncompressed


algorithm_registry[Secp256k1.ALG_TYPE] = Secp256k1
