from rlp_types import *
from ssz_types import *

def recover_legacy_rlp_transaction(
    tx: (
        RlpLegacyReplayableBasicTransaction |
        RlpLegacyReplayableCreateTransaction |
        RlpLegacyBasicTransaction |
        RlpLegacyCreateTransaction
    )
) -> LegacyRlpTransaction:
    r, s, y_parity = secp256k1_unpack(tx.signature)
    if hasattr(tx.payload, "chain_id"):  # EIP-155
        v = uint256(y_parity) + 35 + tx.payload.chain_id * 2
    else:
        v = uint256(y_parity) + 27
    return LegacyRlpTransaction(
        nonce=tx.payload.nonce,
        gas_price=tx.payload.max_fees_per_gas.regular,
        gas=tx.payload.gas,
        to=bytes(tx.payload.to if hasattr(tx.payload, "to") else []),
        value=tx.payload.value,
        data=bytes(tx.payload.input_),
        v=v,
        r=r,
        s=s,
    )

def recover_access_list_rlp_transaction(
    tx: (
        RlpAccessListBasicTransaction |
        RlpAccessListCreateTransaction
    )
) -> AccessListRlpTransaction:
    r, s, y_parity = secp256k1_unpack(tx.signature)
    return AccessListRlpTransaction(
        chain_id=tx.payload.chain_id,
        nonce=tx.payload.nonce,
        gas_price=tx.payload.max_fees_per_gas.regular,
        gas=tx.payload.gas,
        to=bytes(tx.payload.to if hasattr(tx.payload, "to") else []),
        value=tx.payload.value,
        data=bytes(tx.payload.input_),
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in tx.payload.access_list],
        y_parity=y_parity,
        r=r,
        s=s,
    )

def recover_fee_market_rlp_transaction(
    tx: (
        RlpBasicTransaction |
        RlpCreateTransaction
    )
) -> FeeMarketRlpTransaction:
    r, s, y_parity = secp256k1_unpack(tx.signature)
    return FeeMarketRlpTransaction(
        chain_id=tx.payload.chain_id,
        nonce=tx.payload.nonce,
        max_priority_fee_per_gas=tx.payload.max_priority_fees_per_gas.regular,
        max_fee_per_gas=tx.payload.max_fees_per_gas.regular,
        gas=tx.payload.gas,
        to=bytes(tx.payload.to if hasattr(tx.payload, "to") else []),
        value=tx.payload.value,
        data=bytes(tx.payload.input_),
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in tx.payload.access_list],
        y_parity=y_parity,
        r=r,
        s=s,
    )

def recover_blob_rlp_transaction(
    tx: RlpBlobTransaction
) -> BlobRlpTransaction:
    r, s, y_parity = secp256k1_unpack(tx.signature)
    return BlobRlpTransaction(
        chain_id=tx.payload.chain_id,
        nonce=tx.payload.nonce,
        max_priority_fee_per_gas=tx.payload.max_priority_fees_per_gas.regular,
        max_fee_per_gas=tx.payload.max_fees_per_gas.regular,
        gas=tx.payload.gas,
        to=tx.payload.to,
        value=tx.payload.value,
        data=bytes(tx.payload.input_),
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in tx.payload.access_list],
        max_fee_per_blob_gas=tx.payload.max_fees_per_gas.blob,
        blob_versioned_hashes=tx.payload.blob_versioned_hashes,
        y_parity=y_parity,
        r=r,
        s=s,
    )

def recover_set_code_rlp_authorization(
    auth: (
        RlpReplayableBasicAuthorization |
        RlpBasicAuthorization
    )
) -> SetCodeRlpAuthorization:
    r, s, y_parity = secp256k1_unpack(auth.signature)
    return SetCodeRlpAuthorization(
        chain_id=auth.payload.chain_id if hasattr(auth.payload, "chain_id") else 0,
        address=auth.payload.address,
        nonce=auth.payload.nonce,
        y_parity=y_parity,
        r=r,
        s=s,
    )

def recover_set_code_rlp_transaction(
    tx: RlpSetCodeTransaction
) -> SetCodeRlpTransaction:
    r, s, y_parity = secp256k1_unpack(tx.signature)
    return SetCodeRlpTransaction(
        chain_id=tx.payload.chain_id,
        nonce=tx.payload.nonce,
        max_priority_fee_per_gas=tx.payload.max_priority_fees_per_gas.regular,
        max_fee_per_gas=tx.payload.max_fees_per_gas.regular,
        gas=tx.payload.gas,
        to=tx.payload.to,
        value=tx.payload.value,
        data=bytes(tx.payload.input_),
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in tx.payload.access_list],
        authorization_list=[
            recover_set_code_rlp_authorization(auth.data())
            for auth in tx.payload.authorization_list
        ],
        y_parity=y_parity,
        r=r,
        s=s,
    )

def compute_sig_hash(tx) -> Hash32:
    tx_data = tx.data()

    if isinstance(tx_data, RlpSetCodeTransaction):
        tx = recover_set_code_rlp_transaction(tx_data)
        return compute_set_code_sig_hash(tx)

    if isinstance(tx_data, RlpBlobTransaction):
        tx = recover_blob_rlp_transaction(tx_data)
        return compute_blob_sig_hash(tx)

    if isinstance(tx_data, (
        RlpBasicTransaction |
        RlpCreateTransaction
    )):
        tx = recover_fee_market_rlp_transaction(tx_data)
        return compute_fee_market_sig_hash(tx)

    if isinstance(tx_data, (
        RlpAccessListBasicTransaction |
        RlpAccessListCreateTransaction
    )):
        tx = recover_access_list_rlp_transaction(tx_data)
        return compute_access_list_sig_hash(tx)

    if isinstance(tx_data, (
        RlpLegacyReplayableBasicTransaction |
        RlpLegacyReplayableCreateTransaction |
        RlpLegacyBasicTransaction |
        RlpLegacyCreateTransaction
    )):
        tx = recover_legacy_rlp_transaction(tx_data)
        return compute_legacy_sig_hash(tx)

    raise Exception(f'Unsupported transaction: {tx}')

def compute_tx_hash(tx) -> Hash32:
    tx_data = tx.data()

    if isinstance(tx_data, RlpSetCodeTransaction):
        tx = recover_set_code_rlp_transaction(tx_data)
        return compute_set_code_tx_hash(tx)

    if isinstance(tx_data, RlpBlobTransaction):
        tx = recover_blob_rlp_transaction(tx_data)
        return compute_blob_tx_hash(tx)

    if isinstance(tx_data, (
        RlpBasicTransaction |
        RlpCreateTransaction
    )):
        tx = recover_fee_market_rlp_transaction(tx_data)
        return compute_fee_market_tx_hash(tx)

    if isinstance(tx_data, (
        RlpAccessListBasicTransaction |
        RlpAccessListCreateTransaction
    )):
        tx = recover_access_list_rlp_transaction(tx_data)
        return compute_access_list_tx_hash(tx)

    if isinstance(tx_data, (
        RlpLegacyReplayableBasicTransaction |
        RlpLegacyReplayableCreateTransaction |
        RlpLegacyBasicTransaction |
        RlpLegacyCreateTransaction
    )):
        tx = recover_legacy_rlp_transaction(tx_data)
        return compute_legacy_tx_hash(tx)

    raise Exception(f'Unsupported transaction: {tx}')

def compute_auth_hash(auth) -> Hash32:
    auth_data = auth.data()

    if isinstance(auth_data, (
        RlpReplayableBasicAuthorization |
        RlpBasicAuthorization
    )):
        auth = recover_set_code_rlp_authorization(auth_data)
        return compute_set_code_auth_hash(auth)

    raise Exception(f'Unsupported authorization: {auth}')
