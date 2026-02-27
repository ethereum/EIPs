---
eip: 8032
title: Size-Based Storage Gas Pricing
description: Makes `SSTORE` gas cost scale with a contract's storage size to discourage state bloat.
author: Guillaume Ballet (@gballet), Carlos Perez (@CPerezz), Matan Prasma (@KanExtension), Wei Han Ng (@weiihann)
discussions-to: https://ethereum-magicians.org/t/the-case-for-eip-8032-in-glamsterdam-tree-depth-based-storage-gas-pricing/25619
status: Draft
type: Standards Track
category: Core
created: 2025-09-29
---

## Abstract

This EIP introduces a mechanism to dynamically price SSTORE operations based on the storage size of a contract. A new optional `storage_count` field is added to the account RLP, which tracks the number of storage slots it owns. The gas cost for SSTORE will be augmented by a factor that grows exponentially with this `storage_count` field, but only after it crosses a predefined activation threshold. This change aims to align the cost of state growth with the long-term burden it places on the network, thereby disincentivizing state bloat.

## Motivation

Ethereum's state size is a growing concern, as it directly impacts node synchronization times, hardware requirements, and overall network health. The current gas model for storage operations does not fully account for the long-term cost of maintaining state indefinitely. As a result, it remains economically viable to deploy contracts with large storage footprints (“state bloat”), which can be exploited for low-cost data anchoring or spam. This imposes a negative externality on all network participants, who must store and process this data indefinitely.

In practice, the computational and I/O costs of creating and updating storage slots scale with the number of storage slots a contract owns. However, the current gas pricing model does not meaningfully increase with storage size. This discrepancy underprices workloads for contracts with very large state and slows down state root computation.

This proposal aims to address the state growth problem by creating a direct economic link between the size of a contract's storage and the cost to expand it further. By progressively increasing the price of SSTORE operations in proportion to how much storage a contract already owns, storage write costs become more aligned with the actual work clients perform. Contracts that contribute disproportionately to state growth will face rising costs for additional writes, while small and medium-sized contracts remain unaffected. This mechanism creates a market-based incentive for developers to use onchain storage efficiently, helping mitigate unsustainable state growth over time.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Constants and parameters

|Name|Value|Description|
|-|:-:|-|
|`FORK_TIMESTAMP`| TBD | Fork activation timestamp |
|`LIN_FACTOR` | TBD | Linear gas cost factor |
| `ACTIVATION_THRESHOLD` | TBD | Activation threshold, chosen to be at ~8GB of data. |
| `TRANSITION_REGISTRY_ADDRESS` | TBD | The address of system contract that holds the information of account transition |
| `TRANSITION_SLOTS_PER_BLOCK` | TBD | The number of storage slots to iterate per block during the transition process |
| `TRANSITION_MAX_ACCOUNTS` | TBD | The number of accounts to iterate per block during the transition process |

<-- TODO -->

### New account field

Account RLP descriptors receive an optional `storage_count` field, corresponding to the current number of storage slots it contains.

### Account transition

At `FORK_TIMESTAMP`, the transition is activated.

The transition process involves reading all accounts and count the number of storage slots for accounts with non-empty storage root hashes, which in turn populates the `storage_count` field in the account.

The progress of the transition is stored at system contract at `TRANSITION_REGISTRY_ADDRESS`.


Storage layout at `TRANSITION_REGISTRY_ADDRESS`:

- slot `0x00`: `cursor_account_hash` (32-byte account hash)
- slot `0x01`: `cursor_slot_hash` (32-byte slot hash)
- slot `0x02`: `cursor_accum` (uint256 count of non-zero slots seen for the current account)

At the **end** of each block, the client performs up to `TRANSITION_SLOTS_PER_BLOCK` storage slot iterations, possibly spanning one account or multiple accounts:

1. **Select account**  
   If `cursor_account_hash == 0x00…00`, set it to the smallest account hash that is present in the state trie. Otherwise, continue with `cursor_account_hash`.

2. **Iterate storage slots**  
   If the current account at `cursor_account_hash` has a non-empty `storageRootHash`, visit storage slots of this account in ascending lexicographic order of `slot hash`, starting **strictly after** `cursor_slot_hash` (or from the beginning if `cursor_slot_hash == 0x00…00`).
   - Increment `cursor_accum` slot for every slot hash seen
   - Stop when either:
     - `TRANSITION_SLOTS_PER_BLOCK` slots have been processed, or
     - there are no more storage slots for the account.

3. **Finalize account (if exhausted)**  
   If all storage slots for `cursor_account_hash` have been visited, set `storage_count(cursor_account)` to `cursor_accum` in the account object.
   
   If `TRANSITION_MAX_ACCOUNTS` accounts are iterated, then stop iterating.
   - Else: 
        - Advance to the next account:  
        `cursor_account_hash` = next account hash that is present in the state trie
        - Reset per-account cursors:  
        `cursor_slot_hash = 0x00…00`, `cursor_accum = 0`

4. **Persist**  
   If either `TRANSITION_SLOTS_PER_BLOCK` or `TRANSITION_MAX_ACCOUNTS` is reached, write `cursor_account_hash`, `cursor_slot_hash`, and `cursor_accum` to the registry in the post-state of the block.

5. **Completion**  
   The transition is complete when there is no further account present in the trie, with an account hash that is lexicographically greater than the current `cursor_account_hash`.

The account hashes and slot hashes are iterated in ascending lexicographical order.

Transition reference: [EIP-7612](./eip-7612.md)

#### Reorg semantics

Chain reorganizations require **no special handling** beyond normal block re-execution. The mechanism is reorg-safe.

`storage_count` updates and the transition cursors (`cursor_account_hash`, `cursor_slot_hash`, `cursor_accum`) are ordinary state writes committed in the post-state of each block at `TRANSITION_REGISTRY_ADDRESS`. On a reorg, these values revert to those of the new canonical ancestor and are re-derived by re-executing blocks.

### Account update rules

After executing all transactions in a block, clients MUST update `storage_count` for affected accounts as follows:

- Let `old := storage_count(A)` in the block-prestate (treat as `0` if absent).
- Let `new` be the true count of non-zero slots for `A` in the post-block state.
- Set `storage_count(A) := new`.

To compute `new` efficiently without scanning all storage every block, clients MUST apply net deltas derived from slots whose values changed relative to the block-prestate:

For each storage slot `k` of account `A` that was written at least once in the block:

```python
def calculate_storage_delta(prestate_value, poststate_value):
    """
    Calculate the storage slot delta based on pre-state and post-state values.
    
    Args:
        prestate_value: Pre-state value of the storage slot
        poststate_value: Post-state value of the storage slot
    
    Returns:
        int: Delta value (+1, -1, or 0)
    """
    if prestate_value == 0 and poststate_value != 0:
        return 1    # Slot created: empty to non-empty
    elif prestate_value != 0 and poststate_value == 0:
        return -1   # Slot deleted: non-empty to empty
    else:
        return 0    # No change in slot occupancy
```

During a transition, the transition is advanced *first* before applying the storage deltas, but *after* executing all transactions, so the gas costs of a contract that is sweeped by the iterator in this block are only applied for the *next* block. Update semantics when a transition is occurring:

- For accounts that have been iterated (i.e. `cursor_account_hash` > `acc_hash` ), all storage deltas are applied.
- For accounts that have not been iterated at all (i.e. `acc_hash` > `cursor_account_hash`), none of the storage deltas are applied.
- For the account currently being iterated (i.e. `cursor_account_hash` == `acc_hash`), storage deltas are applied only to the slots that have already been accounted for (i.e. `cursor_slot_hash` > `slot_hash`).

### SSTORE gas cost changes

For each contract account `A`, define `S_pre(A)` as the value of `storage_count(A)` in the parent state of the block being executed (pre-state).

For all `SSTORE`s in the block, implementations MUST use `S_pre(A)` when computing the gas cost for `SSTORE`. This value MUST NOT change within the block, regardless of any writes to `A` during the block.

If `storage_count(A)` is absent at block start, clients MUST treat `S_pre(A) = 0`.

> Rationale: holding `S_pre(A)` constant within the block keeps gas estimation stable and independent of transaction ordering.

The gas cost of an `SSTORE` is computed as such:

```python=
constant_sstore_gas(addr, slot) + LIN_FACTOR * ceil_log16(S_pre(addr)) // ACTIVATION_THRESHOLD
```

### Impact on state size

`storage_count` is RLP-encoded as a minimal-length big-endian byte string (no leading zeros). The per-account overhead is therefore small and not a fixed 32 byte number. The field is present only for accounts with a non-empty storage root hash. If `storage_count == 0`, the field may be omitted.

**Per-account overhead**

- Payload length `L = bytes_required(storage_count)`:
  - `L = 0` for `0` (field may be omitted entirely)
  - `L = 1` for `1 … 255`
  - `L = 2` for `256 … 65,535`
  - `L = 3` for `65,536 … 16,777,215`
  - `L = 4` for `16,777,216 … 4,294,967,295` (≈ 4.29B)
- **+1 byte** RLP string prefix (since `L ≤ 55`)
- **+ up to 1 byte** for the account-list prefix growth (only if the list’s total payload crosses a size boundary)

For context, at block ~23,000,000 the largest contract has about **80M** storage slots. Even at that scale (`L = 4`), the per-account addition remains **≤ 6 bytes**.

If we pessimistically assume **23,000,000** contract accounts each carry `storage_count` and each incurs the worst-case **6 bytes**, the upper bound is:

- `23,000,000 × 6 = 138,000,000` bytes ≈ **138 MB**

This is a conservative upper bound. In practice, most contracts have far fewer slots (`L ≤ 1–3`), so a typical addition is 2–4 bytes per contract. Therefore, the net impact on state size is negligible.

## Rationale

The intent is to create friction when growing the state size of a contract, thus limiting the number of such contracts. Going over the limit, some contract developers might want to use another contract to start fresh, which comes at the cost of paying for contract creation, and for any call into the previous instance of the contract.

`ACTIVATION_THRESHOLD` is chosen to not penalize the contracts that are large, but do provide useful value. The idea is to disincentivize spam contracts that grow larger than useful contracts, the latter being legitimately big due to the value they bring to their users and the wider ecosystem. This means that this constant could be increased as the state grows.

`TRANSITION_MAX_ACCOUNTS` bounds how many accounts may be finalized (i.e. have their `storage_count` written) per block during the transition. This prevents excessive write operations per block, reducing write amplification and avoiding large database compactions and associated performance degradation. It complements `TRANSITION_SLOTS_PER_BLOCK`, which limits how many **storage slots** are scanned per block in line with the minimal hardware recommendations. In short, `TRANSITION_SLOTS_PER_BLOCK` bounds read operations, while `TRANSITION_MAX_ACCOUNTS` bounds write operations.

### Comparison with depth-based pricing

The largest contract observed (XEN) sits around depth 9, meaning its relevant storage keys share a 9-nibble (~4.5 bytes) prefix along their MPT paths. Because the storage key into the trie is `keccak256(slot_key)`, an attacker can easily calculate the inputs offchain to find hashes and populate all contracts such that they pay the same cost as XEN.

### Why is a transition needed?

If counting began only at `FORK_TIMESTAMP`, every existing contract would start with an implicit `storage_count = 0` and accrue counts only from *new* writes. While spammy contracts would quickly accumulate writes and thus incur penalties, this would still misprice the workloads we intend to regulate: large pre-fork contracts would continue paying unscaled base costs until they rewrote a substantial portion of their historical slots. During that period, gas pricing would understate their actual storage footprint.

A deterministic, in-protocol transition avoids this. By iterating existing storage under consensus rules and progressively populating each account’s `storage_count` in the state, we ensure that storage-size-based pricing reflects reality for *all* contracts—regardless of whether they write again after the fork. Persisting cursor progress under the state root also makes the process reorg-safe and client-agnostic.

**Alternative (pre-fork background counting by clients)**

- **Idea:** Clients begin counting slots before `FORK_TIMESTAMP`. At activation, they only need to write the final counts into the state for a fixed number of accounts.
- **Pros:** Reduces post-fork iteration work, much faster convergence at fork time since iterating all accounts is faster than all storage slots.
- **Cons:** Late upgraders, snap-syncing nodes, or nodes that were offline cannot reconstruct pre-fork counts deterministically. This approach has to be coordinated so that all users upgrade their nodes and must finish counting prior to the fork activation. Reorgs have to be handled explicitly too.

### Compatibility with Verkle/Binary unified tree

In the current two-layer MPT, a write to contract storage accesses an account path and then a storage path, and the cost a client pays in trie updates and database reads/writes correlates with how deep the storage trie becomes over time.

Under a unified tree, the per-write computational and I/O cost of `SSTORE` no longer tracks an account’s total number of storage slots. The path length is set by the global tree’s branching factor and height, and by the overall distribution of state keys, not by a single account’s footprint. As a result, progressive pricing based on an account’s slot count can become misaligned with the actual work once a unified tree ships.

### Compatibility with EIP-2926

Because [EIP-2926](./eip-2926.md) also requires an account transition to chunkify the bytecode and additional fields, scheduling both EIPs in the same fork enables a single, combined transition. This removes duplicated work, reduces client complexity and the number of tree transitions in the future.

## Backwards Compatibility

No backward compatibility issues found. Making the `storage_count` field optional ensures that the default count is 0, which means that contract will not be affected by the gas increase before they have been reached by the iterator sweep.

This is a backwards incompatible gas repricing that requires a scheduled network upgrade.

Node operators MUST update gas estimation handling to accommodate the new calldata cost rules. Specifically, RPC methods such as `eth_estimateGas` MUST incorporate the updated formula for gas calculation when encountering an `SSTORE`.

Users and wallets can maintain their usual workflows without modification, as RPC updates will handle these changes.

## Test Cases

TODO

## Reference Implementation

TODO

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
