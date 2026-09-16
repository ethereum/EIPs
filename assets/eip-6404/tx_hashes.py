from rlp_types import *
from ssz_types import *

def recover_legacy_rlp_transaction(
    payload: RlpLegacyTransactionPayload,
    r, s, y_parity
) -> LegacyRlpTransaction:
    if hasattr(payload, "chain_id"):  # EIP-155
        v = uint256(y_parity) + 35 + payload.chain_id * 2
    else:
        v = uint256(y_parity) + 27
    return LegacyRlpTransaction(
        nonce=payload.nonce,
        gas_price=payload.max_fees_per_gas.regular,
        gas=payload.gas,
        to=bytes(payload.to if hasattr(payload, "to") else []),
        value=payload.value,
        data=bytes(payload.input_),
        v=v,
        r=r,
        s=s,
    )

def recover_access_list_rlp_transaction(
    payload: RlpAccessListTransactionPayload,
    r, s, y_parity
) -> AccessListRlpTransaction:
    return AccessListRlpTransaction(
        chain_id=payload.chain_id,
        nonce=payload.nonce,
        gas_price=payload.max_fees_per_gas.regular,
        gas=payload.gas,
        to=bytes(payload.to if hasattr(payload, "to") else []),
        value=payload.value,
        data=bytes(payload.input_),
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in payload.access_list],
        y_parity=y_parity,
        r=r,
        s=s,
    )

def recover_fee_market_rlp_transaction(
    payload: RlpFeeMarketTransactionPayload,
    r, s, y_parity
) -> FeeMarketRlpTransaction:
    return FeeMarketRlpTransaction(
        chain_id=payload.chain_id,
        nonce=payload.nonce,
        max_priority_fee_per_gas=payload.max_priority_fees_per_gas.regular,
        max_fee_per_gas=payload.max_fees_per_gas.regular,
        gas=payload.gas,
        to=bytes(payload.to if hasattr(payload, "to") else []),
        value=payload.value,
        data=bytes(payload.input_),
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in payload.access_list],
        y_parity=y_parity,
        r=r,
        s=s,
    )

def recover_blob_rlp_transaction(
    payload: RlpBlobTransactionPayload,
    r, s, y_parity
) -> BlobRlpTransaction:
    return BlobRlpTransaction(
        chain_id=payload.chain_id,
        nonce=payload.nonce,
        max_priority_fee_per_gas=payload.max_priority_fees_per_gas.regular,
        max_fee_per_gas=payload.max_fees_per_gas.regular,
        gas=payload.gas,
        to=payload.to,
        value=payload.value,
        data=bytes(payload.input_),
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in payload.access_list],
        max_fee_per_blob_gas=payload.max_fees_per_gas.blob,
        blob_versioned_hashes=payload.blob_versioned_hashes,
        y_parity=y_parity,
        r=r,
        s=s,
    )

def recover_set_code_rlp_authorization(
    payload: (
        RlpReplayableBasicAuthorizationPayload |
        RlpBasicAuthorizationPayload
    ),
    r, s, y_parity
) -> SetCodeRlpAuthorization:
    return SetCodeRlpAuthorization(
        chain_id=payload.chain_id if hasattr(payload, "chain_id") else 0,
        address=payload.address,
        nonce=payload.nonce,
        y_parity=y_parity,
        r=r,
        s=s,
    )

def recover_set_code_rlp_transaction(
    payload: RlpSetCodeTransactionPayload,
    r, s, y_parity
) -> SetCodeRlpTransaction:
    return SetCodeRlpTransaction(
        chain_id=payload.chain_id,
        nonce=payload.nonce,
        max_priority_fee_per_gas=payload.max_priority_fees_per_gas.regular,
        max_fee_per_gas=payload.max_fees_per_gas.regular,
        gas=payload.gas,
        to=payload.to,
        value=payload.value,
        data=bytes(payload.input_),
        access_list=[(
            access_tuple.address,
            access_tuple.storage_keys,
        ) for access_tuple in payload.access_list],
        authorization_list=[
            recover_set_code_rlp_authorization(
                auth.payload.data(),
                *secp256k1_unpack(auth.signature),
            ) for auth in payload.authorization_list
        ],
        y_parity=y_parity,
        r=r,
        s=s,
    )

def compute_sig_hash(tx) -> Hash32:
    tx_data = tx.payload.data()
    r, s, y_parity = secp256k1_unpack(tx.signature)

    if isinstance(tx_data, RlpSetCodeTransactionPayload):
        tx = recover_set_code_rlp_transaction(tx_data, r, s, y_parity)
        return compute_set_code_sig_hash(tx)

    if isinstance(tx_data, RlpBlobTransactionPayload):
        tx = recover_blob_rlp_transaction(tx_data, r, s, y_parity)
        return compute_blob_sig_hash(tx)

    if isinstance(tx_data, RlpFeeMarketTransactionPayload):
        tx = recover_fee_market_rlp_transaction(tx_data, r, s, y_parity)
        return compute_fee_market_sig_hash(tx)

    if isinstance(tx_data, RlpAccessListTransactionPayload):
        tx = recover_access_list_rlp_transaction(tx_data, r, s, y_parity)
        return compute_access_list_sig_hash(tx)

    if isinstance(tx_data, RlpLegacyTransactionPayload):
        tx = recover_legacy_rlp_transaction(tx_data, r, s, y_parity)
        return compute_legacy_sig_hash(tx)

    raise Exception(f'Unsupported transaction: {tx}')

def compute_tx_hash(tx) -> Hash32:
    tx_data = tx.payload.data()
    r, s, y_parity = secp256k1_unpack(tx.signature)

    if isinstance(tx_data, RlpSetCodeTransactionPayload):
        tx = recover_set_code_rlp_transaction(tx_data, r, s, y_parity)
        return compute_set_code_tx_hash(tx)

    if isinstance(tx_data, RlpBlobTransactionPayload):
        tx = recover_blob_rlp_transaction(tx_data, r, s, y_parity)
        return compute_blob_tx_hash(tx)

    if isinstance(tx_data, RlpFeeMarketTransactionPayload):
        tx = recover_fee_market_rlp_transaction(tx_data, r, s, y_parity)
        return compute_fee_market_tx_hash(tx)

    if isinstance(tx_data, RlpAccessListTransactionPayload):
        tx = recover_access_list_rlp_transaction(tx_data, r, s, y_parity)
        return compute_access_list_tx_hash(tx)

    if isinstance(tx_data, RlpLegacyTransactionPayload):
        tx = recover_legacy_rlp_transaction(tx_data, r, s, y_parity)
        return compute_legacy_tx_hash(tx)

    raise Exception(f'Unsupported transaction: {tx}')

def compute_auth_hash(auth) -> Hash32:
    auth_data = auth.payload.data()
    r, s, y_parity = secp256k1_unpack(auth.signature)

    if isinstance(auth_data, (
        RlpReplayableBasicAuthorizationPayload |
        RlpBasicAuthorizationPayload
    )):
        auth = recover_set_code_rlp_authorization(auth_data, r, s, y_parity)
        return compute_set_code_auth_hash(auth)

    raise Exception(f'Unsupported authorization: {auth}')
