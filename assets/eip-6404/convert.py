from rlp import decode
from rlp_types import *
from ssz_types import *

def upgrade_rlp_transaction_to_ssz(pre_bytes: bytes):
    type_ = pre_bytes[0]

    if type_ == 0x03:  # EIP-4844
        pre = decode(pre_bytes[1:], BlobRlpTransaction)
        assert pre.y_parity in (0, 1)
        ecdsa_signature = ecdsa_pack_signature(
            pre.y_parity != 0,
            pre.r,
            pre.s,
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_blob_sig_hash(pre))

        return RlpBlobTransaction(
            payload=RlpBlobTransactionPayload(
                type_=BLOB_TX_TYPE,
                chain_id=pre.chain_id,
                nonce=pre.nonce,
                max_fees_per_gas=BlobFeesPerGas(
                    regular=pre.max_fee_per_gas,
                    blob=pre.max_fee_per_blob_gas,
                ),
                gas=pre.gas,
                to=ExecutionAddress(pre.to),
                value=pre.value,
                input_=pre.data,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1]
                ) for access_tuple in pre.access_list],
                max_priority_fees_per_gas=BlobFeesPerGas(
                    regular=pre.max_priority_fee_per_gas,
                    blob=FeePerGas(0),
                ),
                blob_versioned_hashes=pre.blob_versioned_hashes,
            ),
            signature=EcdsaExecutionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
            ),
        )

    if type_ == 0x02:  # EIP-1559
        pre = decode(pre_bytes[1:], FeeMarketRlpTransaction)
        assert pre.y_parity in (0, 1)
        ecdsa_signature = ecdsa_pack_signature(
            pre.y_parity != 0,
            pre.r,
            pre.s,
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_fee_market_sig_hash(pre))

        return RlpFeeMarketTransaction(
            payload=RlpFeeMarketTransactionPayload(
                type_=FEE_MARKET_TX_TYPE,
                chain_id=pre.chain_id,
                nonce=pre.nonce,
                max_fees_per_gas=BasicFeesPerGas(
                    regular=pre.max_fee_per_gas,
                ),
                gas=pre.gas,
                to=ExecutionAddress(pre.to) if len(pre.to) > 0 else None,
                value=pre.value,
                input_=pre.data,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1]
                ) for access_tuple in pre.access_list],
                max_priority_fees_per_gas=BasicFeesPerGas(
                    regular=pre.max_priority_fee_per_gas,
                ),
            ),
            signature=EcdsaExecutionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
            ),
        )

    if type_ == 0x01:  # EIP-2930
        pre = decode(pre_bytes[1:], AccessListRlpTransaction)
        assert pre.y_parity in (0, 1)
        ecdsa_signature = ecdsa_pack_signature(
            pre.y_parity != 0,
            pre.r,
            pre.s
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_access_list_sig_hash(pre))

        return RlpAccessListTransaction(
            payload=RlpAccessListTransactionPayload(
                type_=ACCESS_LIST_TX_TYPE,
                chain_id=pre.chain_id,
                nonce=pre.nonce,
                max_fees_per_gas=BasicFeesPerGas(
                    regular=pre.gas_price,
                ),
                gas=pre.gas,
                to=ExecutionAddress(pre.to) if len(pre.to) > 0 else None,
                value=pre.value,
                input_=pre.data,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1]
                ) for access_tuple in pre.access_list],
            ),
            signature=EcdsaExecutionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
            ),
        )

    if 0xc0 <= type_ <= 0xfe:  # Legacy
        pre = decode(pre_bytes, LegacyRlpTransaction)
        ecdsa_signature = ecdsa_pack_signature(
            (pre.v & 0x1) == 0,
            pre.r,
            pre.s,
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_legacy_sig_hash(pre))

        if (pre.v not in (27, 28)):  # EIP-155
            chain_id = ((pre.v - 35) >> 1)
        else:
            chain_id = None

        return RlpLegacyTransaction(
            payload=RlpLegacyTransactionPayload(
                type_=LEGACY_TX_TYPE,
                chain_id=chain_id,
                nonce=pre.nonce,
                max_fees_per_gas=BasicFeesPerGas(
                    regular=pre.gas_price,
                ),
                gas=pre.gas,
                to=ExecutionAddress(pre.to) if len(pre.to) > 0 else None,
                value=pre.value,
                input_=pre.data,
            ),
            signature=EcdsaExecutionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
            ),
        )

    assert False
