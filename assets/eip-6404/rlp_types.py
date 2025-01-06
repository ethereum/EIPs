from eth_hash.auto import keccak
from remerkleable.byte_arrays import Bytes32
from rlp import encode, Serializable
from rlp.sedes import Binary, CountableList, List as RLPList, big_endian_int, binary

class Hash32(Bytes32):
    pass

class LegacyRlpTransactionPayload(Serializable):
    fields = (
        ('nonce', big_endian_int),
        ('gas_price', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
    )

class LegacyRlpTransaction(Serializable):
    fields = (
        ('nonce', big_endian_int),
        ('gas_price', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
        ('v', big_endian_int),
        ('r', big_endian_int),
        ('s', big_endian_int),
    )

def compute_legacy_sig_hash(tx: LegacyRlpTransaction) -> Hash32:
    if tx.v not in (27, 28):  # EIP-155
        return Hash32(keccak(encode(LegacyRlpTransaction(
            nonce=tx.nonce,
            gas_price=tx.gas_price,
            gas=tx.gas,
            to=tx.to,
            value=tx.value,
            data=tx.data,
            v=(tx.v - 35) >> 1,
            r=0,
            s=0,
        ))))
    else:
        return Hash32(keccak(encode(LegacyRlpTransactionPayload(
            nonce=tx.nonce,
            gas_price=tx.gas_price,
            gas=tx.gas,
            to=tx.to,
            value=tx.value,
            data=tx.data,
        ))))

def compute_legacy_tx_hash(tx: LegacyRlpTransaction) -> Hash32:
    return Hash32(keccak(encode(tx)))

class AccessListRlpTransactionPayload(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('gas_price', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
    )

class AccessListRlpTransaction(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('gas_price', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
        ('y_parity', big_endian_int),
        ('r', big_endian_int),
        ('s', big_endian_int),
    )

def compute_access_list_sig_hash(tx: AccessListRlpTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x01]) + encode(AccessListRlpTransactionPayload(
        chain_id=tx.chain_id,
        nonce=tx.nonce,
        gas_price=tx.gas_price,
        gas=tx.gas,
        to=tx.to,
        value=tx.value,
        data=tx.data,
        access_list=tx.access_list,
    ))))

def compute_access_list_tx_hash(tx: AccessListRlpTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x01]) + encode(tx)))

class FeeMarketRlpTransactionPayload(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
    )

class FeeMarketRlpTransaction(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary(20, 20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
        ('y_parity', big_endian_int),
        ('r', big_endian_int),
        ('s', big_endian_int),
    )

def compute_fee_market_sig_hash(tx: FeeMarketRlpTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x02]) + encode(FeeMarketRlpTransactionPayload(
        chain_id=tx.chain_id,
        nonce=tx.nonce,
        max_priority_fee_per_gas=tx.max_priority_fee_per_gas,
        max_fee_per_gas=tx.max_fee_per_gas,
        gas=tx.gas,
        to=tx.to,
        value=tx.value,
        data=tx.data,
        access_list=tx.access_list,
    ))))

def compute_fee_market_tx_hash(tx: FeeMarketRlpTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x02]) + encode(tx)))

class BlobRlpTransactionPayload(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas', big_endian_int),
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

class BlobRlpTransaction(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary(20, 20)),
        ('value', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
        ('max_fee_per_blob_gas', big_endian_int),
        ('blob_versioned_hashes', CountableList(Binary(32, 32))),
        ('y_parity', big_endian_int),
        ('r', big_endian_int),
        ('s', big_endian_int),
    )

def compute_blob_sig_hash(tx: BlobRlpTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x03]) + encode(BlobRlpTransactionPayload(
        chain_id=tx.chain_id,
        nonce=tx.nonce,
        max_priority_fee_per_gas=tx.max_priority_fee_per_gas,
        max_fee_per_gas=tx.max_fee_per_gas,
        gas=tx.gas,
        to=tx.to,
        value=tx.value,
        data=tx.data,
        access_list=tx.access_list,
        max_fee_per_blob_gas=tx.max_fee_per_blob_gas,
        blob_versioned_hashes=tx.blob_versioned_hashes,
    ))))

def compute_blob_tx_hash(tx: BlobRlpTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x03]) + encode(tx)))

class SetCodeRlpAuthorizationPayload(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('address', Binary(20, 20)),
        ('nonce', big_endian_int),
    )

class SetCodeRlpAuthorization(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('address', Binary(20, 20)),
        ('nonce', big_endian_int),
        ('y_parity', big_endian_int),
        ('r', big_endian_int),
        ('s', big_endian_int),
    )

def compute_set_code_auth_hash(auth: SetCodeRlpAuthorization) -> Hash32:
    return Hash32(keccak(bytes([0x05]) + encode(SetCodeRlpAuthorizationPayload(
        chain_id=auth.chain_id,
        address=auth.address,
        nonce=auth.nonce,
    ))))

class SetCodeRlpTransactionPayload(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary(20, 20)),
        ('value', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
        ('authorization_list', CountableList(SetCodeRlpAuthorization)),
    )

class SetCodeRlpTransaction(Serializable):
    fields = (
        ('chain_id', big_endian_int),
        ('nonce', big_endian_int),
        ('max_priority_fee_per_gas', big_endian_int),
        ('max_fee_per_gas', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary(20, 20)),
        ('value', big_endian_int),
        ('data', binary),
        ('access_list', CountableList(RLPList([
            Binary(20, 20),
            CountableList(Binary(32, 32)),
        ]))),
        ('authorization_list', CountableList(SetCodeRlpAuthorization)),
        ('y_parity', big_endian_int),
        ('r', big_endian_int),
        ('s', big_endian_int),
    )

def compute_set_code_sig_hash(tx: SetCodeRlpTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x04]) + encode(SetCodeRlpTransactionPayload(
        chain_id=tx.chain_id,
        nonce=tx.nonce,
        max_priority_fee_per_gas=tx.max_priority_fee_per_gas,
        max_fee_per_gas=tx.max_fee_per_gas,
        gas=tx.gas,
        to=tx.to,
        value=tx.value,
        data=tx.data,
        access_list=tx.access_list,
        authorization_list=tx.authorization_list,
    ))))

def compute_set_code_tx_hash(tx: SetCodeRlpTransaction) -> Hash32:
    return Hash32(keccak(bytes([0x04]) + encode(tx)))
