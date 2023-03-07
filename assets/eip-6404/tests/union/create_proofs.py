from os import mkdir
from shutil import rmtree
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
            tx_proof = UnionAmountProof(
                selector=tx.selector(),
                value=EIP4844AmountProof(
                    gas=tx.value().message.gas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in EIP4844_AMOUNT_PROOF_HELPER_INDICES
                    ],
                    signature_root=tx.value().signature.hash_tree_root(),
                ),
            )
        case 2:
            tx_proof = UnionAmountProof(
                selector=tx.selector(),
                value=EIP1559AmountProof(
                    gas_limit=tx.value().message.gas_limit,
                    destination=tx.value().message.destination,
                    amount=tx.value().message.amount,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in EIP1559_AMOUNT_PROOF_HELPER_INDICES
                    ],
                    signature_root=tx.value().signature.hash_tree_root(),
                ),
            )
        case 1:
            tx_proof = UnionAmountProof(
                selector=tx.selector(),
                value=EIP2930AmountProof(
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in EIP2930_AMOUNT_PROOF_HELPER_INDICES
                    ],
                    signature_root=tx.value().signature.hash_tree_root(),
                ),
            )
        case 0:
            tx_proof = UnionAmountProof(
                selector=tx.selector(),
                value=LegacyAmountProof(
                    startgas=tx.value().message.startgas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in LEGACY_AMOUNT_PROOF_HELPER_INDICES
                    ],
                    signature_root=tx.value().signature.hash_tree_root(),
                ),
            )
    return AmountProof(
        tx_proof=tx_proof,
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
            tx_proof = UnionSenderProof(
                selector=tx.selector(),
                value=EIP4844SenderProof(
                    gas=tx.value().message.gas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in EIP4844_SENDER_PROOF_HELPER_INDICES
                    ],
                    signature=tx.value().signature,
                ),
            )
        case 2:
            tx_proof = UnionSenderProof(
                selector=tx.selector(),
                value=EIP1559SenderProof(
                    gas_limit=tx.value().message.gas_limit,
                    destination=tx.value().message.destination,
                    amount=tx.value().message.amount,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in EIP1559_SENDER_PROOF_HELPER_INDICES
                    ],
                    signature=tx.value().signature,
                ),
            )
        case 1:
            tx_proof = UnionSenderProof(
                selector=tx.selector(),
                value=EIP2930SenderProof(
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in EIP2930_SENDER_PROOF_HELPER_INDICES
                    ],
                    signature=tx.value().signature,
                ),
            )
        case 0:
            tx_proof = UnionSenderProof(
                selector=tx.selector(),
                value=LegacySenderProof(
                    startgas=tx.value().message.startgas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in LEGACY_SENDER_PROOF_HELPER_INDICES
                    ],
                    signature=tx.value().signature,
                ),
            )
    return SenderProof(
        tx_proof=tx_proof,
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
            tx_proof = UnionInfoProof(
                selector=tx.selector(),
                value=EIP4844InfoProof(
                    nonce=tx.value().message.nonce,
                    max_priority_fee_per_gas=tx.value().message.max_priority_fee_per_gas,
                    max_fee_per_gas=tx.value().message.max_fee_per_gas,
                    gas=tx.value().message.gas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in EIP4844_INFO_PROOF_HELPER_INDICES
                    ],
                    signature=tx.value().signature,
                ),
            )
        case 2:
            tx_proof = UnionInfoProof(
                selector=tx.selector(),
                value=EIP1559InfoProof(
                    nonce=tx.value().message.nonce,
                    max_priority_fee_per_gas=tx.value().message.max_priority_fee_per_gas,
                    max_fee_per_gas=tx.value().message.max_fee_per_gas,
                    gas_limit=tx.value().message.gas_limit,
                    destination=tx.value().message.destination,
                    amount=tx.value().message.amount,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in EIP1559_INFO_PROOF_HELPER_INDICES
                    ],
                    signature=tx.value().signature,
                ),
            )
        case 1:
            tx_proof = UnionInfoProof(
                selector=tx.selector(),
                value=EIP2930InfoProof(
                    nonce=tx.value().message.nonce,
                    gas_price=tx.value().message.gas_price,
                    gas_limit=tx.value().message.gas_limit,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in EIP2930_INFO_PROOF_HELPER_INDICES
                    ],
                    signature=tx.value().signature,
                ),
            )
        case 0:
            tx_proof = UnionInfoProof(
                selector=tx.selector(),
                value=LegacyInfoProof(
                    nonce=tx.value().message.nonce,
                    gasprice=tx.value().message.gasprice,
                    startgas=tx.value().message.startgas,
                    to=tx.value().message.to,
                    value=tx.value().message.value,
                    multi_branch=[
                        tx.value().message.get_backing().getter(gindex).merkle_root()
                        for gindex in LEGACY_INFO_PROOF_HELPER_INDICES
                    ],
                    signature=tx.value().signature,
                ),
            )
    return InfoProof(
        tx_proof=tx_proof,
        tx_index=tx_index,
        tx_branch=build_proof(
            transactions.get_backing(),
            MAX_TRANSACTIONS_PER_PAYLOAD * 2 + tx_index,
        ),
    )

transaction_proofs = [
    create_transaction_proof(transactions, tx_index)
    for tx_index in range(len(transactions))
]
amount_proofs = [
    create_amount_proof(transactions, tx_index)
    for tx_index in range(len(transactions))
]
sender_proofs = [
    create_sender_proof(transactions, tx_index)
    for tx_index in range(len(transactions))
]
info_proofs = [
    create_info_proof(transactions, tx_index)
    for tx_index in range(len(transactions))
]

if __name__ == '__main__':
    dir = os_path.join(os_path.dirname(os_path.realpath(__file__)), 'proofs')
    if os_path.exists(dir) and os_path.isdir(dir):
        rmtree(dir)
    mkdir(dir)

    print('transactions_root')
    print(f'0x{transactions_root.hex()}')
    file = open(os_path.join(dir, f'transactions_root.bin'), 'wb')
    file.write(transactions_root)
    file.close()

    for tx_index in range(len(transactions)):
        print()

        encoded = transaction_proofs[tx_index].encode_bytes()
        print(f'{tx_index} - TransactionProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())
        file = open(os_path.join(dir, f'transaction_{tx_index}.bin'), 'wb')
        file.write(encoded)
        file.close()

        encoded = amount_proofs[tx_index].encode_bytes()
        print(f'{tx_index} - AmountProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())
        file = open(os_path.join(dir, f'amount_{tx_index}.bin'), 'wb')
        file.write(encoded)
        file.close()

        encoded = sender_proofs[tx_index].encode_bytes()
        print(f'{tx_index} - SenderProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())
        file = open(os_path.join(dir, f'sender_{tx_index}.bin'), 'wb')
        file.write(encoded)
        file.close()

        encoded = info_proofs[tx_index].encode_bytes()
        print(f'{tx_index} - InfoProof - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(encoded.hex())
        file = open(os_path.join(dir, f'info_{tx_index}.bin'), 'wb')
        file.write(encoded)
        file.close()
