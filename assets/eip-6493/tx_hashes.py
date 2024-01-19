from rlp_types import *
from ssz_types import *

def recover_replayable_rlp_transaction(tx: ReplayableSignedTransaction,
                                       chain_id: ChainId) -> LegacySignedRlpTransaction:
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)
    v = uint256(1 if y_parity else 0) + 27

    return LegacySignedRlpTransaction(
        nonce=tx.payload.nonce,
        gasprice=tx.payload.max_fee_per_gas,
        startgas=tx.payload.gas,
        to=bytes(tx.payload.to if tx.payload.to is not None else []),
        value=tx.payload.value,
        data=tx.payload.input_,
        v=v,
        r=r,
        s=s,
    )

def recover_legacy_rlp_transaction(tx: LegacySignedTransaction,
                                   chain_id: ChainId) -> LegacySignedRlpTransaction:
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)
    v = uint256(1 if y_parity else 0) + 35 + chain_id * 2

    return LegacySignedRlpTransaction(
        nonce=tx.payload.nonce,
        gasprice=tx.payload.max_fee_per_gas,
        startgas=tx.payload.gas,
        to=bytes(tx.payload.to if tx.payload.to is not None else []),
        value=tx.payload.value,
        data=tx.payload.input_,
        v=v,
        r=r,
        s=s,
    )

def recover_eip2930_rlp_transaction(tx: Eip2930SignedTransaction,
                                    chain_id: ChainId) -> Eip2930SignedRlpTransaction:
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)

    return Eip2930SignedRlpTransaction(
        chainId=chain_id,
        nonce=tx.payload.nonce,
        gasPrice=tx.payload.max_fee_per_gas,
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

def recover_eip1559_rlp_transaction(tx: Eip1559SignedTransaction,
                                    chain_id: ChainId) -> Eip1559SignedRlpTransaction:
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)

    return Eip1559SignedRlpTransaction(
        chain_id=chain_id,
        nonce=tx.payload.nonce,
        max_priority_fee_per_gas=tx.payload.max_priority_fee_per_gas,
        max_fee_per_gas=tx.payload.max_fee_per_gas,
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

def recover_eip4844_rlp_transaction(tx: Eip4844SignedTransaction,
                                    chain_id: ChainId) -> Eip4844SignedRlpTransaction:
    y_parity, r, s = ecdsa_unpack_signature(tx.signature.ecdsa_signature)

    return Eip4844SignedRlpTransaction(
        chain_id=chain_id,
        nonce=tx.payload.nonce,
        max_priority_fee_per_gas=tx.payload.max_priority_fee_per_gas,
        max_fee_per_gas=tx.payload.max_fee_per_gas,
        gas_limit=tx.payload.gas,
        to=tx.payload.to,
        value=tx.payload.value,
        data=tx.payload.input_,
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in tx.payload.access_list],
        max_fee_per_blob_gas=tx.payload.max_fee_per_blob_gas,
        blob_versioned_hashes=tx.payload.blob_versioned_hashes,
        signature_y_parity=1 if y_parity else 0,
        signature_r=r,
        signature_s=s,
    )

def compute_sig_hash(tx: AnySignedTransaction,
                     chain_id: ChainId) -> Hash32:
    if (
        isinstance(tx, BasicSignedTransaction) or
        isinstance(tx, BlobSignedTransaction)
    ):
        return compute_ssz_sig_hash(tx.payload, chain_id)

    if isinstance(tx, Eip4844SignedTransaction):
        pre = recover_eip4844_rlp_transaction(tx, chain_id)
        return compute_eip4844_sig_hash(pre)

    if isinstance(tx, Eip1559SignedTransaction):
        pre = recover_eip1559_rlp_transaction(tx, chain_id)
        return compute_eip1559_sig_hash(pre)

    if isinstance(tx, Eip2930SignedTransaction):
        pre = recover_eip2930_rlp_transaction(tx, chain_id)
        return compute_eip2930_sig_hash(pre)

    if isinstance(tx, LegacySignedTransaction):
        pre = recover_legacy_rlp_transaction(tx, chain_id)
        return compute_legacy_sig_hash(pre)

    assert isinstance(tx, ReplayableSignedTransaction)
    pre = recover_replayable_rlp_transaction(tx, chain_id)
    return compute_legacy_sig_hash(pre)

def compute_tx_hash(tx: AnySignedTransaction,
                    chain_id: ChainId) -> Hash32:
    if (
        isinstance(tx, BasicSignedTransaction) or
        isinstance(tx, BlobSignedTransaction)
    ):
        return compute_ssz_tx_hash(tx.payload, chain_id)

    if isinstance(tx, Eip4844SignedTransaction):
        pre = recover_eip4844_rlp_transaction(tx, chain_id)
        return compute_eip4844_tx_hash(pre)

    if isinstance(tx, Eip1559SignedTransaction):
        pre = recover_eip1559_rlp_transaction(tx, chain_id)
        return compute_eip1559_tx_hash(pre)

    if isinstance(tx, Eip2930SignedTransaction):
        pre = recover_eip2930_rlp_transaction(tx, chain_id)
        return compute_eip2930_tx_hash(pre)

    if isinstance(tx, LegacySignedTransaction):
        pre = recover_legacy_rlp_transaction(tx, chain_id)
        return compute_legacy_tx_hash(pre)

    assert isinstance(tx, ReplayableSignedTransaction)
    pre = recover_replayable_rlp_transaction(tx, chain_id)
    return compute_legacy_tx_hash(pre)
