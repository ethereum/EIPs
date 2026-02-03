---
eip: XXXX
title: Namespaced Storage in Binary Trie
description: Introduce MAPSTORE and MAPLOAD opcodes for locality-preserving storage mappings
author: Wei Han Ng (@weiihann)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2025-02-03
requires: 4762, 7864
---

## Abstract

This EIP introduces two new opcodes, `MAPSTORE` and `MAPLOAD`, that provide locality-preserving storage for mapping-style data structures. By using a modified key derivation scheme within the unified binary trie defined in [EIP-7864](./eip-7864.md), values stored under the same `(address, namespace)` pair are co-located in groups of 256, reducing branch openings and witness sizes for clustered access patterns.

## Motivation

A large fraction of Ethereum's state is logically organized as mappings:

- ERC20 balances: `mapping(address => uint256)`
- User positions: `mapping(address => Struct)`
- Token metadata: `mapping(uint256 => Struct)`
- Nested mappings: `mapping(address => mapping(uint256 => uint256))`

Today, these mappings use Solidity's storage layout where slot keys are computed as `keccak256(key || base_slot)`. This scatters logically related data across random locations in the trie. When a transaction accesses multiple fields of the same struct, EL clients must perform multiple unrelated storage lookups.

Consider the following example in Solidity:
```solidity
struct Stake {
    uint256 amount;
    uint256 timestamp;
    uint256 rewardDebt;
}

mapping(address => Stake) public stakes;

function deposit(uint256 amount) external {
    stakes[msg.sender].amount += amount;
    stakes[msg.sender].timestamp = block.timestamp;
    stakes[msg.sender].rewardDebt = calculateDebt(amount);
}
```

When a user calls `deposit()`, the 3 struct fields are scattered across 3 random trie locations, requiring 3 separate branch openings.

With `MAPSTORE`, a compiler can place all 3 fields under the same namespace (the user's address) at consecutive slots 0-2. Since the slots are stored under the same stem, this requires only one branch opening instead of three.

## Specification

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Key Derivation
#### Conventions:
- `address` - the address in the current execution context (32 bytes)
- `namespace` - a 32-byte value identifying the logical grouping
- `slot` - a 32-byte value identifying the position within the namespace
- `tree_hash` - the hash function used by the binary trie as defined in [EIP-7864](./eip-7864.md)

```python
def get_namespaced_storage_key(address: bytes32, namespace: bytes32, slot: int) -> bytes32:
    tree_index = slot // 256
    sub_index = slot % 256
    
    # 96-byte input: address (32) || namespace (32) || tree_index (32)
    stem = tree_hash(
        address + 
        namespace + 
        tree_index.to_bytes(32, "little")
    )[:31]
    
    return stem + bytes([sub_index])
```

This key derivation differs from EIP-7864's main storage key derivation:

| Storage Type | Hash Input |
|--------------|------------|
| Main storage (EIP-7864) | `address \|\| tree_index`
| Namespaced storage | `address \|\| namespace \|\| tree_index`

The different input lengths provide domain separation, making collisions between main storage and namespaced storage computationally infeasible.

### EVM Opcodes

#### `MAPLOAD(namespace, slot)`

Loads a 32-byte value from namespaced storage.

**Stack input:**
| Stack | Value |
|-------|-------|
| top | `namespace` |
| top - 1 | `slot` |

**Stack output:**
| Stack | Value |
|-------|-------|
| top | `value` |

**Lookup the storage tree key derivation:**
1. Let `address` be the 32-byte left-padded address of the current execution context
2. Let `key = get_namespaced_storage_key(address, namespace, slot)`
3. Return the 32-byte value stored at `key` in the binary trie, or `0` if no value exists

#### `MAPSTORE(namespace, slot, value)`

Stores a 32-byte value to namespaced storage.

**Stack input:**
| Stack | Value |
|-------|-------|
| top | `namespace` |
| top - 1 | `slot` |
| top - 2 | `value` |

**Stack output:**
(none)

**Lookup the storage tree key derivation:**
1. Let `address` be the 32-byte left-padded address of the current execution context
2. Let `key = get_namespaced_storage_key(address, namespace, slot)`
3. Store `value` at `key` in the binary trie

### Gas Accounting

Gas costs follow the binary trie access model defined in [EIP-4762](./eip4762.md), with the following considerations:

| Operation | Gas Cost |
|-----------|----------|
| First stem access (cold) | `WITNESS_BRANCH_COST` |
| Subsequent access to same stem (warm) | `WITNESS_CHUNK_COST` |
| Write to new slot | `SUBTREE_EDIT_COST` |
| Write to existing slot | `CHUNK_EDIT_COST` |

### Interaction with DELEGATECALL

When `MAPSTORE` or `MAPLOAD` is executed within a `DELEGATECALL` context, the `address` parameter is the address of the **delegating contract** (the contract that initiated the `DELEGATECALL`), not the contract containing the executing code.

This preserves the expected behavior for proxy patterns where storage is associated with the proxy's address, not the implementation's address.

### Interaction with STATICCALL

`MAPSTORE` is prohibited within a `STATICCALL` context and MUST revert with a state modification error, consistent with `SSTORE` behavior.

`MAPLOAD` is permitted within a `STATICCALL` context.

## Rationale

### Locality

For a fixed `(address, namespace)` pair, slots `0` through `255` share the same stem:

| Slot | tree_index | sub_index | Stem |
|------|------------|-----------|------|
| 0 | 0 | 0 | `hash(address \|\| namespace \|\| 0)[:31]` |
| 1 | 0 | 1 | same stem |
| ... | 0 | ... | same stem |
| 255 | 0 | 255 | same stem |
| 256 | 1 | 0 | `hash(address \|\| namespace \|\| 1)[:31]` |

This means accessing slots `0-255` under the same namespace requires only **one branch opening** in the binary trie.

The key benefit is that accessing multiple slots under the same `(address, namespace)` amortizes the branch cost. For example:
```solidity
// Traditional SSTORE: 3 cold branch accesses
userMints[msg.sender].user = msg.sender;       // cold
userMints[msg.sender].term = term;             // cold (different branch!)
userMints[msg.sender].maturityTs = timestamp;  // cold (different branch!)

// With MAPSTORE: 1 cold + 2 warm accesses
MAPSTORE(msg.sender, 0, msg.sender);  // cold (opens branch)
MAPSTORE(msg.sender, 1, term);        // warm (same stem!)
MAPSTORE(msg.sender, 2, timestamp);   // warm (same stem!)
```

### Collision Resistance

Namespaced storage keys cannot collide with main storage keys because:

- Main storage: `stem = hash(64-byte input)[:31]`
- Namespaced storage: `stem = hash(96-byte input)[:31]`

For a collision to occur, `hash(A || B) = hash(A || B || C)` for some values, which would require finding a preimage collision in the hash function.

Different namespaces within the same contract also cannot collide: `hash(contract || ns1 || idx) ≠ hash(contract || ns2 || idx)` when `ns1 ≠ ns2`.

## Backwards Compatibility
This EIP requires a hard fork to implement. It introduces new opcodes and does not modify existing behavior:

- Existing `SSTORE`/`SLOAD` operations are unchanged
- Contracts not using `MAPSTORE`/`MAPLOAD` are unaffected
- The binary trie structure defined in EIP-7864 is unchanged. Only key derivation for new opcodes is added.

Only newer contracts can take advantage of namespaced storage. Migration of existing contract data is not possible without knowing the original mapping keys (preimage problem).