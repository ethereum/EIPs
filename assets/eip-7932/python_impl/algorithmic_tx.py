from eth_hash.auto import keccak
from remerkleable.byte_arrays import Bytes32
from rlp import encode, Serializable
from rlp.sedes import Binary, raw, big_endian_int, CountableList

ALGORITHMIC_TX_TYPE = 0x07

class Hash32(Bytes32):
    pass

class AlgorithmicTransactionPayload(Serializable):
    fields = (
        ('tx_type', big_endian_int),
        ('tx_data', raw),
        ('chain_id', big_endian_int),
        ('additional_signatures', CountableList(Binary)),
        # ('signature_info', Binary())
    )

class AlgorithmicTransaction(Serializable):
    fields = (
        ('tx_type', big_endian_int),
        ('tx_data', raw),
        ('chain_id', big_endian_int),
        ('additional_signatures', CountableList(Binary)),
        ('signature_info', Binary())
    )

def compute_access_list_sig_hash(tx: AlgorithmicTransaction) -> Hash32:
    return Hash32(keccak(bytes([ALGORITHMIC_TX_TYPE]) + encode(AlgorithmicTransactionPayload(
        chain_id=tx.chain_id,
        nonce=tx.nonce,
        gas_price=tx.gas_price,
        gas=tx.gas,
        to=tx.to,
        value=tx.value,
        data=tx.data,
        access_list=tx.access_list,
    ))))

def compute_access_list_tx_hash(tx: AlgorithmicTransaction) -> Hash32:
    return Hash32(keccak(bytes([ALGORITHMIC_TX_TYPE]) + encode(tx)))


