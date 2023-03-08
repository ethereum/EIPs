from os import path as os_path
from sys import path
path.append(os_path.dirname(os_path.dirname(os_path.realpath(__file__))))
path.append('../../eip-6475')

from typing import Tuple
from optional import Optional
from eth_hash.auto import keccak
from remerkleable.basic import boolean, uint8, uint64, uint256
from remerkleable.byte_arrays import ByteList
from remerkleable.complex import Container, List
from secp256k1 import ECDSA, PublicKey
from eip2718_tx_types import (
    MAX_CALLDATA_SIZE,
    MAX_ACCESS_LIST_SIZE,
    MAX_TRANSACTIONS_PER_PAYLOAD,
    MAX_VERSIONED_HASHES_LIST_SIZE,
    AccessTuple,
    DestinationAddress,
    ExecutionAddress,
    Hash32,
    TransactionLimits,
    VersionedHash,
)

class TransactionType(uint8):
    pass

TRANSACTION_TYPE_LEGACY = TransactionType(0x00)
TRANSACTION_TYPE_EIP2930 = TransactionType(0x01)
TRANSACTION_TYPE_EIP1559 = TransactionType(0x02)
TRANSACTION_TYPE_EIP4844 = TransactionType(0x05)

MAX_TRANSACTION_SIGNATURE_SIZE = uint64(2**18)

class TransactionSignatureType(Container):
    tx_type: TransactionType  # EIP-2718
    no_replay_protection: boolean  # EIP-155; `TRANSACTION_TYPE_LEGACY` only

class TransactionSignature(ByteList[MAX_TRANSACTION_SIGNATURE_SIZE]):
    pass

def ecdsa_pack_signature(y_parity: bool, r: uint256, s: uint256) -> TransactionSignature:
    return r.to_bytes(32, 'big') + s.to_bytes(32, 'big') + bytes([0x01 if y_parity else 0])

def ecdsa_unpack_signature(signature: TransactionSignature) -> Tuple[boolean, uint256, uint256]:
    y_parity = signature[64] != 0
    r = uint256.from_bytes(signature[0:32], 'big')
    s = uint256.from_bytes(signature[32:64], 'big')
    return (y_parity, r, s)

def ecdsa_validate_signature(signature: TransactionSignature):
    SECP256K1N = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
    assert len(signature) == 65
    assert signature[64] in (0, 1)
    _, r, s = ecdsa_unpack_signature(signature)
    assert 0 < r < SECP256K1N
    assert 0 < s < SECP256K1N

def ecdsa_recover_tx_from(signature: TransactionSignature, sig_hash: Hash32) -> ExecutionAddress:
    ecdsa = ECDSA()
    recover_sig = ecdsa.ecdsa_recoverable_deserialize(signature[0:64], signature[64])
    public_key = PublicKey(ecdsa.ecdsa_recover(sig_hash, recover_sig, raw=True))
    uncompressed = public_key.serialize(compressed=False)
    return ExecutionAddress(keccak(uncompressed)[12:32])

class BlobDetails(Container):
    max_fee_per_data_gas: uint256
    blob_versioned_hashes: List[VersionedHash, MAX_VERSIONED_HASHES_LIST_SIZE]

class TransactionPayload(Container):
    tx_from: ExecutionAddress
    nonce: uint64
    tx_to: DestinationAddress
    tx_value: uint256
    tx_input: ByteList[MAX_CALLDATA_SIZE]
    limits: TransactionLimits
    sig_type: TransactionSignatureType
    signature: TransactionSignature
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]  # EIP-2930
    blob: Optional[BlobDetails]  # EIP-4844

class Transaction(Container):
    payload: TransactionPayload
    tx_hash: Hash32

class Transactions(Container):
    tx_list: List[Transaction, MAX_TRANSACTIONS_PER_PAYLOAD]
    chain_id: uint256
