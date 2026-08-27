from snark_lib import *


def dual_mux(a, b, switch):
    # asserts switch is 0 or 1
    assert switch[0] * (1 - switch[0]) == 0
    c = (b - a) * switch[0] + a
    d = (a - b) * switch[0] + b
    return c, d


def verify_path(levels: Const, leaf, leaf_sibling, is_right_child, root):
    node: Mut
    sibling: Mut
    flag: Mut

    path = DynArray([])
    node = Array(8)
    l, r = dual_mux(leaf, leaf_sibling, is_right_child)
    poseidon16_compress(l, r, node)

    sibling = is_right_child + 1
    flag = sibling + 8

    for _ in unroll(0, levels):
        l, r = dual_mux(node, sibling, flag)
        path_node = Array(8)
        poseidon16_compress(l, r, path_node)
        sibling = flag + 1
        flag = sibling + 8
        node = path_node
        path.push(node)

    final_node = path[levels - 1]
    for i in unroll(0, 8):
        assert root[i] == final_node[i]
    return
