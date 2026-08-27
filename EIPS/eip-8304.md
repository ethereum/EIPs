---
eip: 8304
title: Trustless log and transaction index
description: Store the root hashes of index tables in a system contract to allow efficient trustless proofs of log and transaction lookups
author: Zsolt Felföldi (@zsfelfoldi)
discussions-to: https://ethereum-magicians.org/t/eip-8304-trustless-log-and-transaction-index/28824
status: Draft
type: Standards Track
category: Core
created: 2026-06-17
requires: 4788
---

## Abstract

Store the root hashes of fixed-depth binary tree structures called "index tables" in the storage of a system contract as part of the block processing logic. A new table is generated for each block, then merged into bigger tables indexing multiple blocks. The proposed design prioritizes minimalization of index processing costs during block processing. The EIP has no effect on the bloom filters stored in block headers.

## Motivation

While adding logs has a significantly lower gas cost and is accordingly less resource consuming than writing to the state, currently the protocol defined data structures do not offer even a remotely efficient way of performing content lookups. The original per-block bloom filters were moderately efficient in the beginning and now they are oversaturated and practically useless. This EIP proposes an indexing mechanism that is much cheaper to update than the state tree while allowing content query proofs with a reasonable size, thereby maintaining the low gas cost and increasing the utility of logs.

### Trustless end user access

Full nodes can maintain their own index structures but most users rely on remote providers that cannot prove the correctness of the results of user queries. Relying on trusted sources for obtaining the output of smart contracts defeats the purpose of maintaining those contracts on a distributed trustless ledger. As the processing capacity of Ethereum grows, this information asymmetry just gets worse. Trustless provability throughout the entire stack, from end user applications signing transactions, to the same or other end user applications getting the results they need, should be part of the roadmap.

### Cross-chain communication

Since log entries have a time dimension, they are very suitable for differential updates where a receiver contract processes an index query proof of relevant events since its last update. If a recent block hash of another chain that implements this EIP is known, it is possible to efficiently receive messages from that chain in the form of logs emitted there.

### Synergy with ZKP batched pre-checks

As stateless witnesses and PQ signatures are both expected to increase the amount of data proving the validity of transactions, it looks like a probable improvement path in the foreseeable future to allow batching these authorization/verification steps in recursive ZKPs, eliminating the need to propagate all authorization and witness data throughout the network ([EIP-8141](./eip-8141.md) already supports separating a pure code part of transaction execution). While log query proofs are bigger than state witnesses, in the future it might become possible to minimalize their on-chain gas cost by doing the verification in a ZKP batch and only putting the query reference and results in the calldata.

### A new form of state

If the EVM is extended with functionality to query logs emitted in the current block or last few blocks not covered by the batch proof, logs might even be used as an alternative form of state that is very cheap to write, allows very easy expiry as a contract design option (only search most recent N blocks) and generally solves the state bloat issue by allowing protocol participants to forget anything older than a few hundred blocks and leaving the responsibility of proving anything older at the user. Logs are also more friendly to async/parallel execution as writes never collide.

## Specification

| Parameter | Value |
| - | - |
| `TABLE_SIZES`            | `[1, 4, 16, 64, 256]` |
| `TABLES_PER_LEVEL`       | `1024` |
| `SYSTEM_ADDRESS`         | `0xfffffffffffffffffffffffffffffffffffffffe` |
| `INDEX_CONTRACT_ADDRESS` | `<TBD>` |

The EIP defines `len(TABLE_SIZES)` levels of index tables referenced in the system index contract. On each level the tables are indexing `TABLE_SIZES[i]` blocks each and their root hashes are stored in a ring buffer of `TABLES_PER_LEVEL` length.

### Index tables

An index table is an ordered list of _index entries_ hashed into a fixed-depth binary tree. Entries have multiple types and each entry type has its own binary encoding format, used both for hashing and ordering. The order of entries in a table is a lexicographical ordering of their binary representations. For each block a specific set of index entries can be generated based on the indexing rules. Each table represents the entries generated from either a single block or a number of consecutive blocks of the same chain. Therefore in the context of a given canonical chain, tables are identified with `first_block` and `table_size` (number of blocks). Tables can either be generated based on blocks and their belonging receipts or by merging the already sorted entries of tables based on adjacent block ranges.

The protocol mandates generating tables on a fixed number of levels, with a fixed `table_size = TABLE_SIZES[i]` on each level. `first_block` is always a multiple of `table_size` and `TABLE_SIZES[i]` is always a multiple of `TABLE_SIZES[i-1]` where `i>0`. This allows tables to be merged from a fixed number of tables on the level below.

#### Entry types

The following entry types are defined:

| entry type    | type id | content          | position info                                | encoding length |
|---------------|---------|------------------|----------------------------------------------|-----------------|
| block         | 0       | block hash       | block number                                 | 2+32+8 = 42     |
| transaction   | 1       | transaction hash | block number, tx index, cumulative log count | 2+32+8+4+4 = 50 |
| log.address   | 2       | log address      | block number, tx index, log index            | 2+20+8+4+4 = 38 |
| log.topics[0] | 3       | log topic        | block number, tx index, log index            | 2+32+8+4+4 = 50 |
| log.topics[1] | 4       | log topic        | block number, tx index, log index            | 2+32+8+4+4 = 50 |
| log.topics[2] | 5       | log topic        | block number, tx index, log index            | 2+32+8+4+4 = 50 |
| log.topics[3] | 6       | log topic        | block number, tx index, log index            | 2+32+8+4+4 = 50 |

Entries consist of an entry type id, the searchable content and the position information. In case of transaction entries the _cumulative log count_ (the total number of logs in the block before the given transaction) is also added. The _log index_ of address/topic entry types is relative to the transaction beginning. All numbers are encoded as big-endian which ensures correct ordering based on the binary representation.

#### Indexing rules

Transaction and log address/topic indexing is straightforward, for each transaction and each log event in the indexed block the corresponding index entries are added. Block entries are added with a one-block delay; for each block `N` the block entry of the parent block `N-1` is added. For the genesis block no block entry is added. A multi-block merged table covering the block range `first_block` to `first_block + table_size - 1` contains the block entries from `first_block - 1` to `first_block + table_size - 2`. This one-block offset is due to the fact that the single-block table generated from the actually processed block is referenced in the same block, before the block hash can be determined.

#### Index table example

An example scenario of a table indexing the following four blocks:

- Block #40: empty
- Block #41: empty
- Block #42:
    - Tx #0: WETH Transfer from Alice to Bob, USDT Transfer from Bob to Alice
    - Tx #1: WETH Withdrawal by Bob
- Block #43:
    - Tx #0: USDT Transfer from Alice to Carol

The unsorted index entries for the block range 40..43 are (in chronological order):

| Block # | Tx # | Log # | Type        | Value                           |
|---------|------|-------|-------------|---------------------------------|
| 39      |      |       | 0 (Block)   | 0xbf98e6cb26f6ff... (block hash)|
| 40      |      |       | 0 (Block)   | 0x42f66a2e9f9c68... (block hash)|
| 41      |      |       | 0 (Block)   | 0x978ce0036b6d1c... (block hash)|
| 42      | 0    | 0     | 1 (Tx)      | 0xca2d12d1b8132d... (tx hash)   |
| 42      | 0    | 0     | 2 (Address) | 0xc02aaa39b223fe... (WETH)      |
| 42      | 0    | 0     | 3 (Topic0)  | 0xddf252ad1be2c8... (Transfer)  |
| 42      | 0    | 0     | 4 (Topic1)  | 0x00..004a5e9a3b... (Alice)     |
| 42      | 0    | 0     | 5 (Topic2)  | 0x00..00f2a5fd4d... (Bob)       |
| 42      | 0    | 1     | 2 (Address) | 0xdac17f958d2ee5... (USDT)      |
| 42      | 0    | 1     | 3 (Topic0)  | 0xddf252ad1be2c8... (Transfer)  |
| 42      | 0    | 1     | 4 (Topic1)  | 0x00..00f2a5fd4d... (Bob)       |
| 42      | 0    | 1     | 5 (Topic2)  | 0x00..004a5e9a3b... (Alice)     |
| 42      | 1    | 2     | 1 (Tx)      | 0xa75590c9ced728... (tx hash)   |
| 42      | 1    | 0     | 2 (Address) | 0xc02aaa39b223fe... (WETH)      |
| 42      | 1    | 0     | 3 (Topic0)  | 0x7fcf532c15f0a6... (Withdrawal)|
| 42      | 1    | 0     | 4 (Topic1)  | 0x00..00f2a5fd4d... (Bob)       |
| 42      |      |       | 0 (Block)   | 0x66f42ef12b140e... (block hash)|
| 43      | 0    | 0     | 1 (Tx)      | 0x7046035b326ab2... (tx hash)   |
| 43      | 0    | 0     | 2 (Address) | 0xdac17f958d2ee5... (USDT)      |
| 43      | 0    | 0     | 3 (Topic0)  | 0xddf252ad1be2c8... (Transfer)  |
| 43      | 0    | 0     | 4 (Topic1)  | 0x00..004a5e9a3b... (Alice)     |
| 43      | 0    | 0     | 5 (Topic2)  | 0x00..00ac8cbe20... (Carol)     |

The sorted _index table_ (columns reordered according to sorting priority):

| Type        | Value                           | Block # | Tx # | Log # |
|-------------|---------------------------------|---------|------|-------|
| 0 (Block)   | 0x42f66a2e9f9c68... (block hash)| 40      |      |       |
| 0 (Block)   | 0x66f42ef12b140e... (block hash)| 42      |      |       |
| 0 (Block)   | 0x978ce0036b6d1c... (block hash)| 41      |      |       |
| 0 (Block)   | 0xbf98e6cb26f6ff... (block hash)| 39      |      |       |
| 1 (Tx)      | 0x7046035b326ab2... (tx hash)   | 43      | 0    | 0     |
| 1 (Tx)      | 0xa75590c9ced728... (tx hash)   | 42      | 1    | 2     |
| 1 (Tx)      | 0xca2d12d1b8132d... (tx hash)   | 42      | 0    | 0     |
| 2 (Address) | 0xc02aaa39b223fe... (WETH)      | 42      | 0    | 0     |
| 2 (Address) | 0xc02aaa39b223fe... (WETH)      | 42      | 1    | 0     |
| 2 (Address) | 0xdac17f958d2ee5... (USDT)      | 42      | 0    | 1     |
| 2 (Address) | 0xdac17f958d2ee5... (USDT)      | 43      | 0    | 0     |
| 3 (Topic0)  | 0x7fcf532c15f0a6... (Withdrawal)| 42      | 1    | 0     |
| 3 (Topic0)  | 0xddf252ad1be2c8... (Transfer)  | 42      | 0    | 0     |
| 3 (Topic0)  | 0xddf252ad1be2c8... (Transfer)  | 42      | 0    | 1     |
| 3 (Topic0)  | 0xddf252ad1be2c8... (Transfer)  | 43      | 0    | 0     |
| 4 (Topic1)  | 0x00..004a5e9a3b... (Alice)     | 42      | 0    | 0     |
| 4 (Topic1)  | 0x00..004a5e9a3b... (Alice)     | 43      | 0    | 0     |
| 4 (Topic1)  | 0x00..00f2a5fd4d... (Bob)       | 42      | 0    | 1     |
| 4 (Topic1)  | 0x00..00f2a5fd4d... (Bob)       | 42      | 1    | 0     |
| 5 (Topic2)  | 0x00..004a5e9a3b... (Alice)     | 42      | 0    | 1     |
| 5 (Topic2)  | 0x00..00ac8cbe20... (Carol)     | 43      | 0    | 0     |
| 5 (Topic2)  | 0x00..00f2a5fd4d... (Bob)       | 42      | 0    | 0     |

The binary encoding of the entries, lexicographically ordered (same ordering as above):

```
000042f66a2e9f9c68e223e8d826145d7cfacb00520dba6a9555803121de29790b650000000000000028
000066f42ef12b140e8004ad39a760191457f485204ee6c9f990c33f14014e521f20000000000000002a
0000978ce0036b6d1c62d716045505587d15cc85a1def92f9f450937b6467295e5170000000000000029
0000bf98e6cb26f6ff312586968d1f343a3d3c439a8c5c86233aff2a82f1a68263df0000000000000027
00017046035b326ab22a3142e4416ed4300a28a483a31a1e04cf62bec575b2e7cf09000000000000002b0000000000000000
000175590c9ced72898d6207c917e11b452949043404a1802b893f7717a9c1c8f45d000000000000002a0000000100000002
0001ca2d12d1b8132de09d0d668cc87349dc70134bee3010e03ddb2d83f7160bd6e3000000000000002a0000000000000000
0002c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000002a0000000000000000
0002c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000002a0000000100000000
0002dac17f958d2ee523a2206206994597c13d831ec7000000000000002a0000000000000001
0002dac17f958d2ee523a2206206994597c13d831ec7000000000000002b0000000000000000
00037fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65000000000000002a0000000100000000
0003ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef000000000000002a0000000000000000
0003ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef000000000000002a0000000000000001
0003ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef000000000000002b0000000000000000
00040000000000000000000000004a5e9a3bf35df5e0ea4b4cd3289e0111f1deadf7000000000000002a0000000000000000
00040000000000000000000000004a5e9a3bf35df5e0ea4b4cd3289e0111f1deadf7000000000000002b0000000000000000
0004000000000000000000000000f2a5fd4d5bb24b651d1198bc014941a16f6edde5000000000000002a0000000000000001
0004000000000000000000000000f2a5fd4d5bb24b651d1198bc014941a16f6edde5000000000000002a0000000100000000
00050000000000000000000000004a5e9a3bf35df5e0ea4b4cd3289e0111f1deadf7000000000000002a0000000000000001
0005000000000000000000000000ac8cbe20039c2e9547da9107456179bd4f39a734000000000000002b0000000000000000
0005000000000000000000000000f2a5fd4d5bb24b651d1198bc014941a16f6edde5000000000000002a0000000000000000
```

#### Table root hash calculation

The table root hash is calculated as the root of the `List[Hash32, entry_count]` SSZ list containing the SHA2-256 hashes of the binary encoded entries where `entry_count` is the total number of entries in the table.

### Block processing

For each protocol-mandated index table level `i`, tables with a `table_size` equal to `TABLE_SIZES[i]` and a `first_block` that is a multiple of the corresponding `table_size` are generated and their `table_root` added to the index contract. A table is only generated if the EIP was already active at `first_block`. While single block tables (table level 0) are added immediately after processing all transactions, higher-level tables are added with a delay of `TABLE_SIZES[i] // 4` blocks (also at the end of processing the corresponding block). This ensures that higher level tables can be asynchronously merged from lower level tables without increasing the block processing delay.

Table roots are added to the index contract with a call to `INDEX_CONTRACT_ADDRESS` as `SYSTEM_ADDRESS` with the 3*32-byte input of `first_block`, `table_size` (both big-endian) and `table_root`, a gas limit of `30_000_000`, and `0` value. This will trigger the `set()` routine of the history contract. This is a system operation following the same convention as [EIP-4788](./eip-4788.md) and therefore:

- the call must execute to completion
- the call does not count against the block's gas limit
- the call does not follow the [EIP-1559](./eip-1559.md) burn semantics - no value should be transferred as part of the call
- if no code exists at `INDEX_CONTRACT_ADDRESS`, the call must fail silently

Note: Alternatively clients can choose to directly write to the storage of the contract but EVM calling the contract remains preferred.

#### Initializing after chain/state sync

This EIP does not need to extend the sync protocol since all required tables can be regenerated from recent blocks after synchronising. The only requirement is that in the worst case (when the first validated block after sync is one where a highest-level table root needs to be added) the client needs the last `TABLE_SIZES[len(TABLE_SIZES)-1] * 5 // 4 - 1` blocks in order to generate that table root (319 blocks with current parameters). While clients currently do synchronise and keep a lot longer chain history than this, even if this changes in the future, downloading these blocks just for the purpose of indexing them is a really small one-time cost compared to synchronising the state. 

#### Future stateless/execution proof implementation

In a fully stateless protocol where state transitions can be validated purely based on witnesses and a client can start validating with minimal startup overhead, table merging can also be implemented with witnesses of partially merged tables. For example, if a 64 block table that also ends on a 256 block boundary has just been added (with 16 block delay) and merging the last four 64 block tables needs to be performed during the next 48 blocks, the stateless protocol can define equally distributed `entry_index` checkpoints based on the expected total `entry_count` of the merged table and mandate including a Merkle boundary proof of the partially merged table at the next checkpoint with every set of witnesses. This way the producer of each block will commit to the next merged slice of the table while validators can verify this slice based on witnesses of the corresponding slices of each table from the level below.

This approach can also be applied to generating execution ZKPs, though it is also an option to prove table merging asynchronously. ZKPs of table merging will be required anyways for implementing a history index contract (see below).

### Index contract

The history contract has two operations: `get` and `set`. The `set` operation is invoked only when the `caller` is equal to the `SYSTEM_ADDRESS` as per [EIP-4788](./eip-4788.md). Otherwise the `get` operation is performed.

#### `get`

- Caller provides index table parameters `first_block` and `table_size` as calldata to the contract:
    - `first_block` at `calldata[0:32]` (big-endian)
    - `table_size` at `calldata[32:64]` (big-endian)
- Revert in any of the following cases:
    - calldata is not 64 bytes
    - `first_block` is not a multiple of `table_size`
    - The requested table root has not been set yet or has already been overwritten in the ring buffer according to the current `block.number`
    - The retrieved `table_root` is zero either because it's never been initialized yet since the fork or `table_size` is invalid
- Otherwise return a valid `table_root` fetched from the storage value at `table_size * TABLES_PER_LEVEL + (first_block // table_size) % TABLES_PER_LEVEL`.

This function can either be used from the EVM to verify an index table proof on-chain or with an execution witness as part of an off-chain index query proof. It is also also an option for both provers and verifiers to calculate the storage address themselves and create/verify the state proof based on that. It is important to note though that other index contracts (see below) might use a different internal storage scheme.

#### `set`

- Caller provides index table parameters `first_block`, `table_size` and `table_root` as calldata to the contract:
    - `first_block` at `calldata[0:32]` (big-endian)
    - `table_size` at `calldata[32:64]` (big-endian)
    - `table_root` at `calldata[64:96]`
- Set the storage value at `table_size * TABLES_PER_LEVEL + (first_block // table_size) % TABLES_PER_LEVEL` to be `table_root`.

It is always assumed that `first_block` is a multiple of `table_size`, `table_size` is one of the values in the `TABLE_SIZES` list and the contract is called after processing all transactions of block `first_block + table_size - 1 + table_size // 4`.

#### Bytecode

Exact evm assembly that can be used for the index contract:

```
caller
push20 0xfffffffffffffffffffffffffffffffffffffffe
eq
push1 0x60
jumpi
push1 0x40
calldatasize
sub
push1 0x5c
jumpi
push1 0x20
calldataload
dup1
push1 0x80
shr
push1 0x5c
jumpi
push2 0x0400
dup2
push1 0x04
dup2
div
number
sub
div
dup3
dup3
mul
swap3
push0
calldataload
dup2
dup2
mod
push1 0x5c
jumpi
div
swap1
dup2
sub
not
push2 0x03ff
lt
push1 0x5c
jumpi
mod
add
sload
dup1
iszero
push1 0x5c
jumpi
push0
mstore
push1 0x20
push0
return
jumpdest
push0
push0
revert
jumpdest
push1 0x40
calldataload
push1 0x20
calldataload
push2 0x0400
dup2
dup2
mul
swap2
push0
calldataload
div
mod
add
sstore
stop
```

#### Deployment

A special synthetic address is generated by working backwards from the desired deployment transaction:

```json
{
  "type": "0x0",
  "nonce": "0x0",
  "to": null,
  "gas": "0x3d090",
  "gasPrice": "0xe8d4a51000",
  "maxPriorityFeePerGas": null,
  "maxFeePerGas": null,
  "value": "0x0",
  "input": "0x60758060095f395ff33373fffffffffffffffffffffffffffffffffffffffe1460605760403603605c576020358060801c605c576104008160048104430304828202925f35818106605c5704908103196103ff10605c570601548015605c575f5260205ff35b5f5ffd5b604035602035610400818102915f350406015500",
  "v": "<TBD>",
  "r": "<TBD>",
  "s": "<TBD>",
  "hash": "<TBD>"
}
```

Note, the input in the transaction has a simple constructor prefixing the desired runtime code.

The sender of the transaction can be calculated as <!-- TODO --> `<TBD>`. The address of the first contract deployed from the account is `rlp([sender, 0])` which equals <!-- TODO --> `<TBD>`. This is how `INDEX_CONTRACT_ADDRESS` is determined. Although this style of contract creation is not tied to any specific initcode like create2 is, the synthetic address is cryptographically bound to the input data of the transaction (e.g. the initcode).

#### History index contract

While this EIP mandates all participants of the protocol to update the index contract at `INDEX_CONTRACT_ADDRESS` with a fixed set of table sizes, larger tables can also be generated and stored in other index contracts sharing the same `get` interface while having their own way of ensuring that the table roots stored in them are correct. Receivers of index query proofs can decide which alternative index contracts to trust in addition to the system contract defined here.

In order to be able to provide reasonably sized proofs for long history queries, infrastructure providers might want to maintain index tables covering up to millions of blocks. In order to trustlessly prove the correctness of these off-protocol tables to their clients, they can generate ZKPs of the table roots and send them to an index contract that stores these roots after verifying the corresponding proof. A history index contract is not defined in this EIP as it is a separate development effort and technically independent from the proposed protocol change.

#### Alternative index contracts

Alternative or extended index data can also be stored in index tables and referenced in index contracts. For example after [EIP-7708](./eip-7708.md) is activated, the entire chain history before can be reprocessed with the additional ETH transfer/burn logs generated and added to the index tables. While proving the correctness of 11 years of reprocessed chain history with a ZKP is probably too expensive with today's technology, in such a one-time case it might be acceptable to just agree on the correctness of an immutable index contract through human consensus.

### [EIP-161](./eip-161.md) handling

The bytecode above will be deployed à la [EIP-4788](./eip-4788.md). As such the account at `INDEX_CONTRACT_ADDRESS` will have code and a nonce of 1, and will be exempt from EIP-161 cleanup.

### Gas costs

Due to the low cost of generating a single block index table and the fact that bigger tables can be merged asynchronously between processing blocks, the gas cost of `LOG` operations does not need to increase.

## Rationale

The proposed design creates tables up to a limited size (256 blocks) as part of the main protocol while assuming that bigger tables (up to millions of blocks in size) will be created and proven by infrastructure maintainers. Creating big history tables in protocol would both place a significant extra burden on all nodes and also add the assumption that these nodes all possess millions of blocks of chain history, which is not future compatible according to current plans. 

This hybrid solution (both in-protocol and ZKP) has been chosen because leaving the task entirely to external provers simply would not achieve the same level of utility. Even if the index contract would be updated in every block (at the high cost of one on-chain ZKP verification per block), the last block would never be indexed. With a more realistic assumption of less frequent on-chain updates, the most recent section of the chain (which is typically the most interesting when one is looking for events) would not be indexed and any meaningful proof would include all block receipts since the last contract update. The cost of this would be impractical for API proofs and prohibitive for on-chain/cross-chain proofs.

### Number of table levels and size of ring buffers

With the proposed parameters, there are 5 table levels maintained in-protocol, the table sizes forming a geometric sequence with a common ratio of 4. This means that each table on levels above 0 can be merged from 4 tables of the level below. This common ratio has been chosen as a balance between index query proof size overhead and in-protocol processing costs. Reaching the same highest `table_size` (in this case, 256) with a lower common ratio would require more table levels and therefore more tree hashing. On the other hand, an index query proof has to cover the queried block range with individual index table proofs of tables covering adjacent block ranges and a higher common ratio would increase the number of small tables required for each proof, thereby increasing the typical proof size.

The ring buffer of each table level is 1024 tables long. This means that approximately the last 2**18 blocks are covered with 256 block index tables whose root hashes are referenced in the state. Older chain history is expected to be covered by larger tables proven with ZKPs and referenced in a history index contract. Ideally, a 1024 block table could be added to the history index contract every 1024 blocks, meaning that only the most recent 0..4 tables are really required on each level. Since this relies on external actors though, it is better to not rely completely on such an assumption and keep more tables referenced in the system index contract. Storing 1024 table roots per level is not an excessive amount of data and it ensures that the entire chain remains searchable if the most recent proven history table is not older than 36 days. Proof efficiency is reduced and proving time is increased though if hundreds of tables are used (normally an index query proof is expected to consist of 30-50 individual table proofs). Therefore storing a much longer table root history in the system index contract is useless because proof efficiency would become impractical anyways.

## Backwards Compatibility

This EIP introduces backwards incompatible changes to the block validation rule set, but neither of these changes break anything related to current user activity and experience.


## Security Considerations

Having contracts (system or otherwise) with hot update paths (branches) poses a risk of "branch" poisoning attacks where attacker could sprinkle trivial amounts of eth around these hot paths (branches). But it has been deemed that cost of attack would escalate significantly to cause any meaningful slow down of state root updates.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
