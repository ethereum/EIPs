from typing import Any, Sequence, Set, Union as PyUnion
from hashlib import sha256
from remerkleable.basic import uint64
from remerkleable.byte_arrays import Bytes32
from remerkleable.core import Path
from remerkleable.tree import Gindex as GeneralizedIndex, gindex_bit_iter

SSZVariableName = str

class Root(Bytes32):
    pass

def floorlog2(x: int) -> uint64:
    if x < 1:
        raise ValueError(f"floorlog2 accepts only positive values, x={x}")
    return uint64(x.bit_length() - 1)

def get_generalized_index(ssz_class: Any, *path: Sequence[PyUnion[int, SSZVariableName]]) -> GeneralizedIndex:
    ssz_path = Path(ssz_class)
    for item in path:
        ssz_path = ssz_path / item
    return GeneralizedIndex(ssz_path.gindex())

def build_proof(anchor, leaf_index):
    if leaf_index <= 1:
        return []  # Nothing to prove / invalid index
    node = anchor
    proof = []
    # Walk down, top to bottom to the leaf
    bit_iter, _ = gindex_bit_iter(leaf_index)
    for bit in bit_iter:
        # Always take the opposite hand for the proof.
        # 1 = right as leaf, thus get left
        if bit:
            proof.append(node.get_left().merkle_root())
            node = node.get_right()
        else:
            proof.append(node.get_right().merkle_root())
            node = node.get_left()

    return list(reversed(proof))

def hash(x: PyUnion[bytes, bytearray, memoryview]) -> Bytes32:
    return Bytes32(sha256(x).digest())

def generalized_index_parent(index: GeneralizedIndex) -> GeneralizedIndex:
    return GeneralizedIndex(index // 2)

def generalized_index_sibling(index: GeneralizedIndex) -> GeneralizedIndex:
    return GeneralizedIndex(index ^ 1)

def get_branch_indices(tree_index: GeneralizedIndex) -> Sequence[GeneralizedIndex]:
    o = [generalized_index_sibling(tree_index)]
    while o[-1] > 1:
        o.append(generalized_index_sibling(generalized_index_parent(o[-1])))
    return o[:-1]

def get_path_indices(tree_index: GeneralizedIndex) -> Sequence[GeneralizedIndex]:
    o = [tree_index]
    while o[-1] > 1:
        o.append(generalized_index_parent(o[-1]))
    return o[:-1]

def get_helper_indices(indices: Sequence[GeneralizedIndex]) -> Sequence[GeneralizedIndex]:
    all_helper_indices: Set[GeneralizedIndex] = set()
    all_path_indices: Set[GeneralizedIndex] = set()
    for index in indices:
        all_helper_indices = all_helper_indices.union(set(get_branch_indices(index)))
        all_path_indices = all_path_indices.union(set(get_path_indices(index)))

    return sorted(all_helper_indices.difference(all_path_indices), reverse=True)

def calculate_multi_merkle_root(leaves: Sequence[Bytes32],
                                proof: Sequence[Bytes32],
                                indices: Sequence[GeneralizedIndex],
                                helper_indices: Sequence[GeneralizedIndex]) -> Root:
    assert len(leaves) == len(indices)
    assert len(proof) == len(helper_indices)
    objects = {
        **{index: Bytes32(node) for index, node in zip(indices, leaves)},
        **{index: Bytes32(node) for index, node in zip(helper_indices, proof)}
    }
    keys = sorted(objects.keys(), reverse=True)
    pos = 0
    while pos < len(keys):
        k = keys[pos]
        if k in objects and k ^ 1 in objects and k // 2 not in objects:
            objects[GeneralizedIndex(k // 2)] = hash(
                objects[GeneralizedIndex((k | 1) ^ 1)] +
                objects[GeneralizedIndex(k | 1)]
            )
            keys.append(GeneralizedIndex(k // 2))
        pos += 1
    return objects[GeneralizedIndex(1)]
