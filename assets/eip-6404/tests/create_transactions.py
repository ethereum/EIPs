from rlp import decode
from snappy import compress
from eip2718_tx_types import *

# Use `sign_transactions.py` to re-generate signatures after editing this file.

encoded_signed_txs = List[ByteList[MAX_BYTES_PER_TRANSACTION], MAX_TRANSACTIONS_PER_PAYLOAD](
    encode(LegacySignedTransaction(
        nonce=42,
        gasprice=69_123_456_789,
        startgas=21_000,
        to=bytes.fromhex('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045'),
        value=3_141_592_653,
        data=bytes([]),
        v=27,
        r=0x2e05c6dd5e74db9616802ed1df109f96d0a313373fb02e3354c0391383b2907e,
        s=0x46c0489a847f0f9ab491b228eeb1581c21d0a66d5d6b74745fa7a9e8ca769532,
    )),
    encode(LegacySignedTransaction(
        nonce=42,
        gasprice=69_123_456_789,
        startgas=21_000,
        to=bytes.fromhex('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045'),
        value=3_141_592_653,
        data=bytes([]),
        v=cfg.chain_id * 2 + 36,
        r=0x1e3b25952ae32d705fa6907687f90089cf7c34a0b3622e2f4cf13d851dd77153,
        s=0x2064d327555377cb853944f2c6e19082ad279c9284b1b035d6dac1042111fce5,
    )),
    bytes([0x01]) + encode(EIP2930SignedTransaction(
        chainId=cfg.chain_id,
        nonce=42,
        gasPrice=69_123_456_789,
        gasLimit=21_000,
        to=bytes.fromhex('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045'),
        value=3_141_592_653,
        data=bytes([]),
        accessList=[],
        signatureYParity=0,
        signatureR=0x2219f0647af0c6f90e50abef64fe89f3b80ce465e2eae215bfde6cfb06c6f7f4,
        signatureS=0x09eba6b8b601ef43b33b16c8952b35507eeba05c9ecf654d9c18c0bb9d95eb36,
    )),
    bytes([0x02]) + encode(EIP1559SignedTransaction(
        chain_id=cfg.chain_id,
        nonce=42,
        max_priority_fee_per_gas=69_123_456_789,
        max_fee_per_gas=69_123_456_789,
        gas_limit=21_000,
        destination=bytes.fromhex('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045'),
        amount=3_141_592_653,
        data=bytes([]),
        access_list=[],
        signature_y_parity=0,
        signature_r=0x08c4fb0d85fe64bc22aa817b298201bb7dcd29750787c28502146df3dfc5d745,
        signature_s=0x6c5e521d85a84434c889dc0691e9430fb945691239b4ca7f2fc4b1ce2c595422,
    )),
    bytes([0x05]) + BlobTransactionNetworkWrapper(
        tx=SignedBlobTransaction(
            message=BlobTransaction(
                chain_id=cfg.chain_id,
                nonce=42,
                max_priority_fee_per_gas=69_123_456_789,
                max_fee_per_gas=69_123_456_789,
                gas=21_000,
                to=Union[None, ExecutionAddress](
                    selector=1,
                    value=ExecutionAddress(bytes.fromhex('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045')),
                ),
                value=3_141_592_653,
                data=bytes([]),
                access_list=[],
                max_fee_per_data_gas=0,
                blob_versioned_hashes=[
                    VersionedHash(bytes.fromhex('0190be472a05e72a4ae3ee7d166cc1e17defa2ae9c62d7b773833d632ebc9667'))
                ],
            ),
            signature=ECDSASignature(
                y_parity=True,
                r=0x74caac606a751efabe68b963d228c76359fb26966835b9531ba1c4627a8362a0,
                s=0x753beec95b58a8b103db199c24a975b1f2ffb348a060d17b8a2e9fff6d441cde,
            ),
        ),
        blob_kzgs=[
            KZGCommitment(bytes.fromhex('D9DCDA904EEF4B46BEC0435C56324724B93D53A2FF384F128ABA9FCF2AFDEC52DFEE966CE059497999F785B1DFEF898E')),
        ],
        blobs=[
            Vector[BLSFieldElement, FIELD_ELEMENTS_PER_BLOB](
                [BLSFieldElement(i) for i in range(FIELD_ELEMENTS_PER_BLOB)]),
        ],
        kzg_aggregated_proof=KZGProof(bytes.fromhex('3BD713674FB14B46938A768349ABA11B9A45EE94F50B4EB1BDB90FDFA40BDF59445E12541C2D4179938BC934709BB595')),
    ).encode_bytes(),
)

if __name__ == '__main__':
    for tx_index, encoded_signed_tx in enumerate(encoded_signed_txs):
        eip2718_type = encoded_signed_tx[0]
        if eip2718_type == 0x05:
            signed_tx = BlobTransactionNetworkWrapper.decode_bytes(encoded_signed_tx[1:]).tx
            tx_hash = compute_eip4844_tx_hash(signed_tx)
            encoded_signed_tx = bytes([0x05]) + signed_tx.encode_bytes()
        elif eip2718_type == 0x02:
            tx_hash = compute_eip1559_tx_hash(
                decode(encoded_signed_tx[1:], EIP1559SignedTransaction))
        elif eip2718_type == 0x01:
            tx_hash = compute_eip2930_tx_hash(
                decode(encoded_signed_tx[1:], EIP2930SignedTransaction))
        elif 0xc0 <= eip2718_type <= 0xfe:
            tx_hash = compute_legacy_tx_hash(
                decode(encoded_signed_tx, LegacySignedTransaction))
        else:
            assert False
        print(f'{tx_index} - {len(encoded_signed_tx)} bytes (Snappy: {len(compress(encoded_signed_tx))} bytes)')
        print(f'0x{tx_hash.hex()}')
        print(encoded_signed_tx[:1024].hex())
