from snark_lib import *
from utils.hash import *


def main():
    nullifier_preimage = NONRESERVED_PROGRAM_INPUT_START
    validator_key = nullifier_preimage + 8
    withdrawal_cred = validator_key + 13
    amount = withdrawal_cred + 9
    res = compute_commitment(nullifier_preimage, validator_key, withdrawal_cred, amount)
    for i in range(0, 8):
        print(res[i])
    return
