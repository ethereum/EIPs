from rlp import Serializable
from rlp.sedes import Binary, CountableList, List as RLPList, big_endian_int, binary

class EIP4895Withdrawal(Serializable):
    fields = (
        ('index', big_endian_int),
        ('validator_index', big_endian_int),
        ('address', Binary(20, 20)),
        ('amount', big_endian_int),
    )
