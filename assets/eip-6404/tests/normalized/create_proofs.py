from ssz_proof_types import *
from convert_transactions import *

def create_transaction_proof(transactions: Transactions, tx_index: uint64) -> TransactionProof:
    tx = transactions.tx_list[tx_index]
    return TransactionProof(
        payload_root=Root(tx.payload.hash_tree_root()),
        tx_hash=tx.tx_hash,
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing().getter(2),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

def create_amount_proof(transactions: Transactions, tx_index: uint64) -> TransactionProof:
    tx = transactions.tx_list[tx_index]
    return AmountProof(
        tx_from=tx.payload.tx_from,
        nonce=tx.payload.nonce,
        tx_to=tx.payload.tx_to,
        tx_value=tx.payload.tx_value,
        multi_branch=[
            tx.payload.get_backing().getter(gindex).merkle_root()
            for gindex in AMOUNT_PROOF_HELPER_INDICES
        ],
        tx_hash=tx.tx_hash,
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing().getter(2),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

def create_sender_proof(transactions: Transactions, tx_index: uint64) -> TransactionProof:
    tx = transactions.tx_list[tx_index]
    return SenderProof(
        tx_from=tx.payload.tx_from,
        nonce=tx.payload.nonce,
        tx_to=tx.payload.tx_to,
        tx_value=tx.payload.tx_value,
        multi_branch=[
            tx.payload.get_backing().getter(gindex).merkle_root()
            for gindex in SENDER_PROOF_HELPER_INDICES
        ],
        tx_hash=tx.tx_hash,
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing().getter(2),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

def create_info_proof(transactions: Transactions, tx_index: uint64) -> TransactionProof:
    tx = transactions.tx_list[tx_index]
    return InfoProof(
        tx_from=tx.payload.tx_from,
        nonce=tx.payload.nonce,
        tx_to=tx.payload.tx_to,
        tx_value=tx.payload.tx_value,
        limits=tx.payload.limits,
        multi_branch=[
            tx.payload.get_backing().getter(gindex).merkle_root()
            for gindex in INFO_PROOF_HELPER_INDICES
        ],
        tx_hash=tx.tx_hash,
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing().getter(2),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

transaction_proofs = [
    create_transaction_proof(transactions, tx_index)
    for tx_index in range(len(transactions.tx_list))
]
amount_proofs = [
    create_amount_proof(transactions, tx_index)
    for tx_index in range(len(transactions.tx_list))
]
sender_proofs = [
    create_sender_proof(transactions, tx_index)
    for tx_index in range(len(transactions.tx_list))
]
info_proofs = [
    create_info_proof(transactions, tx_index)
    for tx_index in range(len(transactions.tx_list))
]

if __name__ == '__main__':
    print('transactions_root')
    print(f'0x{transactions_root.hex()}')

    for tx_index in range(len(transactions.tx_list)):
        print()

        encoded = transaction_proofs[tx_index].encode_bytes()
        print(f'{tx_index} - TransactionProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())

        encoded = amount_proofs[tx_index].encode_bytes()
        print(f'{tx_index} - AmountProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())

        encoded = sender_proofs[tx_index].encode_bytes()
        print(f'{tx_index} - SenderProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())

        encoded = info_proofs[tx_index].encode_bytes()
        print(f'{tx_index} - InfoProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())
