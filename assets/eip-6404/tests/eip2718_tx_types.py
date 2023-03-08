from eth_hash.auto import keccak
from remerkleable.basic import boolean, uint8, uint32, uint64, uint256
from remerkleable.byte_arrays import ByteList, ByteVector, Bytes32, Bytes48
from remerkleable.complex import Container, List, Vector
from remerkleable.union import Union
from rlp import encode, Serializable
from rlp.sedes import Binary, CountableList, List as RLPList, big_endian_int, binary

MAX_BYTES_PER_TRANSACTION = uint64(2**30)
MAX_TRANSACTIONS_PER_PAYLOAD = uint64(2**20)

class ExecutionConfig(Container):
    chain_id: uint256

cfg = ExecutionConfig(
    chain_id=1_337,
)

class Hash32(Bytes32):
    pass

class LegacyTransaction(Serializable):
    fields = (
        ('nonce', big_endian_int),
        ('gasprice', big_endian_int),
        ('startgas', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
    )

class LegacySignedTransaction(Serializable):
    fields = (
        ('nonce', big_endian_int),
        ('gasprice', big_endian_int),
        ('startgas', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
        ('v', big_endian_int),
        ('r', big_endian_int),
        ('s', big_endian_int),
    )

def compute_legacy_sig_hash(signed_tx: LegacySignedTransaction) -> Hash32:
    if signed_tx.v not in (27, 28):  # EIP-155
        return Hash32(keccak(encode(LegacySignedTransaction(
            nonce=signed_tx.nonce,
            gasprice=signed_tx.gasprice,
            startgas=signed_tx.startgas,
            to=signed_tx.to,
            value=signed_tx.value,
            data=signed_tx.data,
            v=(uint256(signed_tx.v) - 35) >> 1,
            r=0,
            s=0,
        ))))
    else:
        return Hash32(keccak(encode(LegacyTransaction(
            nonce=signed_tx.nonce,
            gasprice=signed_tx.gasprice,
            startgas=signed_tx.startgas,
            to=signed_tx.to,
            value=signed_tx.value,
            data=signed_tx.data,
        ))))

def compute_legacy_tx_hash(signed_tx: LegacySignedTransaction) -> Hash32:
    return Hash32(keccak(encode(signed_tx)))

class EIP2930Transaction(Serializable):
    fields = (
        ('chainId', big_endian_int),
        ('nonce', big_endian_int),
        ('gasPrice', big_endian_int),
        ('gasLimit', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
        ('accessList', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
    )

class EIP2930SignedTransaction(Serializable):
    fields = (
        ('chainId', big_endian_int),
        ('nonce', big_endian_int),
        ('gasPrice', big_endian_int),
        ('gasLimit', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
        ('accessList', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
        ('signatureYParity', big_endian_int),
        ('signatureR', big_endian_int),
        ('signatureS', big_endian_int),
    )

def compute_eip2930_sig_hash(signed_tx: EIP2930SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x01]) + encode(EIP2930Transaction(
        chainId=signed_tx.chainId,
        nonce=signed_tx.nonce,
        gasPrice=signed_tx.gasPrice,
        gasLimit=signed_tx.gasLimit,
        to=signed_tx.to,
        value=signed_tx.value,
        data=signed_tx.data,
        accessList=signed_tx.accessList,
    ))))

def compute_eip2930_tx_hash(signed_tx: EIP2930SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x01]) + encode(signed_tx)))

class EIP1559Transaction(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas_limit', big_endian_int),
        ('destination', Binary(20, 20, allow_empty=True)),
        ('amount', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
    )

class EIP1559SignedTransaction(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas_limit', big_endian_int),
        ('destination', Binary(20, 20, allow_empty=True)),
        ('amount', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
        ('signature_y_parity', big_endian_int),
        ('signature_r', big_endian_int),
        ('signature_s', big_endian_int),
    )

def compute_eip1559_sig_hash(signed_tx: EIP1559SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x02]) + encode(EIP1559Transaction(
        chain_id=signed_tx.chain_id,
        nonce=signed_tx.nonce,
        max_priority_fee_per_gas=signed_tx.max_priority_fee_per_gas,
        max_fee_per_gas=signed_tx.max_fee_per_gas,
        gas_limit=signed_tx.gas_limit,
        destination=signed_tx.destination,
        amount=signed_tx.amount,
        data=signed_tx.data,
        access_list=signed_tx.access_list,
    ))))

def compute_eip1559_tx_hash(signed_tx: EIP1559SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x02]) + encode(signed_tx)))

MAX_CALLDATA_SIZE = uint64(2**24)
MAX_ACCESS_LIST_STORAGE_KEYS = uint64(2**24)
MAX_ACCESS_LIST_SIZE = uint64(2**24)
MAX_VERSIONED_HASHES_LIST_SIZE = uint64(2**24)

class ExecutionAddress(ByteVector[20]):
    pass

class VersionedHash(Bytes32):
    pass

class AccessTuple(Container):
    address: ExecutionAddress
    storage_keys: List[Hash32, MAX_ACCESS_LIST_STORAGE_KEYS]

class BlobTransaction(Container):
    chain_id: uint256
    nonce: uint64
    max_priority_fee_per_gas: uint256
    max_fee_per_gas: uint256
    gas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    data: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]
    max_fee_per_data_gas: uint256
    blob_versioned_hashes: List[VersionedHash, MAX_VERSIONED_HASHES_LIST_SIZE]

class ECDSASignature(Container):
    y_parity: boolean
    r: uint256
    s: uint256

class SignedBlobTransaction(Container):
    message: BlobTransaction
    signature: ECDSASignature

def compute_eip4844_sig_hash(signed_tx: SignedBlobTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x05]) + signed_tx.message.encode_bytes()))

def compute_eip4844_tx_hash(signed_tx: SignedBlobTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x05]) + signed_tx.encode_bytes()))

FIELD_ELEMENTS_PER_BLOB=4096
MAX_TX_WRAP_KZG_COMMITMENTS=uint64(2**12)
LIMIT_BLOBS_PER_TX=uint64(2**12)

class KZGCommitment(Bytes48):
    pass

class BLSFieldElement(uint256):
    pass

class KZGProof(Bytes48):
    pass

class BlobTransactionNetworkWrapper(Container):
    tx: SignedBlobTransaction
    blob_kzgs: List[KZGCommitment, MAX_TX_WRAP_KZG_COMMITMENTS]
    blobs: List[Vector[BLSFieldElement, FIELD_ELEMENTS_PER_BLOB], LIMIT_BLOBS_PER_TX]
    kzg_aggregated_proof: KZGProof

class DestinationType(uint8):
    pass

DESTINATION_TYPE_REGULAR = DestinationType(0x00)
DESTINATION_TYPE_CREATE = DestinationType(0x01)

class DestinationAddress(Container):
    destination_type: DestinationType
    address: ExecutionAddress

class ContractAddressData(Serializable):
    fields = (
        ('tx_from', Binary(20, 20)),
        ('nonce', big_endian_int),
    )

def compute_contract_address(tx_from: ExecutionAddress, nonce: uint64) -> ExecutionAddress:
    return ExecutionAddress(keccak(encode(ContractAddressData(
        tx_from=tx_from,
        nonce=nonce,
    )))[12:32])

class TransactionLimits(Container):
    max_priority_fee_per_gas: uint256
    max_fee_per_gas: uint256
    gas: uint64

class TransactionInfo(Container):
    tx_index: uint32
    tx_hash: Hash32
    tx_from: ExecutionAddress
    nonce: uint64
    tx_to: DestinationAddress
    tx_value: uint256
    limits: TransactionLimits
