---
eip: draft
title: Contract Bytecode Deduplication Discount
description: Reduces gas costs for deploying duplicate contract bytecode via access-list based mechanism
author: Carlos Perez (@CPerezz), Wei-Han (@weiihann), Guillaume Ballet (@gballet)
discussions-to: https://ethereum-magicians.org/t/eip-8037-state-creation-gas-cost-increase/25694
status: Draft
type: Standards Track
category: Core
created: 2025-10-22
requires: 2930
---

## Abstract

This proposal introduces a gas discount for contract deployments when the bytecode being deployed already exists in the state. By leveraging EIP-2930 access lists, any contract address included in the access list automatically contributes its code hash to a deduplication check. When the deployed bytecode matches an existing code hash from the access list, the deployment avoids paying `GAS_CODE_DEPOSIT * L` costs since clients already store the bytecode and only need to link the new account to the existing code hash.

This EIP becomes particularly relevant with the adoption of EIP-8037, which increases `GAS_CODE_DEPOSIT` from 200 to 1,900 gas per byte. Under EIP-8037, deploying a 24kB contract would cost approximately 46.6M gas for code deposit alone, making the deduplication discount economically significant for applications that deploy identical bytecode multiple times.

## Motivation

Currently, deploying duplicate bytecode costs the same as deploying new bytecode, even though execution clients don't store duplicated code in their databases. When the same bytecode is deployed multiple times, clients store only one copy and have multiple accounts point to the same code hash. Under EIP-8037's proposed gas costs, deploying a 24kB contract costs approximately 46.6M gas for code deposit alone (`1,900 × 24,576`). This charge is unfair for duplicate deployments where no additional storage is consumed.

A naive "check if code exists in database" approach would break consensus because different nodes have different database contents due to mostly Sync-mode differences:
- Full-sync nodes: Retain all historical code, including from reverted/reorged transactions
- Snap-sync nodes: initially, only store code referenced in the pivot state tries, and those accumulated past the start of the sync

Empirical analysis reveals that approximately 27,869 bytecodes existed in full-synced node databases with no live account pointing to them (as of the Cancun fork). A database lookup `CodeExists(hash)` would yield different results on different nodes, causing different gas costs and breaking consensus.

This proposal solves the problem by making deduplication checks explicit and deterministic through access lists, ensuring all nodes compute identical gas costs regardless of their database state. (Notice here that even if fully-synced clients have more codes, there are no accounts whose codeHash actually is referencing them. Thus, users can't profit from such discounts which keeps consensus safe).

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Implicit Deduplication via Access Lists

This proposal leverages the existing EIP-2930 access list structure without any modifications. No new fields or protocol changes are required.

### CodeHash Access-Set Construction

Before transaction execution begins, build a set `W` (the "CodeHash Access-Set") as follows:

```
W = { codeHash(a) | a ∈ accessList, a exists in state, a has code }
```

Where:
- `W` is built from state at the **start** of transaction execution (before any state changes)
- **All** addresses in the access list are checked - if they exist in state and have deployed code, their code hash is added to `W`
- Empty accounts or accounts with no code do not contribute to `W`

### Contract Creation Gas Accounting

When a contract creation transaction or opcode (`CREATE`/`CREATE2`) successfully completes and returns bytecode `B` of length `L`, compute `H = keccak256(B)` and apply the following gas charges:

**Deduplication check:**
- If `H ∉ W`: Bytecode is new
  - Charge `GAS_CODE_DEPOSIT * L`
  - Persist bytecode `B` under hash `H`
  - Link the new account's `codeHash` to `H`
- Otherwise, link the new account's `codeHash` to the existing code hash `H`

**Gas costs:**
- The cost of reading `codeHash` for access-listed addresses is already covered by EIP-2929/2930 access costs (intrinsic access-list cost and cold→warm state access charges).
- No additional gas cost is introduced for the deduplication check itself.

### Implementation Pseudocode

```python
# Before transaction execution:
W = set()
for tuple in tx.access_list:
    warm(tuple.address)  # per EIP-2930/EIP-2929 rules
    acc = load_account(tuple.address)
    if acc exists and acc.code is not empty:
        W.add(acc.codeHash)

# On successful CREATE/CREATE2:
H = keccak256(B)
if H in W:
    # Duplicate: no deposit gas
    link_codehash(new_account, H)
else:
    # New bytecode: charge and persist
    charge(GAS_CODE_DEPOSIT * len(B))
    persist_code(H, B)
    link_codehash(new_account, H)
```

### Same-Block Deployments

Sequential transaction execution ensures that a deployment storing new code makes it visible to later transactions in the same block:

1. Transaction `T_A` deploys bytecode `B` at address `X`
   - Pays full `GAS_CODE_DEPOSIT * L` (no prior contract has this bytecode)
   - Code is stored under hash `H = keccak256(B)`

2. Later transaction `T_B` in the same block deploys the same bytecode `B`:
   - `T_B` includes address `X` in its access list
   - When `T_B` executes, `W` is built from the current state (including `T_A`'s changes)
   - Since `X` now exists and is in the access list, `W` contains `H`
   - `T_B`'s deployment gets the discount

> While this only tries to formalize the behavior, it's important to remark that this kind of behavior is complex. As it requires control over tx ordering in order to abuse. Builders can't modify the access list as it is already signed with the transaction. Nevertheless, this could happen, thus is formalized here.

### Edge Case: Simultaneous New Deployments

If two transactions in the same block both deploy identical new bytecode and neither references an existing contract with that bytecode in their access lists, both will pay full `GAS_CODE_DEPOSIT * L`.

**Example:**
- Transaction `T_A` deploys bytecode `B` producing code hash `0xCA` at address `X`
- Transaction `T_B` (later in same block) also deploys bytecode `B` producing code hash `0xCA` at address `Y`
- If `T_B`'s access list does NOT include address `X`, then `T_B` pays full deposit cost
- Deduplication only occurs when the deploying address is included in the access list

This is acceptable because:

- The first deployment cannot be known at transaction construction time
- Deduplication requires explicit opt-in via access list
- This scenario is extremely rare in practice
- The complexity of special handling is not worth the minimal benefit

## Rationale

### Why Access-List Based Deduplication?

The access-list approach provides several critical properties:

1. Deterministic behavior: 
The result depends only on the transaction's access list and current state, not on local database contents. All nodes compute the same gas cost.

2. No reverse index requirement: 
Unlike other approaches, this doesn't require maintaining a `codeHash → [accounts]` reverse index, which would add significant complexity and storage overhead.

3. Leverages existing infrastructure: 
Builds on EIP-2930 access lists and EIP-2929 access costs, requiring minimal protocol changes.

4. Implicit optimization:
Any address included in the access list automatically contributes to deduplication. This provides automatic gas optimization without requiring explicit flags or special handling.

5. Avoids chain split risks:
Since no new transaction structure is introduced, there's no risk of nodes rejecting transactions with unknown fields. The same transaction format works before and after the fork, with only the gas accounting rules changing at fork activation.

6. Forward compatibility:
All nodes enforce identical behavior. Wallets can add addresses to access lists to optimize gas, but this doesn't change transaction validity.

7. Avoid having a code-root for state:
At this point, clients handle code storage on their own ways. They don't have any consensus on the deployed existing codes (besides that all of the ones referenced in account's codehash fields exist).
Changing this seems a lot more complex and unnecessary.

## Backwards Compatibility

This proposal requires a scheduled network upgrade but is designed to be forward-compatible with existing transactions.

**Transaction compatibility:**
- No changes to transaction structure - uses existing EIP-2930 access lists
- Existing transactions with access lists automatically benefit from deduplication post-fork
- Transactions without access lists behave identically to current behavior (no deduplication discount)

**Wallet and tooling updates:**
- RPC methods like `eth_estimateGas` SHOULD account for potential deduplication discounts when access lists are present
- Wallets MAY provide UI for users to add addresses to access lists for deduplication
- Transaction builders MAY automatically detect duplicate deployments and include relevant addresses in access lists

**Node implementation:**
- No changes to state trie structure or database schema required
- No changes to transaction parsing or RLP encoding

## Reference Implementation

### Example Transaction

Deploying a contract with the same bytecode as the contract at `0x1234...5678`:

```json
{
  "from": "0xabcd...ef00",
  "to": null,
  "data": "0x608060405234801561001...",
  "accessList": [
    {
      "address": "0x1234567890123456789012345678901234567890",
      "storageKeys": []
    }
  ]
}
```

If the deployed bytecode hash matches `codeHash(0x1234...5678)` (which is automatically checked because the address is in the access list), the deployment receives the deduplication discount.

## Security Considerations

### Gas Cost Accuracy

The deduplication mechanism ensures that gas costs accurately reflect actual resource consumption. Duplicate deployments don't consume additional storage, so they shouldn't pay storage costs.

### Denial of Service

The access-list mechanism prevents DoS attacks because:
- The cost of reading `codeHash` is already covered by EIP-2929/2930
- No additional state lookups or database queries are required
- The deduplication check is O(1) (set membership test)

### Access List Size

Large access lists with many `checkCodeHash: true` entries could increase transaction size, but:
- Access lists are already part of transaction calldata and priced accordingly
- The `checkCodeHash` field adds minimal bytes
- Users have economic incentive to only include necessary entries

### State Divergence

The explicit access-list approach prevents state divergence issues that would arise from implicit database lookups. All nodes compute identical gas costs regardless of their sync mode or database contents.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
