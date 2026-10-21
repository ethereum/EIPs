---
eip: 8188
title: Last-Written Block for Accounts and Slots
description: Records the last-written block number of each account and storage slot as consensus-level state metadata.
author: Wei Han Ng (@weiihann), Amirul Ashraf (@asdacap), Guillaume Ballet (@gballet), Maria Silva (@misilva73), Gary Rong (@rjl493456442), Carlos Perez (@CPerezz), Jochem Brouwer (@jochem-brouwer)
discussions-to: https://ethereum-magicians.org/t/eip8188-state-tiering-by-write-age/28234
status: Draft
type: Standards Track
category: Core
created: 2026-03-10
requires: 8037
---

## Abstract

This proposal extends the RLP encoding of accounts and storage slots with a `last_written_block` field that records the block number at which each piece of state was last mutated. The field is updated on writes and left untouched by reads. It introduces no gas changes.

This gives clients a consensus-verified, cross-client-consistent signal that identifies the recently mutated active set, which can be used for storage tiering and other client-level optimizations. Gas pricing built on this metadata is left to a separate proposal.

## Motivation

Ethereum state continues to grow, and the protocol currently provides no record of when each piece of state was last mutated. Clients are left to approximate write recency with local heuristics such as caches and snapshots, which are not consistent across nodes and cannot be relied on as a consensus signal.

A consensus-visible `last_written_block` field would help to identify the recently mutated active set, which every client can use as a signal for storage tiering. The main objective is to help clients optimize the commit-critical mutable path: trie updates, state-root computation, compaction, and other work associated with repeatedly rewriting state.

This proposal deliberately limits its scope to the metadata itself. It does not change gas costs. A separate proposal would be needed to introduce in-protocol state tiering with differentiated gas costs.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Encoding Changes

#### Account RLP Change

The account encoding is extended with a fifth field, `last_written_block`:

Before:

```python
account = RLP([nonce, balance, storageRoot, codeHash])
```

After:

```python
account = RLP([nonce, balance, storageRoot, codeHash, last_written_block])
```

**Backwards compatibility:** When decoding an account with only 4 RLP elements (pre-fork format), `last_written_block` MUST default to `0`.

#### Storage Slot Encoding Change

Storage slot values are wrapped in a list to accommodate the new field:

Before:

```python
slot_value = RLP(value)
```

After:

```python
slot_value = RLP([value, last_written_block])
```

**Backwards compatibility:** The two formats are distinguished by their RLP prefix. A single bytestring has a prefix in the `0x80+` range, while a list has a prefix in the `0xc0+` range. Legacy slots (single bytestring) MUST default to `last_written_block = 0`.

### Block Update Rule

`last_written_block` is set to the current `block_number` when a piece of state is mutated. Writing again within the same block is idempotent: the field is already equal to `block_number`, so no further change occurs.

#### Storage slot rules

- **Value change** (`SSTORE` nonzero → different nonzero): set the slot's `last_written_block = block_number`. Also set the containing account's `last_written_block = block_number` (since `storageRoot` is recomputed).
- **Slot deletion** (`SSTORE` to zero): the slot is removed from the trie. No slot field to update. Set the account's `last_written_block = block_number` (since `storageRoot` changes).
- **No-op write** (`SSTORE` same value): no changes.
- **New slot** (zero → nonzero): created with `last_written_block = block_number`. Account field set to `block_number`.

#### Account rules

- **Balance transfer** (nonzero value): set `last_written_block = block_number` for both the sender and receiver addresses.
- **Nonce increment**: set `last_written_block = block_number`.
- **Storage mutation**: set the account's `last_written_block = block_number` (cascading from storage rules above).
- **New account**: created with `last_written_block = block_number`.
- **`SELFDESTRUCT`**: follows the balance-transfer rule under [EIP-6780](./eip-6780.md). When the contract is not created in the same transaction, it is not removed, so set `last_written_block = block_number` on the self-destructing account and on the beneficiary whenever their balances change. There is no update when the beneficiary is the account itself, since the balance does not change. A contract created and destroyed in the same transaction is removed from the trie and carries no `last_written_block`. Only a surviving beneficiary whose balance changes is updated.

#### Reads

Pure reads MUST NOT update `last_written_block`. This includes `SLOAD`, `BALANCE`, `EXTCODESIZE`, `EXTCODECOPY`, `EXTCODEHASH`, and call opcodes that do not mutate state.

#### Reverts

When a call frame reverts, the field is restored to its value from before the frame, exactly like `balance`, `nonce`, and storage. Implementations MUST NOT keep a `last_written_block` update whose accompanying state change was rolled back.

## Rationale

### How can clients utilize the write-age metadata?

The `last_written_block` field identifies the recently mutated active set. Unlike local heuristics such as caches or snapshots, it is consensus-verified and consistent across all clients. This enables several categories of client-level optimization.

**Mutable tier vs stable tier:** The field yields a deterministic, consensus-agreed partition of state into a recently written set and a write-inactive set. Clients can map the two sets onto separate backing stores tuned for opposite access patterns. The mutable tier is sized for high write throughput and repeated rewrites (for example, a compact keyspace kept near the top of the storage hierarchy, or a memory-resident layer flushed periodically), while the stable tier is sized for density and read throughput (heavier compression or slower storage media).

**Commit-path optimization:** Per-block state commitment re-hashes every dirty trie path to the root and persists the resulting nodes. The dominant cost is the write amplification and random I/O of persisting these scattered updates. The mechanism differs by backend but the effect is the same: an LSM-tree rewrites overlapping key ranges during compaction, while a B-tree or other page-oriented store dirties and rewrites whole pages under copy-on-write. When recently written and write-inactive leaves share the same keyspace, each block's updates land across storage regions that are mostly cold, so the churn touches far more physical data than the active set itself. Confining the mutable tier to recently written state improves spatial locality and keeps the commit working set small and dense, so per-block write cost scales with the active set rather than with total state size.

**Prefetching on restart:** When a node restarts, its in-memory caches are empty. With `last_written_block`, clients can scan the database on startup and selectively prefetch recently written items, rebuilding the recent mutable working set without waiting for organic block processing.

None of these optimizations are mandated by this proposal. The `last_written_block` field enables but does not prescribe any particular client architecture.

### Why record the block number directly?

Recording the raw block number keeps this proposal independent of any state-tiering pricing design, so the two can be specified and finalized on separate timelines.

The block number is the finest-grained primitive: any coarser representation a pricing scheme might want, such as fixed-length renewal-age periods, can be derived from it deterministically, while the reverse is not possible once granularity is discarded. Storing the finest granularity therefore preserves the most optionality for the future without committing to any pricing parameters.

Those parameters, such as a period length, an anchor block, or an inactivity threshold, are pricing-policy choices that are still being worked out. Folding them into this encoding would couple a state-format change to an economic design that is not yet settled. By recording only the block number, the metadata can ship and stabilize on its own, while the state-tiering gas schedule is designed, debated, and tuned in a separate proposal that uses this field. That separation also lets the pricing policy be revised later without another change to the account and storage slot encoding.

### Why do reads not update the block?

This is a deliberate design choice. Only writes update `last_written_block` because:

**It would turn reads into writes:** If reads bumped the field, every stale read would rewrite the trie leaf, which escalates to state-root computation. An operation the caller expects to be a read would perform a write, forcing write-equivalent cost for a read operation.

**Database overhead:** When reads bump the field, every stale read forces a trie leaf rewrite, which in turn forces database relocation from the stable tier to the mutable tier. This adds write amplification to what should be a read-only operation, contradicting the goal of isolating the mutable path.

**STATICCALL correctness:** [EIP-214](./eip-214.md) guarantees that state is unchanged across a `STATICCALL`. This metadata is part of consensus state (it affects the state root via trie hashing). A read that modified it would violate this guarantee.

### How does extra metadata affect the state size?

The additional `last_written_block` field adds **5 bytes to every account** and **6 bytes to every storage slot**. The difference comes from RLP framing:

- Block number currently occupies 4 bytes, and RLP encodes a 4-byte string as a 1-byte length prefix (`0x84`) followed by the 4 value bytes, so the field itself is 5 bytes.
- An account is already an RLP list, so the field is appended as a fifth element and the account grows by exactly those 5 bytes.
- A storage slot was a bare byte string. Wrapping it as the two-element list `[value, last_written_block]` adds the 5-byte field **plus a 1-byte list prefix** that did not exist before, for **6 bytes** total. That extra byte versus the account is precisely the new list wrapper.

A 4-byte field holds block numbers up to `2^32 - 1`, about 4.29 billion. At the current 12-second slot time, this is about 1,600 years away, and still roughly 800 years even if the slot time were halved to 6 seconds. Only then would the field need a fifth value byte which increases the overhead to 6 bytes per account and 7 per storage slot. As a rough estimate using current state sizes (as of early 2026):

- 360M accounts × 5 bytes ≈ 1.8 GB
- 1.5B storage slots × 6 bytes ≈ 9.0 GB
- **Total: ~10.8 GB raw data overhead**

Note that this is a worst-case figure assuming all state has been written at least once post-fork. In practice, pre-fork state that is never written post-fork retains the legacy encoding and incurs no overhead. The actual impact should be quantified during benchmarking across different clients.

### Relation with state creation cost ([EIP-8037](./eip-8037.md))

This proposal adds bytes to every state entry, which interacts with [EIP-8037](./eip-8037.md)'s per-byte state-creation pricing. [EIP-8037](./eip-8037.md) charges `CPSB` (cost per state byte) gas for each byte of new state, derived from the on-disk footprint of a new account (`STATE_BYTES_PER_NEW_ACCOUNT = 120`) and a new storage slot (`STATE_BYTES_PER_STORAGE_SET = 64`).

The `last_written_block` field adds 5 bytes to every account leaf and 6 bytes to every storage-slot leaf (see the encoding breakdown above). For state-creation gas to continue reflecting true on-disk growth, these parameters SHOULD increase accordingly:

| Parameter | EIP-8037 value | With this proposal |
| --- | ---: | ---: |
| `STATE_BYTES_PER_NEW_ACCOUNT` | 120 | 125 |
| `STATE_BYTES_PER_STORAGE_SET` | 64 | 70 |

## Backwards Compatibility

- **Hard fork required.** Account and storage leaf RLP encodings change, which affects trie hashing and state-root computation. No tree transition is needed.
- **Legacy entries.** Legacy accounts and slots decode with `last_written_block = 0`. Pre-fork state that has never been written under the new rules retains the legacy encoding until its first post-fork mutation.

## Security Considerations

This proposal increases the encoded size of accounts and storage slots that are written after the fork. That extra state is itself a resource cost. The proposal does not introduce new write operations, but it increases the amount of data touched by writes and the size of state witnesses/proofs for updated entries.

The DoS risk is therefore bounded by existing write gas rules, but the additional bytes should still be accounted for in state-growth pricing. When combined with [EIP-8037](./eip-8037.md), the per-byte state-creation parameters SHOULD include the additional metadata bytes. Otherwise, new accounts and slots would be underpriced relative to their encoded size.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
