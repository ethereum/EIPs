from typing import List as PyList
from rlp import decode
from rlp_types import *
from ssz_types import *

def upgrade_rlp_transaction_to_ssz(pre_bytes: bytes,
                                   chain_id: ChainId) -> SignedTransaction:
    type_ = pre_bytes[0]

    if type_ == 0x03:  # EIP-4844
        pre = decode(pre_bytes[1:], Eip4844SignedTransaction)
        assert pre.chain_id == chain_id

        assert pre.signature_y_parity in (0, 1)
        ecdsa_signature = ecdsa_pack_signature(
            pre.signature_y_parity != 0,
            pre.signature_r,
            pre.signature_s,
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_eip4844_sig_hash(pre))

        return SignedTransaction(
            payload=TransactionPayload(
                nonce=pre.nonce,
                max_fee_per_gas=pre.max_fee_per_gas,
                gas=pre.gas_limit,
                to=ExecutionAddress(pre.destination),
                value=pre.amount,
                input_=pre.data,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1]
                ) for access_tuple in pre.access_list],
                max_priority_fee_per_gas=pre.max_priority_fee_per_gas,
                max_fee_per_blob_gas=pre.max_fee_per_blob_gas,
                blob_versioned_hashes=pre.blob_versioned_hashes,
            ),
            signature=TransactionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
                type_=TRANSACTION_TYPE_EIP4844,
            ),
        )

    if type_ == 0x02:  # EIP-1559
        pre = decode(pre_bytes[1:], Eip1559SignedTransaction)
        assert pre.chain_id == chain_id

        assert pre.signature_y_parity in (0, 1)
        ecdsa_signature = ecdsa_pack_signature(
            pre.signature_y_parity != 0,
            pre.signature_r,
            pre.signature_s,
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_eip1559_sig_hash(pre))

        return SignedTransaction(
            payload=TransactionPayload(
                nonce=pre.nonce,
                max_fee_per_gas=pre.max_fee_per_gas,
                gas=pre.gas_limit,
                to=ExecutionAddress(pre.destination) if len(pre.destination) > 0 else None,
                value=pre.amount,
                input_=pre.data,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1]
                ) for access_tuple in pre.access_list],
                max_priority_fee_per_gas=pre.max_priority_fee_per_gas,
            ),
            signature=TransactionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
                type_=TRANSACTION_TYPE_EIP1559,
            ),
        )

    if type_ == 0x01:  # EIP-2930
        pre = decode(pre_bytes[1:], Eip2930SignedTransaction)
        assert pre.chainId == chain_id

        assert pre.signatureYParity in (0, 1)
        ecdsa_signature = ecdsa_pack_signature(
            pre.signatureYParity != 0,
            pre.signatureR,
            pre.signatureS
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_eip2930_sig_hash(pre))

        return SignedTransaction(
            payload=TransactionPayload(
                nonce=pre.nonce,
                max_fee_per_gas=pre.gasPrice,
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
                type_=TRANSACTION_TYPE_EIP2930,
            ),
        )

    if 0xc0 <= type_ <= 0xfe:  # Legacy
        pre = decode(pre_bytes, LegacySignedTransaction)

        if pre.v not in (27, 28):  # EIP-155
            assert pre.v in (2 * chain_id + 35, 2 * chain_id + 36)
        ecdsa_signature = ecdsa_pack_signature(
            (pre.v & 0x1) == 0,
            pre.r,
            pre.s,
        )
        from_ = ecdsa_recover_from_address(ecdsa_signature, compute_legacy_sig_hash(pre))

        return SignedTransaction(
            payload=TransactionPayload(
                nonce=pre.nonce,
                max_fee_per_gas=pre.gasprice,
                gas=pre.startgas,
                to=ExecutionAddress(pre.to) if len(pre.to) > 0 else None,
                value=pre.value,
                input_=pre.data,
            ),
            signature=TransactionSignature(
                from_=from_,
                ecdsa_signature=ecdsa_signature,
                type_=TRANSACTION_TYPE_LEGACY if (pre.v not in (27, 28)) else None,
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
                               transaction: SignedTransaction) -> Receipt:
    type_ = pre_bytes[0]

    if type_ in (0x03, 0x02, 0x01):  # EIP-4844, EIP-1559, EIP-2930
        pre = decode(pre_bytes[1:], RlpReceipt)
    elif 0xc0 <= type_ <= 0xfe:  # Legacy
        pre = decode(pre_bytes, RlpReceipt)
    else:
        assert False

    if len(pre.post_state_or_status) == 32:
        root = pre.post_state_or_status
        status = None
    else:
        root = None
        status = len(pre.post_state_or_status) > 0 and pre.post_state_or_status[0] != 0

    return Receipt(
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
        status=status,
    )

def upgrade_rlp_receipts_to_ssz(pre_bytes_list: PyList[bytes],
                                chain_id: ChainId,
                                transactions: PyList[SignedTransaction]) -> PyList[Receipt]:
    receipts = []
    cumulative_gas_used = 0
    for i, pre_bytes in enumerate(pre_bytes_list):
        receipt = upgrade_rlp_receipt_to_ssz(pre_bytes, cumulative_gas_used, transactions[i])
        cumulative_gas_used += receipt.gas_used
        receipts.append(receipt)
    return receipts
