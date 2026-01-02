from remerkleable.basic import uint8, uint256, uint
from remerkleable.byte_arrays import ByteVector

from eth_hash.auto import keccak


from .registry import algorithm_registry


class ExecutionAddress(ByteVector[20]):
    pass


def pubkey_to_address(public_key: bytes, algorithm_id: uint8) -> ExecutionAddress:
    if algorithm_id == 0xFF:  # Compatibility shim to ensure backwards compatibility
        return ExecutionAddress(keccak(public_key[1:])[12:])

    # || is binary concatenation
    return ExecutionAddress(keccak(bytes(algorithm_id) + public_key)[12:])


def calculate_penalty(signature_info: bytes) -> uint:
    GAS_PER_ADDITIONAL_VERIFICATION_BYTE = 16
    SECP256K1_SIGNATURE_SIZE = 65

    assert len(signature_info) > 0
    assert uint8(signature_info[0]) in algorithm_registry

    gas_penalty_base = (
        max(len(signature_info) - (SECP256K1_SIGNATURE_SIZE + 1), 0)
        * GAS_PER_ADDITIONAL_VERIFICATION_BYTE
    )
    total_gas_penalty = (
        gas_penalty_base + algorithm_registry[uint8(signature_info[0])].GAS_PENALTY
    )

    return uint256(total_gas_penalty)
