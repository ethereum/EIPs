from ssz_proof_types import *
from convert_transactions import *

def create_transaction_proof(transactions: Transactions, tx_index: uint64) -> TransactionProof:
    tx = transactions[tx_index]
    return TransactionProof(
        tx_root=Root(tx.value().hash_tree_root()),
        tx_selector=tx.selector(),
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing(),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

def create_amount_proof(transactions: Transactions, tx_index: uint64) -> AmountProof:
    tx = transactions[tx_index]
    match tx.selector():
        case 3:
            proof = UnionAmountProof(
                selector=tx.selector(),
                value=EIP4844AmountProof(
                    gas=tx.value().message.gas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in EIP4844_AMOUNT_PROOF_INDICES
                    ],
                ),
            )
        case 2:
            proof = UnionAmountProof(
                selector=tx.selector(),
                value=EIP1559AmountProof(
                    gas_limit=tx.value().message.gas_limit,
                    destination=tx.value().message.destination,
                    amount=tx.value().message.amount,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in EIP1559_AMOUNT_PROOF_INDICES
                    ],
                ),
            )
        case 1:
            proof = UnionAmountProof(
                selector=tx.selector(),
                value=EIP2930AmountProof(
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in EIP2930_AMOUNT_PROOF_INDICES
                    ],
                ),
            )
        case 0:
            proof = UnionAmountProof(
                selector=tx.selector(),
                value=LegacyAmountProof(
                    startgas=tx.value().message.startgas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in LEGACY_AMOUNT_PROOF_INDICES
                    ],
                ),
            )
    return AmountProof(
        proof=proof,
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing(),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

def create_sender_proof(transactions: Transactions, tx_index: uint64) -> SenderProof:
    tx = transactions[tx_index]
    match tx.selector():
        case 3:
            proof = UnionSenderProof(
                selector=tx.selector(),
                value=EIP4844SenderProof(
                    gas=tx.value().message.gas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    signature=tx.value().signature,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in EIP4844_SENDER_PROOF_INDICES
                    ],
                ),
            )
        case 2:
            proof = UnionSenderProof(
                selector=tx.selector(),
                value=EIP1559SenderProof(
                    gas_limit=tx.value().message.gas_limit,
                    destination=tx.value().message.destination,
                    amount=tx.value().message.amount,
                    signature=tx.value().signature,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in EIP1559_SENDER_PROOF_INDICES
                    ],
                ),
            )
        case 1:
            proof = UnionSenderProof(
                selector=tx.selector(),
                value=EIP2930SenderProof(
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    signature=tx.value().signature,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in EIP2930_SENDER_PROOF_INDICES
                    ],
                ),
            )
        case 0:
            proof = UnionSenderProof(
                selector=tx.selector(),
                value=LegacySenderProof(
                    startgas=tx.value().message.startgas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    signature=tx.value().signature,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in LEGACY_SENDER_PROOF_INDICES
                    ],
                ),
            )
    return SenderProof(
        proof=proof,
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing(),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

def create_info_proof(transactions: Transactions, tx_index: uint64) -> InfoProof:
    tx = transactions[tx_index]
    match tx.selector():
        case 3:
            proof = UnionInfoProof(
                selector=tx.selector(),
                value=EIP4844InfoProof(
                    nonce=tx.value().message.nonce,
                    max_priority_fee_per_gas=tx.value().message.max_priority_fee_per_gas,
                    max_fee_per_gas=tx.value().message.max_fee_per_gas,
                    gas=tx.value().message.gas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    signature=tx.value().signature,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in EIP4844_INFO_PROOF_INDICES
                    ],
                ),
            )
        case 2:
            proof = UnionInfoProof(
                selector=tx.selector(),
                value=EIP1559InfoProof(
                    nonce=tx.value().message.nonce,
                    max_priority_fee_per_gas=tx.value().message.max_priority_fee_per_gas,
                    max_fee_per_gas=tx.value().message.max_fee_per_gas,
                    gas_limit=tx.value().message.gas_limit,
                    destination=tx.value().message.destination,
                    amount=tx.value().message.amount,
                    signature=tx.value().signature,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in EIP1559_INFO_PROOF_INDICES
                    ],
                ),
            )
        case 1:
            proof = UnionInfoProof(
                selector=tx.selector(),
                value=EIP2930InfoProof(
                    nonce=tx.value().message.nonce,
                    gas_price=tx.value().message.gas_price,
                    gas_limit=tx.value().message.gas_limit,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    signature=tx.value().signature,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in EIP2930_INFO_PROOF_INDICES
                    ],
                ),
            )
        case 0:
            proof = UnionInfoProof(
                selector=tx.selector(),
                value=LegacyInfoProof(
                    nonce=tx.value().message.nonce,
                    gasprice=tx.value().message.gasprice,
                    startgas=tx.value().message.startgas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    signature=tx.value().signature,
                    multi_branch=[
                        tx.value().get_backing().getter(gindex).merkle_root()
                        for gindex in LEGACY_INFO_PROOF_INDICES
                    ],
                ),
            )
    return InfoProof(
        proof=proof,
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing(),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

if __name__ == '__main__':
    print('transactions_root')
    print(f'0x{transactions.hash_tree_root().hex()}')

    tx_index=0
    for _ in transactions:
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
