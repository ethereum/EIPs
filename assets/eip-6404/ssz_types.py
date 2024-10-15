from typing import Optional, Type
from eth_hash.auto import keccak
from remerkleable.basic import uint8, uint64, uint256
from remerkleable.byte_arrays import ByteList, ByteVector, Bytes32
from remerkleable.complex import Container, List
from remerkleable.stable_container import Profile, StableContainer
from secp256k1 import ECDSA, PublicKey

class Hash32(Bytes32):
    pass

class ExecutionAddress(ByteVector[20]):
    pass

class VersionedHash(Bytes32):
    pass

SECP256K1_SIGNATURE_SIZE = 32 + 32 + 1
MAX_EXECUTION_SIGNATURE_FIELDS = uint64(2**3)

class ExecutionSignature(StableContainer[MAX_EXECUTION_SIGNATURE_FIELDS]):
    secp256k1: Optional[ByteVector[SECP256K1_SIGNATURE_SIZE]]

class Secp256k1ExecutionSignature(Profile[ExecutionSignature]):
    secp256k1: ByteVector[SECP256K1_SIGNATURE_SIZE]

def secp256k1_pack(r: uint256, s: uint256, y_parity: uint8) -> ByteVector[SECP256K1_SIGNATURE_SIZE]:
    return r.to_bytes(32, 'big') + s.to_bytes(32, 'big') + bytes([y_parity])

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

def secp256k1_recover_signer(signature: ByteVector[SECP256K1_SIGNATURE_SIZE],
                             sig_hash: Hash32) -> ExecutionAddress:
    ecdsa = ECDSA()
    recover_sig = ecdsa.ecdsa_recoverable_deserialize(signature[0:64], signature[64])
    public_key = PublicKey(ecdsa.ecdsa_recover(sig_hash, recover_sig, raw=True))
    uncompressed = public_key.serialize(compressed=False)
    return ExecutionAddress(keccak(uncompressed[1:])[12:])

MAX_FEES_PER_GAS_FIELDS = uint64(2**4)
MAX_CALLDATA_SIZE = uint64(2**24)
MAX_ACCESS_LIST_STORAGE_KEYS = uint64(2**19)
MAX_ACCESS_LIST_SIZE = uint64(2**19)
MAX_BLOB_COMMITMENTS_PER_BLOCK = uint64(2**12)
MAX_AUTHORIZATION_PAYLOAD_FIELDS = uint64(2**4)
MAX_AUTHORIZATION_LIST_SIZE = uint64(2**16)
MAX_TRANSACTION_PAYLOAD_FIELDS = uint64(2**5)

class TransactionType(uint8):
    pass

class ChainId(uint64):
    pass

class GasAmount(uint64):
    pass

class FeePerGas(uint256):
    pass

class FeesPerGas(StableContainer[MAX_FEES_PER_GAS_FIELDS]):
    regular: Optional[FeePerGas]

    # EIP-4844
    blob: Optional[FeePerGas]

class AccessTuple(Container):
    address: ExecutionAddress
    storage_keys: List[Hash32, MAX_ACCESS_LIST_STORAGE_KEYS]

class AuthorizationPayload(StableContainer[MAX_AUTHORIZATION_PAYLOAD_FIELDS]):
    magic: Optional[TransactionType]
    chain_id: Optional[ChainId]
    address: Optional[ExecutionAddress]
    nonce: Optional[uint64]

class Authorization(Container):
    payload: AuthorizationPayload
    signature: ExecutionSignature

class TransactionPayload(StableContainer[MAX_TRANSACTION_PAYLOAD_FIELDS]):
    # EIP-2718
    type_: Optional[TransactionType]

    # EIP-155
    chain_id: Optional[ChainId]

    nonce: Optional[uint64]
    max_fees_per_gas: Optional[FeesPerGas]
    gas: Optional[GasAmount]
    to: Optional[ExecutionAddress]
    value: Optional[uint256]
    input_: Optional[ByteList[MAX_CALLDATA_SIZE]]

    # EIP-2930
    access_list: Optional[List[AccessTuple, MAX_ACCESS_LIST_SIZE]]

    # EIP-1559
    max_priority_fees_per_gas: Optional[FeesPerGas]

    # EIP-4844
    blob_versioned_hashes: Optional[List[VersionedHash, MAX_BLOB_COMMITMENTS_PER_BLOCK]]

    # EIP-7702
    authorization_list: Optional[List[Authorization, MAX_AUTHORIZATION_LIST_SIZE]]

class Transaction(Container):
    payload: TransactionPayload
    signature: ExecutionSignature

class BasicFeesPerGas(Profile[FeesPerGas]):
    regular: FeePerGas

class BlobFeesPerGas(Profile[FeesPerGas]):
    regular: FeePerGas
    blob: FeePerGas

class RlpLegacyTransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    chain_id: Optional[ChainId]
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    to: Optional[ExecutionAddress]
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]

class RlpLegacyTransaction(Container):
    payload: RlpLegacyTransactionPayload
    signature: Secp256k1ExecutionSignature

class RlpAccessListTransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    to: Optional[ExecutionAddress]
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]

class RlpAccessListTransaction(Container):
    payload: RlpAccessListTransactionPayload
    signature: Secp256k1ExecutionSignature

class RlpFeeMarketTransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    to: Optional[ExecutionAddress]
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]
    max_priority_fees_per_gas: BasicFeesPerGas

class RlpFeeMarketTransaction(Container):
    payload: RlpFeeMarketTransactionPayload
    signature: Secp256k1ExecutionSignature

class RlpBlobTransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BlobFeesPerGas
    gas: GasAmount
    to: ExecutionAddress
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]
    max_priority_fees_per_gas: BlobFeesPerGas
    blob_versioned_hashes: List[VersionedHash, MAX_BLOB_COMMITMENTS_PER_BLOCK]

class RlpBlobTransaction(Container):
    payload: RlpBlobTransactionPayload
    signature: Secp256k1ExecutionSignature

class RlpSetCodeAuthorizationPayload(Profile[AuthorizationPayload]):
    magic: TransactionType
    chain_id: Optional[ChainId]
    address: ExecutionAddress
    nonce: uint64

class RlpSetCodeAuthorization(Container):
    payload: RlpSetCodeAuthorizationPayload
    signature: Secp256k1ExecutionSignature

class RlpSetCodeTransactionPayload(Profile[TransactionPayload]):
    type_: TransactionType
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    to: ExecutionAddress
    value: uint256
    input_: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]
    max_priority_fees_per_gas: BasicFeesPerGas
    authorization_list: List[Authorization, MAX_AUTHORIZATION_LIST_SIZE]

class RlpSetCodeTransaction(Container):
    payload: RlpSetCodeTransactionPayload
    signature: Secp256k1ExecutionSignature

LEGACY_TX_TYPE = TransactionType(0x00)
ACCESS_LIST_TX_TYPE = TransactionType(0x01)
FEE_MARKET_TX_TYPE = TransactionType(0x02)
BLOB_TX_TYPE = TransactionType(0x03)
SET_CODE_TX_TYPE = TransactionType(0x04)
SET_CODE_TX_MAGIC = TransactionType(0x05)

def identify_authorization_profile(auth: Authorization) -> Type[Profile]:
    if auth.payload.magic == SET_CODE_TX_MAGIC:
        if auth.payload.chain_id == 0:
            raise Exception(f'Unsupported chain ID in Set Code RLP authorization: {auth}')
        return RlpSetCodeAuthorization

    raise Exception(f'Unsupported authorization: {auth}')

def identify_transaction_profile(tx: Transaction) -> Type[Profile]:
    if tx.payload.type_ == SET_CODE_TX_TYPE:
        for auth in tx.payload.authorization_list or []:
            auth = identify_authorization_profile(auth).from_base(auth)
            if not isinstance(auth, RlpSetCodeAuthorization):
                raise Exception(f'Unsupported authorization in Set Code RLP transaction: {tx}')
        return RlpSetCodeTransaction

    if tx.payload.type_ == BLOB_TX_TYPE:
        if (tx.payload.max_priority_fees_per_gas or FeesPerGas()).blob != 0:
            raise Exception(f'Unsupported blob priority fee in Blob RLP transaction: {tx}')
        return RlpBlobTransaction

    if tx.payload.type_ == FEE_MARKET_TX_TYPE:
        return RlpFeeMarketTransaction

    if tx.payload.type_ == ACCESS_LIST_TX_TYPE:
        return RlpAccessListTransaction

    if tx.payload.type_ == LEGACY_TX_TYPE:
        return RlpLegacyTransaction

    raise Exception(f'Unsupported transaction: {tx}')
