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
            for gindex in AMOUNT_PROOF_INDICES
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
            for gindex in SENDER_PROOF_INDICES
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
            for gindex in INFO_PROOF_INDICES
        ],
        tx_hash=tx.tx_hash,
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing().getter(2),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

if __name__ == '__main__':
    print('transactions_root')
    print(f'0x{transactions.hash_tree_root().hex()}')

    tx_index=0
    for _ in transactions.tx_list:
        print()

        encoded = create_transaction_proof(transactions, tx_index).encode_bytes()
        print(f'{tx_index} - TransactionProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())

        encoded = create_amount_proof(transactions, tx_index).encode_bytes()
        print(f'{tx_index} - AmountProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())

        encoded = create_sender_proof(transactions, tx_index).encode_bytes()
        print(f'{tx_index} - SenderProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())

        encoded = create_info_proof(transactions, tx_index).encode_bytes()
        print(f'{tx_index} - InfoProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())

        tx_index += 1
