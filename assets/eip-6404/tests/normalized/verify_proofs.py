from create_proofs import *

def verify_transaction_proof(
    proof: TransactionProof,
    cfg: ExecutionConfig,
    transactions_root: Root,
    expected_tx_hash: Root,
):
    assert proof.tx_hash == expected_tx_hash

    tx_gindex = GeneralizedIndex(MAX_TRANSACTIONS_PER_PAYLOAD * 4 + uint64(proof.tx_index))
    assert calculate_multi_merkle_root(
        [
            proof.payload_root.hash_tree_root(),
            proof.tx_hash.hash_tree_root(),
            cfg.chain_id,
        ],
        proof.tx_branch,
        [
            tx_gindex * 2 + 0,
            tx_gindex * 2 + 1,
            CHAIN_ID_INDEX,
        ],
        get_helper_indices([tx_gindex, CHAIN_ID_INDEX]),
    ) == transactions_root

def verify_amount_proof(
    proof: AmountProof,
    cfg: ExecutionConfig,
    transactions_root: Root,
    expected_tx_to: ExecutionAddress,
    expected_tx_value_min: uint256,
):
    assert proof.tx_to.destination_type == DESTINATION_TYPE_REGULAR
    assert proof.tx_to.address == expected_tx_to
    assert proof.tx_value >= expected_tx_value_min
    payload_root = calculate_multi_merkle_root(
        [
            proof.tx_from.hash_tree_root(),
            proof.nonce.hash_tree_root(),
            proof.tx_to.hash_tree_root(),
            proof.tx_value.hash_tree_root(),
        ],
        proof.multi_branch,
        AMOUNT_PROOF_INDICES,
        AMOUNT_PROOF_HELPER_INDICES,
    )

    tx_gindex = GeneralizedIndex(MAX_TRANSACTIONS_PER_PAYLOAD * 4 + uint64(proof.tx_index))
    assert calculate_multi_merkle_root(
        [
            payload_root,
            proof.tx_hash.hash_tree_root(),
            cfg.chain_id,
        ],
        proof.tx_branch,
        [
            tx_gindex * 2 + 0,
            tx_gindex * 2 + 1,
            CHAIN_ID_INDEX,
        ],
        get_helper_indices([tx_gindex, CHAIN_ID_INDEX]),
    ) == transactions_root

def verify_sender_proof(
    proof: SenderProof,
    cfg: ExecutionConfig,
    transactions_root: Root,
    expected_tx_to: ExecutionAddress,
    expected_tx_value_min: uint256,
) -> ExecutionAddress:
    assert proof.tx_to.destination_type == DESTINATION_TYPE_REGULAR
    assert proof.tx_to.address == expected_tx_to
    assert proof.tx_value >= expected_tx_value_min
    payload_root = calculate_multi_merkle_root(
        [
            proof.tx_from.hash_tree_root(),
            proof.nonce.hash_tree_root(),
            proof.tx_to.hash_tree_root(),
            proof.tx_value.hash_tree_root(),
        ],
        proof.multi_branch,
        SENDER_PROOF_INDICES,
        SENDER_PROOF_HELPER_INDICES,
    )

    tx_gindex = GeneralizedIndex(MAX_TRANSACTIONS_PER_PAYLOAD * 4 + uint64(proof.tx_index))
    assert calculate_multi_merkle_root(
        [
            payload_root,
            proof.tx_hash.hash_tree_root(),
            cfg.chain_id,
        ],
        proof.tx_branch,
        [
            tx_gindex * 2 + 0,
            tx_gindex * 2 + 1,
            CHAIN_ID_INDEX,
        ],
        get_helper_indices([tx_gindex, CHAIN_ID_INDEX]),
    ) == transactions_root

    return proof.tx_from

def verify_info_proof(
    proof: InfoProof,
    cfg: ExecutionConfig,
    transactions_root: Root,
) -> TransactionInfo:
    payload_root = calculate_multi_merkle_root(
        [
            proof.tx_from.hash_tree_root(),
            proof.nonce.hash_tree_root(),
            proof.tx_to.hash_tree_root(),
            proof.tx_value.hash_tree_root(),
            proof.limits.hash_tree_root(),
        ],
        proof.multi_branch,
        INFO_PROOF_INDICES,
        INFO_PROOF_HELPER_INDICES,
    )

    tx_gindex = GeneralizedIndex(MAX_TRANSACTIONS_PER_PAYLOAD * 4 + uint64(proof.tx_index))
    assert calculate_multi_merkle_root(
        [
            payload_root,
            proof.tx_hash.hash_tree_root(),
            cfg.chain_id,
        ],
        proof.tx_branch,
        [
            tx_gindex * 2 + 0,
            tx_gindex * 2 + 1,
            CHAIN_ID_INDEX,
        ],
        get_helper_indices([tx_gindex, CHAIN_ID_INDEX]),
    ) == transactions_root

    return TransactionInfo(
        tx_index=proof.tx_index,
        tx_hash=proof.tx_hash,
        tx_from=proof.tx_from,
        nonce=proof.nonce,
        tx_to=proof.tx_to,
        tx_value=proof.tx_value,
        limits=proof.limits,
    )

if __name__ == '__main__':
    print('transactions_root')
    print(f'0x{transactions_root.hex()}')

    print()
    for tx_index in range(len(transaction_proofs)):
        print(f'{tx_index} - TransactionProof')
        expected_tx_hash = transaction_proofs[tx_index].tx_hash
        verify_transaction_proof(
            transaction_proofs[tx_index], cfg, transactions_root,
            expected_tx_hash)
        print(f'tx_index = {transaction_proofs[tx_index].tx_index}')

    print()
    for tx_index in range(len(amount_proofs)):
        print(f'{tx_index} - AmountProof')
        expected_tx_to = ExecutionAddress(bytes.fromhex('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045'))
        expected_tx_value_min = 1_000_000_000
        verify_amount_proof(
            amount_proofs[tx_index], cfg, transactions_root,
            expected_tx_to, expected_tx_value_min,
        )
        print(f'OK')

    print()
    for tx_index in range(len(sender_proofs)):
        print(f'{tx_index} - SenderProof')
        expected_tx_to = ExecutionAddress(bytes.fromhex('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045'))
        expected_tx_value_min = 1_000_000_000
        tx_from = verify_sender_proof(
            sender_proofs[tx_index], cfg, transactions_root,
            expected_tx_to, expected_tx_value_min,
        )
        print(f'tx_from = 0x{tx_from.hex()}')

    print()
    for tx_index in range(len(info_proofs)):
        print(f'{tx_index} - InfoProof')
        info = verify_info_proof(
            info_proofs[tx_index], cfg, transactions_root,
        )
        print(f'info = {info}')
