from secp256k1 import PrivateKey
from create_transactions import *

if __name__ == '__main__':
    privkey = PrivateKey()

    for tx_index, encoded_signed_tx in enumerate(encoded_signed_txs):
        eip2718_type = encoded_signed_tx[0]
        if eip2718_type == 0x05:
            sig_hash = compute_eip4844_sig_hash(
                BlobTransactionNetworkWrapper.decode_bytes(encoded_signed_tx[1:]).tx)
        elif eip2718_type == 0x02:
            sig_hash = compute_eip1559_sig_hash(
                decode(encoded_signed_tx[1:], EIP1559SignedTransaction))
        elif eip2718_type == 0x01:
            sig_hash = compute_eip2930_sig_hash(
                decode(encoded_signed_tx[1:], EIP2930SignedTransaction))
        elif 0xc0 <= eip2718_type <= 0xfe:
            sig_hash = compute_legacy_sig_hash(
                decode(encoded_signed_tx, LegacySignedTransaction))
        else:
            assert False
        raw_sig = privkey.ecdsa_sign_recoverable(sig_hash, raw=True)
        sig, y_parity = privkey.ecdsa_recoverable_serialize(raw_sig)
        print(f'{tx_index}')
        print(f'y_parity = {y_parity}')
        print(f'r = 0x{sig[0:32].hex()}')
        print(f's = 0x{sig[32:64].hex()}')
