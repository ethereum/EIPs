import secp256k1

import algorithm_registry

INVALID = "0x0000000000000000000000000000000000000000"

secp256k1_test_key = bytes.fromhex("1f7627096fa44f0b850f5d9a859d271723ee856e526b947d0d4b011168bdcac1")
address = "0xd3eF791e8a9c9BD26787D262e66e673FE8E7262A"

ecdsa = secp256k1.ECDSA()

zero_sig = secp256k1.PrivateKey(secp256k1_test_key, True).ecdsa_sign(b"\x00" * 32, raw=True)
zero_sig = ecdsa.ecdsa_recoverable_serialize(zero_sig)[0]

# Test cases in format "input data" -> ("output", "gas_charged")
test_cases = [
    """
    Invalid algorithm
    """
    
    # Invalid algorithm (without data)
    (b"\xFE" + b"\x20" + b"\x00" * 32, (INVALID, 3000)),

    # Invalid algorithm (with data at secp256k1 size)
    (b"\xFE" + b"\x01" * 65 + b"\x20" + b"\x00" * 32, (INVALID, 3000)), 
    
    # Invalid algorithm (with data greater than secp256k1 size)
    (b"\xFE" + b"\x01" * 66 + b"\x20" + b"\x00" * 32, (INVALID, 3016)),

    """
    secp256k1
    """

    # secp256k1 (without data)
    (b"\xFF" + b"\x20" + b"\x00" * 32, (INVALID, 3000)),

    # secp256k1 (too little data)
    (b"\xFF" + b"\xFE" * 64 + b"\x20" + b"\x00" * 32, (INVALID, 3000)),
    
    # secp256k1 (erroneous data)
    (b"\xFF" + b"\xFE" * 67 + b"\x20" + b"\x00" * 32, (INVALID, 3032)),

    # secp256k1 (invalid signature)
    (b"\xFF" + b"\xFE" * 65 + b"\x20" + b"\x00" * 32, (INVALID, 3000)),

    # secp256k1 (valid signature)
    (b"\xFF" + zero_sig + b"\x20" + b"\x00" * 32, (address, 3000)),
]




