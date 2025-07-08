# Template secp256k1 variables
from typing import List, Tuple

ALG_TX_TYPE = b"\x07"
MAX_SIZE = 65
ALG_TYPE = 0
GAS_PENALTY = 0

# Make tx that has been signed for wrapping / unwrapping,
# this will use the internal signature parameters as they are secp256k1
# and should be valid.

def generate_tx_wrapping() -> Tuple[bytes, bytes, bytes, bytes, bytes]:
    from hexbytes import HexBytes
    from web3 import Web3
    import rlp

    w3 = Web3()
    acc = w3.eth.account.create()

    tx = {
        'to': '0x0000000000000000000000000000000000000000',
        'value': 1000000000,
        'gas': 2000000,
        'maxFeePerGas': 2000000000,
        'maxPriorityFeePerGas': 1000000000,
        'nonce': 0,
        'chainId': 1,
    }

    tx_signed = acc.sign_transaction(tx).raw_transaction
    tx_signed_rlp = rlp.decode(tx_signed[1:])

    tx_sig_data = tx_signed_rlp[-2] + tx_signed_rlp[-1] + (int.from_bytes(tx_signed_rlp[-3], "big") + 27).to_bytes(1, "big")

    tx_signed_rlp[-1] = HexBytes("0x")
    tx_signed_rlp[-2] = HexBytes("0x")
    tx_signed_rlp[-3] = HexBytes("0x")

    tx = tx_signed[0].to_bytes(1, "big") + rlp.encode(tx_signed_rlp)

    del tx_signed_rlp, tx_signed # Cleanup

    legacy_tx = {
        'to': '0x0000000000000000000000000000000000000000',
        'value': 1000000000,
        'gas': 2000000,
        'gasPrice': 2000000000,
        'nonce': 0,
        'chainId': 0x1234
    }

    legacy_tx_signed = rlp.decode(acc.sign_transaction(legacy_tx).raw_transaction)

    recover_id = int.from_bytes(legacy_tx_signed[-3], "big") - 35
    v = recover_id % 2
    chain_id = recover_id // 2

    legacy_tx_sig_data = legacy_tx_signed[-2] + legacy_tx_signed[-1] + ((v + 27).to_bytes(1, "big"))

    legacy_tx_signed[-1] = HexBytes("0x")
    legacy_tx_signed[-2] = HexBytes("0x")
    legacy_tx_signed[-3] = chain_id

    legacy_tx = rlp.encode(legacy_tx_signed)

    del legacy_tx_signed, recover_id, v, chain_id # Cleanup

    return (tx, tx_sig_data, legacy_tx, legacy_tx_sig_data, acc.address) # type: ignore

def generate_fee_txs_gas() -> Tuple[bytes, bytes, bytes]:
    from hexbytes import HexBytes
    from web3 import Web3
    import rlp

    w3 = Web3()
    acc = w3.eth.account.create()

    tx = {
        'to': '0x0000000000000000000000000000000000000000',
        'value': 1000000000,
        'gas': 21000,
        'maxFeePerGas': 2000000000,
        'maxPriorityFeePerGas': 1000000000,
        'nonce': 0,
        'chainId': 1,
    }

    tx_signed = acc.sign_transaction(tx).raw_transaction
    tx_signed_rlp = rlp.decode(tx_signed[1:])

    tx_sig_data = tx_signed_rlp[-2] + tx_signed_rlp[-1] + (int.from_bytes(tx_signed_rlp[-3], "big") + 27).to_bytes(1, "big")

    tx_signed_rlp[-1] = HexBytes("0x")
    tx_signed_rlp[-2] = HexBytes("0x")
    tx_signed_rlp[-3] = HexBytes("0x")

    tx = tx_signed[0].to_bytes(1, "big") + rlp.encode(tx_signed_rlp)

    return (tx, tx_sig_data, acc.address) # type: ignore

def generate_7702_tx(gas: int) -> Tuple[bytes, bytes, List[Tuple[int, bytes]], bytes]:
    from hexbytes import HexBytes
    from web3 import Web3, utils
    import rlp

    w3 = Web3()
    acc = w3.eth.account.create()

    signed_auth = acc.sign_authorization({
        "address": "0x0000000000000000000000000000000000000000",
        "nonce": 1,
        "chainId": 1,
    })

    signed_auth_2 = acc.sign_authorization({
        "address": "0x0000000000000000000000000000000000000001",
        "nonce": 2,
        "chainId": 1,
    })

    tx = {
        'to': '0x0000000000000000000000000000000000000000',
        'value': 1000000000,
        'gas': gas,
        'maxFeePerGas': 2000000000,
        'maxPriorityFeePerGas': 1000000000,
        'nonce': 0,
        "authorizationList": [signed_auth, signed_auth_2],
        'chainId': 1,
    }

    tx_signed = acc.sign_transaction(tx).raw_transaction
    tx_signed_rlp = rlp.decode(tx_signed[1:])

    sig_data = tx_signed_rlp[-4][1][-2] + tx_signed_rlp[-4][1][-1] + (int.from_bytes(tx_signed_rlp[-4][1][-3], "big") + 27).to_bytes(1, "big")

    tx_signed_rlp[-4][1][-1] = HexBytes("0x")
    tx_signed_rlp[-4][1][-2] = HexBytes("0x")
    tx_signed_rlp[-4][1][-3] = Web3.keccak(b"\x00" + sig_data)

    tx_signed = tx_signed[:1] + rlp.encode(tx_signed_rlp)

    auth_list = [(0x00, sig_data)]

    return (tx_signed, b"", auth_list, acc.address) # type: ignore

tx, tx_sig_data, legacy_tx, legacy_tx_sig_data, address = generate_tx_wrapping()

# Generate test cases for TX handling
import rlp, json, os

# Wrapping / Unwrapping normal and legacy tx

cases = []

cases.append({
    "name": "Tx decode bad signature format",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0x0, b"\x00" * 100, tx])).hex(),
    "output": None,
})

cases.append({
    "name": "Tx decode invalid signature",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0x0, b"\x00" * 65, tx])).hex(),
    "output": None,
})

cases.append({
    "name": "Tx decode null algorithm as main algorithm",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0xff, b"", tx])).hex(),
    "output": None,
})

cases.append({
    "name": "Valid tx decode EIP-1559",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0x0, tx_sig_data, tx])).hex(),
    "output": address,
})

mangled_tx = rlp.decode(tx[1:])
mangled_tx[-2] = b"erroneous data" # Invalid sig
mangled_tx = rlp.encode(mangled_tx)

cases.append({
    "name": "Invalid tx decode EIP-1559 `r`, `s`, `v` fields are not `0x`",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0x0, tx_sig_data, tx[0].to_bytes(1, "big") + mangled_tx])).hex(),
    "output": None,
})

cases.append({
    "name": "Valid tx decode legacy",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0x0, legacy_tx_sig_data, legacy_tx])).hex(),
    "output": address,
})

mangled_legacy_tx = rlp.decode(legacy_tx)
mangled_legacy_tx[-2] = b"erroneous data" # Invalid sig
mangled_legacy_tx = rlp.encode(mangled_legacy_tx)

cases.append({
    "name": "Inalid tx decode legacy `r`, `s` fields are not `0x`",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0x0, legacy_tx_sig_data, mangled_legacy_tx])).hex(),
    "output": None,
})

mangled_legacy_tx = rlp.decode(legacy_tx)
mangled_legacy_tx[-3] = 0x05 # Invalid chain id value
mangled_legacy_tx = rlp.encode(mangled_legacy_tx)

cases.append({
    "name": "Bad chain id tx decode legacy",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0x0, legacy_tx_sig_data, mangled_legacy_tx])).hex(),
    "output": None,
})

# Generate test cases with little gas

tx, tx_sig_data, addr = generate_fee_txs_gas()

cases.append({
    "name": "Inalid tx not enough gas",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0xfe, b"\x00" * 256, mangled_legacy_tx])).hex(),
    "output": None,
})

with open(os.path.join(os.path.dirname(__file__), "transactions.json"), "w") as f:
    json.dump(cases, f, indent=4)

# Generate test cases with `additional_info`

cases = []

tx, _sig_data, auth_info, addr = generate_7702_tx(200000)

cases.append({
    "name": "Valid 7702 tx, 2 authorizations",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0xff, b"", tx, auth_info])).hex(),
    "output": [addr, addr, addr],
})

mangled_auth_info = auth_info
mangled_auth_info[0] = (mangled_auth_info[0][0], b"\x00")

cases.append({
    "name": "Invalid 7702 tx, bad signature",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0xff, b"", tx, mangled_auth_info])).hex(),
    "output": None,
})

mangled_tx = rlp.decode(tx[1:])
mangled_tx[-4][1][-3] = b"\x00"
mangled_tx = tx[:1] + rlp.encode(mangled_tx)

cases.append({
    "name": "Invalid 7702 tx, bad signature",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0xff, b"", mangled_tx, auth_info])).hex(),
    "output": None,
})


tx, _sig_data, auth_info, addr = generate_7702_tx(21000 + (2 * 25000))

auth_info.append((0xfe, b"\x00" * 200))

cases.append({
    "name": "Invalid 7702 tx, not enough gas",
    "tx": "0x" + (ALG_TX_TYPE + rlp.encode([0xff, b"", tx, auth_info])).hex(),
    "output": None,
})

with open(os.path.join(os.path.dirname(__file__), "additional_info.json"), "w") as f:
    json.dump(cases, f, indent=4)

# Generate test cases for Sigrecover Precompile

from Crypto.Hash import keccak
import coincurve

cases = []

private = coincurve.PrivateKey.from_int(0x10)

k = keccak.new(digest_bits=256)
k.update(private.public_key.format(False)[1:])
addr = '0x' + k.digest()[-20:].hex()

cases.append({
    "name": "Valid sigrecover secp256k1",
    "input": "0x" + ((b"\xFF" * 32) + b"\x00" + (65).to_bytes(31, "little") + private.sign_recoverable(b"\xFF" * 32, None)).hex(),
    "output": addr,
})

cases.append({
    "name": "Invalid NULL algorithm sigrecover",
    "input": "0x" + ((b"\xFF" * 32) + b"\xFF" + (65).to_bytes(31, "little") + private.sign_recoverable(b"\xFF" * 32, None)).hex(),
    "output": "0x" + ("00" * 20),
})

cases.append({
    "name": "Invalid badsize sigrecover",
    "input": "0x" + ((b"\xFF" * 32) + b"\x00" + (128).to_bytes(31, "little") + b"\x00" * 128).hex(),
    "output": "0x" + ("00" * 20),
})

cases.append({
    "name": "Invalid badformat sigrecover",
    "input": "0x" + ((b"\xFF" * 32) + b"\x00" + (128).to_bytes(31, "little") + b"\x00" * 7).hex(),
    "output": "0x" + ("00" * 20),
})

with open(os.path.join(os.path.dirname(__file__), "precompile.json"), "w") as f:
    json.dump(cases, f, indent=4)
