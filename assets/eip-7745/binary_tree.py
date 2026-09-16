"""
Binary Merkle Tree.

.. contents:: Table of Contents
    :backlinks: none
    :local:

"""

from dataclasses import dataclass, field
from typing import Callable, Dict

from ethereum_types.numeric import U256, Uint


@dataclass
class BinaryTree:
    """
    Binary Merkle Tree.
    """

    binary_hash: Callable[[U256, U256], U256]
    empty_node: Callable[[U256], U256]
    _data: Dict[U256, U256] = field(default_factory=dict)


GTI_ROOT = U256(1)
GTI_MAX_LEVEL = U256(1) << 255


def btree_get(tree: BinaryTree, index: U256) -> U256:
    """
    Returns the node value at the given generalized tree index. If it is an
    internal node with an invalidated value then the value is recursively
    recalculated on demand and also cached for future use.

    Note that this function does not automatically expand previously untouched
    empty subtrees.
    """
    if index not in tree._data:
        if index >= GTI_MAX_LEVEL:
            raise AssertionError("Trying to get non-existent node")
        left = btree_get(tree, index * 2)
        right = btree_get(tree, index * 2 + 1)
        tree._data[index] = tree.binary_hash(left, right)
    return tree._data[index]


def btree_set(tree: BinaryTree, index, value: U256) -> None:
    """
    Sets the leaf node value at the given generalized tree index and
    invalidates any cached ancestor nodes. If the node did not exist previously
    then it expands the tree, assuming that it is an empty, previously
    untouched region.
    """
    if index not in tree._data:
        btree_expand(tree, index)
    tree._data[index] = value
    _invalidate_ancestors(tree, index)


def _invalidate_ancestors(tree: BinaryTree, index: U256) -> None:
    """
    Invalidates ancestors of the given node, moving down towards the root until
    an already invalidated node is found. It is assumed that an invalidated
    node always has invalidated ancestors.
    """
    while index != GTI_ROOT:
        index //= 2
        if index not in tree._data:
            return
        del tree._data[index]


def btree_expand(tree: BinaryTree, index: U256) -> None:
    """
    Expands the tree ensuring that the given node exists and can be updated,
    assuming that it is in an empty, previously untouched region.

    Note that empty tree expansion relies on the empty_node callback function
    that defines the tree structure. This structure might include optional
    containers that are represented by a node that can either have a zero value
    or the root hash of the container. Expanding the tree beyond the root node
    of such a container initializes the container, changing the actual contents
    of the tree. For this reason an expand operation invalidates the ancestors
    of the expanded node.
    """
    if index in tree._data:
        if tree._data[index] != tree.empty_node(index):
            raise AssertionError("Trying to expand non-empty subtree")
        return
    tree._data[index] = tree.empty_node(index)
    if index == GTI_ROOT:
        return
    parent = index // 2
    sibling = parent * 4 + 1 - index
    btree_expand(tree, parent)
    tree._data[sibling] = tree.empty_node(sibling)
    _invalidate_ancestors(tree, index)


def btree_collapse(tree: BinaryTree, index: U256) -> None:
    """
    Collapses the descendants of the given node into a single hash node.

    Note that a collapsed subtree should not be expanded again.
    """
    btree_get(tree, index)
    if index * 2 in tree._data:
        btree_collapse(tree, index * 2)
        del tree._data[index * 2]
    if index * 2 + 1 in tree._data:
        btree_collapse(tree, index * 2 + 1)
        del tree._data[index * 2 + 1]


def gti_height(index: U256) -> Uint:
    """
    Returns the height of a generalized tree index. The height of the root node
    is zero, all other nodes have the height of their parent plus one.
    """
    # TODO: more efficient implementation?
    height = Uint(0)
    while index > GTI_ROOT:
        height += 1
        index >>= 1
    return height


def gti_vector(root: U256, index, height: Uint) -> U256:
    """
    Returns the generalized tree index of a vector item.
    """
    return root << height + index


def gti_merge(index, sub_index: U256) -> U256:
    """
    Returns the generalized tree index that has a relative position sub_index
    from the position index.
    """
    sub_height = gti_height(sub_index)
    return (index - 1) << sub_height + sub_index


def gti_split_below(index: U256, level: Uint) -> U256:
    """
    Splits the path leading to the given generalized tree index at the
    specified height and returns the index at the given height. If the height
    of the given index is less than the specified level then the original
    index is returned.
    """
    height = gti_height(index)
    if height > level:
        index >>= height - level
    return index


def gti_split_above(index: U256, level: Uint) -> U256:
    """
    Splits the path leading to the given generalized tree index at the
    specified height and returns the relative sub-index pointing to the
    original index from the given height. If the height of the given index is
    less than the specified level then the root index is returned.
    """
    height = gti_height(index)
    if height <= level:
        return GTI_ROOT
    gti_base = GTI_ROOT << height - level
    return gti_base + (index & (gti_base - 1))
