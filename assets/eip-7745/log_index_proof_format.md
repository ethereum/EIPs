## EIP-7745 log index proof format

A log index proof is a Merkle multiproof that fully or partially proves the contents of certain filter map rows and index entries. The proof format specified here can be used to prove the results of log queries, transaction and block hash lookups, and also to initialize the log index state. The root hash of any proof can be calculated and validated against the expected log index root regardless of its contents but the required contents (the proven subset of filter rows and index entries) depend on the use case. These use cases and their conditions for proof validity are detailed in separate documents.

The general format of a log index proof is defined as follows:

```
class LogIndexProof(Container):
    filter_rows: FilterRows
    index_entries: IndexEntries
    next_index: uint64
    proof_nodes: List[Bytes32]
```

The filter map and index entry data included in the proof uses a more compact encoding than the binary Merkle tree leaves but their contents can be translated into a known set of tree leaves. The `proof_nodes` list provides additional tree node contents required to calculate the log index root and validate it against the one found in the relevant block header.

Note that the position and order of the proof nodes is not specified in the proof but can be determined based on the set of known leaves. Also note that the `next_index` pointer of the log index is always supplied with the proof and its leaf node is always considered known.

### Filter map row encoding

The `FilterRows` container contains all filter map row data included in the proof. For storage efficiency two different encodings are used: a general purpose one that supports long rows and partial storage of row data, and a compact one capable of fully storing limited size filter rows belonging to the same row index in a continuous range of adjacent filter maps.

Note that the efficiency gain achieved by using the compact encoding wherever possible is very significant; with the current filter map parameters the global average of filter row lengths is 1 entry (3 bytes) and for these less populated rows it is a typical scenario that the proof encodes all rows of the same row index in an entire epoch (1024 maps). In a typical use case these rows might account for the major part of the log index proof data. EIP-7745 generally tries to achieve a reasonable balance between efficiency and complexity, and in this case optimizing the encoding of the most frequently occurring scenario with a relatively simple extra encoding format is justified.
```
class FilterRows(Container):
    short_rows: List[ShortRows]
    long_rows: List[FilterRow]
```

#### General row encoding

```
class FilterRow(Container):
    map_index: uint32
    row_index, row_length: uint16
    stored_row_data: List[StoredRowSection]

class StoredRowSection(Container):
    start_index: uint16
    row_data: ByteList
```

In the general case, each filter map row is encoded in its own container. The row length is always stored while the stored column indices are represented as a list of continuous sections, with `row_data` encoded in a compact form (3 bytes per list entry, little endian byte order).

Note that in the consensus tree format list entries are hashed as 4 byte _uint32_ values in 32 byte data chunks stored in _ProgressiveList_ tree leaves. Therefore each stored section has to start and end on a chunk boundary (units of 8 list entries), except for the last chunk which can be shorter. Since the row length does determine the number of _ProgressiveList_ tree levels, all leaves of all used tree levels (including the unused zero leaves at the end of the last tree level) are considered as known leaves. Also the `PROG_LIST_NEXT_TREE` branch of the last tree level is known to be a zero leaf. If all list entries are stored then all leaves of the _ProgressiveList_ container tree are considered as known and no extra proof nodes are added in that subtree.

#### Short row encoding

```
class ShortRows(Container):
    first_map_index: uint32 
    row_index: uint16
    row_lengths, row_data: ByteList
```

The `ShortRows` container fully encodes a continuous range of rows if none of them is longer than 255 entries. The length of each row is encoded in the `row_lengths` byte list, while the length of this list determines the number of adjacent map rows encoded. The `row_data` is encoded in compact form (3 bytes per list entry, little endian), with the entries of all encoded rows stored in a single byte list.

### Index entry encoding

```
class IndexEntries(Container):
    empty_entries: List[uint64]
    matching_logs: List[MatchingLogEntry]
    false_logs: List[FalsePositiveLogEntry]
    tx_entries: List[TxEntry]
    block_entries: List[BlockEntry]
```

#### Log entry (true match)

```
class MatchingLogEntry(Container):
    entry_index: uint64
    log: Log
    meta: LogMeta

class Log(Container):
    address: ExecutionAddress
    topics: List[Bytes32, 4]
    data: ProgressiveByteList

class LogMeta(Container):
    block_number: uint64
    transaction_hash: Root
    transaction_index: uint64
    log_in_tx_index: uint64
```

In this case the index entry is fully specified, all leaves of the index entry subtree are known, not proof nodes will be added in the index entry container subtree, only at the siblings of the Merkle path leading to the entry in the `index_entries` tree.

#### Log entry (false positive)

```
class FalsePositiveLogEntry(Container):
    entry_index: uint64
    address: ExecutionAddress
    topics: List[Bytes32, 4]
```

In this case only the `address` and `topics` are specified because they are supposed to prove that the potential match indicated by the filter maps is not really a match as the actual address and topics do not match the specified filter criteria. The root of the `data` byte list and the `meta` container are considered unknown and are added as proof nodes.

#### Transaction entry

```
class TransactionEntry(Container):
    entry_index: uint64
    meta: TransactionMeta

class TransactionMeta(Container):
    block_number: uint64
    transaction_hash: Root
    transaction_index: uint64
    receipt_hash: Root
```

In this case the `Log` container is not initialized and its root is considered to be known as a zero leaf, which distinguishes `TransactionEntry` from log entries.

#### Block entry

```
class BlockEntry(Container):
    entry_index: uint64
    meta: BlockMeta

class BlockMeta(Container):
    block_number: uint64
    block_hash: Root
    timestamp: uint64
```
Similarly to `TransactionEntry`, the `Log` container root is known zero. Note that the last unused (zero) leaf of `BlockMeta` is also considered known and ensures that a `BlockMeta` is always distinguishable from a `TransactionMeta` which has `receipt_hash` in the same position that cannot be zero.

### Proof nodes

Proof nodes are tree nodes that are not known and also have no known descendants. They are added to the `proof_nodes` list in the order of a depth-first (left to right) traversal of the log index tree and can also be processed in the same order during the recursive reconstruction of the log index root, as shown on the figure below:

```
        14  *15
          \ /
*4   5 6   7
  \ /   \ /
   2     3
    \   /
     \ /
      1

*: known nodes
proof nodes: [5, 6, 14]
```


