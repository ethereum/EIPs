from remerkleable.basic import uint8, uint
from remerkleable.byte_arrays import ByteVector

from eth_hash.auto import keccak

from .registry import algorithm_registry


class ExecutionAddress(ByteVector[20]):
    pass


def pubkey_to_address(public_key: bytes, algorithm_id: uint8) -> ExecutionAddress:
    if algorithm_id == 0xFF: # Compatibility shim to ensure backwards compatibility
        return ExecutionAddress(keccak(public_key[1:])[12:])

    return ExecutionAddress(keccak(algorithm_id.to_bytes(1, "big") + public_key)[12:])


def calculate_penalty(algorithm: uint8, signing_data: bytes) -> uint:
    assert algorithm in algorithm_registry

    algorithm = algorithm_registry[algorithm]

    return algorithm.gas_cost(signing_data)


def validate_signature(signature: bytes):
    assert len(signature) > 0
    assert signature[0] in algorithm_registry

    algorithm = algorithm_registry[signature[0]]

    return algorithm.validate(signature)


def verify_signature(signing_data: bytes, signature: bytes) -> bytes:
    algorithm = algorithm_registry[signature[0]]

    return algorithm.verify(signature, signing_data)