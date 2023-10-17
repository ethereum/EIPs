from rlp import encode
from ssz_receipt_types import *
from eip2718_receipt_types import *

def recover_legacy_receipt(receipt: Receipt) -> LegacyReceipt:
    return LegacyReceipt(
        status=receipt.status,
        cumulativeGasUsed=receipt.cumulative_gas_used,
        logsBloom=receipt.logs_bloom,
        logs=[(
            log.address,
            log.topics,
            log.data,
        ) for log in receipt.logs],
    )

def recover_eip2930_receipt(receipt: Receipt) -> EIP2930Receipt:
    return EIP2930Receipt(
        status=receipt.status,
        cumulativeGasUsed=receipt.cumulative_gas_used,
        logsBloom=receipt.logs_bloom,
        logs=[(
            log.address,
            log.topics,
            log.data,
        ) for log in receipt.logs],
    )

def recover_eip1559_receipt(receipt: Receipt) -> EIP1559Receipt:
    return EIP1559Receipt(
        status=receipt.status,
        cumulative_transaction_gas_used=receipt.cumulative_gas_used,
        logs_bloom=receipt.logs_bloom,
        logs=[(
            log.address,
            log.topics,
            log.data,
        ) for log in receipt.logs],
    )

def recover_eip4844_receipt(receipt: Receipt) -> EIP4844Receipt:
    return EIP4844Receipt(
        status=receipt.status,
        cumulative_gas_used=receipt.cumulative_gas_used,
        logs_bloom=receipt.logs_bloom,
        logs=[(
            log.address,
            log.topics,
            log.data,
        ) for log in receipt.logs],
        cumulative_data_gas_used=receipt.cumulative_data_gas_used.get(),
    )

def recover_encoded_receipt(receipt: Receipt) -> bytes:
    tx_type = receipt.tx_type

    if tx_type == TRANSACTION_TYPE_EIP4844:
        return bytes([0x05]) + encode(recover_eip4844_receipt(receipt))
    if tx_type == TRANSACTION_TYPE_EIP1559:
        return bytes([0x02]) + encode(recover_eip1559_receipt(receipt))
    if tx_type == TRANSACTION_TYPE_EIP2930:
        return bytes([0x01]) + encode(recover_eip2930_receipt(receipt))
    if tx_type == TRANSACTION_TYPE_LEGACY:
        return encode(recover_legacy_receipt(receipt))
    assert False
