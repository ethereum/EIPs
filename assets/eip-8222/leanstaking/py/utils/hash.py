from snark_lib import *


def compute_commitment(nullifier_preimage, validator_key, withdrawal_cred, amount):
    # Memory layout (contiguous):
    #   nullifier_preimage (8) | validator_key (13) | withdrawal_cred (9) | amount (1)
    # Total: 31 field elements → 3 chained poseidon16 calls
    #
    # Call 1: hash(nullifier_preimage[0:8], validator_key[0:8])
    # Call 2: hash(h1, validator_key[8:13] | withdrawal_cred[0:3])  — contiguous at validator_key + 8
    # Call 3: hash(h2, last_block) — explicitly packed: withdrawal_cred[3:9] | amount | 0
    h1 = Array(8)
    poseidon16_compress(nullifier_preimage, validator_key, h1)
    h2 = Array(8)
    poseidon16_compress(h1, validator_key + 8, h2)
    last_block = Array(8)
    wc_tail = withdrawal_cred + 3
    for i in unroll(0, 6):
        last_block[i] = wc_tail[i]
    last_block[6] = amount[0]
    last_block[7] = 0
    commitment = Array(8)
    poseidon16_compress(h2, last_block, commitment)
    return commitment


def compute_nullifier(nullifier_preimage):
    nullifier = Array(8)
    poseidon16_compress(nullifier_preimage, nullifier_preimage, nullifier)
    return nullifier
