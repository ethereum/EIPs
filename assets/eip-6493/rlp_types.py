from eth_hash.auto import keccak
from remerkleable.byte_arrays import Bytes32
from rlp import encode, Serializable
from rlp.sedes import Binary, CountableList, List as RLPList, big_endian_int, binary

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

def compute_legacy_sig_hash(tx: LegacySignedTransaction) -> Hash32:
    if tx.v not in (27, 28):  # EIP-155
        return Hash32(keccak(encode(LegacySignedTransaction(
            nonce=tx.nonce,
            gasprice=tx.gasprice,
            startgas=tx.startgas,
            to=tx.to,
            value=tx.value,
            data=tx.data,
            v=(tx.v - 35) >> 1,
            r=0,
            s=0,
        ))))
    else:
        return Hash32(keccak(encode(LegacyTransaction(
            nonce=tx.nonce,
            gasprice=tx.gasprice,
            startgas=tx.startgas,
            to=tx.to,
            value=tx.value,
            data=tx.data,
        ))))

def compute_legacy_tx_hash(tx: LegacySignedTransaction) -> Hash32:
    return Hash32(keccak(encode(tx)))

class Eip2930Transaction(Serializable):
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

class Eip2930SignedTransaction(Serializable):
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

def compute_eip2930_sig_hash(tx: Eip2930SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x01]) + encode(Eip2930Transaction(
        chainId=tx.chainId,
        nonce=tx.nonce,
        gasPrice=tx.gasPrice,
        gasLimit=tx.gasLimit,
        to=tx.to,
        value=tx.value,
        data=tx.data,
        accessList=tx.accessList,
    ))))

def compute_eip2930_tx_hash(tx: Eip2930SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x01]) + encode(tx)))

class Eip1559Transaction(Serializable):
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

class Eip1559SignedTransaction(Serializable):
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

def compute_eip1559_sig_hash(tx: Eip1559SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x02]) + encode(Eip1559Transaction(
        chain_id=tx.chain_id,
        nonce=tx.nonce,
        max_priority_fee_per_gas=tx.max_priority_fee_per_gas,
        max_fee_per_gas=tx.max_fee_per_gas,
        gas_limit=tx.gas_limit,
        destination=tx.destination,
        amount=tx.amount,
        data=tx.data,
        access_list=tx.access_list,
    ))))

def compute_eip1559_tx_hash(tx: Eip1559SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x02]) + encode(tx)))

class Eip4844Transaction(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas_limit', big_endian_int),
        ('to', Binary(20, 20)),
        ('value', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
        ('max_fee_per_blob_gas', big_endian_int),
        ('blob_versioned_hashes', CountableList(Binary(32, 32))),
    )

class Eip4844SignedTransaction(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas_limit', big_endian_int),
        ('to', Binary(20, 20)),
        ('value', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
        ('max_fee_per_blob_gas', big_endian_int),
        ('blob_versioned_hashes', CountableList(Binary(32, 32))),
        ('signature_y_parity', big_endian_int),
        ('signature_r', big_endian_int),
        ('signature_s', big_endian_int),
    )

def compute_eip4844_sig_hash(tx: Eip4844SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x03]) + encode(Eip4844Transaction(
        chain_id=tx.chain_id,
        nonce=tx.nonce,
        max_priority_fee_per_gas=tx.max_priority_fee_per_gas,
        max_fee_per_gas=tx.max_fee_per_gas,
        gas_limit=tx.gas_limit,
        to=tx.to,
        value=tx.value,
        data=tx.data,
        access_list=tx.access_list,
        max_fee_per_blob_gas=tx.max_fee_per_blob_gas,
        blob_versioned_hashes=tx.blob_versioned_hashes,
    ))))

def compute_eip4844_tx_hash(tx: Eip4844SignedTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x03]) + encode(tx)))

class RlpReceipt(Serializable):
    fields = (
        ('post_state_or_status', Binary(0, 32)),
        ('cumulative_gas_used', big_endian_int),
        ('logs_bloom', Binary(256, 256)),
        ('logs', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32), 4),
            binary,
        ]))),
    )
