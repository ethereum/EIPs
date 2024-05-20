from rlp_types import *
from ssz_types import *

def recover_replayable_rlp_transaction(
        tx: ReplayableTransaction) -> LegacyRlpTransaction:
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)
    v = uint64(1 if y_parity else 0) + 27

    return LegacyRlpTransaction(
        nonce=tx.payload.nonce,
        gasprice=tx.payload.max_fees_per_gas.regular,
        startgas=tx.payload.gas,
        to=bytes(tx.payload.to if tx.payload.to is not None else []),
        value=tx.payload.value,
        data=tx.payload.input_,
        v=v,
        r=r,
        s=s,
    )

def recover_legacy_rlp_transaction(
        tx: LegacyTransaction) -> LegacyRlpTransaction:
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)
    v = uint64(1 if y_parity else 0) + 35 + tx.payload.chain_id * 2

    return LegacyRlpTransaction(
        nonce=tx.payload.nonce,
        gasprice=tx.payload.max_fees_per_gas.regular,
        startgas=tx.payload.gas,
        to=bytes(tx.payload.to if tx.payload.to is not None else []),
        value=tx.payload.value,
        data=tx.payload.input_,
        v=v,
        r=r,
        s=s,
    )

def recover_eip2930_rlp_transaction(
        tx: Eip2930Transaction) -> Eip2930RlpTransaction:
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)

    return Eip2930RlpTransaction(
        chainId=tx.payload.chain_id,
        nonce=tx.payload.nonce,
        gasPrice=tx.payload.max_fees_per_gas.regular,
        gasLimit=tx.payload.gas,
        to=bytes(tx.payload.to if tx.payload.to is not None else []),
        value=tx.payload.value,
        data=tx.payload.input_,
        accessList=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in tx.payload.access_list],
        signatureYParity=1 if y_parity else 0,
        signatureR=r,
        signatureS=s,
    )

def recover_eip1559_rlp_transaction(
        tx: Eip1559Transaction) -> Eip1559RlpTransaction:
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)

    return Eip1559RlpTransaction(
        chain_id=tx.payload.chain_id,
        nonce=tx.payload.nonce,
        max_priority_fee_per_gas=tx.payload.max_priority_fees_per_gas.regular,
        max_fee_per_gas=tx.payload.max_fees_per_gas.regular,
        gas_limit=tx.payload.gas,
        destination=bytes(tx.payload.to if tx.payload.to is not None else []),
        amount=tx.payload.value,
        data=tx.payload.input_,
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in tx.payload.access_list],
        signature_y_parity=1 if y_parity else 0,
        signature_r=r,
        signature_s=s,
    )

def recover_eip4844_rlp_transaction(tx: Eip4844Transaction) -> Eip4844RlpTransaction:
    assert tx.payload.max_priority_fees_per_gas.blob == FeePerGas(0)
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)

    return Eip4844RlpTransaction(
        chain_id=tx.payload.chain_id,
        nonce=tx.payload.nonce,
        max_priority_fee_per_gas=tx.payload.max_priority_fees_per_gas.regular,
        max_fee_per_gas=tx.payload.max_fees_per_gas.regular,
        gas_limit=tx.payload.gas,
        to=tx.payload.to,
        value=tx.payload.value,
        data=tx.payload.input_,
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in tx.payload.access_list],
        max_fee_per_blob_gas=tx.payload.max_fees_per_gas.blob,
        blob_versioned_hashes=tx.payload.blob_versioned_hashes,
        signature_y_parity=1 if y_parity else 0,
        signature_r=r,
        signature_s=s,
    )

def compute_sig_hash(tx: AnyTransaction) -> Hash32:
    if (
        isinstance(tx, BasicTransaction) or
        isinstance(tx, BlobTransaction)
    ):
        return compute_ssz_sig_hash(tx.payload)

    if isinstance(tx, Eip4844Transaction):
        pre = recover_eip4844_rlp_transaction(tx)
        return compute_eip4844_sig_hash(pre)

    if isinstance(tx, Eip1559Transaction):
        pre = recover_eip1559_rlp_transaction(tx)
        return compute_eip1559_sig_hash(pre)

    if isinstance(tx, Eip2930Transaction):
        pre = recover_eip2930_rlp_transaction(tx)
        return compute_eip2930_sig_hash(pre)

    if isinstance(tx, LegacyTransaction):
        pre = recover_legacy_rlp_transaction(tx)
        return compute_legacy_sig_hash(pre)

    assert isinstance(tx, ReplayableTransaction)
    pre = recover_replayable_rlp_transaction(tx)
    return compute_legacy_sig_hash(pre)

def compute_tx_hash(tx: AnyTransaction) -> Hash32:
    if (
        isinstance(tx, BasicTransaction) or
        isinstance(tx, BlobTransaction)
    ):
        return compute_ssz_tx_hash(tx.payload)

    if isinstance(tx, Eip4844Transaction):
        pre = recover_eip4844_rlp_transaction(tx)
        return compute_eip4844_tx_hash(pre)

    if isinstance(tx, Eip1559Transaction):
        pre = recover_eip1559_rlp_transaction(tx)
        return compute_eip1559_tx_hash(pre)

    if isinstance(tx, Eip2930Transaction):
        pre = recover_eip2930_rlp_transaction(tx)
        return compute_eip2930_tx_hash(pre)

    if isinstance(tx, LegacyTransaction):
        pre = recover_legacy_rlp_transaction(tx)
        return compute_legacy_tx_hash(pre)

    assert isinstance(tx, ReplayableTransaction)
    pre = recover_replayable_rlp_transaction(tx)
    return compute_legacy_tx_hash(pre)
