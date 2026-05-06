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
requires: 161, 684, 7523, 7610, 7928
---

## Abstract

This EIP defines an irregular state transition that, at the start of a designated fork block, removes from the state a fixed list of accounts that have empty code, zero nonce, and non-empty storage. Such accounts can only have been created prior to [EIP-161](./eip-161.md) (activated in the Spurious Dragon hard fork, see [EIP-607](./eip-607.md)), and the list of all such accounts on Ethereum Mainnet is enumerable. Removing them from state is offered as an alternative to [EIP-7610](./eip-7610.md), which instead requires every contract creation to check that the destination address has empty storage.

## Motivation

[EIP-684](./eip-684.md) requires that, at contract creation, the destination address has zero nonce and zero code length. As [EIP-7610](./eip-7610.md) notes, this is not sufficient: prior to [EIP-161](./eip-161.md), a `CREATE` (0xf0), did not increment the nonce before running the initcode. A constructor could deposit no code, where the initcode would write to storage: the result is an account with zero nonce, but with non-empty storage. A small set of such accounts exists on Ethereum Mainnet today. No new ones could be produced after Spurious Dragon, as EIP-161 bumps the nonce of the intended contract address by one before executing the initcode. Also note that accounts delegated to by [EIP-7702](./eip-7702.md) experience a nonce bump, so also externally owned accounts (EOAs) cannot have zero nonce and non-empty storage.

EIP-7610 addresses this by adding a runtime check that every contract creation must observe empty storage at the destination address. This would thus require an extra check prior to any contract creation operation which verifies if the target account has empty storage. Depending on the database layout, this would require one or more disk reads. Because the check applies retroactively to every block, it is paid even though the targeted condition cannot occur for any address created after Spurious Dragon.

Some clients have decided not to implement EIP-7610, which is currently part of the canonical tests, which means these client fail the canonical tests. The reasoning is that a collission with these accounts cannot feasibly happen in practice: one would have to create a hash collission targeting a specific set of target hashes.

This EIP simplifies the protocol: rather than amending the rules of contract creation, it removes the offending accounts from state once, by way of an irregular state transition. After the fork block, the condition that EIP-7610 guards against can no longer occur for any address in the targeted list, and clients implementing only the post-fork rules need not perform the additional check.

The motivation is analogous to that of [EIP-7523](./eip-7523.md), which deprecates empty accounts. Empty accounts were a historical artifact whose lingering possibility imposed long-term technical debt — edge cases in the "touch" rules of EIP-161 that had to be reasoned about, implemented, and tested even though no such account remained on Mainnet. By cleanly removing the storage of the accounts targeted by this EIP from state, we likewise remove their handling from re-execution logic and from the surface area that future EIPs and their tests must consider.

This EIP requires [EIP-7523](./eip-7523.md). Under [EIP-161](./eip-161.md), an account is *empty* iff it has no code, zero nonce, and zero balance — storage is not part of the emptiness predicate. The Mainnet state-clearing transaction described in EIP-7523 swept every account satisfying that predicate. Therefore, every Mainnet account that today has empty code, zero nonce, and non-empty storage necessarily has a *non-zero balance*; otherwise it would have been removed by the state-clearing process. Because of this guarantee, the specification below does not need a balance check or a conditional account-deletion path.

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
3. `A` remains in the trie with its existing balance, zero nonce, empty code, and an empty storage root.

By [EIP-7523](./eip-7523.md), every targeted account on Mainnet has a non-zero balance, so step 3 is unconditional: no account is ever removed from the trie by this EIP. Implementations MUST NOT add a balance check or a conditional deletion path. If the procedure in [Reference Implementation](#reference-implementation) ever produces an account with zero balance, the list is invalid and the EIP cannot be applied as-is.

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

When this `BlockAccessList` is applied to the pre-fork-block state root, the only effect for each targeted account is that its storage trie becomes empty; the account itself remains in the state trie because its balance is non-zero (guaranteed by [EIP-7523](./eip-7523.md)). The post-state root produced by re-applying the BAL therefore matches the post-state root produced by the irregular state transition described above.

## Rationale

### Irregular state transition vs. runtime check

The principal alternative is [EIP-7610](./eip-7610.md), which leaves the offending state in place and adds a check at every contract creation. The chief drawbacks of that approach are:

- A per-creation cost (potentially a disk read) on every block, forever, that exists solely to guard against an address set that cannot grow.
- Permanent retention of edge-case logic that re-execution clients, test frameworks, and EIP authors must reason about.

By removing the accounts once, this EIP eliminates both costs. The trade-off is a one-time irregular state transition, which is consensus-sensitive and requires a hard-coded list — a pattern Ethereum has used before (e.g. the DAO fork) but uses sparingly.

### Why only clear storage, and why no balance check

Outright deletion of a targeted account would burn its ether and is out of scope for this proposal: this EIP is, with respect to ether supply, a no-op. Because [EIP-7523](./eip-7523.md) guarantees that every Mainnet account meeting the targeted-account predicate has a non-zero balance, the spec does not need to handle a "balance is zero, remove account" branch — that path is unreachable. Keeping the spec to a pure storage clear avoids re-introducing EIP-161 "touch" semantics into a place that does not otherwise need them.

### Why include both preimages and hashed keys

Clients differ in how they index the state trie. Including both forms in the published list removes any need for a client to compute additional hashes from a partial input, and makes independent verification of the list straightforward.

### BAL encoding choice

The natural representation in [EIP-7928](./eip-7928.md) is a series of `SlotChanges` writing zero at `block_access_index = 0`, because that is exactly what changes in the trie. No other field changes for any targeted account, so no `BalanceChange`, `NonceChange`, or `CodeChange` is emitted.

## Backwards Compatibility

This is a consensus change and requires a hard fork.

The targeted accounts have empty code and zero nonce. They are not callable as contracts (an empty-code call returns success with no effect) and cannot have signed transactions or set authorizations, since their nonce is zero and there is no associated key. Their only externally-observable property beyond balance is their storage, which is not reachable from the EVM except via a re-deployment to the same address — exactly the case that [EIP-7610](./eip-7610.md) addresses and that this EIP makes a non-issue by removing the storage outright while keeping the balance intact.

Any address in the list that is the target of a future contract creation will, after this fork, have zero nonce, empty code, and empty storage; the creation will succeed under the existing [EIP-684](./eip-684.md) rules without need for the additional check from EIP-7610. The pre-existing balance is preserved in the newly created contract, which is the same behaviour as a `CREATE` to any address with a prior balance and no code/nonce/storage.

If a client also implements EIP-7610, the runtime check becomes a no-op for these addresses after the fork, and the two EIPs are compatible. This EIP is, however, intended as a replacement for EIP-7610 rather than a supplement to it.

## Test Cases

Test cases SHOULD cover at least the following scenarios. They are independent of any specific Mainnet address; tests can construct synthetic targeted accounts via genesis state. Per the Specification, all targeted accounts have a non-zero balance, so all tests below assume a non-zero balance for `A`.

1. **Storage clear with preserved balance, nonce, and code.** A genesis state contains an account `A` with empty code, zero nonce, non-zero balance `b`, and one or more non-zero storage slots. After applying the fork block (with no transactions), `A` MUST be present in the post-state with balance `b`, zero nonce, empty code, and a storage root equal to the empty storage root.

2. **Successful CREATE to a cleared address.** Following test case 1, a `CREATE` (or `CREATE2`) targeting `A` MUST succeed under [EIP-684](./eip-684.md) rules, deploying code at `A` and preserving its balance `b`. Under EIP-7610 alone (without this EIP), the same operation would revert because `A`'s storage was non-empty.

3. **CALL semantics unchanged.** Following test case 1, a `CALL` to `A` (with or without value transfer) behaves the same as before: because `A` exists in the trie with non-zero balance, no new-account gas is charged. The call returns success with no observable effect (empty code, no logs, no storage reads return non-zero).

4. **Multiple accounts in the list.** A genesis state contains several targeted accounts, each with a different non-zero balance and a different set of non-zero storage slots. After the fork block, every listed account MUST have its storage cleared, with all other fields (including balance) untouched.

5. **No effect on non-targeted accounts.** A non-targeted account that happens to have empty code and zero nonce but only zero-valued storage (i.e. does not appear in the list) is unaffected by this EIP. An account with code or non-zero nonce is also unaffected, even if it has storage.

6. **Ordering relative to pre-execution system contracts.** The irregular state transition MUST occur before any pre-execution system contract call (e.g. [EIP-4788](./eip-4788.md), [EIP-2935](./eip-2935.md)) for the fork block. A test in which a pre-execution system contract reads from a slot of `A` MUST observe the cleared (zero) value.

For chains that activate [EIP-7928](./eip-7928.md):

7. **BAL encoding correctness.** The fork block's `BlockAccessList` MUST contain, for each targeted account, an `AccountChanges` entry with `address = A`, one `SlotChanges` entry per cleared slot with a single `StorageChange` `[0, 0]`, and empty `storage_reads`, `balance_changes`, `nonce_changes`, and `code_changes`. Reapplying the BAL to the pre-fork-block state root MUST reproduce the post-fork-block state root.

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
        # By EIP-7523, balance(addr) != 0, so the account stays in the trie.
        # balance, nonce, and codeHash are intentionally not modified.
```

This is invoked at the start of the fork block, before any pre-execution system contract calls.

## Security Considerations

This EIP performs a one-time, hard-coded mutation of state. The principal risks are:

- **List completeness and correctness.** A list that omits an eligible account leaves the corresponding edge case in state and partially defeats the EIP's purpose; a list that includes an account not actually meeting the criteria would be a consensus-relevant alteration of state. Both risks are mitigated by the requirement that the list be reproducible from the canonical chain via the procedure in [Reference Implementation](#reference-implementation), and by encouraging multi-client and external verification before the fork is scheduled.
- **Reliance on EIP-7523.** This EIP assumes, on the strength of [EIP-7523](./eip-7523.md), that no targeted account on Mainnet has zero balance. If an account ever appeared with empty code, zero nonce, non-empty storage, and zero balance, the specification here would leave behind an account in the trie that satisfies EIP-161's emptiness predicate but is not deleted. The pre-fork list-construction procedure MUST therefore be checked against this invariant, and any zero-balance targeted account discovered MUST be raised before the fork rather than handled implicitly.
- **No supply change.** Because balances are preserved, the total ether supply is not affected. Storage being cleared does not in itself cause any value transfer.
- **Compatibility with EIP-7610.** If both this EIP and EIP-7610 are active, the runtime check from EIP-7610 is redundant for the targeted addresses and never triggers; there is no consensus conflict, but implementers are encouraged to choose one mechanism.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
