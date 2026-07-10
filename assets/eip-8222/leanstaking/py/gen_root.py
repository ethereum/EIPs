
from snark_lib import *
from utils.hash import *
from utils.merkle import *

LEVELS = 32

def main():
    # public inputs: all commitment data + merkle path data
    nullifier_preimage = NONRESERVED_PROGRAM_INPUT_START
    validator_key = nullifier_preimage + 8
    withdrawal_cred = validator_key + 13
    amount = withdrawal_cred + 9

    leaf_sibling = amount + 1
    leaf_is_right_child = leaf_sibling + 8

    commitment = compute_commitment(
        nullifier_preimage, validator_key, withdrawal_cred, amount)

    # same logic as verify_path
    node: Mut
    sibling: Mut
    flag: Mut

    node = Array(8)
    l, r = dual_mux(commitment, leaf_sibling, leaf_is_right_child)
    poseidon16_compress(l, r, node)

    sibling = leaf_is_right_child + 1
    flag = sibling + 8

    path = DynArray([])
    for _ in unroll(0, LEVELS):
        l, r = dual_mux(node, sibling, flag)
        path_node = Array(8)
        poseidon16_compress(l, r, path_node)
        sibling = flag + 1
        flag = sibling + 8
        node = path_node
        path.push(node)

    final_node = path[LEVELS - 1]
    for i in range(0, 8):
        print(final_node[i])
    return
