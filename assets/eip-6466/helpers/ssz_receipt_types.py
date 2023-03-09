from os import path as os_path
from sys import path
path.append(os_path.dirname(os_path.dirname(os_path.realpath(__file__))))
path.append('../../eip-6475')

from optional import Optional
from remerkleable.basic import uint8, uint64, uint256
from remerkleable.byte_arrays import ByteVector, Bytes32
from remerkleable.complex import Container, List

class ExecutionAddress(ByteVector[20]):
    pass

class TransactionType(uint8):
    pass

TRANSACTION_TYPE_LEGACY = TransactionType(0x00)
TRANSACTION_TYPE_EIP2930 = TransactionType(0x01)
TRANSACTION_TYPE_EIP1559 = TransactionType(0x02)
TRANSACTION_TYPE_EIP4844 = TransactionType(0x05)

BYTES_PER_LOGS_BLOOM = uint64(2**8)

class Topic(Bytes32):
    pass

MAX_TOPICS_PER_LOG = uint64(2**2)
MAX_LOG_DATA_SIZE = uint64(2**24)
MAX_LOGS_PER_RECEIPT = uint64(2**20)

class ReceiptLog(Container):
    address: ExecutionAddress
    topics: List[Topic, MAX_TOPICS_PER_LOG]
    data: ByteVector[MAX_LOG_DATA_SIZE]

class Receipt(Container):
    status: uint256  # EIP-658
    cumulative_gas_used: uint64
    logs_bloom: ByteVector[BYTES_PER_LOGS_BLOOM]
    logs: List[ReceiptLog, MAX_LOGS_PER_RECEIPT]
    tx_type: TransactionType
    cumulative_data_gas_used: Optional[uint64]
