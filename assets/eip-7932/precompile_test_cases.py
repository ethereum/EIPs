import secp256k1

from precompile import sigrecover_precompile
from eth_hash.auto import keccak

INVALID = b"\x00" * 32

secp256k1_test_key = bytes.fromhex("1f7627096fa44f0b850f5d9a859d271723ee856e526b947d0d4b011168bdcac1")
address = b"\x00" * 12 + bytes.fromhex("d3eF791e8a9c9BD26787D262e66e673FE8E7262A")

deadbeef_hash = bytes(keccak(bytes.fromhex("deadbeef")))

ecdsa = secp256k1.ECDSA()

zero_sig = secp256k1.PrivateKey(secp256k1_test_key, True).ecdsa_sign_recoverable(b"\x00" * 32, raw=True)
deadbeef_sig = secp256k1.PrivateKey(secp256k1_test_key, True).ecdsa_sign_recoverable(deadbeef_hash, raw=True)

zero_sig = ecdsa.ecdsa_recoverable_serialize(zero_sig)
deadbeef_sig = ecdsa.ecdsa_recoverable_serialize(deadbeef_sig)

# Test cases in format "input data" -> ("output", "gas_charged")
test_cases = [
    #
    # Invalid algorithm
    #
   
    # No data
    (b"", (INVALID, 3000)),

    # Invalid algorithm (without data)
    (b"\xFE", (INVALID, 3000)),

    # Invalid algorithm (with data at secp256k1 size)
    (b"\xFE" + b"\x01" * 65 + b"\x00" * 32, (INVALID, 3000)), 

    # Invalid algorithm (with data greater than secp256k1 size)
    (b"\xFE" + b"\x01" * 66 + b"\x00" * 32, (INVALID, 3000)),

    #
    # secp256k1
    # 

    # secp256k1 (without data)
    (b"\xFF", (INVALID, 3000)),

    # secp256k1 (too little data)
    (b"\xFF" + b"\xFE" * 64 + b"\x00" * 32, (INVALID, 3036)),

    # secp256k1 (erroneous data)
    (b"\xFF" + b"\xFE" * 67 + b"\x00" * 32, (INVALID, 3042)),

    # secp256k1 (invalid signature)
    (b"\xFF" + b"\xFE" * 65 + b"\x00" * 32, (INVALID, 3000)),

    # secp256k1 (valid signature)
    (b"\xFF" + zero_sig[0] + zero_sig[1].to_bytes(1, "big") + b"\x00" * 32, (address, 3000)),

    # secp256k1 (invalid signature + non 32 byte signing data size)
    (b"\xFF" + b"\xFE" * 65 + b"\x00" * 30, (INVALID, 3036)),

    # secp256k1 (valid signature + non 32 byte signing data size)
    (b"\xFF" + deadbeef_sig[0] + deadbeef_sig[1].to_bytes(1, "big") + bytes.fromhex("deadbeef"), (address, 3036)),
]


for (input, (address, gas)) in test_cases:
    (o_address, o_gas) = sigrecover_precompile(input)

    assert(str(address) == str(o_address))
    assert(gas == o_gas)

