from rlp import decode
from rlp_types import *
from ssz_types import *

def upgrade_rlp_transaction_to_ssz(tx_bytes: bytes):
    type_ = tx_bytes[0]

    if type_ == 0x04:  # EIP-7702
        tx = decode(tx_bytes[1:], SetCodeRlpTransaction)

        def upgrade_authorization(auth: SetCodeRlpAuthorization):
            if auth.chain_id != 0:
                return RlpSetCodeAuthorization(
                    payload=RlpSetCodeAuthorizationPayload(
                        selector=0x02,
                        data=RlpBasicAuthorizationPayload(
                            magic=RlpTxType.SET_CODE_MAGIC,
                            chain_id=auth.chain_id,
                            address=ExecutionAddress(auth.address),
                            nonce=auth.nonce,
                        ),
                    ),
                    signature=secp256k1_pack(auth.r, auth.s, auth.y_parity),
                )
            return RlpSetCodeAuthorization(
                payload=RlpSetCodeAuthorizationPayload(
                    selector=0x01,
                    data=RlpReplayableBasicAuthorizationPayload(
                        magic=RlpTxType.SET_CODE_MAGIC,
                        address=ExecutionAddress(auth.address),
                        nonce=auth.nonce,
                    ),
                ),
                signature=secp256k1_pack(auth.r, auth.s, auth.y_parity),
            )

        return Transaction(
            payload=TransactionPayload(
                selector=0x0a,
                data=RlpSetCodeTransactionPayload(
                    type_=RlpTxType.SET_CODE,
                    chain_id=tx.chain_id,
                    nonce=tx.nonce,
                    max_fees_per_gas=BasicFeesPerGas(
                        regular=tx.max_fee_per_gas,
                    ),
                    gas=tx.gas,
                    to=ExecutionAddress(tx.to),
                    value=tx.value,
                    input_=tx.data,
                    access_list=[AccessTuple(
                        address=access_tuple[0],
                        storage_keys=access_tuple[1]
                    ) for access_tuple in tx.access_list],
                    max_priority_fees_per_gas=BasicFeesPerGas(
                        regular=tx.max_priority_fee_per_gas,
                    ),
                    authorization_list=[
                        upgrade_authorization(auth)
                        for auth in tx.authorization_list
                    ],
                ),
            ),
            signature=secp256k1_pack(tx.r, tx.s, tx.y_parity),
        )

    if type_ == 0x03:  # EIP-4844
        tx = decode(tx_bytes[1:], BlobRlpTransaction)
        return Transaction(
            payload=TransactionPayload(
                selector=0x09,
                data=RlpBlobTransactionPayload(
                    type_=RlpTxType.BLOB,
                    chain_id=tx.chain_id,
                    nonce=tx.nonce,
                    max_fees_per_gas=BlobFeesPerGas(
                        regular=tx.max_fee_per_gas,
                        blob=tx.max_fee_per_blob_gas,
                    ),
                    gas=tx.gas,
                    to=ExecutionAddress(tx.to),
                    value=tx.value,
                    input_=tx.data,
                    access_list=[AccessTuple(
                        address=access_tuple[0],
                        storage_keys=access_tuple[1]
                    ) for access_tuple in tx.access_list],
                    max_priority_fees_per_gas=BlobFeesPerGas(
                        regular=tx.max_priority_fee_per_gas,
                        blob=FeePerGas(0),
                    ),
                    blob_versioned_hashes=tx.blob_versioned_hashes,
                ),
            ),
            signature=secp256k1_pack(tx.r, tx.s, tx.y_parity),
        )

    if type_ == 0x02:  # EIP-1559
        tx = decode(tx_bytes[1:], FeeMarketRlpTransaction)
        if len(tx.to) == 0:
            return Transaction(
                payload=TransactionPayload(
                    selector=0x08,
                    data=RlpCreateTransactionPayload(
                        type_=RlpTxType.FEE_MARKET,
                        chain_id=tx.chain_id,
                        nonce=tx.nonce,
                        max_fees_per_gas=BasicFeesPerGas(
                            regular=tx.max_fee_per_gas,
                        ),
                        gas=tx.gas,
                        value=tx.value,
                        input_=tx.data,
                        access_list=[AccessTuple(
                            address=access_tuple[0],
                            storage_keys=access_tuple[1]
                        ) for access_tuple in tx.access_list],
                        max_priority_fees_per_gas=BasicFeesPerGas(
                            regular=tx.max_priority_fee_per_gas,
                        ),
                    ),
                ),
                signature=secp256k1_pack(tx.r, tx.s, tx.y_parity),
            )
        return Transaction(
            payload=TransactionPayload(
                selector=0x07,
                data=RlpBasicTransactionPayload(
                    type_=RlpTxType.FEE_MARKET,
                    chain_id=tx.chain_id,
                    nonce=tx.nonce,
                    max_fees_per_gas=BasicFeesPerGas(
                        regular=tx.max_fee_per_gas,
                    ),
                    gas=tx.gas,
                    to=ExecutionAddress(tx.to),
                    value=tx.value,
                    input_=tx.data,
                    access_list=[AccessTuple(
                        address=access_tuple[0],
                        storage_keys=access_tuple[1]
                    ) for access_tuple in tx.access_list],
                    max_priority_fees_per_gas=BasicFeesPerGas(
                        regular=tx.max_priority_fee_per_gas,
                    ),
                ),
            ),
            signature=secp256k1_pack(tx.r, tx.s, tx.y_parity),
        )

    if type_ == 0x01:  # EIP-2930
        tx = decode(tx_bytes[1:], AccessListRlpTransaction)
        if len(tx.to) == 0:
            return Transaction(
                payload=TransactionPayload(
                    selector=0x06,
                    data=RlpAccessListCreateTransactionPayload(
                        type_=RlpTxType.ACCESS_LIST,
                        chain_id=tx.chain_id,
                        nonce=tx.nonce,
                        max_fees_per_gas=BasicFeesPerGas(
                            regular=tx.gas_price,
                        ),
                        gas=tx.gas,
                        value=tx.value,
                        input_=tx.data,
                        access_list=[AccessTuple(
                            address=access_tuple[0],
                            storage_keys=access_tuple[1]
                        ) for access_tuple in tx.access_list],
                    ),
                ),
                signature=secp256k1_pack(tx.r, tx.s, tx.y_parity),
            )
        return Transaction(
            payload=TransactionPayload(
                selector=0x05,
                data=RlpAccessListBasicTransactionPayload(
                    type_=RlpTxType.ACCESS_LIST,
                    chain_id=tx.chain_id,
                    nonce=tx.nonce,
                    max_fees_per_gas=BasicFeesPerGas(
                        regular=tx.gas_price,
                    ),
                    gas=tx.gas,
                    to=ExecutionAddress(tx.to),
                    value=tx.value,
                    input_=tx.data,
                    access_list=[AccessTuple(
                        address=access_tuple[0],
                        storage_keys=access_tuple[1]
                    ) for access_tuple in tx.access_list],
                ),
            ),
            signature=secp256k1_pack(tx.r, tx.s, tx.y_parity),
        )

    if 0xc0 <= type_ <= 0xfe:  # Legacy
        tx = decode(tx_bytes, LegacyRlpTransaction)
        if tx.v not in (27, 28):
            if len(tx.to) == 0:
                return Transaction(
                    payload=TransactionPayload(
                        selector=0x04,
                        data=RlpLegacyCreateTransactionPayload(
                            type_=RlpTxType.LEGACY,
                            chain_id=(tx.v - 35) >> 1,
                            nonce=tx.nonce,
                            max_fees_per_gas=BasicFeesPerGas(
                                regular=tx.gas_price,
                            ),
                            gas=tx.gas,
                            value=tx.value,
                            input_=tx.data,
                        ),
                    ),
                    signature=secp256k1_pack(tx.r, tx.s, y_parity=(tx.v & 0x1) == 0),
                )
            return Transaction(
                payload=TransactionPayload(
                    selector=0x03,
                    data=RlpLegacyBasicTransactionPayload(
                        type_=RlpTxType.LEGACY,
                        chain_id=(tx.v - 35) >> 1,
                        nonce=tx.nonce,
                        max_fees_per_gas=BasicFeesPerGas(
                            regular=tx.gas_price,
                        ),
                        gas=tx.gas,
                        to=ExecutionAddress(tx.to),
                        value=tx.value,
                        input_=tx.data,
                    ),
                ),
                signature=secp256k1_pack(tx.r, tx.s, y_parity=(tx.v & 0x1) == 0),
            )
        if len(tx.to) == 0:
            return Transaction(
                payload=TransactionPayload(
                    selector=0x02,
                    data=RlpLegacyReplayableCreateTransactionPayload(
                        type_=RlpTxType.LEGACY,
                        nonce=tx.nonce,
                        max_fees_per_gas=BasicFeesPerGas(
                            regular=tx.gas_price,
                        ),
                        gas=tx.gas,
                        value=tx.value,
                        input_=tx.data,
                    ),
                ),
                signature=secp256k1_pack(tx.r, tx.s, y_parity=(tx.v & 0x1) == 0),
            )
        return Transaction(
            payload=TransactionPayload(
                selector=0x01,
                data=RlpLegacyReplayableBasicTransactionPayload(
                    type_=RlpTxType.LEGACY,
                    nonce=tx.nonce,
                    max_fees_per_gas=BasicFeesPerGas(
                        regular=tx.gas_price,
                    ),
                    gas=tx.gas,
                    to=ExecutionAddress(tx.to),
                    value=tx.value,
                    input_=tx.data,
                ),
            ),
            signature=secp256k1_pack(tx.r, tx.s, y_parity=(tx.v & 0x1) == 0),
        )

    assert False
