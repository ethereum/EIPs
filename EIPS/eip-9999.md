---
eip: 9999
title: Multi-block access list warming
description: Pre-warm the per-transaction access list with items from the previous 256 block access lists
author: Toni Wahrstätter (@nerolation)
discussions-to: https://ethereum-magicians.org/t/eip-9999-multi-block-access-list-warming/0
status: Draft
type: Standards Track
category: Core
created: 2026-05-03
requires: 2929, 2930, 7928
---

## Abstract

About **17 %** of an Ethereum mainnet block's gas pays the [EIP-2929](./eip-2929.md) cold-access surcharge: the extra ~2100 gas for the first touch of a storage slot and ~2600 for the first touch of an account address in a transaction. About **79 %** of those first-touch items were also touched in the previous 256 blocks, so the surcharge is recoverable: a 256-block warming horizon saves **~14 %** of total block gas at the median.

This EIP defines a chain-state **warm-access multiset (WAM)** that records every item (an account address or `(address, storage_key)` pair) present in the Block Access Lists (BALs, [EIP-7928](./eip-7928.md)) of the last 256 blocks. Items in the WAM at the start of a block are treated as already-accessed for [EIP-2929](./eip-2929.md) pricing in every transaction of that block. The WAM is maintained incrementally each block: `+1` for every item in the new BAL, `-1` for every item in the BAL leaving the window. Membership tests are `O(1)`; per-block updates are `O(|BAL|)`.

## Motivation

[EIP-2929](./eip-2929.md) charges a cold-access surcharge of ~2100 gas per storage slot and ~2600 per account address the first time each transaction touches a given item, then resets the list at every new transaction. On Ethereum mainnet this surcharge accounts for a median of **17 % of every block's gas**: gas paid only to mark state as known to the EVM.

Across blocks, the same items are touched repeatedly. Empirical measurement on 5731 mainnet blocks shows that **79 % of cold-charged items in a typical block were also touched in the previous 256 blocks** (~51 minutes). Treating those items as already-accessed at the start of the block would eliminate the surcharge they paid, saving **~14 % of total block gas at the median**.

A naive implementation (store the 256 most recent raw BALs, recompute their union per query) makes membership tests `O(256)`. The refcounted-multiset representation specified here gives `O(1)` membership tests and `O(|BAL|)` per-block updates, independent of the window size.

## Specification

The key words "MUST", "MUST NOT", "SHOULD", and "MAY" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Constants

```
WARMING_WINDOW = 256           # blocks (~51 min at 12 s/slot)
```

### Item type

An item is one of:

- `Account(addr)`: a 20-byte Ethereum address;
- `Slot(addr, key)`: a 20-byte address paired with a 32-byte storage key.

`items(BAL(N))` is the deduplicated set of every address and `(address, slot)` pair in `BAL(N)` ([EIP-7928](./eip-7928.md)).

### State: the warm-access multiset

Add one piece of chain-derived state:

```
WAM : Item -> u32
```

Items not present have count 0. **An item is *warm* iff `WAM[item] > 0`.**

### Per-block transition

Before transaction execution in block `B`:

```
ADD = items(BAL(B − 1))
DEL = items(BAL(B − 1 − WARMING_WINDOW))      # empty if B ≤ WARMING_WINDOW

for item in ADD:
    WAM[item] += 1
for item in DEL:
    WAM[item] -= 1
    if WAM[item] == 0:
        delete WAM[item]
```

`ADD` is applied before `DEL` so items appearing in both do not transiently reach zero. The final `WAM` is independent of update order.

Historical `items(BAL(N))` for `N ≥ B − 1 − WARMING_WINDOW` are needed to evaluate `DEL` and are already available from [EIP-7928](./eip-7928.md).

### Commitment

The WAM is committed to by a binary Sparse Merkle Tree (SMT) of depth 256:

```
leaf_key(item) = SHA256(serialize(item))      # 256-bit
leaf_value     = u32 counter (0 if absent)
WAM_ROOT       = SMT root over { leaf_key → leaf_value }
```

SHA-256 is used for both leaf keys and node hashing (matching beacon-chain SSZ Merkleization; precompile `0x02`). `WAM_ROOT` is added to the block header as a new 32-byte field `wam_root`:

```python
class Header:
    ...
    wam_root: Hash32
```

The per-block transition updates the SMT incrementally: one leaf update per item in `ADD ∪ DEL`. Order does not affect the root since SMT structure depends only on leaf keys.

Inclusion or non-inclusion proofs consist of 256 sibling hashes (fixed shape, independent of `|WAM|`). A future ZK-friendly hash precompile (e.g., Poseidon) can replace `SHA256` without changing the structure.

### Access-list initialization in transactions

At the start of every transaction in block `B`, the per-tx access list is initialized as today (precompiles, `tx.from`, `tx.to`, coinbase per [EIP-3651](./eip-3651.md), [EIP-2930](./eip-2930.md) access list, [EIP-7702](./eip-7702.md) authority list) **plus** every item with `WAM[item] > 0`.

### Pricing

No new gas constants. For every access-list-priced opcode:

- if its operand item is warm (present in the WAM or added earlier in this transaction), it pays the warm cost: `100` gas for both account and storage access;
- otherwise it pays the cold cost (`2600` for accounts, `2100` for storage), and the item is added to the per-transaction access list as in [EIP-2929](./eip-2929.md).

### Revert semantics

The WAM is mutated only by the per-block transition. Transaction execution, including reverts, does not modify it.

### Genesis and activation

For the first `WARMING_WINDOW` blocks after activation, `DEL` is empty. The WAM grows monotonically until block `activation_block + WARMING_WINDOW`, then enters steady-state.

## Rationale

### Why a refcounted multiset

Multi-block warming is a sliding-window union of BAL items. Three representations:

| Representation | Membership test | Per-block update | Recompute on reorg |
|---|---|---|---|
| Store 256 raw BALs, recompute union per query | O(256) lookups | O(1), shift the ring | O(1) |
| Store 256 raw BALs, materialize union as a set | O(1) | O(union recompute), expensive | O(union recompute) |
| **Refcounted multiset (this EIP)** | **O(1)** | **O(\|BAL_in\| + \|BAL_out\|)** | **O(WARMING_WINDOW · avg \|BAL\|)** |

The refcounted multiset is preferable on both the membership-test path (consulted on every access-list-priced opcode) and the per-block update path. Reorg recomputation cost is identical across all three representations.

### Why 256 blocks

Median per-block trade-off on a 5 731-block mainnet sample:

| W | Time back | % cold ops flipped | % gas saved | WAM (MB) |
|---:|---:|---:|---:|---:|
| 8 | 96 s | 60 % | 10.1 % | 0.6 |
| 32 | 6.4 min | 70 % | 12.0 % | 2 |
| 128 | 25.6 min | 78 % | 13.3 % | 6 |
| **256** | **51 min** | **81 %** | **13.9 %** | **10** |
| 512 | 102 min | 84 % | 14.3 % | 18 |
| 1024 | 3.4 h | 85 % | 14.5 % | 31 |
| Asymptote | n/a | 100 % | 17.5 % | n/a |

W=256 captures ~79 % of the gas asymptote at ~10 MB of WAM state and sits 4× past the finality horizon. The next doubling (W=512) triples the marginal cost per added warm conversion for only ~0.4 percentage points more, so W=256 is at the inflection of the cost-benefit curve.

Implementations that prioritise memory can pick W=8 (~0.6 MB, 60 % ops), W=16 (~1 MB, 65 %), or W=32 (~2 MB, 70 %, also one epoch). Implementations with memory to spare can pick W=512 (~18 MB, 84 %); past that the cost-benefit deteriorates sharply.

### Reuse of EIP-7928 BALs

[EIP-7928](./eip-7928.md) introduces a canonical Block Access List committed to the block header. This specification consumes that artifact directly as the source of `ADD` and `DEL` items. Without [EIP-7928](./eip-7928.md), this EIP would need an independent access-list commitment mechanism, which is out of scope.

### Binary SMT (not MPT) and SHA-256 (not Keccak)

A zkEVM prover charges every access opcode with one inclusion or non-inclusion proof against `WAM_ROOT`. For ~3 000 access opcodes per block, per-proof cost is on the critical path. Two independent choices drive efficiency:

- **SMT over MPT.** A binary SMT keyed by `SHA256(item)` gives a uniform 256-level proof shape and natural non-inclusion proofs (a zero leaf on the deterministic path). MPT proofs are variable-depth and need a divergent-sibling step for non-inclusion, producing non-uniform circuits that need recursive verification.
- **SHA-256 over Keccak-256.** Both are available on Ethereum L1, but SHA-256 costs ~25 k constraints per hash in standard R1CS/BN254 arithmetization (5–10 k in lookup-based proof systems), versus ~150 k for Keccak. SHA-256 is also the hash used by beacon-chain SSZ Merkleization. A future EIP introducing a ZK-friendly hash precompile (e.g., Poseidon) can replace `SHA256` without changing the structure.

The WAM is new state, so a ZK-friendly commitment does not break compatibility with the existing MPT/Keccak state trie.

### Why a separate `wam_root`

The WAM is deterministic from the chain of `BAL` commitments, so `wam_root` is technically redundant with the historical `block_access_list_hash` fields, the same way `state_root` is technically redundant with genesis plus all transactions. The commitment is included because re-deriving it on demand is too expensive for the verifiers that matter:

- a zkEVM prover would need to prove the 256-block WAM transition inside the circuit, or feed the full WAM as witness;
- a light or stateless client would need to download all 256 BALs to check a single warmness query.

With `wam_root`, both reduce to one 256-hash proof against the block header. The cost is 32 bytes per header and an incremental SMT update per block.

### No new gas constants

Reusing existing warm/cold costs keeps the gas table small and lets gas estimation, fuzzers, and compilers continue to work without modification.

## Backwards Compatibility

Forward-only: every existing transaction pays the same or less gas. No transaction becomes invalid. [EIP-2930](./eip-2930.md) access lists remain valid and are pre-warmed (idempotent overlap with the WAM).

**State cost.** From a 5 731-block mainnet sample, ~3 000 distinct items per block enter the WAM with heavy overlap. Empirical WAM size at W=256: ~170 000 distinct items, ~10 MB at 60 bytes per entry, plus SMT internal nodes. Comparable to the [EIP-7928](./eip-7928.md) BAL history nodes already retain.

**Block header.** One new 32-byte field `wam_root`. Validators verify it matches the SMT root after the per-block transition.

**Worst-case state.** Bounded by `WARMING_WINDOW × max_distinct_items_per_block`, which is bounded by the block gas limit. A pathological block of only unique cold storage accesses contributes ~16 000 items; the worst-case WAM at W=256 is ~4 million items ≈ 250 MB. No realistic mainnet workload approaches this.

## Test Cases

To be added. Reference scenarios for a storage slot `(c, s)`:

1. Block `N−1`: SLOAD on `(c, s)`. Cold (2100). `items(BAL(N−1))` now contains `Slot(c, s)`.
2. Block `N`: WAM has `Slot(c, s) → 1`. SLOAD on `(c, s)`. **Warm (100)**.
3. Blocks `N+1 … N+256`: SLOAD on `(c, s)` once per block. WAM count increments to ≤ 257 then decrements as the oldest contributing block ages out; the item stays warm.
4. Block `N+257`: assume `(c, s)` was not touched after `N`. The transition adds `items(BAL(N+256))` (no `(c, s)`) and removes `items(BAL(N))` (contains `(c, s)`). `WAM[Slot(c, s)]` drops to 0 and is deleted. SLOAD on `(c, s)`: **Cold (2100)**.

## Security Considerations

### State growth and DoS

Adding an item to the WAM requires paying the [EIP-2929](./eip-2929.md) cold cost (≥ 2100 gas), which is unchanged from today. The 2000–2500 gas saving accrues only to subsequent legitimate accessors of the same item, not to the contributor, so there is no economic incentive to inflate the WAM.

### Memory pressure

At ~10 MB the WAM fits in memory alongside existing node caches. A hash map of items to small counters does not require cold-tier storage.

### Reorg behavior

WAM transitions are deterministic functions of `BAL(N−1)` and `BAL(N−1−WARMING_WINDOW)`. Re-executing the new canonical chain rebuilds the correct WAM. No explicit refund machinery is required. Finality (~12.8 min for two epochs) bounds reorg depth to a tiny fraction of the warming window.

### Light/stateless clients

The WAM is derived deterministically from [EIP-7928](./eip-7928.md) BAL history. Light clients can either compute `WAM_ROOT` from BAL history or verify (non-)inclusion proofs directly against the `wam_root` in the block header.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
