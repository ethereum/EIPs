---
eip: TBD
title: Keyed Nonces for Frame Transactions
description: Independent nonce domains for frame transactions, with APPROVE-atomic nonce consumption
author: Thomas Thiery (@soispoke) <thomas.thiery@ethereum.org>
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-04-16
requires: 8141
---

## Abstract

A frame transaction ([EIP-8141](./eip-8141.md)) currently uses one sender nonce, so all frame transactions from the same sender share one inclusion order: a delayed transaction blocks every later one from that sender.

This EIP replaces that single nonce with `(nonce_key, nonce_seq)`:

- `nonce_key` selects a nonce domain,
- `nonce_seq` is the sequence number within that domain.

The zero key selects the sender's legacy account nonce. Each non-zero key selects an independent protocol-managed keyed nonce domain. Transactions in different non-zero domains are replay-independent; transactions in the same domain remain linearly sequenced.

EIP-8141 consumes the sender nonce when payment is approved. This EIP preserves that approval-time consumption rule, but applies it to the transaction's selected nonce.

If `nonce_key == 0`, payment approval advances the sender's legacy account nonce. If `nonce_key != 0`, payment approval advances the keyed nonce for `(sender, nonce_key)`.

Because nonce consumption is part of EIP-8141's atomic payment-approval transition, it persists even if later frames revert. For single-use-key applications such as privacy nullifiers, this means that if validation requires the selected key to be unused, successful inclusion makes that key used.

This EIP is a replay-protection and concurrency primitive. It does not by itself provide confidentiality or change public-mempool policy.

## Motivation

Frame transactions make validation programmable, but their replay protection still uses a single linear sender nonce. That is too restrictive for several use cases, most notably shared-sender privacy withdrawals. Other applications include smart-wallet session keys and relayer designs where many independent actions intentionally share one sender account.

A privacy protocol may use a shared sender so that onchain activity is not tied to a unique public sender. With a single sequential nonce, that shared sender becomes a throughput bottleneck: one user's inclusion invalidates every other user's pending transaction even when the two spends are otherwise unrelated.

At the consensus layer, keyed nonces remove this bottleneck. Each spend can use its own nonce domain, for example one derived from its nullifier in a privacy protocol. They do not remove other shared-state dependencies such as sender balance, sender storage, paymaster state, or legacy-nonce advancement triggered by `CREATE`.

Importantly, this EIP does not itself change EIP-8141's public-mempool one-pending-frame-per-sender guidance, but it provides the protocol-level condition for relaxing rules of that kind: transactions on distinct non-zero keys are replay-independent and no longer alias on one sender-wide nonce.

Keyed nonces also solve an atomicity problem. In EIP-8141, `VERIFY` frames can check that a single-use key is valid, but cannot write to contract storage to mark it as spent.

Marking the key later in a `SENDER` frame is not enough. Payment approval persists even if later frames revert, so a transaction could be included and pay fees, but still fail before the contract marks the key as spent.

This EIP fixes that by consuming the selected nonce when payment is approved. If payment approval succeeds, the protocol advances the selected nonce exactly once. For single-use-key applications such as privacy nullifiers, this gives a simple rule: if validation requires the selected key to be unused, successful inclusion makes that key used.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

This specification is a delta against [EIP-8141](./eip-8141.md).

### Terminology

Terms not defined below are as defined in EIP-8141.

- **`FRAME_TX_TYPE`**: the frame-transaction type byte.
- **`SENDER` frame**: a frame executed on behalf of the transaction sender.
- **`VERIFY` frame**: a static validation frame. It can read state but cannot write contract state.
- **Nonce domain**: the nonce state selected by `nonce_key`.
- **Legacy nonce domain**: the sender's ordinary account nonce, selected when `nonce_key == 0`.
- **Keyed nonce domain**: the protocol-managed nonce for `(sender, nonce_key)`, selected when `nonce_key != 0`.
- **Selected nonce**: the nonce consumed by this transaction: the legacy nonce if `nonce_key == 0`, otherwise the keyed nonce for `(sender, nonce_key)`.
- **Payment approval**: a successful `APPROVE_PAYMENT` or `APPROVE_PAYMENT_AND_EXECUTION`.
- **`APPROVE_PAYMENT` / `APPROVE_PAYMENT_AND_EXECUTION`**: `APPROVE` variants that approve transaction payment and set `payer_approved = true` when successful.
- **`payer_approved`**: a one-shot transaction flag. It starts as `false`, becomes `true` on the first successful payment approval, and cannot be set again in the same transaction. Any later payment-approval attempt reverts its containing frame.
- **`TXPARAM(i)` / `FRAMEPARAM(i, f)`**: EIP-8141 opcodes that expose transaction-level and frame-level values to `VERIFY` code.

### Parameters

| Name                        | Value          |
| --------------------------- | -------------- |
| `FORK_TIMESTAMP`            | `TBD`          |
| `NONCE_MANAGER_ADDRESS`     | `0xTBD`        |
| `NONCE_MANAGER_CODE`        | `0x60006000fd` |
| `KEYED_NONCE_FIRST_USE_GAS` | `20000`        |
| `MAX_NONCE_SEQ`             | `2**64 - 1`    |
| `TXPARAM_NONCE_KEY`         | `0x0B`         |
| `TXPARAM_LEGACY_NONCE`      | `0x0C`         |

- `NONCE_MANAGER_ADDRESS` is assigned at finalization and MUST NOT collide with any already-assigned system contract address.
- `NONCE_MANAGER_ADDRESS` MUST be selected so that, on every intended activation network, the account has no code and empty storage immediately before activation. If the account has a balance, the fork transition preserves it.
- At finalization, the literal `TBD` in the `DOMAIN` preimage below MUST be replaced with the assigned EIP number in decimal, without zero-padding.
- `NONCE_MANAGER_CODE` is a minimal runtime equivalent to `revert(0, 0)`. Any call to it immediately reverts with empty returndata.

### Transaction payload

EIP-8141 defines the frame-transaction payload as:

```text
[chain_id, nonce, sender, frames, max_priority_fee_per_gas,
 max_fee_per_gas, max_fee_per_blob_gas, blob_versioned_hashes]
```

This EIP replaces `nonce` with two fields:

```text
[chain_id, nonce_key, nonce_seq, sender, frames, max_priority_fee_per_gas,
 max_fee_per_gas, max_fee_per_blob_gas, blob_versioned_hashes]
```

- `nonce_key` is a `uint256` that selects the nonce domain.
- `nonce_seq` is a `uint64` sequence number within that domain.

Transactions still use EIP-8141's `FRAME_TX_TYPE` and typed-transaction RLP envelope. Only the `FRAME_TX_TYPE` payload layout changes.

Encoders MUST encode `nonce_key` and `nonce_seq` as canonical minimal-length RLP integers.

Decoders MUST reject a `FRAME_TX_TYPE` transaction if any of the following is true:

- the payload does not match the active schema for the block;
- `nonce_key` or `nonce_seq` is not encoded as a canonical RLP integer;
- `nonce_key` is not representable as a `uint256`;
- `nonce_seq` is not representable as a `uint64`.

Schema selection is based on the block timestamp:

- if `timestamp < FORK_TIMESTAMP`, clients MUST use the pre-fork EIP-8141 payload schema;
- if `timestamp >= FORK_TIMESTAMP`, clients MUST use the post-fork payload schema defined here.

Historical pre-fork blocks remain interpreted under the pre-fork schema, even when synced by a post-fork client.

### Structural validity

For post-fork `FRAME_TX_TYPE` transactions, replace EIP-8141's structural nonce constraint:

```python
assert tx.nonce < 2**64
```

with:

```python
assert tx.nonce_key < 2**256
assert tx.nonce_seq < 2**64
```

All other EIP-8141 structural constraints are unchanged unless explicitly modified by this EIP.

The stricter exhaustion rule `tx.nonce_seq < MAX_NONCE_SEQ` is part of stateful validity. Therefore `nonce_seq == 2**64 - 1` is structurally decodable but statefully invalid. A nonce domain whose current sequence is `MAX_NONCE_SEQ` is exhausted.

### Current nonce sequence

Define:

```text
current_nonce_seq(sender, nonce_key)
```

as:

- if `nonce_key == 0`, return `state[sender].nonce`,
- otherwise, return the keyed value stored for `(sender, nonce_key)` in protocol-managed keyed state, defaulting to `0` when the entry is absent.

Thus `nonce_key == 0` aliases the legacy nonce domain, and `nonce_key != 0` selects a protocol-managed keyed nonce domain.

### Keyed nonce state

All keyed nonces with `nonce_key != 0` are stored in protocol-managed state under Ethereum's main execution-state root. In this design, that state is realized as storage in a dedicated system contract at `NONCE_MANAGER_ADDRESS`.

Let:

- `DOMAIN = keccak256("EIP-TBD:KEYED_NONCE_DOMAIN")`
- `A = left_pad_32(sender_address)`
- `K = uint256_to_bytes32(nonce_key)`

Then:

```text
slot(sender, nonce_key) = keccak256(DOMAIN || A || K)
```

The `DOMAIN` prefix isolates keyed-nonce slots from any other keccak-derived storage scheme that a future EIP might host in the same contract.

For `nonce_key != 0`, the value stored at `NONCE_MANAGER_ADDRESS[slot]` is interpreted as a `uint256` `raw` with the following semantics:

- `raw = 0`: entry absent; `current_nonce_seq == 0`
- `raw > 0`: entry present; `current_nonce_seq == raw`

The protocol never writes `raw == 0`. `current_nonce_seq == 0` is represented only by an absent slot.

The following accessors are protocol-private bookkeeping operations over the storage trie of `NONCE_MANAGER_ADDRESS`. They are not ordinary user-level `SLOAD` or `SSTORE` operations.

```text
keyed_nonce_read_raw(sender, nonce_key):                       # nonce_key != 0
    return read_storage_trie_value(
        NONCE_MANAGER_ADDRESS,
        slot(sender, nonce_key)
    )

get_keyed_nonce_seq(sender, nonce_key):                       # nonce_key != 0
    raw = keyed_nonce_read_raw(sender, nonce_key)
    return raw

set_keyed_nonce_seq(sender, nonce_key, next):                 # nonce_key != 0
    assert 1 <= next <= MAX_NONCE_SEQ
    write_storage_trie_value(
        NONCE_MANAGER_ADDRESS,
        slot(sender, nonce_key),
        next
    )
```

The account at `NONCE_MANAGER_ADDRESS` has inert runtime code: execution at that address immediately reverts with empty returndata and cannot modify keyed-nonce storage. Only the protocol logic defined in this EIP writes keyed-nonce slots.

### Nonce manager initialization

During processing of the first execution payload whose `timestamp >= FORK_TIMESTAMP`, and before executing any transaction in that payload, clients MUST initialize `NONCE_MANAGER_ADDRESS` against that payload's parent state so that it exists as a protocol-owned system contract with:

- runtime code exactly equal to `NONCE_MANAGER_CODE`,
- empty storage,
- nonce at least `1`.

If the account does not exist, clients MUST create it with balance `0`, nonce `1`, code `NONCE_MANAGER_CODE`, and empty storage.

If the account already exists, clients MUST set its code to `NONCE_MANAGER_CODE`, clear its storage, set its nonce to `max(existing_nonce, 1)`, and preserve its balance.

This initialization runs exactly once at fork activation and MUST NOT be re-applied during normal chain progression after activation. Clients MUST handle reorgs across the fork boundary by applying or undoing this transition according to the canonical chain.

### Stateful validity

Let `tx_legacy_nonce` be the value of `state[tx.sender].nonce` observed from the transaction's actual pre-state within block execution order, before any frame executes.

A frame transaction is statefully valid only if:

```text
tx.nonce_seq == current_nonce_seq(tx.sender, tx.nonce_key)
AND
tx.nonce_seq < MAX_NONCE_SEQ
```

This check occurs at the same stage as EIP-8141's nonce check: after signature and structural checks, before any frame executes.

Stateful validity is evaluated against the transaction's actual pre-state within block execution order. Therefore, two frame transactions using the same `(sender, nonce_key)` are valid in one block only if they appear in ascending `nonce_seq` order.

`tx_legacy_nonce` is transaction-scoped and immutable. It is exposed by `TXPARAM(0x0C)` throughout execution, even if payment approval, keyed-nonce consumption, or `CREATE` changes `state[tx.sender].nonce` during the transaction.

### Nonce consumption

EIP-8141 increments the sender nonce when payment approval succeeds. This EIP replaces that increment with consumption of the transaction's selected nonce.

```text
consume_nonce(sender, nonce_key, next):
    assert 1 <= next <= MAX_NONCE_SEQ

    if nonce_key == 0:
        increment_account_nonce(sender)
        return

    set_keyed_nonce_seq(sender, nonce_key, next)
```

For `nonce_key == 0`, `increment_account_nonce(sender)` is the same legacy account-nonce increment that EIP-8141 performs during payment approval. It increments the sender's current account nonce; it does not set the nonce to `tx.nonce_seq + 1`. This preserves EIP-8141 behavior if an earlier `SENDER` frame in the same transaction has already advanced the legacy nonce, for example via `CREATE`.

For `nonce_key != 0`, `next` is `tx.nonce_seq + 1`, the next sequence value in the selected keyed nonce domain.

For `APPROVE_PAYMENT` and `APPROVE_PAYMENT_AND_EXECUTION`, nonce consumption occurs only after all EIP-8141 scope and payment-approval precondition checks have succeeded.

For `APPROVE_PAYMENT`, those checks include:

- `payer_approved == false`,
- `sender_approved == true`,
- the requested `scope` is a non-zero subset of the frame's `allowed_scope`,
- `ADDRESS == resolved_target`,
- `resolved_target` has sufficient balance to pay the transaction maximum cost.

For `APPROVE_PAYMENT_AND_EXECUTION`, those checks include:

- `payer_approved == false`,
- `sender_approved == false`,
- the requested `scope` is a non-zero subset of the frame's `allowed_scope`,
- `ADDRESS == resolved_target`,
- `resolved_target == tx.sender`,
- `resolved_target` has sufficient balance to pay the transaction maximum cost.

After these checks succeed, clients MUST perform payment approval in the following order:

1. If `tx.nonce_key != 0`, read `raw_before = keyed_nonce_read_raw(tx.sender, tx.nonce_key)`. Otherwise skip to step 4.
2. If `raw_before == 0` and the frame has less than `KEYED_NONCE_FIRST_USE_GAS` remaining, the `APPROVE` fails with out-of-gas. The frame reverts, ordinary out-of-gas gas consumption rules apply to that frame, `payer_approved` stays `false`, and no keyed-nonce state changes.
3. If `raw_before == 0`, deduct `KEYED_NONCE_FIRST_USE_GAS` from the remaining gas of the frame executing that `APPROVE`.
4. Execute `consume_nonce(tx.sender, tx.nonce_key, tx.nonce_seq + 1)`.
5. Perform the remaining EIP-8141 payment-approval effects other than the legacy nonce increment, including collecting the transaction maximum cost, setting `payer_approved = true`, and, for `APPROVE_PAYMENT_AND_EXECUTION`, setting `sender_approved = true`.

Steps 3 through 5 are atomic with respect to payment approval: either the nonce update and the remaining payment-approval effects all occur, or none occur. Per EIP-8141, once this transition succeeds its effects persist through later-frame reverts.

Gas deducted as `KEYED_NONCE_FIRST_USE_GAS` is gas used by the frame executing `APPROVE`. The surcharge is deducted only as part of the successful payment-approval transition that sets `payer_approved = true`; if payment approval does not succeed, no keyed-nonce surcharge is separately charged. An out-of-gas failure while attempting to pay the surcharge still follows ordinary out-of-gas semantics for the current frame. When charged, the surcharge is included in the frame's `gas_used` receipt value, transaction gas accounting, and EIP-8141 unpaid-gas refund calculation.

`consume_nonce` runs exactly once per transaction: on the unique successful `APPROVE_PAYMENT` or `APPROVE_PAYMENT_AND_EXECUTION` execution that sets `payer_approved = true`.

Keyed-nonce accesses performed by `current_nonce_seq(tx.sender, tx.nonce_key)` during stateful validity and by payment approval are protocol-private bookkeeping. They:

- do NOT modify `accessed_addresses` or `accessed_storage_keys`,
- are NOT charged under [EIP-2929](./eip-2929.md) account or storage access rules,
- are NOT charged under [EIP-2200](./eip-2200.md) `SSTORE` pricing,
- do NOT warm `NONCE_MANAGER_ADDRESS` or any keyed-nonce slot for later user-level access, even transiently.

They incur only `KEYED_NONCE_FIRST_USE_GAS` on first use of a non-zero key and no additional keyed-nonce surcharge on subsequent uses.

### First transaction and deployment

This EIP does not change EIP-8141 deploy-first flows. If a `deploy` frame is present, it must still be the first frame of the transaction.

A `deploy` frame is not a replay-protection mechanism. It executes before sender authentication and may be front-run under EIP-8141's deployment assumptions. Validation code for a newly deployed account must authenticate the selected nonce domain in the same way as validation code for an already deployed account; it must not treat `TXPARAM(0x01) == 0` alone as sufficient authorization for a first transaction.

Because the nonce check occurs before any frame execution, and because both a non-existent sender and an absent keyed entry evaluate to `current_nonce_seq == 0`, a first frame transaction MAY use either:

- `nonce_key == 0, nonce_seq == 0`, or
- `nonce_key != 0, nonce_seq == 0`.

### TXPARAM

This EIP preserves every EIP-8141 `TXPARAM` index and adds two:

| `param` | Return value                  | Size     |
| ------: | ----------------------------- | -------- |
|  `0x0B` | `nonce_key`                   | 32 bytes |
|  `0x0C` | pre-state legacy sender nonce | 32 bytes |

- `TXPARAM(0x01)` returns `nonce_seq`, the sequence value in the selected nonce domain.
- `TXPARAM(0x0B)` returns `tx.nonce_key`.
- `TXPARAM(0x0C)` returns `tx_legacy_nonce`, the value of `state[tx.sender].nonce` observed during stateful validity before any frame executes.
- For `nonce_key == 0`, stateful validity requires `TXPARAM(0x01) == TXPARAM(0x0C)`.
- For `nonce_key != 0`, `TXPARAM(0x01)` and `TXPARAM(0x0C)` may differ.
- `TXPARAM(0x08)` returns `compute_sig_hash(tx)`.
- `TXPARAM(0x0A)` remains the currently executing frame index.
- All other EIP-8141 indices are unchanged.

`TXPARAM(0x0C)` is transaction-scoped. It is not updated by payment approval, keyed-nonce consumption, or `CREATE` operations within the same transaction.

### Canonical signature hash

This EIP preserves EIP-8141's canonical signature-hash procedure and applies it to the post-fork frame-transaction payload layout:

```text
post_fork_sig_hash_payload(tx) = [
    tx.chain_id,
    tx.nonce_key,
    tx.nonce_seq,
    tx.sender,
    tx.frames with VERIFY-frame data elided exactly as in EIP-8141,
    tx.max_priority_fee_per_gas,
    tx.max_fee_per_gas,
    tx.max_fee_per_blob_gas,
    tx.blob_versioned_hashes,
]
```

`compute_sig_hash(tx)` then applies EIP-8141's ordinary signature-hash rule to that payload, preserving VERIFY-frame data elision and transaction-type domain separation.

The transaction hash committed in the transaction trie is computed over the post-fork typed transaction bytes.

### CREATE and other transaction types

`CREATE` address derivation is unchanged. `CREATE` uses and increments the sender account's legacy nonce regardless of which `nonce_key` the enclosing frame transaction selects. Therefore, a frame transaction with `nonce_key != 0` is not isolated from legacy nonce progression if it executes a successful `CREATE`.

Within a single frame transaction, `CREATE` and payment approval may both advance the legacy account nonce.

If `tx.nonce_key == 0`, payment approval advances the current legacy account nonce by one, preserving EIP-8141 behavior even if an earlier `SENDER` frame has already executed `CREATE`.

If `tx.nonce_key != 0`, payment approval advances only the keyed nonce for `(sender, tx.nonce_key)`. Any `CREATE` in a `SENDER` frame still advances the sender's legacy account nonce by ordinary EVM rules.

All non-frame transaction types are unchanged and continue to consume the sender account's legacy nonce. This includes legacy (type `0x00`), access-list (`0x01`), dynamic-fee (`0x02`), blob (`0x03`), and [EIP-7702](./eip-7702.md) set-code (`0x04`) transactions.

### Interaction with EIP-7702

For EIP-7702-delegated EOAs:

- a frame transaction with `nonce_key == 0` advances the legacy account nonce during payment approval,
- a frame transaction with `nonce_key != 0` does not itself advance the legacy account nonce during payment approval,
- however, any successful `CREATE` still advances the legacy account nonce by ordinary EVM rules.

EIP-7702-delegated EOAs MAY use keyed nonces. The delegation determines the account's executable code, while keyed nonce state is managed separately by the protocol.

Wallets SHOULD surface this distinction clearly.

`NONCE_MANAGER_ADDRESS` itself cannot be used as an EIP-7702 delegation authority: EIP-7702 requires the authority's code to be empty or already delegated, and `NONCE_MANAGER_CODE` is neither.

### JSON-RPC (non-normative)

`eth_getTransactionCount` is unchanged and returns the legacy account nonce.

Because keyed nonce state is represented as storage of `NONCE_MANAGER_ADDRESS`, raw keyed nonce entries are observable through ordinary state-inspection methods such as `eth_getStorageAt` and `eth_getProof`. For a consumed non-zero key, the raw value at `slot(sender, nonce_key)` is `current_nonce_seq`; an absent slot represents sequence `0`.

Clients may expose:

```text
eth_getTransactionCountByKey(address, nonceKey, blockParameter) -> QUANTITY
```

Semantics:

- if `nonceKey == 0`, return the legacy account nonce,
- otherwise, return `current_nonce_seq(address, nonceKey)`.

`pending` semantics for `eth_getTransactionCountByKey` are implementation-defined until public-mempool policies for same-sender keyed concurrency are standardized or converge in practice.

### Public mempool policy (non-normative)

This EIP does not require changes to EIP-8141's public-mempool policy. A conservative node MAY continue to keep at most one pending frame transaction per sender.

For post-fork frame transactions, any public-mempool rule that refers to the sender's nonce dependency should be interpreted as referring to the selected nonce-domain state: `state[sender].nonce` when `nonce_key == 0`, and protocol-managed keyed nonce state when `nonce_key != 0`.

Any public-mempool rule that compares or replaces by transaction nonce should compare `(nonce_key, nonce_seq)`. Under a conservative one-pending-frame-per-sender policy, replacement should require the same `(sender, nonce_key, nonce_seq)` and the node's ordinary fee-bump rule.

A future policy may admit multiple pending frame transactions for the same sender when their non-zero `nonce_key` values differ, subject to validation-prefix dependency tracking, payer balance reservation, and replacement rules.

A block transaction that consumes `(sender, nonce_key)` invalidates or changes the validity of pending frame transactions depending on the same `(sender, nonce_key)`. A transaction that advances only the legacy nonce does not, by that fact alone, invalidate a pending frame transaction using a distinct non-zero `nonce_key`.

### Activation

This EIP MUST activate at or after the activation of [EIP-8141](./eip-8141.md). Co-activation with EIP-8141 is strongly preferred.

Let `B` be a block containing an execution payload.

- if `B.timestamp < FORK_TIMESTAMP`, clients MUST apply the pre-fork EIP-8141 `FRAME_TX_TYPE` schema and MUST NOT apply keyed-nonce logic;
- if `B.timestamp >= FORK_TIMESTAMP`, clients MUST apply the post-fork `FRAME_TX_TYPE` schema defined in this EIP.

During processing of the first execution payload `B` such that `B.timestamp >= FORK_TIMESTAMP`, clients MUST run the nonce-manager initialization defined above before executing any transaction in `B`.

Post-fork blocks MUST reject `FRAME_TX_TYPE` transactions encoded under the pre-fork payload layout.

Schema selection and nonce-manager initialization are determined per block from that block's timestamp and parent state. Clients MUST handle reorgs across the fork boundary by re-evaluating those rules for the new canonical chain.

If activated after EIP-8141, the frame-transaction payload changes atomically at the fork boundary. Pending pre-fork frame transactions become invalid and MUST be evicted from mempools, and any authorizations bound to the pre-fork canonical signature hash MUST be regenerated under the post-fork payload format. Historical pre-fork blocks continue to be interpreted under the pre-fork frame-transaction schema.

## Rationale

### Scope and follow-on work

This EIP is a consensus replay-protection primitive. It does not by itself change fork choice, attestation contents, or attester-side validity objects. The following topics remain deliberately deferred:

- public-mempool propagation and replacement rules for same-sender concurrent keyed frame transactions,
- FOCIL omitted-transaction validity objects for keyed frame transactions,
- transaction witnesses under stateless or partial-stateless designs,
- execution proofs,
- compression or re-commitment of the keyed-nonce map.

### Known tradeoffs

This draft intentionally uses a minimal realization: one dedicated system contract, one storage-slot derivation rule, and one payment-approval hook.

That choice carries three main tradeoffs:

- all keyed-nonce writes hit one hot `NONCE_MANAGER_ADDRESS` and rotate one shared `storageRoot`,
- public-mempool same-sender concurrency is enabled by this EIP's replay independence but still depends on client and builder policy adopting it,
- existing `VERIFY` code that assumes `TXPARAM(0x01)` is the legacy sender nonce must either enforce `nonce_key == 0` or migrate to `TXPARAM(0x0C)`.

### Why protocol-level keyed nonces

A contract-managed nonce table inside `VERIFY` cannot provide the same guarantee. `VERIFY` is static-call, and deferring the spent-mark to a later `SENDER` frame breaks atomicity once payment approval can persist through later failure. Protocol-managed keyed nonces move the replay check to the same stage as EIP-8141's nonce check and move nonce consumption to the same transition that atomically approves payment.

### Prior art: ERC-4337 semi-abstracted nonces

[ERC-4337](./eip-4337.md) already uses a key/sequence split by treating one 256-bit nonce as a key and a sequence. This EIP lifts the same basic idea into consensus for frame transactions, but uses explicit `(nonce_key, nonce_seq)` fields instead of packing so that `TXPARAM(0x01)` remains the scalar sequence value and verifiers avoid bit slicing.

### Main-state integration and forward compatibility

This EIP stores keyed-nonce state in the storage trie of a dedicated system contract, committed under `stateRoot` alongside all other execution state. No new top-level execution-state commitment is introduced, and no new EL/CL payload field or Engine API transport is required.

This choice optimizes for minimal consensus-surface change, not for optimal witness locality. In the current hexary state model, every keyed-nonce update mutates `NONCE_MANAGER_ADDRESS.storageRoot`; in a stateless or partial-stateless regime, this may be less locality-friendly than an account-scoped protocol-owned nonce map.

This design remains forward-compatible with future state-model transitions, including a unified binary tree. A follow-up EIP may optionally re-parent keyed-nonce state from the system contract's storage into a more direct account-scoped protocol-owned representation under the unified main state tree. This EIP does not require such a migration.

### Design choices

- **`nonce_key == 0` aliases the legacy nonce** to preserve EIP-8141 replay behavior and legacy nonce progression. Payment approval advances the current legacy account nonce by one, while `CREATE` continues to use and advance the same legacy nonce by ordinary EVM rules.
- **`nonce_key` is `uint256`** because privacy protocols often use 256-bit nullifiers derived from cryptographic commitments.
- **Storing the next sequence directly** makes first-use detection a single storage read: an absent slot reads as zero, while any present entry represents at least one prior use and equals the next valid `nonce_seq`.
- **Consumption occurs at the first successful payment approval** because that transition occurs exactly once per transaction, is atomic with fee approval, and persists through later-frame reverts.
- **`TXPARAM(0x0B)` and `TXPARAM(0x0C)` are both exposed** so verifier code can read the selected nonce key and the pre-state legacy account nonce explicitly, without inferring legacy-nonce semantics indirectly from `nonce_key == 0`.
- **`KEYED_NONCE_FIRST_USE_GAS = 20000`** uses the present-day zero-to-nonzero state-creation reference point. This is an initial calibration choice, not a claim that the value fully internalizes every downstream proof-locality or caching externality of the current realization, and it remains subject to review during standardization.

## Backwards Compatibility

Legacy account objects, non-frame transaction types, `eth_getTransactionCount`, and EIP-8141's existing `TXPARAM` indices are unchanged. The frame-transaction payload layout changes only for `FRAME_TX_TYPE`. `nonce_key == 0` preserves EIP-8141 replay behavior. `TXPARAM(0x01)` continues to return the replay-protection sequence value, which equals the pre-state legacy nonce under zero-key and the per-domain sequence under non-zero keys. `TXPARAM(0x0C)` provides explicit pre-state legacy-account-nonce access for verifier code that needs it.

Existing verifier code that implicitly treats `TXPARAM(0x01)` as the sender's legacy account nonce MUST be reviewed before use with non-zero-key frame transactions.

## Test Cases

Consensus tests should cover at minimum:

1. `nonce_key == 0` behaves identically to the legacy EIP-8141 nonce path for stateful validity and payment-approval nonce consumption.
2. A zero-key transaction whose legacy nonce is advanced by `CREATE` before payment approval preserves EIP-8141 behavior: `CREATE` advances the current account nonce, and later payment approval advances it again.
3. A non-zero-key transaction whose legacy nonce is advanced by `CREATE` before payment approval advances the keyed nonce during payment approval and preserves the legacy nonce advancement caused by `CREATE`.
4. Two frame transactions from the same sender on distinct non-zero keys at `nonce_seq == 0` are both individually valid.
5. Two frame transactions on the same `(sender, nonce_key)` are valid only if they appear in ascending `nonce_seq` order.
6. Two frame transactions with the same non-zero `nonce_key` but different `sender` values do not conflict, because keyed nonce state is scoped by `(sender, nonce_key)`.
7. First use of a non-zero key incurs `KEYED_NONCE_FIRST_USE_GAS`; reuse does not.
8. Insufficient gas for first-use surcharge causes the approving frame to fail out-of-gas, leaves `payer_approved` unset, and leaves keyed-nonce state unchanged.
9. A later frame revert after successful payment approval does not roll back nonce consumption.
10. A transaction with `nonce_key != 0` that executes `CREATE` advances the legacy nonce only through `CREATE`.
11. `TXPARAM(0x0C)` returns the pre-state legacy nonce and is unchanged by payment approval, keyed-nonce consumption, or `CREATE` within the same transaction.
12. Post-fork decoders reject pre-fork `FRAME_TX_TYPE` payload layouts.
13. RLP decoders reject non-canonical encodings of `nonce_key` and `nonce_seq`.
14. A transaction with `nonce_seq != current_nonce_seq(sender, nonce_key)` is rejected during stateful validity.
15. The stateful-validity keyed lookup and the later `consume_nonce` access do not warm `NONCE_MANAGER_ADDRESS` or its keyed-nonce slots for later user-level accesses in the same transaction, even transiently.
16. `tx.nonce_seq == MAX_NONCE_SEQ` is invalid.
17. The first post-fork block initializes `NONCE_MANAGER_ADDRESS` before executing any transaction.
18. A pre-existing `NONCE_MANAGER_ADDRESS` account with nonzero balance, empty code, and empty storage is initialized with `NONCE_MANAGER_CODE`, nonce at least `1`, empty storage, and preserved balance.
19. A post-fork client syncing historical blocks decodes pre-fork `FRAME_TX_TYPE` payloads under the pre-fork schema and post-fork payloads under the post-fork schema.
20. `TXPARAM(0x01)` and `TXPARAM(0x0C)` are equal when `nonce_key == 0` at transaction start and may differ when `nonce_key != 0`.
21. `APPROVE_PAYMENT` that fails because `sender_approved == false` does not consume a nonce.
22. `APPROVE_PAYMENT_AND_EXECUTION` that fails because `sender_approved == true` does not consume a nonce.
23. Reorgs across the fork boundary re-evaluate schema selection and nonce-manager initialization against the new canonical chain.
24. Raw keyed nonce storage is absent before first use and equals the next valid `nonce_seq` after consumption.
25. Advancing the legacy nonce does not, by itself, invalidate a pending frame transaction using a distinct non-zero `nonce_key`.

## Security Considerations

### Threat model and guarantees

This EIP guarantees consensus-level uniqueness only for `(sender, nonce_key, nonce_seq)`. Equivalently, replay protection is scoped to the nonce domain selected by `(sender, nonce_key)`.

This EIP does not by itself guarantee confidentiality, global uniqueness of an application-level identifier across senders, successful downstream value delivery after payment approval, or freedom from ordinary shared-state conflicts between transactions using distinct keys.

`tx.nonce_seq == MAX_NONCE_SEQ` is invalid. A key may advance until `current_nonce_seq == MAX_NONCE_SEQ`, after which that key is exhausted and no further transaction on it is valid.

### Legacy nonce assumptions and application requirements

Under EIP-8141, `TXPARAM(0x01)` is naturally read as the sender's legacy account nonce. Under this EIP, `TXPARAM(0x01)` remains the replay-protection sequence value, which equals the legacy nonce only when `nonce_key == 0`.

Applications that require pre-state legacy-account-nonce semantics should read `TXPARAM(0x0C)`. Applications that require the legacy nonce domain specifically may additionally enforce `TXPARAM(0x0B) == 0`.

This EIP provides a counter, not a set. Applications that require strict single-use, such as nullifier schemes, must enforce a first-use invariant in `VERIFY`, for example by asserting `TXPARAM(0x01) == 0` and authenticating the expected `TXPARAM(0x0B)` value.

A verifier must not treat `TXPARAM(0x01) == 0` alone as a first-transaction or first-use authorization. For single-use keyed domains, the verifier should bind at least the selected key and sequence, and preferably the full canonical signature hash exposed by `TXPARAM(0x08)`.

Example single-use-key checks:

```text
assert TXPARAM(0x0B) == expected_key      # selected nonce_key
assert TXPARAM(0x01) == 0                 # first sequence in that key
# Prefer also authenticating TXPARAM(0x08), the canonical signature hash.
```

Different nonce keys remove only the replay-ordering dependency. Transactions on different keys may still conflict through sender balance, sender storage, paymaster state, legacy-nonce advancement via `CREATE`, or any other ordinary state dependency.

### Replay protection and malleability

`compute_sig_hash(tx)` commits to `chain_id`, `sender`, `nonce_key`, `nonce_seq`, all frame metadata, all non-VERIFY frame data, and every fee field. An authorization bound to it cannot be replayed across chains, senders, domains, sequences, or fee configurations.

The preferred defense against transaction malleability is to bind the user's authorization directly to `TXPARAM(0x08)`. If the proof system cannot bind the full canonical hash, the verifier must explicitly authenticate every later-frame field it depends on using `FRAMEPARAM`, `FRAMEDATALOAD`, and `FRAMEDATACOPY`, including at minimum frame ordering, target, gas allocation, value, calldata commitment, and any payer-side fee ceilings.

### Nullifier-derived keys and observability

The nonce-key space is per sender. Applications that derive `nonce_key` from a per-use identifier must domain-separate by application identity within that sender's key space, for example by hashing `app_id || pool_id || per_use_identifier` into 256 bits.

Privacy applications SHOULD use a domain-separated hash of the application nullifier, rather than a raw nullifier, unless revealing the raw nullifier in the transaction payload is explicitly intended.

For `nonce_key != 0`, the selected key is visible in the outer frame-transaction payload and is committed to by `compute_sig_hash(tx)`. This EIP therefore provides replay-domain separation, not confidentiality of key selection.

### Cancellation assumptions

A frame transaction with `nonce_key != 0` does not itself advance the legacy account nonce during payment approval. Advancing the sender's legacy account nonce with another transaction therefore does not, by itself, cancel or invalidate a pending non-zero-key frame transaction.

To cancel or replace a non-zero-key frame transaction, wallets should submit a replacement transaction with the same `(sender, nonce_key, nonce_seq)` under the relevant mempool or builder replacement rules, or submit another transaction on the same key that intentionally consumes the domain.

### EIP-7702 cancellation assumptions

For EIP-7702-delegated EOAs, the same cancellation distinction applies: a frame transaction with `nonce_key != 0` does not itself advance the legacy account nonce during payment approval. However, a successful `CREATE` still can. Wallets and offchain tooling should not rely on legacy "send another transaction to cancel" semantics unless the transaction being cancelled uses `nonce_key == 0` or the replacement targets the same keyed domain.

### State growth and proof locality

Each distinct `(sender, nonce_key != 0)` that has been consumed occupies one persistent slot in `NONCE_MANAGER_ADDRESS`'s storage trie. Entries are not deleted by this EIP.

Growth is priced by `KEYED_NONCE_FIRST_USE_GAS`. At `20000` gas per new slot, the maximum number of new keyed nonce slots in a block is bounded by the block gas limit divided by `20000`, before accounting for all other transaction costs.

Because all keyed nonces share one `storageRoot`, any keyed-nonce write invalidates cached proofs against `NONCE_MANAGER_ADDRESS` globally. This is a tradeoff of the current realization under the main execution-state commitment. Future stateless or partial-stateless optimizations may motivate an account-scoped nonce map or a dedicated execution-layer commitment. A later follow-up EIP may change the state representation without changing the keyed replay-domain semantics introduced here.

### Approval persistence

Per EIP-8141, approval effects persist through later-frame reverts. A single-use key consumed by `consume_nonce` is therefore spent even if a later frame responsible for value delivery reverts.

Applications that consume single-use keys SHOULD minimize post-approval revert paths, for example by preferring pull escrow or other delivery patterns that avoid volatile external calls after consumption.

### Accidental transfers

Ordinary direct calls or transfers to `NONCE_MANAGER_ADDRESS` revert. However, the account may still receive ETH through force-send mechanisms where applicable. Any balance held at `NONCE_MANAGER_ADDRESS` is outside the scope of this EIP and is not recoverable by protocol logic defined here.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).