from rlp import decode
from ssz_receipt_types import *
from eip2718_receipt_types import *

def normalize_receipt(encoded_receipt: bytes) -> Receipt:
    eip2718_type = encoded_receipt[0]

    if eip2718_type == 0x05:  # EIP-4844
        receipt = decode(encoded_receipt[1:], EIP4844Receipt)

        return Receipt(
            status=receipt.status,
            cumulative_gas_used=receipt.cumulative_gas_used,
            logs_bloom=receipt.logs_bloom,
            logs=[ReceiptLog(
                address=log[0],
                topics=log[1],
                data=log[2]
            ) for log in receipt.logs],
            tx_type=TRANSACTION_TYPE_EIP4844,
            cumulative_data_gas_used=Optional[uint64](receipt.cumulative_data_gas_used),
        )

    if eip2718_type == 0x02:  # EIP-1559
        receipt = decode(encoded_receipt[1:], EIP1559Receipt)

        return Receipt(
            status=receipt.status,
            cumulative_gas_used=receipt.cumulative_transaction_gas_used,
            logs_bloom=receipt.logs_bloom,
            logs=[ReceiptLog(
                address=log[0],
                topics=log[1],
                data=log[2]
            ) for log in receipt.logs],
            tx_type=TRANSACTION_TYPE_EIP1559,
        )

    if eip2718_type == 0x01:  # EIP-2930
        receipt = decode(encoded_receipt[1:], EIP2930Receipt)

        return Receipt(
            status=receipt.status,
            cumulative_gas_used=receipt.cumulativeGasUsed,
            logs_bloom=receipt.logsBloom,
            logs=[ReceiptLog(
                address=log[0],
                topics=log[1],
                data=log[2]
            ) for log in receipt.logs],
            tx_type=TRANSACTION_TYPE_EIP2930,
        )

    if 0xc0 <= eip2718_type <= 0xfe:  # Legacy
        receipt = decode(encoded_receipt, LegacyReceipt)

        return Receipt(
            status=receipt.status,
            cumulative_gas_used=receipt.cumulativeGasUsed,
            logs_bloom=receipt.logsBloom,
            logs=[ReceiptLog(
                address=log[0],
                topics=log[1],
                data=log[2]
            ) for log in receipt.logs],
            tx_type=TRANSACTION_TYPE_LEGACY,
        )

    assert False
