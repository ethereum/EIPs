---
title: Code Reads in Block-Level Access Lists
description: Record in the block access list the code hash of every pre-block bytecode that a block loads
author: Lukasz Rozmej (@LukaszRozmej)
discussions-to: https://ethereum-magicians.org/t/eip-draft-code-reads-in-block-level-access-lists
status: Draft
type: Standards Track
category: Core
created: 2026-11-12
requires: 2929, 7702, 7928
---

## Abstract

This EIP adds a `code_hash` field to the `AccountChanges` entry of the [EIP-7928](./eip-7928.md) block access list (BAL). For every account whose pre-block bytecode is executed, copied or inspected during the block, the field holds the Keccak-256 hash of that bytecode. For every other account the field is empty. The BAL then names every piece of pre-block state that a block reads. When [EIP-7709](./eip-7709.md) is also active, a stateless or proving input for the block can be assembled from the block, its BAL and a state snapshot, without executing the block.

## Motivation

[EIP-7928](./eip-7928.md) records every account and storage slot a block touches. A stateless verifier or a zkVM prover can use the BAL as the index of the pre-state it has to load: the account leaves of every listed address and the storage leaves of every listed key. Bytecode is the one exception. The BAL records bytecode only when it changes, in `code_changes`. An address that is only called, or whose code is only copied or sized, appears with empty change lists, indistinguishable from an address whose balance was read. Which bytecode a block needs can today only be learned by executing the block, or by over-approximating and shipping the code of every listed address.

A witness is therefore still gathered the way it was before BALs existed: execute the block, record what it reads, then prove. This EIP removes the last state read that the BAL does not name. [EIP-7709](./eip-7709.md) removes the only non-state read, by serving `BLOCKHASH` from the storage of the [EIP-2935](./eip-2935.md) history contract so that it appears in `storage_reads`. With both, the block, its BAL and a state snapshot are a complete proving input. A prover assembles the witness by lookup alone, with no execution ahead of proving, and can start collecting it as soon as the BAL arrives, which under [EIP-8146](./eip-8146.md) is before the transactions.

Clients already diverge on this point. A witness generator that answers `EXTCODESIZE` from the code hash never loads the bytes and omits the code from its witness, while a guest built on the reference implementation reads the code and fails without it. A normative definition of "code read" in the BAL removes that class of interoperability bug and gives witness formats such as [EIP-8025](./eip-8025.md) a complete and checkable definition of their code list.

Recording the code hash lets consumers without state, such as witness services or peers exchanging BALs, resolve the bytecode from a hash-keyed code store, deduplicates shared code across accounts, and matches the hash form that [EIP-8298](./eip-8298.md) uses for adopted code.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Definitions

- **Pre-block code** of an account is its bytecode at the start of block execution, before the pre-execution system contract calls at `block_access_index = 0`. For an [EIP-7702](./eip-7702.md) delegated account it is the delegation indicator, not the delegate's code.
- **First code change** of an account is the first point in the block's execution order at which the account's code changes, by contract creation, by an EIP-7702 delegation set, update or clear, or by any other instruction that changes code. Execution order is the order in which the state transition function performs the changes, which is finer than `block_access_index`.

### Data Structure

`AccountChanges` gains a seventh element, `code_hash`:

```python
CodeHash = bytes32  # Keccak-256 hash of bytecode

# AccountChanges: [address, storage_changes, storage_reads, balance_changes, nonce_changes, code_changes, code_hash]
AccountChanges = [
    Address,                    # address
    List[SlotChanges],          # storage_changes
    List[StorageKey],           # storage_reads
    List[BalanceChange],        # balance_changes
    List[NonceChange],          # nonce_changes
    List[CodeChange],           # code_changes
    CodeHash | bytes0           # code_hash (hash of the pre-block code if it was loaded, else empty)
]
```

`code_hash` MUST be RLP-encoded as a 32-byte string when set and as the empty byte string (`0x80`) when not set. All other encoding rules of [EIP-7928](./eip-7928.md) are unchanged.

### Code Loads

A **code load** of address `A` is any of the following events, and only these:

1. A message frame executes with `A` as its code address. This covers the recipient of a transaction with a non-empty `to`, the code address of `CALL`, `CALLCODE`, `DELEGATECALL` and `STATICCALL` after [EIP-7702](./eip-7702.md) delegation resolution, and the targets of pre- and post-execution system contract calls. The frame counts even if it reverts, halts exceptionally, or is not started because the call fails its sender-balance or call-stack-depth check.
2. `EXTCODESIZE` or `EXTCODECOPY` executes with `A` as its target.
3. An [EIP-7702](./eip-7702.md) authorization names `A` as its authority and the authority account is loaded, whether or not the authorization then succeeds.
4. A `CALL`, `CALLCODE`, `DELEGATECALL` or `STATICCALL` targets a delegated account `A`. `A` is loaded under rule 1 to resolve the delegation. The delegate is loaded under rule 1 when [EIP-7928](./eip-7928.md) includes it.
5. Transaction validation checks the code of sender `A` under the [EIP-7702](./eip-7702.md) transaction-origination rule. This loads only the sender's own code, not its delegate's code.
6. When [EIP-8298](./eip-8298.md) is active, `SETCODEFROM` targets source `A` and passes its `SETCODEFROM_SOURCE_GAS` check. This loads only the source's own code, without resolving delegation, whether or not the source is valid, the instruction subsequently runs out of gas, or the enclosing execution reverts.

An event is a code load only when [EIP-7928](./eip-7928.md) records the corresponding address access. In particular an operation that fails its pre-state gas validation of [EIP-7928](./eip-7928.md) loads no code, and `code_hash` can never be set on an address that is absent from the BAL.

The following are not code loads: `BALANCE`, `EXTCODEHASH`, the collision check of `CREATE` and `CREATE2`, `SELFDESTRUCT` beneficiaries, withdrawal recipients, and the fee recipient.

### Recording Rule

For every `AccountChanges` entry of address `A`:

- `code_hash` MUST be `keccak256(pre_block_code(A))` if the pre-block code of `A` is non-empty and at least one code load of `A` occurs before the first code change of `A` in the block.
- Otherwise `code_hash` MUST be empty.

Code introduced during the block is reconstructed during execution from contract creation, authorization processing, or code-adoption sources. Only surviving post-transaction code changes appear in `code_changes`; intermediate or reverted code need not appear there.

### Validation

The [EIP-7928](./eip-7928.md) rule that the BAL MUST be complete and accurate extends to `code_hash`. A BAL whose `code_hash` values differ from those produced by execution invalidates the block.

The reference pseudocode of [EIP-7928](./eip-7928.md) changes as follows. New account entries initialize `code_changed` to `False` and `code_hash` to `b""`. `EMPTY_CODE_HASH` is the Keccak-256 hash of the empty byte string. `get_pre_block_code_hash` reads the code hash from the pre-block account leaf and returns `EMPTY_CODE_HASH` for an absent account; it does not load bytecode.

```python
def track_code_load(addr, accesses):
    """Called for every code load of addr, in execution order"""
    entry = accesses.setdefault(addr, new_account_entry())
    if entry['code_changed'] or entry['code_hash'] != b"":
        return
    code_hash = get_pre_block_code_hash(addr)
    if code_hash != EMPTY_CODE_HASH:
        entry['code_hash'] = code_hash

def track_code_change(addr, accesses):
    """Called when the code of addr changes, before the change is recorded"""
    accesses.setdefault(addr, new_account_entry())['code_changed'] = True
```

`build_bal` appends `data['code_hash']` as the seventh element of each account entry.

### Chain Specifics

On a chain that activates this EIP at genesis, the pre-block code of every account in the first block is its genesis code.

## Rationale

### Hash rather than bytecode

Recording the full bytecode would make the BAL self-contained but would add the code of every executed contract to a consensus object that is gossiped with every block. A mainnet block loads a few hundred distinct contracts, so this adds on the order of megabytes per block, against a BAL of roughly 72 KiB at a 60M gas limit per the size analysis of [EIP-7928](./eip-7928.md).

Each populated `code_hash` costs 33 bytes, roughly 13 KiB for 400 populated fields, plus one byte for every empty field and any growth in enclosing RLP length prefixes. It lets a consumer without state resolve the bytecode from a hash-keyed store, deduplicates code shared by many accounts, lets a verifier check witness completeness against the BAL alone, and uses the same form as the `new_code_hash` element that [EIP-8298](./eip-8298.md) adds to `CodeChange`.

### Pre-block code only

The field identifies pre-block bytecode needed during execution. Code introduced during the block can be reconstructed as execution proceeds, even when it is later overwritten or reverted and therefore absent from `code_changes`. A load after the account's first code change does not add a hash to this field. Code that is loaded only while empty needs no bytes: the account leaf, or its absence, already proves that the code is empty. Both conditions depend only on the account's state and on instruction semantics, never on whether a client chose to read the bytes or to answer from the code hash, so independent implementations produce the same value.

### `EXTCODEHASH` is not a code load

`EXTCODEHASH` is answered by the account leaf. `EXTCODESIZE` is a code load because the account leaf does not carry the code size.

### Block-level, not per block access index

[EIP-7928](./eip-7928.md) records storage reads without a block access index, and a stateless input is assembled per block, so one value per account suffices. A per-index list would only serve transaction-level proof sharding and would cost a few bytes per transaction that loads the account.

### Interaction with EIP-8298

`SETCODEFROM` in [EIP-8298](./eip-8298.md) inspects the source's own code to determine whether it is valid regular deployed code before copying its code hash. The source bytes are therefore needed even when validation rejects a delegation indicator or a later gas charge fails. Rule 6 records this access once the source-access gas check passes, independently of success or reversion. It also makes pre-block source code available to an adopter called later in the block, whose `code_changes` entry contains only the adopted hash.

### Witness construction

A witness builder with access to the pre-state includes, for every account entry with a non-empty `code_hash`, the bytecode with that hash, deduplicated by hash. A verifier binds each bytecode to the account leaf by hashing it on first use. Together with the storage reads that [EIP-7709](./eip-7709.md) records for `BLOCKHASH`, this makes the BAL a complete index of the pre-state a block reads. Without EIP-7709, a proving input still needs the historical block data required to resolve `BLOCKHASH`; EIP-2935 alone does not change the opcode's access recording.

## Backwards Compatibility

This EIP requires a hard fork. It changes the RLP encoding of `AccountChanges` and therefore the value of `block_access_list_hash`. A client implementing only [EIP-7928](./eip-7928.md) rejects blocks produced under this EIP, and vice versa.

No gas cost changes. Contracts are unaffected.

## Test Cases

For each case, `pre` describes the pre-block state and `expect` the `code_hash` value of the named account.

1. `CALL` to contract `C` from a frame that later reverts. `pre`: `C` has code. `expect`: `C.code_hash = keccak256(C.code)`.
2. `CALL` to contract `C` with too little gas for the cold access cost. `expect`: `C` is absent from the BAL.
3. `EXTCODEHASH` of contract `C`, no other access. `expect`: `C.code_hash` empty, `C` present with empty change lists.
4. `EXTCODESIZE` of an EOA `E` with no code. `expect`: `E.code_hash` empty.
5. `EXTCODESIZE` of contract `C`. `expect`: `C.code_hash = keccak256(C.code)`.
6. `CALL` to a delegated EOA `E` with delegate `D`. `expect`: `E.code_hash = keccak256(0xef0100 || D)` and `D.code_hash = keccak256(D.code)`.
7. `CALL` to a delegated EOA `E` at call-stack depth 1024. `expect`: as case 6, since the delegation is resolved before the depth check.
8. Transaction with an authorization whose authority `E` already holds a delegation indicator, then a `CALL` to `E` in the same transaction. `expect`: `E.code_hash = keccak256(old indicator)` by rule 3; the new indicator appears in `E.code_changes`.
9. Authorization whose authority `E` has empty code, followed by a `CALL` to `E`. `expect`: `E.code_hash` empty; the indicator appears in `E.code_changes`.
10. Contract `N` created at index 2 and called at index 5. `expect`: `N.code_hash` empty; `N.code_changes` holds the deployed code.
11. Contract `N` created and called in the same transaction. `expect`: as case 10.
12. Contract `C` with code, whose code changes at index 3 and which is called only at index 5. `expect`: `C.code_hash` empty.
13. Block with transactions. `expect`: the [EIP-2935](./eip-2935.md), [EIP-4788](./eip-4788.md), [EIP-7002](./eip-7002.md) and [EIP-7251](./eip-7251.md) system contracts have `code_hash = keccak256(code)` at the entries created for index `0` and `len(transactions) + 1`.
14. `CALL` to a precompile. `expect`: `code_hash` empty.
15. Value transfer from an EOA with no code to another EOA with no code. `expect`: `code_hash` empty for sender and recipient.
16. Ordinary transaction from a delegated sender `E` to an EOA with no code, with no authorizations or other accesses to `E` or its delegate `D`. `pre`: `E.code = 0xef0100 || D`. `expect`: `E.code_hash = keccak256(E.code)`; `D` is absent from the BAL.
17. A parent frame creates contract `N`, calls its deployed code, then reverts. `pre`: `N` does not exist. `expect`: `N` remains in the BAL with an empty `code_hash` and no `code_changes` entry. The executed runtime code is reconstructed by executing the initcode, despite the deployment being reverted.

The following cases additionally activate EIP-8298. The source has no other accesses or code changes in the block:

18. `SETCODEFROM(S)` with sufficient gas, followed by a call to the adopter. `pre`: `S` has regular deployed code. `expect`: `S.code_hash = keccak256(S.code)`; the adopter's `code_changes` entry records the adopted hash.
19. `SETCODEFROM(E)` rejects a delegated source. `pre`: `E.code = 0xef0100 || D`. `expect`: `E.code_hash = keccak256(E.code)`; `D` is absent from the BAL unless independently accessed.
20. `SETCODEFROM(S)` passes the source-access gas check but fails a subsequent gas charge. `pre`: `S` has regular deployed code. `expect`: `S.code_hash = keccak256(S.code)` despite the exceptional halt.
21. Successful `SETCODEFROM(S)` in a frame that later reverts. `pre`: `S` has regular deployed code. `expect`: `S.code_hash = keccak256(S.code)`; the reverted adoption contributes no `code_changes` entry.
22. `SETCODEFROM(S)` fails its source-access gas check. `expect`: `S` is absent from the BAL.
23. `SETCODEFROM(E)` with an empty-code source. `expect`: `E` is included with an empty `code_hash`.

## Reference Implementation

See the pseudocode under [Validation](#validation). A client that already tracks state accesses for [EIP-7928](./eip-7928.md) records one additional value per account entry, set at the first code load of an account that has not yet changed code.

## Security Considerations

### Size

For `A` account entries and `R` populated `code_hash` fields, the fields add `A + 32 * R` bytes before growth in enclosing RLP length prefixes: one byte per empty field and 33 bytes per populated field. This includes accounts accessed by system calls and other accesses that do not pay a cold-account access cost. The overhead is bounded by the [EIP-7928](./eip-7928.md) size constraint on the number of account entries.

### Validation overhead

Recording the field requires checking whether code has changed or a hash has already been recorded, then reading the existing account code hash when needed. Clients keep code hashes with the account, so deriving the field requires no additional bytecode load or hashing. The hash of a bytecode deployed in the block is never recorded.

### Completeness

As with every other BAL field, a wrong `code_hash` makes the block invalid. The field is derived from execution, so a block producer cannot use it to force a verifier to load bytecode that the block does not read.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
