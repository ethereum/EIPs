from typing import List as PyList
from rlp import decode
from rlp_types import *
from ssz_types import *

def upgrade_rlp_transaction_to_ssz(pre_bytes: bytes) -> AnyTransaction:
    type_ = pre_bytes[0]

    if type_ == 0x03:  # EIP-4844
        pre = decode(pre_bytes[1:], Eip4844RlpTransaction)
        assert pre.signature_y_parity in (0, 1)
        ecdsa_signature = ecdsa_pack_signature(
            pre.signature_y_parity != 0,
            pre.signature_r,
            pre.signature_s,
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_eip4844_sig_hash(pre))

        return Eip4844Transaction(
            payload=Eip4844TransactionPayload(
                type_=TRANSACTION_TYPE_EIP4844,
                chain_id=pre.chain_id,
                nonce=pre.nonce,
                max_fees_per_gas=BlobFeesPerGas(
                    regular=pre.max_fee_per_gas,
                    blob=pre.max_fee_per_blob_gas,
                ),
                gas=pre.gas_limit,
                to=ExecutionAddress(pre.destination),
                value=pre.amount,
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
            signature=TransactionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
            ),
        )

    if type_ == 0x02:  # EIP-1559
        pre = decode(pre_bytes[1:], Eip1559RlpTransaction)
        assert pre.signature_y_parity in (0, 1)
        ecdsa_signature = ecdsa_pack_signature(
            pre.signature_y_parity != 0,
            pre.signature_r,
            pre.signature_s,
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_eip1559_sig_hash(pre))

        return Eip1559Transaction(
            payload=Eip1559TransactionPayload(
                type_=TRANSACTION_TYPE_EIP1559,
                chain_id=pre.chain_id,
                nonce=pre.nonce,
                max_fees_per_gas=BasicFeesPerGas(
                    regular=pre.max_fee_per_gas,
                ),
                gas=pre.gas_limit,
                to=ExecutionAddress(pre.destination) if len(pre.destination) > 0 else None,
                value=pre.amount,
                input_=pre.data,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1]
                ) for access_tuple in pre.access_list],
                max_priority_fees_per_gas=BasicFeesPerGas(
                    regular=pre.max_priority_fee_per_gas,
                ),
            ),
            signature=TransactionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
            ),
        )

    if type_ == 0x01:  # EIP-2930
        pre = decode(pre_bytes[1:], Eip2930RlpTransaction)
        assert pre.signatureYParity in (0, 1)
        ecdsa_signature = ecdsa_pack_signature(
            pre.signatureYParity != 0,
            pre.signatureR,
            pre.signatureS
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_eip2930_sig_hash(pre))

        return Eip2930Transaction(
            payload=Eip2930TransactionPayload(
                type_=TRANSACTION_TYPE_EIP2930,
                chain_id=pre.chainId,
                nonce=pre.nonce,
                max_fees_per_gas=BasicFeesPerGas(
                    regular=pre.gasPrice,
                ),
                gas=pre.gasLimit,
                to=ExecutionAddress(pre.to) if len(pre.to) > 0 else None,
                value=pre.value,
                input_=pre.data,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1]
                ) for access_tuple in pre.accessList],
            ),
            signature=TransactionSignature(
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
            return LegacyTransaction(
                payload=LegacyTransactionPayload(
                    type_=TRANSACTION_TYPE_LEGACY,
                    chain_id=chain_id,
                    nonce=pre.nonce,
                    max_fees_per_gas=BasicFeesPerGas(
                        regular=pre.gasprice,
                    ),
                    gas=pre.startgas,
                    to=ExecutionAddress(pre.to) if len(pre.to) > 0 else None,
                    value=pre.value,
                    input_=pre.data,
                ),
                signature=TransactionSignature(
                    from_=from_,
                    ecdsa_signature=ecdsa_signature,
                ),
            )

        return ReplayableTransaction(
            payload=ReplayableTransactionPayload(
                type_=TRANSACTION_TYPE_LEGACY,
                nonce=pre.nonce,
                max_fees_per_gas=BasicFeesPerGas(
                    regular=pre.gasprice,
                ),
                gas=pre.startgas,
                to=ExecutionAddress(pre.to) if len(pre.to) > 0 else None,
                value=pre.value,
                input_=pre.data,
            ),
            signature=TransactionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
            ),
        )

    assert False

class ContractAddressData(Serializable):
    fields = (
        ('from_', Binary(20, 20)),
        ('nonce', big_endian_int),
    )

def compute_contract_address(from_: ExecutionAddress,
                             nonce: uint64) -> ExecutionAddress:
    return ExecutionAddress(keccak(encode(ContractAddressData(
        from_=from_,
        nonce=nonce,
    )))[12:32])

def upgrade_rlp_receipt_to_ssz(pre_bytes: bytes,
                               prev_cumulative_gas_used: uint64,
                               transaction: AnyTransaction) -> AnyReceipt:
    type_ = pre_bytes[0]

    if type_ in (0x03, 0x02, 0x01):  # EIP-4844, EIP-1559, EIP-2930
        pre = decode(pre_bytes[1:], RlpReceipt)
    elif 0xc0 <= type_ <= 0xfe:  # Legacy
        pre = decode(pre_bytes, RlpReceipt)
    else:
        assert False

    if len(pre.post_state_or_status) != 32:
        status = len(pre.post_state_or_status) > 0 and pre.post_state_or_status[0] != 0

        return BasicReceipt(
            gas_used=pre.cumulative_gas_used - prev_cumulative_gas_used,
            contract_address=compute_contract_address(
                transaction.signature.from_,
                transaction.payload.nonce,
            ) if transaction.payload.to is None else None,
            logs_bloom=pre.logs_bloom,
            logs=[Log(
                address=log[0],
                topics=log[1],
                data=log[2],
            ) for log in pre.logs],
            status=status,
        )

    root = pre.post_state_or_status
    return HomesteadReceipt(
        root=root,
        gas_used=pre.cumulative_gas_used - prev_cumulative_gas_used,
        contract_address=compute_contract_address(
            transaction.signature.from_,
            transaction.payload.nonce,
        ) if transaction.payload.to is None else None,
        logs_bloom=pre.logs_bloom,
        logs=[Log(
            address=log[0],
            topics=log[1],
            data=log[2],
        ) for log in pre.logs],
    )

def upgrade_rlp_receipts_to_ssz(pre_bytes_list: PyList[bytes],
                                transactions: PyList[AnyTransaction]) -> PyList[AnyReceipt]:
    receipts = []
    cumulative_gas_used = 0
    for i, pre_bytes in enumerate(pre_bytes_list):
        receipt = upgrade_rlp_receipt_to_ssz(pre_bytes, cumulative_gas_used, transactions[i])
        cumulative_gas_used += receipt.gas_used
        receipts.append(receipt)
    return receipts
