---
eip: XXXX
title: Clear storage from zero-nonce empty-code accounts
description: Clear pre-Spurious-Dragon-created storage from accounts with empty code, zero nonce, and non-empty storage via an irregular state transition
author: Jochem Brouwer (@jochem-brouwer)
discussions-to: https://ethereum-magicians.org/t/TBD
status: Draft
type: Standards Track
category: Core
created: 2026-05-05
requires: 161, 684, 7523, 7610, 7928
---

## Abstract

At the start of the designated fork block, clear the storage of a fixed list of accounts that have empty code, zero nonce, and non-empty storage. This is offered as an alternative to [EIP-7610](./eip-7610.md), which adds a runtime check on every contract creation to check for collisions.

## Motivation

[EIP-684](./eip-684.md) requires zero nonce and zero code length at a `CREATE` destination. Pre-[EIP-161](./eip-161.md), `CREATE` did not increment the nonce before init code ran, so a constructor that wrote storage and returned no code left an account with zero nonce and non-empty storage. EIP-7610 fixes the resulting collision risk by additionally requiring empty storage at the destination. This however needs an extra check in runtime code, and for some clients/database layouts also another disk read, which is paid forever, guarding against a non-growing address set after Spurious Dragon.

This EIP removes the offending accounts from state once instead. After the fork, no address in the list can satisfy the EIP-7610 trigger, so the runtime check is unnecessary. The motivation parallels [EIP-7523](./eip-7523.md), which similarly cleaned up empty accounts to retire EIP-161's "touch" edge cases from re-execution and test logic. By removing these accounts, these types of accounts (a non-EOA, zero-nonce, non-empty storage) are also removed from the account types in existing in future state, removing the need for analysis for any edge cases or writing tests for these types of accounts.

EIP-7523 also lets us drop a balance-zero branch from the spec: under EIP-161, "empty" ignores storage, so the EIP-7523 sweep removed every account with empty code, zero nonce, and zero balance. Every Mainnet account today with empty code, zero nonce, and non-empty storage therefore has *non-zero balance*, and the spec below does not need to handle deletion.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Mainnet account list

The targeted Mainnet accounts are published as [`assets/eip-XXXX/targeted-accounts.json`](../assets/eip-XXXX/targeted-accounts.json) (28 entries). Each entry contains the 20-byte address, its `keccak256` hash of this address, and per non-zero-valued storage slot: the 32-byte slot key and its `keccak256` hash of this key.

The construction procedure and verification (storage-root reconstruction against `eth_getProof` on `latest`) are documented in [`assets/eip-XXXX/methodology.md`](../assets/eip-XXXX/methodology.md). The 224-entry pre-EIP-161-deletion superset at the Spurious Dragon block is published alongside, as [`assets/eip-XXXX/zero-nonce-matches.jsonl`](../assets/eip-XXXX/zero-nonce-matches.jsonl).

### State transition

At the start of the fork block, before any pre-execution system contract calls (e.g. those introduced by [EIP-2935](./eip-2935.md), [EIP-4788](./eip-4788.md), [EIP-7002](./eip-7002.md), [EIP-7251](./eip-7251.md)) and before any transactions, for each account `A` in the list:

1. Every storage slot listed for `A` is set to zero. After this step, `storageRoot(A)` MUST equal `0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421` (the empty storage root).
2. `balance`, `nonce`, and `codeHash` of `A` are not modified; `A` remains in the trie.

Implementations MUST NOT add a balance check or a conditional deletion path: by EIP-7523, every targeted account has non-zero balance, so the account never becomes empty.

The transition produces no transaction, receipt, or log, and consumes no gas.

### Application to non-Mainnet chains

Chains forked from Mainnet post–Spurious-Dragon can apply the same list. Other chains have to generate these specific lists for that chain in order to obtain addressess (and their hashes) and the associated preimages for storage keys and their hashes using a specific method to that chain, MUST list all these preimages and hashes for both the addressess of the relevant accounts and associated storage keys. Note that chains which do not have these type of accounts at genesis, and also have no way to create these accounts, will thus end up with an empty list and should thus ignore this EIP.

### Interaction with EIP-7928

If [EIP-7928](./eip-7928.md) is active at the fork block, the BAL MUST encode the changes at `block_access_index = 0`, ordered before any pre-execution system contract calls. For each targeted account `A`, the `AccountChanges` entry is:

- `address = A`;
- `storage_changes`: one `SlotChanges` per cleared slot, value `[slot, [[0, 0]]]`;
- `storage_reads`, `balance_changes`, `nonce_changes`, `code_changes`: empty.

Re-applying the BAL to the pre-fork-block state root MUST reproduce the post-fork-block state root.

## Rationale

**Irregular state transition vs. runtime check.** EIP-7610 leaves the offending state in place and pays a per-creation cost forever to guard a closed address set. This EIP pays a one-time consensus mutation instead, which is the same pattern Ethereum has used for prior cleanups (e.g. EIP-7523).

**Generally smaller test surface.** Accounts with zero-nonce, no code, but empty storage are a specific, special account type which would need analysis for edge case tests for some EIPs if these would target such accounts. This is now removed from state.

**No balance branch.** EIP-7523 makes the balance-zero case unreachable, so the spec stays a pure storage clear and avoids re-introducing EIP-161 "touch" semantics.

**BAL encoding.** Storage clears are exactly what changes in the trie; no other field of `A` changes, so no other change types are emitted. The EIP can thus be activated by the block builder emiting these extra storage clears at the start of the block (this leads to correct state root calculation using only the BAL without re-execution).

## Backwards Compatibility

This is a consensus change and requires a hard fork. Targeted accounts have empty code and zero nonce, so they are not callable as contracts and have no associated key. After the fork, a `CREATE`/`CREATE2` to such an address succeeds under [EIP-684](./eip-684.md) rules and the pre-existing balance is preserved in the new contract: the same behaviour as creating to any address that previously held only a balance.

## Test Cases

All targeted accounts have non-zero balance.

1. **Storage clear.** `A` has empty code, zero nonce, balance `b > 0`, and non-zero storage. After the fork block, `A` has balance `b`, zero nonce, empty code, and the empty storage root.
2. **CREATE succeeds.** A `CREATE`/`CREATE2` to `A` succeeds and preserves balance `b`. Without this EIP (under EIP-7610 alone), it would revert. This should be tested as first transaction in the fork block, which MUST succeed.
3. **CALL unchanged.** A `CALL` to `A` still does not charge new-account gas, since `A` remains in the trie.
4. **Non-targeted accounts unaffected.** Accounts with code or non-zero nonce, or accounts not in the list, are untouched.
5. **BAL correctness** (if [EIP-7928](./eip-7928.md) is active). For each targeted account, the BAL has one `SlotChanges` per cleared slot at index `0` with new value `0`, and all other change lists empty. Re-applying the BAL reproduces the post-state root.

## Reference Implementation

```python
def apply_irregular_state_transition(state, account_list):
    for entry in account_list:
        for slot in entry.slots:
            state.set_storage(entry.address, slot, 0)
        # storage_root(addr) == EMPTY_STORAGE_ROOT; balance/nonce/codeHash untouched.
        # By EIP-7523, balance != 0, so the account stays in the trie.
```

The list construction procedure (predicate, re-execution of pre-Spurious-Dragon blocks, the snapshot scan, `eth_getProof` verification) is described in [`assets/eip-XXXX/methodology.md`](../assets/eip-XXXX/methodology.md). The published list MUST be byte-equal to the output of that procedure run against Mainnet at the fork block height.

## Security Considerations

- **List correctness.** Both an omission and a spurious entry are consensus-relevant. The list is reproducible from canonical state via the procedure in [`methodology.md`](../assets/eip-XXXX/methodology.md); multi-client and external verification before scheduling the fork is required.
- **Reliance on EIP-7523.** The spec assumes no targeted account has zero balance. The list-construction procedure MUST be checked against this invariant; any zero-balance match discovered MUST be raised before the fork rather than handled implicitly.
- **No supply change.** Balances are preserved.
- **Genesis cannot contain these accounts.** This is not caught by re-execution. It would be caught by the snapshot scan though.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
