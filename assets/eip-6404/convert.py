from rlp import decode
from rlp_types import *
from ssz_types import *

def upgrade_rlp_transaction_to_ssz(tx_bytes: bytes):
    type_ = tx_bytes[0]

    if type_ == 0x04:  # EIP-7702
        tx = decode(tx_bytes[1:], SetCodeRlpTransaction)
        return RlpSetCodeTransaction(
            payload=RlpSetCodeTransactionPayload(
                type_=SET_CODE_TX_TYPE,
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
                authorization_list=[RlpSetCodeAuthorization(
                    payload=RlpSetCodeAuthorizationPayload(
                        magic=SET_CODE_TX_MAGIC,
                        chain_id=auth.chain_id if auth.chain_id != 0 else None,
                        address=ExecutionAddress(auth.address),
                        nonce=auth.nonce,
                    ),
                    signature=Secp256k1ExecutionSignature(
                        secp256k1=secp256k1_pack(auth.r, auth.s, auth.y_parity),
                    ),
                ).to_base(Authorization) for auth in tx.authorization_list],
            ),
            signature=Secp256k1ExecutionSignature(
                secp256k1=secp256k1_pack(tx.r, tx.s, tx.y_parity),
            ),
        )

    if type_ == 0x03:  # EIP-4844
        tx = decode(tx_bytes[1:], BlobRlpTransaction)
        return RlpBlobTransaction(
            payload=RlpBlobTransactionPayload(
                type_=BLOB_TX_TYPE,
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
            signature=Secp256k1ExecutionSignature(
                secp256k1=secp256k1_pack(tx.r, tx.s, tx.y_parity),
            ),
        )

    if type_ == 0x02:  # EIP-1559
        tx = decode(tx_bytes[1:], FeeMarketRlpTransaction)
        return RlpFeeMarketTransaction(
            payload=RlpFeeMarketTransactionPayload(
                type_=FEE_MARKET_TX_TYPE,
                chain_id=tx.chain_id,
                nonce=tx.nonce,
                max_fees_per_gas=BasicFeesPerGas(
                    regular=tx.max_fee_per_gas,
                ),
                gas=tx.gas,
                to=ExecutionAddress(tx.to) if len(tx.to) > 0 else None,
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
            signature=Secp256k1ExecutionSignature(
                secp256k1=secp256k1_pack(tx.r, tx.s, tx.y_parity),
            ),
        )

    if type_ == 0x01:  # EIP-2930
        tx = decode(tx_bytes[1:], AccessListRlpTransaction)
        return RlpAccessListTransaction(
            payload=RlpAccessListTransactionPayload(
                type_=ACCESS_LIST_TX_TYPE,
                chain_id=tx.chain_id,
                nonce=tx.nonce,
                max_fees_per_gas=BasicFeesPerGas(
                    regular=tx.gas_price,
                ),
                gas=tx.gas,
                to=ExecutionAddress(tx.to) if len(tx.to) > 0 else None,
                value=tx.value,
                input_=tx.data,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1]
                ) for access_tuple in tx.access_list],
            ),
            signature=Secp256k1ExecutionSignature(
                secp256k1=secp256k1_pack(tx.r, tx.s, tx.y_parity),
            ),
        )

    if 0xc0 <= type_ <= 0xfe:  # Legacy
        tx = decode(tx_bytes, LegacyRlpTransaction)
        return RlpLegacyTransaction(
            payload=RlpLegacyTransactionPayload(
                type_=LEGACY_TX_TYPE,
                chain_id=((tx.v - 35) >> 1) if tx.v not in (27, 28) else None,
                nonce=tx.nonce,
                max_fees_per_gas=BasicFeesPerGas(
                    regular=tx.gas_price,
                ),
                gas=tx.gas,
                to=ExecutionAddress(tx.to) if len(tx.to) > 0 else None,
                value=tx.value,
                input_=tx.data,
            ),
            signature=Secp256k1ExecutionSignature(
                secp256k1=secp256k1_pack(tx.r, tx.s, y_parity=(tx.v & 0x1) == 0),
            ),
        )

    assert False
