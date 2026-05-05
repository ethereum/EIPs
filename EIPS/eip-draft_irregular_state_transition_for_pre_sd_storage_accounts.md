---
eip: XXXX
title: Irregular state transition for non-empty storage zero-nonce accounts
description: Remove pre-Spurious-Dragon contracts with empty code, zero nonce, and non-empty storage via an irregular state transition
author: Jochem Brouwer (@jochem-brouwer)
discussions-to: https://ethereum-magicians.org/t/TBD
status: Draft
type: Standards Track
category: Core
created: 2026-05-05
requires: 161, 684, 7610, 7928
---

## Abstract

This EIP defines an irregular state transition that, at the start of a designated fork block, removes from the state a fixed list of accounts that have empty code, zero nonce, and non-empty storage. Such accounts can only have been created prior to [EIP-161](./eip-161.md) (activated in the Spurious Dragon hard fork, see [EIP-607](./eip-607.md)), and the list of all such accounts on Ethereum Mainnet is enumerable. Removing them from state is offered as an alternative to [EIP-7610](./eip-7610.md), which instead requires every contract creation to check that the destination address has empty storage.

## Motivation

[EIP-684](./eip-684.md) requires that, at contract creation, the destination address has zero nonce and zero code length. As [EIP-7610](./eip-7610.md) notes, this is not sufficient: prior to [EIP-161](./eip-161.md), a `CREATE` (0xf0), did not increment the nonce before running the initcode. A constructor could deposit no code, where the initcode would write to storage: the result is an account with zero nonce, but with non-empty storage. A small set of such accounts exists on Ethereum Mainnet today. No new ones could be produced after Spurious Dragon, as EIP-161 bumps the nonce of the intended contract address by one before executing the initcode. Also note that accounts delegated to by [EIP-7702](./eip-7702.md) experience a nonce bump, so also externally owned accounts (EOAs) cannot have zero nonce and non-empty storage.

EIP-7610 addresses this by adding a runtime check that every contract creation must observe empty storage at the destination address. This would thus require an extra check prior to any contract creation operation which verifies if the target account has empty storage. Depending on the database layout, this would require one or more disk reads. Because the check applies retroactively to every block, it is paid even though the targeted condition cannot occur for any address created after Spurious Dragon.

Some clients have decided not to implement EIP-7610, which is currently part of the canonical tests, which means these client fail the canonical tests. The reasoning is that a collission with these accounts cannot feasibly happen in practice: one would have to create a hash collission targeting a specific set of target hashes.

This EIP simplifies the protocol: rather than amending the rules of contract creation, it removes the offending accounts from state once, by way of an irregular state transition. After the fork block, the condition that EIP-7610 guards against can no longer occur for any address in the targeted list, and clients implementing only the post-fork rules need not perform the additional check.

The motivation is analogous to that of [EIP-7523](./eip-7523.md), which deprecates empty accounts. Empty accounts were a historical artifact whose lingering possibility imposed long-term technical debt — edge cases in the "touch" rules of EIP-161 that had to be reasoned about, implemented, and tested even though no such account remained on Mainnet. By cleanly removing the accounts targeted by this EIP from state, we likewise remove their handling from re-execution logic and from the surface area that future EIPs and their tests must consider.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Targeted accounts

A *targeted account* is an account whose pre-fork state satisfies all of the following:

- it has empty code (i.e. `codeHash == keccak256("")`);
- it has zero nonce;
- it has non-empty storage (i.e. `storageRoot != keccak256(RLP.encode(""))`)

### Mainnet account list

The set of targeted accounts on Ethereum Mainnet is fixed and is to be enumerated by the time this EIP is scheduled. Each entry consists of:

- the account preimage (the 20-byte address); and
- for each non-zero storage slot of that account, the slot preimage (the 32-byte storage key) and its current value.

Both preimages are mandatory. Some clients key the trie by hashed address and hashed slot, while others retain the preimages directly; including both forms allows every client to apply this EIP without an out-of-band lookup.

```
TBD: full Mainnet list (accounts and their storage slots) to be inserted prior to fork scheduling.
```

The current count is expected to be in line with the figure cited in [EIP-7610](./eip-7610.md) (28 accounts).

### State transition

At the start of the fork block, before any pre-execution system contract calls and before any transactions are processed, for each account `A` in the Mainnet account list:

1. Every storage slot listed for `A` is set to zero (i.e. its entry is removed from `A`'s storage trie). After this step, `A`'s storage root MUST equal the empty storage root (`0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421`).
2. The fields `balance`, `nonce` and `codeHash` of `A` are not modified.
3. If, after step 1, `A` has zero balance (it already has zero nonce and empty code by definition of a targeted account), then `A` MUST be removed from the state trie. Conceptually, this is the same effect as a Spurious Dragon "touch" of an account that has become empty: when no field carries any information, the account does not remain in the trie as an empty entry.
4. Otherwise, `A` remains in the trie with its existing balance, zero nonce, empty code, and an empty storage root.

This transition is purely a state mutation; it does not produce a transaction, a receipt, or a log, and it does not consume gas. Its only observable consequences are the resulting state root and any later behavioural differences caused by the absence of the cleared storage.

The transition MUST be applied exactly once, at the very start of the fork block, prior to any other block-level processing (including pre-execution system contract calls such as those introduced by [EIP-2935](./eip-2935.md), [EIP-4788](./eip-4788.md), [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md)).

### Chain Specifics

This EIP is targeted at Ethereum Mainnet. Other chains MAY adopt this EIP. Chains forked from Mainnet or cloning state after the Spurious Dragon fork at block 2675000 will typically find that the Mainnet list is sufficient, given that the chain does not re-introduce the possibility to create the type of accounts this EIP removes from state. Chains not derived from Mainnet MAY define their own list using the procedure described in [Reference Implementation](#reference-implementation). In case Spurious Dragon was already active at genesis, and the chain did not re-introduce creating the type of accounts being removed here, the account state trie will not hold these type of accounts.

### Interaction with EIP-7928 (Block-Level Access Lists)

If [EIP-7928](./eip-7928.md) is active at the fork block, the irregular state transition above MUST be reflected in the `BlockAccessList` of the fork block. Because EIP-7928 reserves `block_access_index = 0` for pre-execution state changes, the changes from this EIP are encoded at index `0`, ordered before any pre-execution system contract calls.

For each targeted account `A` whose storage is being cleared, the BAL MUST contain an `AccountChanges` entry with:

- `address` set to `A`;
- `storage_changes` containing one `SlotChanges` entry per cleared slot, each with `[slot, [[0, 0]]]` — i.e. a single `StorageChange` at `block_access_index = 0` setting the new value to `0`;
- `storage_reads`, `balance_changes`, `nonce_changes`, and `code_changes` left empty (no other fields of `A` are modified by this EIP).

When this `BlockAccessList` is applied to the pre-fork-block state root, an account whose storage has been emptied by these `SlotChanges` and which has zero balance (and, by definition, zero nonce and empty code) MUST be removed from the trie, in the same manner as an EIP-161 "touch" deletion. This ensures that the post-state root produced by re-applying the BAL matches the post-state root produced by the irregular state transition.

Note that no explicit balance, nonce, or code change is encoded for these accounts, because none of those fields change. The trie removal is a consequence of the resulting empty state, not of an explicit field write.

## Rationale

### Irregular state transition vs. runtime check

The principal alternative is [EIP-7610](./eip-7610.md), which leaves the offending state in place and adds a check at every contract creation. The chief drawbacks of that approach are:

- A per-creation cost (potentially a disk read) on every block, forever, that exists solely to guard against an address set that cannot grow.
- Permanent retention of edge-case logic that re-execution clients, test frameworks, and EIP authors must reason about.

By removing the accounts once, this EIP eliminates both costs. The trade-off is a one-time irregular state transition, which is consensus-sensitive and requires a hard-coded list — a pattern Ethereum has used before (e.g. the DAO fork) but uses sparingly.

### Why preserve balance when non-zero

Targeted accounts that carry a non-zero balance are not deleted, only their storage is cleared. Outright deletion would burn ether and is out of scope for this proposal; balance is preserved so that this EIP is, with respect to ether supply, a no-op. In practice, the targeted accounts on Mainnet are not expected to hold meaningful balances, but the spec is written so that a non-zero balance is handled correctly without a special case.

### Why include both preimages and hashed keys

Clients differ in how they index the state trie. Including both forms in the published list removes any need for a client to compute additional hashes from a partial input, and makes independent verification of the list straightforward.

### BAL encoding choice

The cleanest representation in [EIP-7928](./eip-7928.md) is a series of `SlotChanges` writing zero, because that is what actually changes in the trie. Encoding the deletion of the account itself as an explicit "account change" would either require a new BAL field type or a sentinel value; instead, the account's removal from the trie falls out of EIP-161-style touch semantics applied at the end of the index-0 batch, which is consistent with how empty-account deletion is already handled.

## Backwards Compatibility

This is a consensus change and requires a hard fork.

The targeted accounts have empty code and zero nonce. They are not callable as contracts (an empty-code call returns success with no effect) and cannot have signed transactions or set authorizations, since their nonce is zero and there is no associated key. Their only observable property is their storage, which is not reachable from the EVM except via a re-deployment to the same address — exactly the case that [EIP-7610](./eip-7610.md) addresses and that this EIP makes impossible by removing the storage outright.

Any address in the list that is the target of a future contract creation will, after this fork, behave as a fresh address (zero nonce, empty code, empty storage) and the creation will succeed under the existing [EIP-684](./eip-684.md) rules without need for the additional check from EIP-7610.

If a client also implements EIP-7610, the runtime check becomes a no-op for these addresses after the fork, and the two EIPs are compatible. This EIP is, however, intended as a replacement for EIP-7610 rather than a supplement to it.

## Test Cases

Test cases SHOULD cover at least the following scenarios. They are independent of any specific Mainnet address; tests can construct synthetic targeted accounts via genesis state.

1. **Pre-fork-block state.** A genesis state contains an account `A` with empty code, zero nonce, zero balance, and a single non-zero storage slot `s -> v`. After applying the fork block (with no transactions), `A` MUST NOT be present in the post-state trie. The post-state root MUST match the root computed by deleting `A` outright.

2. **Storage clear with surviving balance.** A genesis state contains an account `A` with empty code, zero nonce, non-zero balance `b`, and a non-zero storage slot. After the fork block, `A` MUST be present with balance `b`, zero nonce, empty code, and empty storage (storage root equal to the empty storage root).

3. **Re-creation pays the new-account gas.** Following test case 1, the first transaction in or after the fork block that sends ether to `A` MUST be charged the standard new-account cost (per [EIP-161](./eip-161.md) / `G_newaccount`), since `A` is no longer present in the trie. Prior to the fork (or under EIP-7610 alone), this cost is not paid because the account is already present in the trie.

4. **Successful CREATE to a cleared address.** Following test case 1, a `CREATE` (or `CREATE2`) targeting `A` MUST succeed under [EIP-684](./eip-684.md) rules, deploying code at `A` as if it were a fresh address. Under EIP-7610 alone (without this EIP), the same operation would revert.

5. **Multiple accounts in the list.** A genesis state contains several targeted accounts, some of which retain a non-zero balance and some of which do not. After the fork block, the appropriate subset is removed from the trie and the remainder is preserved with empty storage.

6. **No effect on non-targeted accounts.** A non-targeted account that happens to have empty code and zero nonce but only zero-valued storage (i.e. does not appear in the list) is unaffected by this EIP, even if it would superficially "look like" a targeted account from an external view that does not enumerate slots.

For chains that activate [EIP-7928](./eip-7928.md):

7. **BAL encoding correctness.** The fork block's `BlockAccessList` MUST contain, for each targeted account, an `AccountChanges` entry whose `storage_changes` list each appears at `block_access_index = 0` with new value `0`, and which contains no other field changes. Reapplying the BAL to the pre-fork-block state root MUST reproduce the post-fork-block state root, including the trie removal of those accounts whose storage was emptied and whose balance is zero.

## Reference Implementation

### Constructing the list

The list of Mainnet accounts MUST be reproducible from the canonical chain, so that anyone can verify it independently. A practical procedure is:

1. Iterate every account in the post-Spurious-Dragon Mainnet state trie.
2. For each account, check whether `codeHash == keccak256("")` and `nonce == 0`.
3. For each account that satisfies (2), check whether its storage trie root differs from the empty storage root.
4. The set of accounts satisfying (1)–(3) is the targeted set. For each such account, enumerate its non-zero storage slots and record both the address preimage and the slot preimages.

Because this procedure depends only on the canonical state and pure functions of it, the list is uniquely determined and any client (or external reviewer) can produce it from a synced node. The list included in this EIP MUST be byte-equal to the output of this procedure run against Mainnet at the fork block height.

### Pseudocode

```python
def apply_irregular_state_transition(state, account_list):
    for entry in account_list:
        addr = entry.address
        for slot in entry.slots:
            state.set_storage(addr, slot, 0)
        # All listed slots are now zero, so storage_root(addr) == EMPTY_STORAGE_ROOT.
        if state.get_balance(addr) == 0:
            # nonce is 0 and code is empty by precondition; account is now empty.
            state.delete_account(addr)
```

This is invoked at the start of the fork block, before any pre-execution system contract calls.

## Security Considerations

This EIP performs a one-time, hard-coded mutation of state. The principal risks are:

- **List completeness and correctness.** A list that omits an eligible account leaves the corresponding edge case in state and partially defeats the EIP's purpose; a list that includes an account not actually meeting the criteria would be a consensus-relevant alteration of state. Both risks are mitigated by the requirement that the list be reproducible from the canonical chain via the procedure in [Reference Implementation](#reference-implementation), and by encouraging multi-client and external verification before the fork is scheduled.
- **No supply change.** Because balances are preserved, the total ether supply is not affected. Storage being cleared does not in itself cause any value transfer.
- **Consistency with EIP-161 semantics.** The trie-removal step for accounts whose storage becomes empty (and whose balance is zero) follows the same logic as EIP-161 "touch" deletions, so it does not introduce a new class of state mutation.
- **Compatibility with EIP-7610.** If both this EIP and EIP-7610 are active, the runtime check from EIP-7610 is redundant for the targeted addresses and never triggers; there is no consensus conflict, but implementers are encouraged to choose one mechanism.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
