from rlp import Serializable
from rlp.sedes import Binary, CountableList, List as RLPList, big_endian_int, binary

class LegacyReceipt(Serializable):
    fields = (
        ('status', big_endian_int),
        ('cumulativeGasUsed', big_endian_int),
        ('logsBloom', Binary(256, 256)),
        ('logs', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32), 4),
            binary
        ]))),
    )

class EIP2930Receipt(Serializable):
    fields = (
        ('status', big_endian_int),
        ('cumulativeGasUsed', big_endian_int),
        ('logsBloom', Binary(256, 256)),
        ('logs', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32), 4),
            binary
        ]))),
    )

class EIP1559Receipt(Serializable):
    fields = (
        ('status', big_endian_int),
        ('cumulative_transaction_gas_used', big_endian_int),
        ('logs_bloom', Binary(256, 256)),
        ('logs', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32), 4),
            binary
        ]))),
    )

class EIP4844Receipt(Serializable):
    fields = (
        ('status', big_endian_int),
        ('cumulative_gas_used', big_endian_int),
        ('logs_bloom', Binary(256, 256)),
        ('logs', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32), 4),
            binary
        ]))),
        ('cumulative_data_gas_used', big_endian_int),
    )
