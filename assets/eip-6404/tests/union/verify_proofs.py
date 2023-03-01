from remerkleable.settings import zero_hashes
from secp256k1 import ECDSA, PublicKey
from create_proofs import *

def verify_transaction_proof(
    proof: TransactionProof,
    cfg: ExecutionConfig,
    transactions_root: Root,
    expected_tx_hash: Root,
):
    assert proof.tx_root == expected_tx_hash

    tx_gindex = GeneralizedIndex(MAX_TRANSACTIONS_PER_PAYLOAD * 2 + uint64(proof.tx_index))
    assert calculate_multi_merkle_root(
        [
            proof.tx_root.hash_tree_root(),
            proof.tx_selector.hash_tree_root(),
        ],
        proof.tx_branch,
        [
            tx_gindex * 2 + 0,
            tx_gindex * 2 + 1,
        ],
        get_helper_indices([tx_gindex]),
    ) == transactions_root

def verify_amount_proof(
    proof: AmountProof,
    cfg: ExecutionConfig,
    transactions_root: Root,
    expected_tx_to: ExecutionAddress,
    expected_tx_value_min: uint256,
):
    match proof.tx_proof.selector():
        case 3:
            assert proof.tx_proof.value().to.selector() == 1
            assert proof.tx_proof.value().to.value() == expected_tx_to
            assert proof.tx_proof.value().value >= expected_tx_value_min
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().gas.hash_tree_root(),
                    proof.tx_proof.value().to.hash_tree_root(),
                    proof.tx_proof.value().value.hash_tree_root(),
                ],
                proof.tx_proof.value().multi_branch,
                EIP4844_AMOUNT_PROOF_INDICES,
                EIP4844_AMOUNT_PROOF_HELPER_INDICES,
            )
        case 2:
            assert proof.tx_proof.value().destination.selector() == 1
            assert proof.tx_proof.value().destination.value() == expected_tx_to
            assert proof.tx_proof.value().amount >= expected_tx_value_min
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().gas_limit.hash_tree_root(),
                    proof.tx_proof.value().destination.hash_tree_root(),
                    proof.tx_proof.value().amount.hash_tree_root(),
                ],
                proof.tx_proof.value().multi_branch,
                EIP1559_AMOUNT_PROOF_INDICES,
                EIP1559_AMOUNT_PROOF_HELPER_INDICES,
            )
        case 1:
            assert proof.tx_proof.value().to.selector() == 1
            assert proof.tx_proof.value().to.value() == expected_tx_to
            assert proof.tx_proof.value().value >= expected_tx_value_min
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().to.hash_tree_root(),
                    proof.tx_proof.value().value.hash_tree_root(),
                ],
                proof.tx_proof.value().multi_branch,
                EIP2930_AMOUNT_PROOF_INDICES,
                EIP2930_AMOUNT_PROOF_HELPER_INDICES,
            )
        case 0:
            assert proof.tx_proof.value().to.selector() == 1
            assert proof.tx_proof.value().to.value() == expected_tx_to
            assert proof.tx_proof.value().value >= expected_tx_value_min
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().startgas.hash_tree_root(),
                    proof.tx_proof.value().to.hash_tree_root(),
                    proof.tx_proof.value().value.hash_tree_root(),
                    zero_hashes[1],
                ],
                proof.tx_proof.value().multi_branch,
                LEGACY_AMOUNT_PROOF_INDICES,
                LEGACY_AMOUNT_PROOF_HELPER_INDICES,
            )

    tx_gindex = GeneralizedIndex(MAX_TRANSACTIONS_PER_PAYLOAD * 2 + uint64(proof.tx_index))
    assert calculate_multi_merkle_root(
        [
            sig_root,
            proof.tx_proof.value().signature_root.hash_tree_root(),
            uint8(proof.tx_proof.selector()).hash_tree_root(),
        ],
        proof.tx_branch,
        [
            tx_gindex * 4 + 0,
            tx_gindex * 4 + 1,
            tx_gindex * 2 + 1,
        ],
        get_helper_indices([tx_gindex]),
    ) == transactions_root

def verify_sender_proof(
    proof: SenderProof,
    cfg: ExecutionConfig,
    transactions_root: Root,
    expected_tx_to: ExecutionAddress,
    expected_tx_value_min: uint256,
) -> ExecutionAddress:
    match proof.tx_proof.selector():
        case 3:
            assert proof.tx_proof.value().to.selector() == 1
            assert proof.tx_proof.value().to.value() == expected_tx_to
            assert proof.tx_proof.value().value >= expected_tx_value_min
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().gas.hash_tree_root(),
                    proof.tx_proof.value().to.hash_tree_root(),
                    proof.tx_proof.value().value.hash_tree_root(),
                ],
                proof.tx_proof.value().multi_branch,
                EIP4844_SENDER_PROOF_INDICES,
                EIP4844_SENDER_PROOF_HELPER_INDICES,
            )
            signature = proof.tx_proof.value().signature
        case 2:
            assert proof.tx_proof.value().destination.selector() == 1
            assert proof.tx_proof.value().destination.value() == expected_tx_to
            assert proof.tx_proof.value().amount >= expected_tx_value_min
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().gas_limit.hash_tree_root(),
                    proof.tx_proof.value().destination.hash_tree_root(),
                    proof.tx_proof.value().amount.hash_tree_root(),
                ],
                proof.tx_proof.value().multi_branch,
                EIP1559_SENDER_PROOF_INDICES,
                EIP1559_SENDER_PROOF_HELPER_INDICES,
            )
            signature = proof.tx_proof.value().signature
        case 1:
            assert proof.tx_proof.value().to.selector() == 1
            assert proof.tx_proof.value().to.value() == expected_tx_to
            assert proof.tx_proof.value().value >= expected_tx_value_min
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().to.hash_tree_root(),
                    proof.tx_proof.value().value.hash_tree_root(),
                ],
                proof.tx_proof.value().multi_branch,
                EIP2930_SENDER_PROOF_INDICES,
                EIP2930_SENDER_PROOF_HELPER_INDICES,
            )
            signature = proof.tx_proof.value().signature
        case 0:
            assert proof.tx_proof.value().to.selector() == 1
            assert proof.tx_proof.value().to.value() == expected_tx_to
            assert proof.tx_proof.value().value >= expected_tx_value_min
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().startgas.hash_tree_root(),
                    proof.tx_proof.value().to.hash_tree_root(),
                    proof.tx_proof.value().value.hash_tree_root(),
                    zero_hashes[1],
                ],
                proof.tx_proof.value().multi_branch,
                LEGACY_SENDER_PROOF_INDICES,
                LEGACY_SENDER_PROOF_HELPER_INDICES,
            )
            signature = ECDSASignature(
                y_parity=(proof.tx_proof.value().signature.v & 0x1) == 0,
                r = proof.tx_proof.value().signature.r,
                s = proof.tx_proof.value().signature.s,
            )

    ecdsa = ECDSA()
    recover_sig = ecdsa.ecdsa_recoverable_deserialize(
        signature.r.to_bytes(32, 'big') + signature.s.to_bytes(32, 'big'),
        0x01 if signature.y_parity else 0,
    )
    public_key = PublicKey(ecdsa.ecdsa_recover(sig_root, recover_sig, raw=True))
    uncompressed = public_key.serialize(compressed=False)
    tx_from = ExecutionAddress(keccak(uncompressed)[12:32])

    tx_gindex = GeneralizedIndex(MAX_TRANSACTIONS_PER_PAYLOAD * 2 + uint64(proof.tx_index))
    assert calculate_multi_merkle_root(
        [
            sig_root,
            proof.tx_proof.value().signature.hash_tree_root(),
            uint8(proof.tx_proof.selector()).hash_tree_root(),
        ],
        proof.tx_branch,
        [
            tx_gindex * 4 + 0,
            tx_gindex * 4 + 1,
            tx_gindex * 2 + 1,
        ],
        get_helper_indices([tx_gindex]),
    ) == transactions_root

    return tx_from

def verify_info_proof(
    proof: InfoProof,
    cfg: ExecutionConfig,
    transactions_root: Root,
) -> TransactionInfo:
    match proof.tx_proof.selector():
        case 3:
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().nonce.hash_tree_root(),
                    proof.tx_proof.value().max_priority_fee_per_gas.hash_tree_root(),
                    proof.tx_proof.value().max_fee_per_gas.hash_tree_root(),
                    proof.tx_proof.value().gas.hash_tree_root(),
                    proof.tx_proof.value().to.hash_tree_root(),
                    proof.tx_proof.value().value.hash_tree_root(),
                    cfg.chain_id.hash_tree_root(),
                ],
                proof.tx_proof.value().multi_branch,
                EIP4844_INFO_PROOF_INDICES,
                EIP4844_INFO_PROOF_HELPER_INDICES,
            )
            print(sig_root.hex())
            to = proof.tx_proof.value().to
            signature = proof.tx_proof.value().signature
            info = TransactionInfo(
                tx_index=proof.tx_index,
                nonce=proof.tx_proof.value().nonce,
                tx_value=proof.tx_proof.value().value,
                limits=TransactionLimits(
                    max_priority_fee_per_gas=proof.tx_proof.value().max_priority_fee_per_gas,
                    max_fee_per_gas=proof.tx_proof.value().max_fee_per_gas,
                    gas=proof.tx_proof.value().gas,
                ),
            )
        case 2:
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().nonce.hash_tree_root(),
                    proof.tx_proof.value().max_priority_fee_per_gas.hash_tree_root(),
                    proof.tx_proof.value().max_fee_per_gas.hash_tree_root(),
                    proof.tx_proof.value().gas_limit.hash_tree_root(),
                    proof.tx_proof.value().destination.hash_tree_root(),
                    proof.tx_proof.value().amount.hash_tree_root(),
                    cfg.chain_id.hash_tree_root(),
                ],
                proof.tx_proof.value().multi_branch,
                EIP1559_INFO_PROOF_INDICES,
                EIP1559_INFO_PROOF_HELPER_INDICES,
            )
            to = proof.tx_proof.value().destination
            signature = proof.tx_proof.value().signature
            info = TransactionInfo(
                tx_index=proof.tx_index,
                nonce=proof.tx_proof.value().nonce,
                tx_value=proof.tx_proof.value().amount,
                limits=TransactionLimits(
                    max_priority_fee_per_gas=proof.tx_proof.value().max_priority_fee_per_gas,
                    max_fee_per_gas=proof.tx_proof.value().max_fee_per_gas,
                    gas=proof.tx_proof.value().gas_limit,
                ),
            )
        case 1:
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().nonce.hash_tree_root(),
                    proof.tx_proof.value().gas_price.hash_tree_root(),
                    proof.tx_proof.value().gas_limit.hash_tree_root(),
                    proof.tx_proof.value().to.hash_tree_root(),
                    proof.tx_proof.value().value.hash_tree_root(),
                    cfg.chain_id.hash_tree_root(),
                ],
                proof.tx_proof.value().multi_branch,
                EIP2930_INFO_PROOF_INDICES,
                EIP2930_INFO_PROOF_HELPER_INDICES,
            )
            to = proof.tx_proof.value().to
            signature = proof.tx_proof.value().signature
            info = TransactionInfo(
                tx_index=proof.tx_index,
                nonce=proof.tx_proof.value().nonce,
                tx_value=proof.tx_proof.value().value,
                limits=TransactionLimits(
                    max_priority_fee_per_gas=proof.tx_proof.value().gas_price,
                    max_fee_per_gas=proof.tx_proof.value().gas_price,
                    gas=proof.tx_proof.value().gas_limit,
                ),
            )
        case 0:
            sig_root = calculate_multi_merkle_root(
                [
                    proof.tx_proof.value().nonce.hash_tree_root(),
                    proof.tx_proof.value().gasprice.hash_tree_root(),
                    proof.tx_proof.value().startgas.hash_tree_root(),
                    proof.tx_proof.value().to.hash_tree_root(),
                    proof.tx_proof.value().value.hash_tree_root(),
                    zero_hashes[1],
                ],
                proof.tx_proof.value().multi_branch,
                LEGACY_INFO_PROOF_INDICES,
                LEGACY_INFO_PROOF_HELPER_INDICES,
            )
            to = proof.tx_proof.value().to
            signature = ECDSASignature(
                y_parity=(proof.tx_proof.value().signature.v & 0x1) == 0,
                r = proof.tx_proof.value().signature.r,
                s = proof.tx_proof.value().signature.s,
            )
            info = TransactionInfo(
                tx_index=proof.tx_index,
                nonce=proof.tx_proof.value().nonce,
                tx_value=proof.tx_proof.value().value,
                limits=TransactionLimits(
                    max_priority_fee_per_gas=proof.tx_proof.value().gasprice,
                    max_fee_per_gas=proof.tx_proof.value().gasprice,
                    gas=proof.tx_proof.value().startgas,
                ),
            )

    ecdsa = ECDSA()
    recover_sig = ecdsa.ecdsa_recoverable_deserialize(
        signature.r.to_bytes(32, 'big') + signature.s.to_bytes(32, 'big'),
        0x01 if signature.y_parity else 0,
    )
    public_key = PublicKey(ecdsa.ecdsa_recover(sig_root, recover_sig, raw=True))
    uncompressed = public_key.serialize(compressed=False)
    info.tx_from = ExecutionAddress(keccak(uncompressed)[12:32])

    match to.selector():
        case 1:
            info.tx_to = DestinationAddress(
                destination_type=DESTINATION_TYPE_REGULAR,
                address=to.value(),
            )
        case 0:
            info.tx_to = DestinationAddress(
                destination_type=DESTINATION_TYPE_CREATE,
                address=compute_contract_address(info.tx_from, info.nonce),
            )

    info.tx_hash = calculate_multi_merkle_root(
        [
            sig_root,
            proof.tx_proof.value().signature.hash_tree_root(),
        ],
        [],
        [
            GeneralizedIndex(2),
            GeneralizedIndex(3),
        ],
        [],
    )

    tx_gindex = GeneralizedIndex(MAX_TRANSACTIONS_PER_PAYLOAD * 2 + uint64(proof.tx_index))
    assert calculate_multi_merkle_root(
        [
            info.tx_hash.hash_tree_root(),
            uint8(proof.tx_proof.selector()).hash_tree_root(),
        ],
        proof.tx_branch,
        [
            tx_gindex * 2 + 0,
            tx_gindex * 2 + 1,
        ],
        get_helper_indices([tx_gindex]),
    ) == transactions_root

    return info

if __name__ == '__main__':
    print('transactions_root')
    print(f'0x{transactions_root.hex()}')

    print()
    for tx_index in range(len(transaction_proofs)):
        print(f'{tx_index} - TransactionProof')
        expected_tx_hash = transaction_proofs[tx_index].tx_root
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
