from os import path as os_path
from sys import path
path.append(os_path.dirname(os_path.dirname(os_path.realpath(__file__))))

from remerkleable.basic import uint64, uint256
from remerkleable.byte_arrays import ByteList
from remerkleable.complex import Container, List
from remerkleable.union import Union
from eip2718_tx_types import (
    MAX_CALLDATA_SIZE,
    MAX_ACCESS_LIST_SIZE,
    MAX_TRANSACTIONS_PER_PAYLOAD,
    AccessTuple,
    ECDSASignature,
    ExecutionAddress,
    SignedBlobTransaction,
)

class LegacySSZTransaction(Container):
    nonce: uint64
    gasprice: uint256
    startgas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    data: ByteList[MAX_CALLDATA_SIZE]

class LegacyECDSASignature(Container):
    v: uint256
    r: uint256
    s: uint256

class LegacySignedSSZTransaction(Container):
    message: LegacySSZTransaction
    signature: LegacyECDSASignature

class EIP2930SSZTransaction(Container):
    chain_id: uint256
    nonce: uint64
    gas_price: uint256
    gas_limit: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    data: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]

class EIP2930SignedSSZTransaction(Container):
    message: EIP2930SSZTransaction
    signature: ECDSASignature

class EIP1559SSZTransaction(Container):
    chain_id: uint256
    nonce: uint64
    max_priority_fee_per_gas: uint256
    max_fee_per_gas: uint256
    gas_limit: uint64
    destination: Union[None, ExecutionAddress]
    amount: uint256
    data: ByteList[MAX_CALLDATA_SIZE]
    access_list: List[AccessTuple, MAX_ACCESS_LIST_SIZE]

class EIP1559SignedSSZTransaction(Container):
    message: EIP1559SSZTransaction
    signature: ECDSASignature

class Transaction(Union[
    LegacySignedSSZTransaction,
    EIP2930SignedSSZTransaction,
    EIP1559SignedSSZTransaction,
    SignedBlobTransaction,
]):
    pass

class Transactions(List[Transaction, MAX_TRANSACTIONS_PER_PAYLOAD]):
    pass
