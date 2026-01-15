---
eip: 7932
title: Secondary Signature Algorithms
description: Introduces a precompile and registry for handling alternative signature algorithms
author: James Kempton (@SirSpudlington)
discussions-to: https://ethereum-magicians.org/t/eip-7932-secondary-signature-algorithms/23514
status: Draft
type: Standards Track
category: Core
created: 2025-04-12
---

## Abstract

This EIP:

 - Creates a unified registry & standardized interface for introducing additional signature algorithms for the use of deriving account addresses.
 - Introduces a precompile at address `SIGRECOVER_PRECOMPILE_ADDRESS` for decoding these newly introduced algorithms.

## Motivation

As quantum computers become more advanced, several new post-quantum (PQ) algorithms have been designed. These algorithms all have certain drawbacks, such as large key sizes (>1KiB), large signature sizes, or long verification times. These issues make them more expensive to compute and store than the currently used secp256k1 curve.

This EIP allows the use of many algorithms by introducing an algorithm registry that can be used via a single interface.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Unless explicitly noted, integer encoding MUST be in big-endian format.

### Parameters

| Constant | Value |
| - | - |
| `SIGRECOVER_PRECOMPILE_ADDRESS`| `Bytes20(0x12)` |
| `SIGRECOVER_PRECOMPILE_BASE_GAS` | `3000` |


### Algorithm specification

New algorithms beyond the `secp256k1` algorithm specified in this EIP MUST be specified via a distinct EIP.

Each type of algorithm MUST specify the following fields:

```rust
trait Algorithm {
    // The algorithm type byte
    ALG_TYPE: uint8,

    // The size of signatures. Signatures MUST be padded
    // to this size to be valid. Note that this does include
    // the ALG_TYPE byte prefix
    SIZE: uint32

    // Get the gas cost of signing this data. This
    // SHOULD include a reasonable minimum and MUST
    // be relative to secp256k1, i.e. 0 gas is secp256k1.
    fn gas_cost(signing_data: Bytes) -> Uint64;

    // Check whether the signature is valid. For some
    // algorithms, this may be a no-op. This function
    // will always be called before `verify`.
    fn validate(signature: Bytes) -> None | Error;

    // Take the signature and signing_data and return the
    // public key of the signer.
    fn verify(signature: Bytes, signing_data: Bytes) -> Bytes | Error;
}
```

Specifications MUST include some form of security analysis on the provided algorithm and basic benchmarks justifying gas costs. Additionally, specifications MUST address malleability issues that may arise from specified algorithms. 

An example of this specification can be found [here](../assets/eip-7932/template-eip.md).

### Deriving address from public keys

The function below MUST be used when deriving an address from a public key:

```python
def pubkey_to_address(public_key: Bytes, algorithm_id: uint8) -> ExecutionAddress:
    if algorithm_id == 0xFF: # Compatibility shim to ensure backwards compatibility
        return ExecutionAddress(keccak(public_key[1:])[12:])

    # with `||` being binary concatenation
    return ExecutionAddress(keccak(algorithm_id || public_key)[12:])
```

### Algorithm Registry

```python
class AlgorithmEntry():
    ALG_TYPE: uint8,
    SIZE: uint32,
    gas_cost: Callable[[Bytes], uint64],
    validate: Callable[[Bytes], None | Error],
    verify: Callable[[Bytes, Bytes], Bytes | Error]

algorithm_registry: Dict[uint8, AlgorithmEntry]
```

This EIP uses the `algorithm_registry` object to signify algorithms that have been included within a hard fork.

A living EIP MAY be created on finalization of this EIP to track currently active algorithms across forks.

The algorithm type is reserved `0xFE` as invalid / missing.

### Helper functions

The following helper functions are defined for convenience:

```python
def calculate_penalty(algorithm: uint8, signing_data: Bytes) -> uint:
    assert algorithm in algorithm_registry

    algorithm = algorithm_registry[algorithm]

    return algorithm.gas_cost(signing_data)

def validate_signature(signature: Bytes):
    assert len(signature) > 0
    assert signature[0] in algorithm_registry

    algorithm = algorithm_registry[signature[0]]

    return algorithm.validate(signature)

# This function cannot be called without prior calling `validate_signature(signature)`
def verify_signature(signing_data: Bytes, signature: Bytes) -> Bytes:
    algorithm = algorithm_registry[signature[0]]

    return algorithm.verify(signature, signing_data)
```

### `secp256k1` algorithm


```python
ALG_TYPE = 0xFF
SIZE = 66

SECP256K1_SIGNATURE_SIZE = SIZE - 1

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

def gas_cost(signing_data: Bytes) -> Uint64:
    # This is an adaptation from the KECCAK256 opcode
    if len(signing_data) == 32:
        return Uint64(0)
    else:
        minimum_word_size = (len(signing_data) + 31) // 32
        return Uint64(30 + (6 * minimum_word_size))

def validate(signature: Bytes) -> None | Error:
    secp256k1_validate(signature[1:])

def verify(signature: Bytes, signing_data: Bytes) -> Bytes | Error:
    # Another compatibility shim to ensure passing a 32 byte hash still works.
    if len(signing_data) != 32:
        signing_data = keccak256(signing_data)

    ecdsa = ECDSA()
    recover_sig = ecdsa.ecdsa_recoverable_deserialize(signature[1:65], signature[65])
    public_key = PublicKey(ecdsa.ecdsa_recover(signing_data, recover_sig, raw=True))
    uncompressed = public_key.serialize(compressed=False)
    return uncompressed
```

### `sigrecover` precompile

This EIP also introduces a new precompile located at `SIGRECOVER_PRECOMPILE_ADDRESS`.

This precompile MUST charge `SIGRECOVER_PRECOMPILE_BASE_GAS` static gas before executing.

The precompile MUST output the 20-byte address of the signer provided left padded to 32 bytes. Callers MUST assume all zero bytes as a failure. On failure, the precompile MUST return 32 `0x00` bytes.

The precompile is defined as follows:

```python
def sigrecover_precompile(input: Bytes) -> Bytes:
    assert len(input) >= 1
    assert input[0] in algorithm_registry

    size = algorithm_registry[input[0]].SIZE

    assert len(input) > size

    signature = input[:size]
    signing_data = input[size:]

    charge_gas(calculate_penalty(input[0], signing_data))

    # Run validate/verify function
    validate_signature(signature)
    pubkey = verify_signature(signing_data, signature)

    # Return address left-padded to 32 bytes
    return (b"\x00" * 12) + pubkey_to_address(pubkey, input[0])
```

## Rationale

### ERC-4337 interoperability

While initial drafts of this EIP were competing with ERC-4337, current versions of this EIP support it via the sigrecover precompile. This allows any ERC-4337 implementation to have the same signature verification logic and address derivation logic for any given private key. This also works agnostic of whatever algorithm derives the address.

### Precompile over native EVM code

Having a precompile allows non-EVM processes, i.e. transaction level signature verification, to access the registry *without* having to call into the EVM.

### Opaque `signature` type

As each algorithm has unique properties, e.g. supporting signature recovery and key sizes, the object needs to hold every permutation of every possible signature and potentially additional recovery information. A bytearray of an algorithm-defined size would be able to achieve this goal.

## Backwards Compatibility

EIP-7932 does not modify any existing logic and does not pose any backwards compatibility issues.

## Test Cases

Test cases for the `sigrecover` precompile may be found in the [precompile_test_cases.py](../assets/eip-7932/precompile_test_cases.py) file.

## Security Considerations

Allowing more ways to derive addresses for a single account may decrease overall security for that specific account. However, this is partially mitigated by the increase in processing power required to trial all algorithms. Even still, adding additional algorithms may need further discussion to ensure that the security of the network would not be compromised.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
