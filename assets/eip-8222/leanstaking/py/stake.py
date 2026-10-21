
from snark_lib import *
from utils.hash import *
from utils.merkle import *

# program constants
VALIDATOR_KEY_SIZE = 13
WITHDRAWAL_KEY_SIZE = 9
NULLIFIER_SIZE = 8
ROOT_SIZE = 8
NULLIFIER_PREIMAGE_SIZE = 8

# located at (NONRESERVED_PROGRAM_INPUT_START + inputs.public_inputs.len()).next_power_of_two()
# see https://github.com/leanEthereum/leanMultisig/blob/24a09fa9d884648fe8188383f9ae9781268d3b4c/crates/lean_vm/src/execution/runner.rs#L168
NONRESERVED_PROGRAM_PRIVATE_INPUT_START = 128


def main():
    levels = 32

    # public inputs
    validator_key = NONRESERVED_PROGRAM_INPUT_START
    withdrawal_cred = validator_key + VALIDATOR_KEY_SIZE
    amount = withdrawal_cred + WITHDRAWAL_KEY_SIZE
    nullifier = amount + 1
    root = nullifier + NULLIFIER_SIZE

    nullifier_preimage = NONRESERVED_PROGRAM_PRIVATE_INPUT_START
    leaf_sibling = nullifier_preimage + NULLIFIER_PREIMAGE_SIZE
    leaf_is_right_child = leaf_sibling + 8

    commitment = compute_commitment(
        nullifier_preimage, validator_key, withdrawal_cred, amount)
    computed_nullifier = compute_nullifier(nullifier_preimage)
    verify_path(levels, commitment, leaf_sibling, leaf_is_right_child, root)

    for i in range(0, NULLIFIER_SIZE):
        assert nullifier[i] == computed_nullifier[i]

    return
