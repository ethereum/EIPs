from typing import Optional
from enum import IntEnum
from remerkleable.basic import uint8, uint64, uint256, uint
from remerkleable.byte_arrays import ByteVector, Bytes32
from remerkleable.complex import Container
from remerkleable.progressive import CompatibleUnion, ProgressiveByteList, ProgressiveContainer, ProgressiveList

# Import EIP-7932 registry from EIP-7932

from os import path as os_path
from sys import path
current_dir = os_path.dirname(os_path.realpath(__file__))
path.append(current_dir)
path.append(current_dir + '/../eip-7932')

from algorithm_registry.helpers import pubkey_to_address, calculate_penalty, validate_signature, verify_signature


class Hash32(Bytes32):
    pass

class ExecutionAddress(ByteVector[20]):
    pass

class VersionedHash(Bytes32):
    pass

class ExecutionSignature(ProgressiveByteList):
    pass

class ExecutionSignatureAlgorithm(uint8):
    pass


def get_signature_gas_cost(
    signature: ExecutionSignature,
    sig_hash: Hash32,
    expected_algorithm: Optional[ExecutionSignatureAlgorithm]=None
) -> uint:
    assert len(signature) > 0

    if expected_algorithm is not None:
        assert signature[0] == expected_algorithm

    return calculate_penalty(signature[0], sig_hash)


def validate_execution_signature(
    signature: ExecutionSignature,
    expected_algorithm: Optional[ExecutionSignatureAlgorithm]=None,
):
    assert len(signature) > 0

    if expected_algorithm is not None:
        assert signature[0] == expected_algorithm

    validate_signature(signature)

def recover_execution_signer(signature: ExecutionSignature, sig_hash: Hash32) -> ExecutionAddress:
    public_key = verify_signature(sig_hash, signature)

    return pubkey_to_address(public_key, signature[0])

SECP256K1_ALGORITHM = ExecutionSignatureAlgorithm(0xFF)
SECP256K1_SIGNATURE_SIZE = 1 + 32 + 32 + 1

def secp256k1_pack(r: uint256, s: uint256, y_parity: uint8) -> ExecutionSignature:
    return (
        bytes([SECP256K1_ALGORITHM]) +
        r.to_bytes(32, 'big') + s.to_bytes(32, 'big') + bytes([y_parity])
    )

def secp256k1_unpack(signature: ExecutionSignature) -> tuple[uint256, uint256, uint8]:
    assert len(signature) == SECP256K1_SIGNATURE_SIZE
    assert signature[0] == SECP256K1_ALGORITHM
    r = uint256.from_bytes(signature[1:33], 'big')
    s = uint256.from_bytes(signature[33:65], 'big')
    y_parity = signature[65]
    return (r, s, y_parity)

class FeePerGas(uint256):
    pass

class BasicFeesPerGas(ProgressiveContainer(active_fields=[1])):
    regular: FeePerGas

class BlobFeesPerGas(ProgressiveContainer(active_fields=[1, 1])):
    regular: FeePerGas
    blob: FeePerGas

class TransactionType(uint8):
    pass

class ChainId(uint256):
    pass

class GasAmount(uint64):
    pass

class RlpLegacyReplayableBasicTransactionPayload(
    ProgressiveContainer(active_fields=[1, 0, 1, 1, 1, 1, 1, 1])
):
    type_: TransactionType  # 0x00
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    to: ExecutionAddress
    value: uint256
    input_: ProgressiveByteList

class RlpLegacyReplayableCreateTransactionPayload(
    ProgressiveContainer(active_fields=[1, 0, 1, 1, 1, 0, 1, 1])
):
    type_: TransactionType  # 0x00
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    value: uint256
    input_: ProgressiveByteList

class RlpLegacyBasicTransactionPayload(
    ProgressiveContainer(active_fields=[1, 1, 1, 1, 1, 1, 1, 1])
):
    type_: TransactionType  # 0x00
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    to: ExecutionAddress
    value: uint256
    input_: ProgressiveByteList

class RlpLegacyCreateTransactionPayload(
    ProgressiveContainer(active_fields=[1, 1, 1, 1, 1, 0, 1, 1])
):
    type_: TransactionType  # 0x00
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    value: uint256
    input_: ProgressiveByteList

RlpLegacyTransactionPayload = (
    RlpLegacyReplayableBasicTransactionPayload |
    RlpLegacyReplayableCreateTransactionPayload |
    RlpLegacyBasicTransactionPayload |
    RlpLegacyCreateTransactionPayload
)

class AccessTuple(Container):
    address: ExecutionAddress
    storage_keys: ProgressiveList[Hash32]

class RlpAccessListBasicTransactionPayload(
    ProgressiveContainer(active_fields=[1, 1, 1, 1, 1, 1, 1, 1, 1])
):
    type_: TransactionType  # 0x01
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    to: ExecutionAddress
    value: uint256
    input_: ProgressiveByteList
    access_list: ProgressiveList[AccessTuple]

class RlpAccessListCreateTransactionPayload(
    ProgressiveContainer(active_fields=[1, 1, 1, 1, 1, 0, 1, 1, 1])
):
    type_: TransactionType  # 0x01
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    value: uint256
    input_: ProgressiveByteList
    access_list: ProgressiveList[AccessTuple]

RlpAccessListTransactionPayload = (
    RlpAccessListBasicTransactionPayload |
    RlpAccessListCreateTransactionPayload
)

class RlpBasicTransactionPayload(
    ProgressiveContainer(active_fields=[1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
):
    type_: TransactionType  # 0x02
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    to: ExecutionAddress
    value: uint256
    input_: ProgressiveByteList
    access_list: ProgressiveList[AccessTuple]
    max_priority_fees_per_gas: BasicFeesPerGas

class RlpCreateTransactionPayload(
    ProgressiveContainer(active_fields=[1, 1, 1, 1, 1, 0, 1, 1, 1, 1])
):
    type_: TransactionType  # 0x02
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    value: uint256
    input_: ProgressiveByteList
    access_list: ProgressiveList[AccessTuple]
    max_priority_fees_per_gas: BasicFeesPerGas

RlpFeeMarketTransactionPayload = (
    RlpBasicTransactionPayload |
    RlpCreateTransactionPayload
)

class RlpBlobTransactionPayload(
    ProgressiveContainer(active_fields=[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
):
    type_: TransactionType  # 0x03
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BlobFeesPerGas
    gas: GasAmount
    to: ExecutionAddress
    value: uint256
    input_: ProgressiveByteList
    access_list: ProgressiveList[AccessTuple]
    max_priority_fees_per_gas: BasicFeesPerGas
    blob_versioned_hashes: ProgressiveList[VersionedHash]

class RlpReplayableBasicAuthorizationPayload(ProgressiveContainer(active_fields=[1, 0, 1, 1])):
    magic: TransactionType  # 0x05
    address: ExecutionAddress
    nonce: uint64

class RlpBasicAuthorizationPayload(ProgressiveContainer(active_fields=[1, 1, 1, 1])):
    magic: TransactionType  # 0x05
    chain_id: ChainId
    address: ExecutionAddress
    nonce: uint64

class RlpSetCodeAuthorizationPayload(CompatibleUnion({
    0x01: RlpReplayableBasicAuthorizationPayload,
    0x02: RlpBasicAuthorizationPayload,
})):
    pass

class RlpSetCodeAuthorization(Container):
    payload: RlpSetCodeAuthorizationPayload
    signature: ExecutionSignature

class RlpSetCodeTransactionPayload(
    ProgressiveContainer(active_fields=[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1])
):
    type_: TransactionType  # 0x04
    chain_id: ChainId
    nonce: uint64
    max_fees_per_gas: BasicFeesPerGas
    gas: GasAmount
    to: ExecutionAddress
    value: uint256
    input_: ProgressiveByteList
    access_list: ProgressiveList[AccessTuple]
    max_priority_fees_per_gas: BasicFeesPerGas
    authorization_list: ProgressiveList[RlpSetCodeAuthorization]

class TransactionPayload(CompatibleUnion({
    0x01: RlpLegacyReplayableBasicTransactionPayload,
    0x02: RlpLegacyReplayableCreateTransactionPayload,
    0x03: RlpLegacyBasicTransactionPayload,
    0x04: RlpLegacyCreateTransactionPayload,
    0x05: RlpAccessListBasicTransactionPayload,
    0x06: RlpAccessListCreateTransactionPayload,
    0x07: RlpBasicTransactionPayload,
    0x08: RlpCreateTransactionPayload,
    0x09: RlpBlobTransactionPayload,
    0x0a: RlpSetCodeTransactionPayload,
})):
    pass

class Transaction(Container):
    payload: TransactionPayload
    signature: ExecutionSignature

class RlpTxType(IntEnum):
    LEGACY = 0x00
    ACCESS_LIST = 0x01
    FEE_MARKET = 0x02
    BLOB = 0x03
    SET_CODE = 0x04
    SET_CODE_MAGIC = 0x05

def calculate_transaction_intrinsic_gas(tx: Transaction) -> uint:
    tx_data = tx.payload.data()

    TX_BASE_COST = 21000 # FIXME
    gas_cost = TX_BASE_COST

    if hasattr(tx_data, "authorization_list"):
        for auth in tx_data.authorization_list:
            gas_cost += get_signature_gas_cost(auth.signature)

    gas_cost += get_signature_gas_cost(tx.signature)

    return uint256(gas_cost)

def validate_transaction(tx: Transaction):
    tx_data = tx.payload.data()

    expected_signature_algorithm = None

    if hasattr(tx_data, "type_"):
        expected_signature_algorithm = SECP256K1_ALGORITHM
        match tx_data.type_:
            case RlpTxType.LEGACY:
                assert isinstance(tx_data, RlpLegacyTransactionPayload)
            case RlpTxType.ACCESS_LIST:
                assert isinstance(tx_data, RlpAccessListTransactionPayload)
            case RlpTxType.FEE_MARKET:
                assert isinstance(tx_data, RlpFeeMarketTransactionPayload)
            case RlpTxType.BLOB:
                assert isinstance(tx_data, RlpBlobTransactionPayload)
            case RlpTxType.SET_CODE:
                assert isinstance(tx_data, RlpSetCodeTransactionPayload)
            case _:
                assert False

    if hasattr(tx_data, "authorization_list"):
        for auth in tx_data.authorization_list:
            auth_data = auth.payload.data()

            if hasattr(auth_data, "magic"):
                assert auth_data.magic == RlpTxType.SET_CODE_MAGIC
            if hasattr(auth_data, "chain_id"):
                assert auth_data.chain_id != 0

            validate_execution_signature(auth.signature, expected_algorithm=expected_signature_algorithm)

    validate_execution_signature(tx.signature, expected_algorithm=expected_signature_algorithm)
