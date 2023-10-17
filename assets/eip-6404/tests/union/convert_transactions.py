from ssz_tx_types import *
from create_transactions import *

def normalize_signed_transaction(encoded_signed_tx: bytes, cfg: ExecutionConfig) -> Transaction:
    eip2718_type = encoded_signed_tx[0]

    if eip2718_type == 0x05:  # EIP-4844
        signed_tx = BlobTransactionNetworkWrapper.decode_bytes(encoded_signed_tx[1:]).tx

        return Transaction(
            selector=3,
            value=signed_tx,
        )

    if eip2718_type == 0x02:  # EIP-1559
        signed_tx = decode(encoded_signed_tx[1:], EIP1559SignedTransaction)

        return Transaction(
            selector=2,
            value=EIP1559SignedSSZTransaction(
                message=EIP1559SSZTransaction(
                    chain_id=signed_tx.chain_id,
                    nonce=signed_tx.nonce,
                    max_priority_fee_per_gas=signed_tx.max_priority_fee_per_gas,
                    max_fee_per_gas=signed_tx.max_fee_per_gas,
                    gas_limit=signed_tx.gas_limit,
                    destination=Union[None, ExecutionAddress](
                        selector=1,
                        value=ExecutionAddress(signed_tx.destination),
                    ) if len(signed_tx.destination) > 0 else Union[None, ExecutionAddress](),
                    amount=signed_tx.amount,
                    data=signed_tx.data,
                    access_list=[AccessTuple(
                        address=access_tuple[0],
                        storage_keys=access_tuple[1],
                    ) for access_tuple in signed_tx.access_list],
                ),
                signature=ECDSASignature(
                    y_parity=signed_tx.signature_y_parity,
                    r=signed_tx.signature_r,
                    s=signed_tx.signature_s,
                ),
            ),
        )

    if eip2718_type == 0x01:  # EIP-2930
        signed_tx = decode(encoded_signed_tx[1:], EIP2930SignedTransaction)

        return Transaction(
            selector=1,
            value=EIP2930SignedSSZTransaction(
                message=EIP2930SSZTransaction(
                    chain_id=signed_tx.chainId,
                    nonce=signed_tx.nonce,
                    gas_price=signed_tx.gasPrice,
                    gas_limit=signed_tx.gasLimit,
                    to=Union[None, ExecutionAddress](
                        selector=1,
                        value=ExecutionAddress(signed_tx.to),
                    ) if len(signed_tx.to) > 0 else Union[None, ExecutionAddress](),
                    value=signed_tx.value,
                    data=signed_tx.data,
                    access_list=[AccessTuple(
                        address=access_tuple[0],
                        storage_keys=access_tuple[1],
                    ) for access_tuple in signed_tx.accessList],
                ),
                signature=ECDSASignature(
                    y_parity=signed_tx.signatureYParity,
                    r=signed_tx.signatureR,
                    s=signed_tx.signatureS,
                ),
            ),
        )

    if 0xc0 <= eip2718_type <= 0xfe:
        signed_tx = decode(encoded_signed_tx, LegacySignedTransaction)

        return Transaction(
            selector=0,
            value=LegacySignedSSZTransaction(
                message=LegacySSZTransaction(
                    nonce=signed_tx.nonce,
                    gasprice=signed_tx.gasprice,
                    startgas=signed_tx.startgas,
                    to=Union[None, ExecutionAddress](
                        selector=1,
                        value=ExecutionAddress(signed_tx.to),
                    ) if len(signed_tx.to) > 0 else Union[None, ExecutionAddress](),
                    value=signed_tx.value,
                    data=signed_tx.data,
                ),
                signature=LegacyECDSASignature(
                    v=signed_tx.v,
                    r=signed_tx.r,
                    s=signed_tx.s,
                ),
            ),
        )

    assert False

transactions = Transactions(*[
    normalize_signed_transaction(encoded_signed_tx, cfg)
    for encoded_signed_tx in encoded_signed_txs
])
transactions_root = transactions.hash_tree_root()

if __name__ == '__main__':
    print('transactions_root')
    print(f'0x{transactions_root.hex()}')

    for tx_index in range(len(transactions)):
        tx = transactions[tx_index]
        encoded = tx.encode_bytes()
        print(f'{tx_index} - {len(encoded)} bytes (Snappy: {len(compress(encoded))})')
        print(f'0x{tx.get_backing().getter(2).merkle_root().hex()}')
        print(encoded.hex())
