# SPDX-License-Identifier: CC0-1.0
"""Prepare private input for the local EIP-8425 prover."""
import argparse
import getpass
import hashlib
import sys
import unicodedata
import warnings


def hex_bytes(value, size):
    digits = value[2:] if value.startswith("0x") else value
    if len(digits) != 2 * size:
        raise ValueError(f"expected {size} bytes of hexadecimal")
    raw = bytes.fromhex(digits)
    if len(raw) != size:
        raise ValueError("embedded whitespace in hexadecimal input")
    return raw


def encode_witness(mnemonic, passphrase, account_index, change, address_index,
                   chain_id, nonce, source, code_hash):
    if not (0 <= account_index < 2**31 and 0 <= address_index < 2**31 and change in (0, 1)):
        raise ValueError("expected a BIP-44 account index, change index and address index")
    if not (0 <= chain_id < 2**256 and 0 <= nonce < 2**64):
        raise ValueError("chain ID or nonce out of range")
    if len(source) != 20 or len(code_hash) != 32:
        raise ValueError("expected a 20-byte source address and 32-byte code hash")
    words = unicodedata.normalize("NFKD", mnemonic).encode("utf-8")
    salt = b"mnemonic" + unicodedata.normalize("NFKD", passphrase).encode("utf-8")
    seed = hashlib.pbkdf2_hmac("sha512", words, salt, 2048, dklen=64)
    path = b"".join(i.to_bytes(4, "big") for i in (account_index, change, address_index))
    return seed + path + chain_id.to_bytes(32, "big") + nonce.to_bytes(8, "big") + source + code_hash


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chain-id", type=int, required=True)
    parser.add_argument("--nonce", type=int, required=True)
    parser.add_argument("--source", required=True, help="deployed source address, hex")
    parser.add_argument("--code-hash", required=True, help="Keccak-256 of source runtime, hex")
    parser.add_argument("--account-index", type=int, default=0)
    parser.add_argument("--change", type=int, choices=(0, 1), default=0)
    parser.add_argument("--address-index", type=int, default=0)
    args = parser.parse_args()
    if sys.stdout.isatty():
        parser.error("pipe the private witness directly to the local prover")
    try:
        source = hex_bytes(args.source, 20)
        code_hash = hex_bytes(args.code_hash, 32)
        with warnings.catch_warnings():
            warnings.simplefilter("error", getpass.GetPassWarning)
            mnemonic = getpass.getpass("BIP-39 mnemonic: ")
            passphrase = getpass.getpass("BIP-39 passphrase (empty if unused): ")
        witness = encode_witness(
            mnemonic, passphrase, args.account_index, args.change, args.address_index, args.chain_id, args.nonce, source, code_hash,
        )
    except getpass.GetPassWarning:
        parser.error("a terminal with hidden input is required to enter a mnemonic")
    except ValueError as err:
        parser.error(str(err))
    sys.stdout.buffer.write(witness)


if __name__ == "__main__":
    main()
