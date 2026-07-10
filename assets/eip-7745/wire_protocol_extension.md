## EIP-7745 wire protocol extension

This document specifies the extensions to the [Ethereum Wire Protocol](https://github.com/ethereum/devp2p/blob/master/caps/eth.md) required to initialize the log index.

### Proposed new messages

#### GetLogIndexProof (0x12)

`[request-id: P, referenceBlockHash: B_32, proofType: P, proofSubset: P]`

Require peer to return a __LogIndexProof__ message containing a log index proof that proves the specified subset of the specified type of initialization data from the log index tree belonging to the specified _reference block_.

Note that all clients are expected to be able to serve log index proofs using either the current finalized block or the previous one as _reference block_. Also note that the initialization data served by this protocol are split into a limited number of pre-defined subsets so that proofs can be pre-generated for each potential _reference block_. This, together with the limited size of each individual response, makes it easy to ensure that serving this data will not be an excessive burden on the clients.

#### LogIndexProof (0x13)

`[request-id: P, log_index_proof]`

This is the response to __GetLogIndexProof__, providing the RLP encoded log index proof of the requested partial initialization data. See the [log index proof format](log_index_proof_format.md) specification.

### Allowed proof types

#### EpochBoundaryProof (proofType = 0x01)

This proof allows the client to initialize log index rendering at epoch boundaries. It does not prove any filter row data, only index entries, typically of __BlockEntry__ type. Epoch boundary `i` is defined as the boundary between epochs `i` and `i+1` and allows the client to start rendering the index from epoch `i+1`. Epoch boundaries `0 <= i < epoch_count` can be proven, where `epoch_count = next_index // (MAPS_PER_EPOCH * VALUES_PER_MAP)` is the number of completed epochs. Note that every proof proves `next_index` and thereby also `epoch_count`. 

The range of proven boundaries is determined by the `proofSubset` parameter; boundaries `proofSubset * 128` to `min((proofSubset+1) * 128, epoch_count) - 1` are proven by the returned log index proof. Except for some corner cases listed below, each boundary `i` is proven by two adjacent __BlockEntry__ entries: the last one whose `map_entry_index < i * MAPS_PER_EPOCH * VALUES_PER_MAP` and the first one whose `map_entry_index >= i * MAPS_PER_EPOCH * VALUES_PER_MAP`. This proves the `map_entry_index` position of the last block boundary in the previous epoch, which allows the client to start processing the next block, skip the appropriate number of _map values_ and _index entries_ until the epoch boundary, then start rendering the next epoch.

Note that rendering from an epoch boundary is one option to initialize the log index and also makes it possible to generate the index for older epochs later.

##### Corner cases

The typical scenario described above assumes that there is at least one __BlockEntry__ both before and after the boundary. This assumption can be false in three valid corner cases:

- there is no __BlockEntry__ before the boundary and the block number of the one after the boundary is `firstIndexedBlock`. In this case rendering should start from the first epoch.
- there is no __BlockEntry__ after the boundary and the block number of the one before the boundary is `referenceBlock - 1`. In this case rendering from the boundary is possible.
- there are no __BlockEntry__ entries anywhere in the index and `firstIndexedBlock == referenceBlock`. In this case rendering should start from the first epoch.

In any other case the proof should be considered invalid.

Note that rendering an epoch as a part of a log index Merkle tree requires the sibling of the rendered epoch's root node to be known. This is automatically true if a `BlockEntry` in the rendered epoch (the one after the boundary) is proven. Otherwise it is not always guaranteed, therefore if there is no __BlockEntry__ in the next epoch after a proven boundary then the first index entry of that epoch should be proven, either as an __empty entry__, a __FalsePositiveLogEntry__ or a __TxEntry__. 

#### CurrentMapProof (proofType = 0x02)

This proof allows the client to initialize log index rendering at the _reference block_. It proves all rows of the current filter map and the index entry at `next_index`. This dataset is split into a fixed number of subsets (`0 <= proofSubset <= 63`). The proven map index is calculated as `mapIndex = next_index // VALUES_PER_MAP`.

Each proof proves 1024 rows between row index `proofSubset * 1024` and `proofSubset * 1024 + 1023`. Additionally, if `proofSubset == 0` then the index entry at `next_index` is also proven as an __empty entry__. This type of proof always uses the general row encoding format and the __FilterRow__ container type (`long_rows` is 1024 items long and `short_rows` is empty). Note that short row encoding has significant benefits when encoding a long section of rows of adjacent maps which is not the case here; in this case the majority of proof data is the sibling proof nodes of the Merkle path leading to each individual row of the same map index.
