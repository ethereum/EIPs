from os import path as os_path
from sys import path
current_dir = os_path.dirname(os_path.realpath(__file__))
path.append(current_dir)
path.append(current_dir + '/../eip-7495')

from typing import Optional, Type
from eth_hash.auto import keccak
from remerkleable.basic import boolean, uint8, uint64, uint256
from remerkleable.byte_arrays import ByteList, ByteVector, Bytes4, Bytes32
from remerkleable.complex import Container, List
from rlp_types import Hash32
from secp256k1 import ECDSA, PublicKey
from stable_container import OneOf, Profile, StableContainer

class TransactionType(uint8):
    pass

TRANSACTION_TYPE_LEGACY = TransactionType(0x00)
TRANSACTION_TYPE_EIP2930 = TransactionType(0x01)
TRANSACTION_TYPE_EIP1559 = TransactionType(0x02)
TRANSACTION_TYPE_EIP4844 = TransactionType(0x03)
TRANSACTION_TYPE_SSZ = TransactionType(0x04)

class ExecutionAddress(ByteVector[20]):
    pass

class VersionedHash(Bytes32):
    pass

class ChainId(uint64):
    pass

class FeePerGas(uint256):
    pass

MAX_CALLDATA_SIZE = uint64(2**24)
MAX_ACCESS_LIST_STORAGE_KEYS = uint64(2**19)
MAX_ACCESS_LIST_SIZE = uint64(2**19)
MAX_BLOB_COMMITMENTS_PER_BLOCK = uint64(2**12)
ECDSA_SIGNATURE_SIZE = 32 + 32 + 1
MAX_TRANSACTION_PAYLOAD_FIELDS = uint64(2**5)
MAX_TRANSACTION_SIGNATURE_FIELDS = uint64(2**4)

class AccessTuple(Container):
    address: ExecutionAddress
    storage_keys: List[Hash32, MAX_ACCESS_LIST_STORAGE_KEYS]

class TransactionPayload(StableContainer[MAX_TRANSACTION_PAYLOAD_FIELDS]):
    # EIP-2718
    type_: TransactionType

    # EIP-155
    chain_id: Optional[ChainId]

    nonce: uint64
    max_fee_per_gas: FeePerGas
    gas: uint64
    to: Optional[ExecutionAddress]
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]

    # EIP-2930
    access_list: Optional[List[AccessTuple, MAX_ACCESS_LIST_SIZE]]

    # EIP-1559
    max_priority_fee_per_gas: Optional[FeePerGas]

    # EIP-4844
    max_fee_per_blob_gas: Optional[FeePerGas]
    blob_versioned_hashes: Optional[List[VersionedHash, MAX_BLOB_COMMITMENTS_PER_BLOCK]]

class TransactionSignature(StableContainer[MAX_TRANSACTION_SIGNATURE_FIELDS]):
    from_: ExecutionAddress
    ecdsa_signature: ByteVector[ECDSA_SIGNATURE_SIZE]

class Transaction(Container):
    payload: TransactionPayload
    signature: TransactionSignature

class ReplayableTransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    nonce: uint64
    max_fee_per_gas: FeePerGas
    gas: uint64
    to: Optional[ExecutionAddress]
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]

class ReplayableTransaction(Container):
    payload: ReplayableTransactionPayload
    signature: TransactionSignature

class LegacyTransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    chain_id: ChainId
    nonce: uint64
    max_fee_per_gas: FeePerGas
    gas: uint64
    to: Optional[ExecutionAddress]
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]

class LegacyTransaction(Container):
    payload: LegacyTransactionPayload
    signature: TransactionSignature

class Eip2930TransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    chain_id: ChainId
    nonce: uint64
    max_fee_per_gas: FeePerGas
    gas: uint64
    to: Optional[ExecutionAddress]
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]

class Eip2930Transaction(Container):
    payload: Eip2930TransactionPayload
    signature: TransactionSignature

class Eip1559TransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    chain_id: ChainId
    nonce: uint64
    max_fee_per_gas: FeePerGas
    gas: uint64
    to: Optional[ExecutionAddress]
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]
    max_priority_fee_per_gas: FeePerGas

class Eip1559Transaction(Container):
    payload: Eip1559TransactionPayload
    signature: TransactionSignature

class Eip4844TransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    chain_id: ChainId
    nonce: uint64
    max_fee_per_gas: FeePerGas
    gas: uint64
    to: ExecutionAddress
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]
    max_priority_fee_per_gas: FeePerGas
    max_fee_per_blob_gas: FeePerGas
    blob_versioned_hashes: List[VersionedHash, MAX_BLOB_COMMITMENTS_PER_BLOCK]

class Eip4844Transaction(Container):
    payload: Eip4844TransactionPayload
    signature: TransactionSignature

class BasicTransactionPayload(Profile[TransactionPayload]):
    chain_id: ChainId
    nonce: uint64
    max_fee_per_gas: FeePerGas
    gas: uint64
    to: Optional[ExecutionAddress]
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]
    max_priority_fee_per_gas: FeePerGas

class BasicTransaction(Container):
    payload: BasicTransactionPayload
    signature: TransactionSignature

class BlobTransactionPayload(Profile[TransactionPayload]):
    chain_id: ChainId
    nonce: uint64
    max_fee_per_gas: FeePerGas
    gas: uint64
    to: ExecutionAddress
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]
    max_priority_fee_per_gas: FeePerGas
    max_fee_per_blob_gas: FeePerGas
    blob_versioned_hashes: List[VersionedHash, MAX_BLOB_COMMITMENTS_PER_BLOCK]

class BlobTransaction(Container):
    payload: BlobTransactionPayload
    signature: TransactionSignature

class AnyTransaction(OneOf[Transaction]):
    @classmethod
    def select_from_base(cls, value: Transaction) -> Type[Transaction]:
        if value.payload.type_ is None:
            if value.payload.blob_versioned_hashes is not None:
                return BlobTransaction
            return BasicTransaction

        if value.payload.type_ == TRANSACTION_TYPE_EIP4844:
            return Eip4844Transaction

        if value.payload.type_ == TRANSACTION_TYPE_EIP1559:
            return Eip1559Transaction

        if value.payload.type_ == TRANSACTION_TYPE_EIP2930:
            return Eip2930Transaction

        if value.payload.chain_id is not None:
            return LegacyTransaction

        return ReplayableTransaction

class Root(Bytes32):
    pass

class DomainType(Bytes4):
    pass

class ChainId(uint256):
    pass

DOMAIN_TRANSACTION_SSZ = DomainType('0x04000080')

class ExecutionSigningData(Container):
    object_root: Root
    domain_type: DomainType

def compute_ssz_sig_hash(payload: TransactionPayload) -> Hash32:
    return Hash32(ExecutionSigningData(
        object_root=payload.hash_tree_root(),
        domain=DOMAIN_TRANSACTION_SSZ,
    ).hash_tree_root())

def compute_ssz_tx_hash(tx: Transaction) -> Hash32:
    assert tx.payload.type_ == TRANSACTION_TYPE_SSZ
    return Hash32(tx.hash_tree_root())

def ecdsa_pack_signature(y_parity: bool,
                         r: uint256,
                         s: uint256) -> ByteVector[ECDSA_SIGNATURE_SIZE]:
    return r.to_bytes(32, 'big') + s.to_bytes(32, 'big') + bytes([0x01 if y_parity else 0x00])

def ecdsa_unpack_signature(signature: ByteVector[ECDSA_SIGNATURE_SIZE]) -> tuple[bool, uint256, uint256]:
    y_parity = signature[64] != 0
    r = uint256.from_bytes(signature[0:32], 'big')
    s = uint256.from_bytes(signature[32:64], 'big')
    return (y_parity, r, s)

def ecdsa_validate_signature(signature: ByteVector[ECDSA_SIGNATURE_SIZE]):
    SECP256K1N = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
    assert len(signature) == 65
    assert signature[64] in (0, 1)
    _, r, s = ecdsa_unpack_signature(signature)
    assert 0 < r < SECP256K1N
    assert 0 < s < SECP256K1N

def ecdsa_recover_from_address(signature: ByteVector[ECDSA_SIGNATURE_SIZE],
                               sig_hash: Hash32) -> ExecutionAddress:
    ecdsa = ECDSA()
    recover_sig = ecdsa.ecdsa_recoverable_deserialize(signature[0:64], signature[64])
    public_key = PublicKey(ecdsa.ecdsa_recover(sig_hash, recover_sig, raw=True))
    uncompressed = public_key.serialize(compressed=False)
    return ExecutionAddress(keccak(uncompressed[1:])[12:])

from tx_hashes import compute_sig_hash, compute_tx_hash

def validate_transaction(tx: AnyTransaction):
    ecdsa_validate_signature(tx.signature.ecdsa_signature)
    assert tx.signature.from_ == ecdsa_recover_from_address(
        tx.signature.ecdsa_signature,
        compute_sig_hash(tx),
    )

BYTES_PER_LOGS_BLOOM = uint64(2**8)
MAX_TOPICS_PER_LOG = 4
MAX_LOG_DATA_SIZE = uint64(2**24)
MAX_LOGS_PER_RECEIPT = uint64(2**21)
MAX_RECEIPT_FIELDS = uint64(2**5)

class Log(Container):
    address: ExecutionAddress
    topics: List[Bytes32, MAX_TOPICS_PER_LOG]
    data: ByteList[MAX_LOG_DATA_SIZE]

class Receipt(StableContainer[MAX_RECEIPT_FIELDS]):
    root: Optional[Hash32]
    gas_used: uint64
    contract_address: Optional[ExecutionAddress]
    logs_bloom: ByteVector[BYTES_PER_LOGS_BLOOM]
    logs: List[Log, MAX_LOGS_PER_RECEIPT]

    # EIP-658
    status: Optional[boolean]

class HomesteadReceipt(Profile[Receipt]):
    root: Hash32
    gas_used: uint64
    contract_address: Optional[ExecutionAddress]
    logs_bloom: ByteVector[BYTES_PER_LOGS_BLOOM]
    logs: List[Log, MAX_LOGS_PER_RECEIPT]

class BasicReceipt(Profile[Receipt]):
    gas_used: uint64
    contract_address: Optional[ExecutionAddress]
    logs_bloom: ByteVector[BYTES_PER_LOGS_BLOOM]
    logs: List[Log, MAX_LOGS_PER_RECEIPT]
    status: boolean

class AnyReceipt(OneOf[Receipt]):
    @classmethod
    def select_from_base(cls, value: Receipt) -> Type[Receipt]:
        if value.status is not None:
            return BasicReceipt

        return HomesteadReceipt
