"""
Log Index.

.. contents:: Table of Contents
    :backlinks: none
    :local:

"""

from dataclasses import field
from hashlib import sha256
from typing import List, Tuple

from ethereum_rlp import rlp
from ethereum_types.numeric import U64, U256, Uint

from ethereum.crypto.hash import Hash32, keccak256

from .base_types import Address, Bytes
from .binary_tree import (
    GTI_ROOT,
    BinaryTree,
    btree_collapse,
    btree_expand,
    btree_get,
    btree_set,
    gti_height,
    gti_merge,
    gti_split_above,
    gti_split_below,
    gti_vector,
)
from .blocks import Header, Log
from .fork_types import Root

LOG2_EPOCH_HISTORY = Uint(24)
LOG2_MAPS_PER_EPOCH = Uint(10)
LOG2_VALUES_PER_MAP = Uint(16)
LOG2_MAP_WIDTH = Uint(24)
LOG2_MAP_HEIGHT = Uint(16)
LOG2_MAPPING_FREQUENCY: List[Uint] = [10, 6, 2, 0]
MAX_ROW_LENGTH: List[Uint] = [8, 168, 2728, 10920]
PROG_LIST_HEIGHT_FIRST = Uint(0)
PROG_LIST_HEIGHT_STEP = Uint(2)

MAPS_PER_EPOCH = Uint(1) << LOG2_MAPS_PER_EPOCH
VALUES_PER_MAP = Uint(1) << LOG2_VALUES_PER_MAP
MAP_HEIGHT = Uint(1) << LOG2_MAP_HEIGHT

# absolute generalized tree indices
GTI_EPOCH_HISTORY = U256(2)
GTI_NEXT_ENTRY = U256(3)
# relative to epoch root
GTI_FILTER_MAPS = U256(2)
GTI_INDEX_ENTRIES = U256(3)
# relative to list root (progressive or regular)
GTI_LIST_TREE = U256(2)
GTI_LIST_COUNT = U256(3)
# relative to progressive list tree root
GTI_PROG_LIST_SUBTREE = U256(2)
GTI_PROG_LIST_NEXT_TREE = U256(3)
# relative to log entry root
GTI_LOG_ENTRY = U256(2)
GTI_ENTRY_META = U256(3)
# relative to log data rootINDEX
GTI_LOG_ADDRESS = U256(4)
GTI_LOG_TOPICS = U256(5)
GTI_LOG_DATA = U256(6)
# relative to entry meta root
GTI_ENTRY_META_FIELD_0 = U256(4)
GTI_ENTRY_META_FIELD_1 = U256(5)
GTI_ENTRY_META_FIELD_2 = U256(6)
GTI_ENTRY_META_FIELD_3 = U256(7)


class LogIndexState:
    """
    Contains all information required to append the log index and calculate its
    root hash.
    """

    tree: BinaryTree = field(
        default_factory=lambda: BinaryTree(
            binary_hash=_binary_hash,
            empty_node=log_index_empty_node,
        )
    )
    next_entry: Uint


def log_index_root(log_index: LogIndexState) -> Root:
    """
    Returns the current root hash of the log index tree.
    """
    return Root(btree_get(log_index.tree, GTI_ROOT))


def log_index_add_tx_entry(
    log_index: LogIndexState,
    block_number: Uint,
    tx_hash,
    receipt_hash: Hash32,
    tx_index: Uint,
) -> None:
    """
    Adds a transaction delimiter to the log index at the current next_entry
    position.
    """
    prepare_index(log_index, 1)
    add_to_filter_maps(log_index, map_value_hash_tx(tx_hash))
    add_entry_meta(
        log_index,
        U256(block_number),
        U256(tx_hash),
        U256(tx_index),
        U256(receipt_hash),
    )
    advance_index(log_index, 1)


def log_index_add_block_entry(
    log_index: LogIndexState, header: Header
) -> None:
    """
    Adds a block delimiter to the log index at the current next_entry position.
    """
    prepare_index(log_index, 1)
    block_hash = keccak256(rlp.encode(header))
    add_to_filter_maps(log_index, map_value_hash_block(block_hash))
    add_entry_meta(
        log_index,
        U256(header.number),
        U256(block_hash),
        header.timestamp,
        U256(0),
    )
    advance_index(log_index, 1)


def log_index_add_log_entries(
    log_index: LogIndexState,
    block_number: Uint,
    tx_hash: Hash32,
    tx_index: Uint,
    logs: Tuple[Log, ...],
) -> None:
    """
    Adds address and topic entries to the current filter map and a log entry to
    the index entries tree according to the given list of log events.
    """
    log_index = Uint(0)
    for log in logs:
        prepare_index(log_index, Uint(len(log.topics) + 1))
        add_to_filter_maps(log_index, map_value_hash_address(log.address))
        add_log_entry(log_index, log)
        add_entry_meta(
            log_index,
            U256(block_number),
            U256(tx_hash),
            U256(tx_index),
            U256(0),
        )
        advance_index(log_index, 1)
        for topic in log.topics:
            add_to_filter_maps(log_index, map_value_hash_topic(topic))
            advance_index(log_index, 1)


def prepare_index(log_index: LogIndexState, count: Uint) -> None:
    """
    Prepares the log index before adding the given number of entries by
    expanding the rows of the next filter map if the previous one has been
    filled.

    Note that a batch of entries belonging to a single log cannot be split
    between two maps so the function also pads the end of the current map with
    empty entries and starts a new one if the old one does not have enough
    space left.
    """
    map_remaining = VALUES_PER_MAP - log_index.next_entry % VALUES_PER_MAP
    if map_remaining < count:
        advance_index(log_index, map_remaining)
        map_remaining = VALUES_PER_MAP
    if map_remaining == VALUES_PER_MAP:  # initialize new map
        map_index = log_index.next_entry // VALUES_PER_MAP
        for row_index in range(MAP_HEIGHT):  # expand prog list of each row
            prog_list_root = map_row_gti(map_index, row_index)
            expand_node = gti_merge(prog_list_root, GTI_LIST_COUNT)
            btree_expand(log_index.tree, expand_node)


def advance_index(log_index: LogIndexState, count: Uint) -> None:
    """
    Collapses the given number of index entries starting from the current
    next_entry pointer while also advancing the pointer. If the current map is
    filled then its rows are also collapsed.

    Note that this function should always be called after adding an entry to
    the current position. It may also be called without adding anything which
    results in empty collapsed index entries and no row entries added to the
    filter map.
    """
    if log_index.next_entry % VALUES_PER_MAP == 0:
        collapse_map(log_index.next_entry // VALUES_PER_MAP - 1)
    for _ in range(count):
        collapse_subtree(log_index, index_entry_gti(log_index.next_entry))
        log_index.next_entry += 1
    btree_set(log_index.tree, GTI_NEXT_ENTRY, U256(log_index.next_entry))


def collapse_subtree(log_index: LogIndexState, gti: U256) -> None:
    """
    Collapses the biggest subtree of the entire log index tree that has the
    given generalized tree index on its path of rightmost descendants.

    Note that this incremental collapse logic assumes that for any internal
    node of the entire log index tree, the rightmost descendant of the left
    child is collapsed before the rightmost descendant of the right child so
    that the parent is collapsed after the subtree is completed.

    A practical implementation that actually needs the generated tree structure
    should save the collapsed subtrees to a persistent database.
    Also a practical implementation might only collapse the parts of the index
    generated by a block that has actually been finalized, so that reverting
    a block can be realized by rolling back recent additions to the index.
    """
    while (gti & U256(1)) == 1 and gti != GTI_ROOT:
        gti //= 2
    btree_collapse(log_index.tree, gti)


def collapse_map(log_index: LogIndexState, map_index: Uint) -> None:
    """
    Collapses each row of the given filter map.

    Note that the incremental collapse logic (see collapse_subtree)
    is applied here too and maps should also be collapsed in a strictly
    increasing order. This also ensures that collapsing each map of an epoch
    finally collapses the entire filter maps subtree. It also assumes that the
    last index entry of the epoch is collapsed after the last map, finally
    collapsing the entire epoch tree.
    """
    for row_index in range(MAP_HEIGHT):
        collapse_subtree(log_index, map_row_gti(map_index, row_index))


def map_value_hash_address(address: Address) -> Hash32:
    """
    Returns the filter mapping hash for log address entries.
    """
    return Hash32(sha256(address).digest())


def map_value_hash_topic(topic: Hash32) -> Hash32:
    """
    Returns the filter mapping hash for log topic entries.
    """
    return Hash32(sha256(topic).digest())


def map_value_hash_tx(tx_hash: Hash32) -> Hash32:
    """
    Returns the filter mapping hash for transaction delimiter entries.
    """
    return Hash32(sha256(tx_hash + b"\x01").digest())


def map_value_hash_block(block_hash: Hash32) -> Hash32:
    """
    Returns the filter mapping hash for block delimiter entries.
    """
    return Hash32(sha256(block_hash + b"\x02").digest())


def add_to_filter_maps(
    log_index: LogIndexState, map_value_hash: Hash32
) -> None:
    """
    Adds the given entry hash to the current filter map at the current
    next_entry position.
    """
    map_index = log_index.next_entry // VALUES_PER_MAP
    layer_index = Uint(0)
    while True:
        row_index = get_row_index(map_index, layer_index, map_value_hash)
        map_row_root = map_row_gti(map_index, row_index)
        count_node = gti_merge(map_row_root, GTI_LIST_COUNT)
        row_length = Uint(btree_get(log_index.tree, count_node))
        max_length = MAX_ROW_LENGTH[min(layer_index, len(MAX_ROW_LENGTH) - 1)]
        if row_length < max_length:
            column = get_column_index(log_index.next_entry, map_value_hash)
            chunk_node = prog_list_chunk_gti(map_row_root, row_length // 8)
            chunk = U256(0)
            chunk_subindex = row_length % 8
            if chunk_subindex > 0:
                chunk = btree_get(log_index.tree, chunk_node)
            chunk += U256(column) << (32 * chunk_subindex)
            btree_set(log_index.tree, chunk_node, chunk)
            row_length += 1
            btree_set(log_index.tree, count_node, U256(row_length))
            return


def add_log_entry(log_index: LogIndexState, log: Log) -> None:
    """
    Adds the given log entry to the index entry at the current next_entry
    position.
    """
    index_entry_root = index_entry_gti(log_index.next_entry)
    log_entry_root = gti_merge(index_entry_root, GTI_LOG_ENTRY)
    address_node = gti_merge(log_entry_root, GTI_LOG_ADDRESS)
    btree_set(log_index.tree, address_node, U256(log.address))
    topics_root = gti_merge(log_entry_root, GTI_LOG_TOPICS)
    list_tree_root = gti_merge(topics_root, GTI_LIST_TREE)
    for i in range(len(log.topics)):
        topic_node = gti_vector(list_tree_root, i, 2)
        btree_set(log_index.tree, topic_node, U256(log.topics[i]))
    btree_set(
        log_index.tree,
        gti_merge(topics_root, GTI_LIST_COUNT),
        U256(len(log.topics)),
    )
    data_root = gti_merge(log_entry_root, GTI_LOG_DATA)
    for i in range((len(log.data) + 31) // 32):
        chunk_node = prog_list_chunk_gti(data_root, i)
        chunk_data = U256.from_le_bytes(log.data[i * 32 : (i + 1) * 32])
        btree_set(log_index.tree, chunk_node, chunk_data)
    count_node = gti_merge(data_root, GTI_LIST_COUNT)
    btree_set(log_index.tree, log_index, count_node, U256(len(log.data)))


def add_entry_meta(
    log_index: LogIndexState,
    field_0,
    field_1,
    field_2,
    field_3: U256,
) -> None:
    """
    Adds the given entry meta to the index entry at the current next_entry
    position.
    """
    root = gti_merge(index_entry_gti(log_index.next_entry), GTI_ENTRY_META)
    btree_set(log_index.tree, gti_merge(root, GTI_ENTRY_META_FIELD_0), field_0)
    btree_set(log_index.tree, gti_merge(root, GTI_ENTRY_META_FIELD_1), field_1)
    btree_set(log_index.tree, gti_merge(root, GTI_ENTRY_META_FIELD_2), field_2)
    btree_set(log_index.tree, gti_merge(root, GTI_ENTRY_META_FIELD_3), field_3)


def get_row_index(
    map_index, layer_index: Uint, map_value_hash: Hash32
) -> Uint:
    """
    Returns the row index where the given map value hash is mapped on the given
    map and mapping layer.
    """
    mf_index = min(layer_index, len(LOG2_MAPPING_FREQUENCY) - 1)
    mapping_frequency = Uint(1) << LOG2_MAPPING_FREQUENCY[mf_index]
    masked_map_index = map_index - (map_index % mapping_frequency)
    row_hash = sha256(
        map_value_hash
        + masked_map_index.to_le_bytes4()
        + layer_index.to_le_bytes4()
    ).digest()
    return Uint.from_le_bytes(row_hash[0:4]) % MAP_HEIGHT


def get_column_index(map_value_index: Uint, map_value_hash: Hash32) -> Uint:
    """
    Returns the column index where the given entry hash is mapped at the given
    entry index.
    """
    col_hash = _fnv1a_64(map_value_index.to_le_bytes8() + map_value_hash)
    folded_hash = (col_hash >> 32) ^ (col_hash & 0xFFFFFFFF)
    hash_bits = LOG2_MAP_WIDTH - LOG2_VALUES_PER_MAP
    return (
        (map_value_index % VALUES_PER_MAP)
        << hash_bits + folded_hash
        >> (32 - hash_bits)
    )


def _binary_hash(left, right: U256) -> U256:
    """
    Returns the SHA2 binary tree hash of two given descendants.
    """
    node_hash = sha256(left.to_le_bytes32() + right.to_le_bytes32()).digest()
    return U256.from_le_bytes(node_hash)


def _fnv1a_64(data: Bytes) -> U64:
    """
    Returns the FNV1A64 hash of the input.
    """
    fnv_prime = U64(0x100000001B3)
    hash_val = U64(0xCBF29CE484222325)
    for byte in data:
        hash_val ^= byte
        hash_val = (hash_val * fnv_prime) & 0xFFFFFFFFFFFFFFFF
    return hash_val


def index_entry_gti(map_entry_index: Uint) -> U256:
    """
    Returns the generalized tree index of the root of the given index entry.
    """
    epoch_index = map_entry_index // (MAPS_PER_EPOCH * VALUES_PER_MAP)
    sub_index = map_entry_index % (MAPS_PER_EPOCH * VALUES_PER_MAP)
    epoch_root = gti_vector(GTI_EPOCH_HISTORY, epoch_index, LOG2_EPOCH_HISTORY)
    index_entires_root = gti_merge(epoch_root, GTI_INDEX_ENTRIES)
    return gti_vector(
        index_entires_root,
        sub_index,
        LOG2_MAPS_PER_EPOCH + LOG2_VALUES_PER_MAP,
    )


def map_row_gti(map_index, row_index: Uint) -> U256:
    """
    Returns the generalized tree index of the root of the progressive list
    representing the given filter map row.
    """
    epoch_index = map_index // MAPS_PER_EPOCH
    map_sub_index = map_index % MAPS_PER_EPOCH
    epoch_root = gti_vector(GTI_EPOCH_HISTORY, epoch_index, LOG2_EPOCH_HISTORY)
    filter_maps_root = gti_merge(epoch_root, GTI_FILTER_MAPS)
    return gti_vector(
        filter_maps_root,
        row_index * MAPS_PER_EPOCH + map_sub_index,
        LOG2_MAP_HEIGHT + LOG2_MAPS_PER_EPOCH,
    )


def prog_list_chunk_gti(list_root: U256, chunk_index: Uint) -> U256:
    """
    Returns the generalized tree index for the data chunk node with the given
    chunk index.
    """
    gti = gti_merge(list_root, GTI_LIST_TREE)
    height = PROG_LIST_HEIGHT_FIRST
    while chunk_index >= Uint(1) << height:
        chunk_index -= Uint(1) << height
        gti = gti_merge(gti, GTI_PROG_LIST_NEXT_TREE)
        height += PROG_LIST_HEIGHT_STEP
    subtree_root = gti_merge(gti, GTI_PROG_LIST_SUBTREE)
    return gti_vector(subtree_root, chunk_index, height)


def _make_empty_vector_nodes(length: Uint) -> List[U256]:
    """
    Calculates the tree node values of an empty vector. Item 0 is zero (empty
    value) while item i is the root of a vector or a vector subtree with a max
    length of 2 ** i.
    """
    roots = []
    next_root = U256(0)
    for _ in range(length):
        roots.append(next_root)
        next_root = _binary_hash(next_root, next_root)
    return roots


_empty_vector_nodes = _make_empty_vector_nodes(256)
_empty_log_index_root = _binary_hash(
    _empty_vector_nodes[LOG2_EPOCH_HISTORY], U256(0)
)


def log_index_empty_node(index: U256) -> U256:
    """
    Returns the default empty node value of the log index tree at the given
    generalized tree index. This function is used by BinaryTree for
    initializing an empty tree and expanding previously untouched regions of
    the tree.

    Note that certain containers have a default zero value until expanded.
    This function returns the zero value for the root index of each of these
    structures. For descendants of the container root it returns the
    appropriate node values of the expanded container.

    These zero-root default containers are:
    - epoch trees
    - map row lists
    - index entries
    - log entry containers (empty in case of non-log index entries)
    - log.topics and log.data lists
    """
    if index == GTI_ROOT:
        return _empty_log_index_root
    side = gti_split_below(index, 1)
    index = gti_split_above(index, 1)
    height = gti_height(index)
    if side == GTI_EPOCH_HISTORY:
        if height <= LOG2_EPOCH_HISTORY:
            return _empty_vector_nodes[LOG2_EPOCH_HISTORY - height]
        index = gti_split_above(index, LOG2_EPOCH_HISTORY)
        return epoch_tree_empty_node(index)
    if side == GTI_NEXT_ENTRY:
        if height != 0:
            raise AssertionError("Invalid log index tree node")
        return U256(0)
    raise AssertionError("Invalid log index tree node")


def epoch_tree_empty_node(index: U256) -> U256:
    """
    Returns the default empty node value of a single epoch tree at the given
    generalized tree index (relative to the epoch root).

    Note that the node values returned apply to an expanded container.
    Non-expanded epoch trees have a zero default value at their root and
    therefore this function should not be called with index == GTI_ROOT.
    """
    side = gti_split_below(index, 1)
    index = gti_split_above(index, 1)
    height = gti_height(index)
    if side == GTI_FILTER_MAPS:
        tree_height = LOG2_MAP_HEIGHT + LOG2_MAPS_PER_EPOCH
        if height <= tree_height:
            return _empty_vector_nodes[tree_height - height]
        index = gti_split_above(index, tree_height)
        return prog_list_empty_node(index)
    if side == GTI_INDEX_ENTRIES:
        tree_height = LOG2_MAPS_PER_EPOCH + LOG2_VALUES_PER_MAP
        if height <= tree_height:
            return _empty_vector_nodes[tree_height - height]
        index = gti_split_above(index, tree_height)
        return index_entry_empty_node(index)
    raise AssertionError("Invalid log index tree node")


def prog_list_empty_node(index: U256) -> U256:
    """
    Returns the default empty node value of a progressive list at the given
    generalized tree index (relative to the list root).

    Note that the node values returned apply to an expanded list.
    Non-expanded progressive lists have a zero default value at their root and
    therefore this function should not be called with index == GTI_ROOT.
    """
    side = gti_split_below(index, 1)
    index = gti_split_above(index, 1)
    height = gti_height(index)
    if side == GTI_LIST_TREE:
        if height == 0:
            return U256(0)
        return prog_list_tree_empty_node(0, index)
    if side == GTI_LIST_COUNT:
        if height != 0:
            raise AssertionError("Invalid log index tree node")
        return U256(0)
    raise AssertionError("Invalid log index tree node")


def prog_list_tree_empty_node(level: Uint, index: U256) -> U256:
    """
    Returns the default empty node value of a single tree level of a
    progressive list at the given generalized tree index (relative to the list
    tree root).
    """
    side = gti_split_below(index, 1)
    index = gti_split_above(index, 1)
    height = gti_height(index)
    if side == GTI_PROG_LIST_SUBTREE:
        max_height = PROG_LIST_HEIGHT_FIRST + PROG_LIST_HEIGHT_STEP * level
        if height <= max_height:
            return _empty_vector_nodes[max_height - height]
        raise AssertionError("Invalid log index tree node")
    if side == GTI_PROG_LIST_NEXT_TREE:
        if height == 0:
            return U256(0)
        return prog_list_tree_empty_node(level + 1, index)
    raise AssertionError("Invalid log index tree node")


def index_entry_empty_node(index: U256) -> U256:
    """
    Returns the default empty node value of a single index entry at the given
    generalized tree index (relative to the index entry root).

    Note that the node values returned apply to an expanded container.
    Non-expanded index entries have a zero default value at their root and
    therefore this function should not be called with index == GTI_ROOT.
    """
    side = gti_split_below(index, 1)
    index = gti_split_above(index, 1)
    height = gti_height(index)
    if side == GTI_LOG_ENTRY:
        if height == 0:
            return U256(0)
        return log_entry_empty_node(index)
    if side == GTI_ENTRY_META:  # meta fields (log/block/tx, always 4 fields)
        if height > 2:
            raise AssertionError("Invalid log index tree node")
        return _empty_vector_nodes[2 - height]
    raise AssertionError("Invalid log index tree node")


def log_entry_empty_node(index: U256) -> U256:
    """
    Returns the default empty node value of a single log entry at the given
    generalized tree index (relative to the epoch root).

    Note that the node values returned apply to an expanded container.
    Non-expanded log entries have a zero default value at their root and
    therefore this function should not be called with index == GTI_ROOT.
    """
    height = gti_height(index)
    if height <= 2:
        return _empty_vector_nodes[2 - height]
    field = gti_split_below(index, 2)
    sub_index = gti_split_above(index, 2)
    if field == GTI_LOG_ADDRESS:
        raise AssertionError("Invalid log index tree node")
    if field == GTI_LOG_TOPICS:
        return log_topics_list_empty_node(index)
    if field == GTI_LOG_DATA:
        return prog_list_empty_node(sub_index)
    raise AssertionError("Invalid log index tree node")


def log_topics_list_empty_node(index: U256) -> U256:
    """
    Returns the default empty node value of a single log topics list at the
    given generalized tree index (relative to the topics field node).

    Note that the node values returned apply to an expanded container.
    Non-expanded lists have a zero default value at their root and
    therefore this function should not be called with index == GTI_ROOT.
    """
    side = gti_split_below(index, 1)
    index = gti_split_above(index, 1)
    height = gti_height(index)
    if side == GTI_LIST_TREE:
        if height > 2:
            raise AssertionError("Invalid log index tree node")
        return _empty_vector_nodes[2 - height]
    if side == GTI_LIST_COUNT:
        if height == 0:
            return U256(0)
    raise AssertionError("Invalid log index tree node")
