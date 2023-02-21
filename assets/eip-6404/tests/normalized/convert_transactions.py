from rlp import decode
from snappy import compress
from ssz_tx_types import *
from create_transactions import *

def normalize_signed_transaction(encoded_signed_tx: bytes, cfg: ExecutionConfig) -> Transaction:
    eip2718_type = encoded_signed_tx[0]

    if eip2718_type == 0x05:  # EIP-4844
        signed_tx = BlobTransactionNetworkWrapper.decode_bytes(encoded_signed_tx[1:]).tx
        assert signed_tx.message.chain_id == cfg.chain_id

        signature = ecdsa_pack_signature(
            signed_tx.signature.y_parity,
            signed_tx.signature.r,
            signed_tx.signature.s,
        )
        tx_from = ecdsa_recover_tx_from(signature, compute_eip4844_sig_hash(signed_tx))
        match signed_tx.message.to.selector():
            case 1:
                tx_to = DestinationAddress(
                    destination_type=DESTINATION_TYPE_REGULAR,
                    address=signed_tx.message.to.value(),
                )
            case 0:
                tx_to = DestinationAddress(
                    destination_type=DESTINATION_TYPE_CREATE,
                    address=compute_contract_address(tx_from, signed_tx.message.nonce),
                )

        return Transaction(
            payload=TransactionPayload(
                tx_from=tx_from,
                nonce=signed_tx.message.nonce,
                tx_to=tx_to,
                tx_value=signed_tx.message.value,
                tx_input=signed_tx.message.data,
                limits=TransactionLimits(
                    max_priority_fee_per_gas=signed_tx.message.max_priority_fee_per_gas,
                    max_fee_per_gas=signed_tx.message.max_fee_per_gas,
                    gas=signed_tx.message.gas,
                ),
                sig_type=TransactionSignatureType(
                    tx_type=TRANSACTION_TYPE_EIP4844,
                ),
                signature=signature,
                access_list=signed_tx.message.access_list,
                blob=Optional[BlobDetails](BlobDetails(
                    max_fee_per_data_gas=signed_tx.message.max_fee_per_data_gas,
                    blob_versioned_hashes=signed_tx.message.blob_versioned_hashes,
                )),
            ),
            tx_hash=compute_eip4844_tx_hash(signed_tx),
        )

    if eip2718_type == 0x02:  # EIP-1559
        signed_tx = decode(encoded_signed_tx[1:], EIP1559SignedTransaction)
        assert signed_tx.chain_id == cfg.chain_id

        assert signed_tx.signature_y_parity in (0, 1)
        signature = ecdsa_pack_signature(
            signed_tx.signature_y_parity != 0,
            signed_tx.signature_r,
            signed_tx.signature_s,
        )
        tx_from = ecdsa_recover_tx_from(signature, compute_eip1559_sig_hash(signed_tx))
        if len(signed_tx.destination) != 0:
            tx_to = DestinationAddress(
                destination_type=DESTINATION_TYPE_REGULAR,
                address=ExecutionAddress(signed_tx.destination),
            )
        else:
            tx_to = DestinationAddress(
                destination_type=DESTINATION_TYPE_CREATE,
                address=compute_contract_address(tx_from, signed_tx.nonce),
            )

        return Transaction(
            payload=TransactionPayload(
                tx_from=tx_from,
                nonce=signed_tx.nonce,
                tx_to=tx_to,
                tx_value=signed_tx.amount,
                tx_input=signed_tx.data,
                limits=TransactionLimits(
                    max_priority_fee_per_gas=signed_tx.max_priority_fee_per_gas,
                    max_fee_per_gas=signed_tx.max_fee_per_gas,
                    gas=signed_tx.gas_limit,
                ),
                sig_type=TransactionSignatureType(
                    tx_type=TRANSACTION_TYPE_EIP1559,
                ),
                signature=signature,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1],
                ) for access_tuple in signed_tx.access_list],
            ),
            tx_hash=compute_eip1559_tx_hash(signed_tx),
        )

    if eip2718_type == 0x01:  # EIP-2930
        signed_tx = decode(encoded_signed_tx[1:], EIP2930SignedTransaction)
        assert signed_tx.chainId == cfg.chain_id

        assert signed_tx.signatureYParity in (0, 1)
        signature = ecdsa_pack_signature(
            signed_tx.signatureYParity != 0,
            signed_tx.signatureR,
            signed_tx.signatureS,
        )
        tx_from = ecdsa_recover_tx_from(signature, compute_eip2930_sig_hash(signed_tx))
        if len(signed_tx.to) != 0:
            tx_to = DestinationAddress(
                destination_type=DESTINATION_TYPE_REGULAR,
                address=ExecutionAddress(signed_tx.to),
            )
        else:
            tx_to = DestinationAddress(
                destination_type=DESTINATION_TYPE_CREATE,
                address=compute_contract_address(tx_from, signed_tx.nonce),
            )

        return Transaction(
            payload=TransactionPayload(
                tx_from=tx_from,
                nonce=signed_tx.nonce,
                tx_to=tx_to,
                tx_value=signed_tx.value,
                tx_input=signed_tx.data,
                limits=TransactionLimits(
                    max_priority_fee_per_gas=signed_tx.gasPrice,
                    max_fee_per_gas=signed_tx.gasPrice,
                    gas=signed_tx.gasLimit,
                ),
                sig_type=TransactionSignatureType(
                    tx_type=TRANSACTION_TYPE_EIP2930,
                ),
                signature=signature,
                access_list=[AccessTuple(
                    address=access_tuple[0],
                    storage_keys=access_tuple[1],
                ) for access_tuple in signed_tx.accessList],
            ),
            tx_hash=compute_eip2930_tx_hash(signed_tx),
        )

    if 0xc0 <= eip2718_type <= 0xfe:  # Legacy
        signed_tx = decode(encoded_signed_tx, LegacySignedTransaction)

        if signed_tx.v not in (27, 28):  # EIP-155
            assert signed_tx.v in (2 * cfg.chain_id + 35, 2 * cfg.chain_id + 36)
        signature = ecdsa_pack_signature(
            ((signed_tx.v & 0x1) == 0),
            signed_tx.r,
            signed_tx.s,
        )
        tx_from = ecdsa_recover_tx_from(signature, compute_legacy_sig_hash(signed_tx))
        if len(signed_tx.to) != 0:
            tx_to = DestinationAddress(
                destination_type=DESTINATION_TYPE_REGULAR,
                address=ExecutionAddress(signed_tx.to),
            )
        else:
            tx_to = DestinationAddress(
                destination_Type=DESTINATION_TYPE_CREATE,
                address=compute_contract_address(tx_from, signed_tx.nonce),
            )

        return Transaction(
            payload=TransactionPayload(
                tx_from=tx_from,
                nonce=signed_tx.nonce,
                tx_to=tx_to,
                tx_value=signed_tx.value,
                tx_input=signed_tx.data,
                limits=TransactionLimits(
                    max_priority_fee_per_gas=signed_tx.gasprice,
                    max_fee_per_gas=signed_tx.gasprice,
                    gas=signed_tx.startgas,
                ),
                sig_type=TransactionSignatureType(
                    tx_type=TRANSACTION_TYPE_LEGACY,
                    no_replay_protection=(signed_tx.v in (27, 28)),
                ),
                signature=signature,
            ),
            tx_hash=compute_legacy_tx_hash(signed_tx),
        )

    assert False

transactions = Transactions(
    tx_list=[
        normalize_signed_transaction(encoded_signed_tx, cfg)
        for encoded_signed_tx in encoded_signed_txs
    ],
    chain_id=cfg.chain_id,
)
transactions_root = transactions.hash_tree_root()

if __name__ == '__main__':
    print('transactions_root')
    print(f'0x{transactions_root.hex()}')

    for tx_index in range(len(transactions.tx_list)):
        tx = transactions.tx_list[tx_index]
        encoded = tx.encode_bytes()
        print(f'{tx_index} - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(f'0x{tx.tx_hash.hex()}')
        print(encoded.hex())
