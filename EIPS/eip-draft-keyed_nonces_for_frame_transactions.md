---
eip: TBD
title: Keyed Nonces for Frame Transactions
description: Independent nonce domains for frame transactions
author: Thomas Thiery (@soispoke) <thomas.thiery@ethereum.org>
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-04-16
requires: 8141
---

## Abstract

A frame transaction ([EIP-8141](./eip-8141.md)) currently uses one sender nonce, so all frame transactions from the same sender share one inclusion order: a delayed transaction blocks every later frame transaction from that sender.

This EIP replaces that single nonce with `(nonce_key, nonce_seq)`:

* `nonce_key` selects a nonce domain.
* `nonce_seq` is the sequence number within that domain.

The zero key selects the sender's legacy account nonce. Each non-zero key selects an independent protocol-managed keyed nonce domain. Transactions in different non-zero domains are replay-independent; transactions in the same domain remain linearly sequenced.

EIP-8141 consumes the sender nonce when payment is approved. This EIP preserves that approval-time consumption rule, but applies it to the transaction's selected nonce.

If `nonce_key == 0`, payment approval advances the sender's current legacy account nonce. If `nonce_key != 0`, payment approval advances the keyed nonce for `(sender, nonce_key)`.

Because nonce consumption is part of EIP-8141's payment-approval transition, it persists even if later frames revert. For single-use-key applications such as privacy nullifiers, this means that if validation requires the selected key to be unused, successful inclusion makes that key used.

This EIP is a replay-protection and concurrency primitive. It does not by itself provide confidentiality or change public-mempool policy.

## Motivation

Frame transactions make validation programmable, but their replay protection still uses a single linear sender nonce. That is too restrictive for several use cases, most notably shared-sender privacy withdrawals. Other applications include smart-wallet session keys and relayer designs where many independent actions intentionally share one sender account.

A privacy protocol may use a shared sender so that onchain activity is not tied to a unique public sender. With a single sequential nonce, that shared sender becomes a throughput bottleneck: one user's inclusion invalidates every other user's pending transaction even when the two spends are otherwise unrelated.

At the consensus layer, keyed nonces remove this bottleneck. Each spend can use its own nonce domain, for example one derived from its nullifier in a privacy protocol. They do not remove other shared-state dependencies such as sender balance, sender storage, payer balance, paymaster state, contract storage, or legacy-nonce advancement caused by `CREATE` or `CREATE2`.

This EIP does not itself change EIP-8141's public-mempool one-pending-frame-transaction-per-sender guidance, but it provides the protocol-level condition for relaxing rules of that kind: transactions on distinct non-zero keys are replay-independent and no longer alias on one sender-wide nonce.

Keyed nonces also solve an atomicity problem. In EIP-8141, `VERIFY` frames can check that a single-use key is valid, but cannot write to contract storage to mark it as spent.

Marking the key later in a `SENDER` frame is not enough. Payment approval persists even if later frames revert, so a transaction could be included and pay fees, but still fail before the contract marks the key as spent.

This EIP fixes that by consuming the selected nonce when payment is approved. If payment approval succeeds, the protocol advances the selected nonce exactly once. For single-use-key applications such as privacy nullifiers, this gives a simple rule: if validation requires the selected key to be unused, successful inclusion makes that key used.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

This specification is a delta against [EIP-8141](./eip-8141.md).

### Terminology

Terms not defined below are as defined in EIP-8141.

* **`FRAME_TX_TYPE`**: the frame-transaction type byte.
* **`DEFAULT` frame**: an EIP-8141 frame executed with caller `ENTRY_POINT`.
* **`VERIFY` frame**: an EIP-8141 validation frame. It can read state but cannot write ordinary contract state. `APPROVE` may still update transaction-scoped approval state and payment-approval state as defined by EIP-8141 and this EIP.
* **`SENDER` frame**: an EIP-8141 frame executed with caller `tx.sender`.
* **Nonce domain**: the nonce state selected by `nonce_key`.
* **Legacy nonce domain**: the sender's ordinary account nonce, selected when `nonce_key == 0`.
* **Keyed nonce domain**: the protocol-managed nonce for `(sender, nonce_key)`, selected when `nonce_key != 0`.
* **Selected nonce**: the nonce consumed by this transaction: the legacy nonce if `nonce_key == 0`, otherwise the keyed nonce for `(sender, nonce_key)`.
* **`APPROVE_PAYMENT`**: EIP-8141 `APPROVE` scope `0x1`.
* **`APPROVE_EXECUTION`**: EIP-8141 `APPROVE` scope `0x2`.
* **`APPROVE_PAYMENT_AND_EXECUTION`**: EIP-8141 `APPROVE` scope `0x3`.
* **Payment-scoped `APPROVE`**: an EIP-8141 `APPROVE` whose scope includes `APPROVE_PAYMENT`, i.e. scope `0x1` or scope `0x3`.
* **`payer_approved`**: a one-shot transaction flag. It starts as `false`, becomes `true` on the first successful payment-scoped `APPROVE`, and cannot be set again in the same transaction.
* **`sender_approved`**: a one-shot transaction flag defined by EIP-8141. It starts as `false`, becomes `true` on successful execution approval, and cannot be set again in the same transaction.
* **`TXPARAM(i)`**: the EIP-8141 opcode that exposes transaction-scoped values to frame code.
* **`FRAMEPARAM(i, frameIndex)`**: the EIP-8141 opcode that exposes frame-scoped values to frame code.

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

`NONCE_MANAGER_CODE` is a minimal runtime equivalent to `revert(0, 0)`. Any ordinary call to it immediately reverts with empty returndata.

`NONCE_MANAGER_ADDRESS` is assigned at finalization and MUST NOT collide with any already-assigned system contract address.

`NONCE_MANAGER_ADDRESS` SHOULD be selected using a high-entropy procedure such that no known externally owned account, `CREATE`, or `CREATE2` preimage can create code at that address before activation.

At fork-configuration finalization, clients MUST verify that `NONCE_MANAGER_ADDRESS` has zero nonce, zero balance, empty code, and empty storage on every intended activation network, unless the fork configuration explicitly accepts preserving a pre-existing balance as described below.

If the selected address has non-empty code or non-empty storage on any intended activation network at fork-configuration finalization, a different `NONCE_MANAGER_ADDRESS` MUST be selected before finalization.

If the selected address has non-empty code or non-empty storage on any intended activation network after finalization but before activation, the fork configuration MUST be updated before activation. This EIP does not define a normal activation transition that clears non-empty storage or overwrites non-empty code at `NONCE_MANAGER_ADDRESS`.

At activation, the fork transition MUST preserve any balance already present at `NONCE_MANAGER_ADDRESS`.

At finalization, the literal `TBD` in the `DOMAIN` preimage below MUST be replaced with the assigned EIP number in decimal, without zero-padding.

### Transaction payload

EIP-8141 defines the frame-transaction payload as:

```text
[chain_id, nonce, sender, frames, max_priority_fee_per_gas,
 max_fee_per_gas, max_fee_per_blob_gas, blob_versioned_hashes]
````

with frame layout:

```text
frames = [[mode, flags, target, gas_limit, value, data], ...]
```

This EIP replaces `nonce` with two fields:

```text
[chain_id, nonce_key, nonce_seq, sender, frames, max_priority_fee_per_gas,
 max_fee_per_gas, max_fee_per_blob_gas, blob_versioned_hashes]
```

This EIP does not change EIP-8141's frame-list layout:

```text
frames = [[mode, flags, target, gas_limit, value, data], ...]
```

If no blobs are included, EIP-8141's rule remains unchanged: `blob_versioned_hashes` MUST be an empty list and `max_fee_per_blob_gas` MUST be `0`.

* `nonce_key` is a `uint256` that selects the nonce domain.
* `nonce_seq` is a `uint64` sequence number within that domain.

Transactions still use EIP-8141's `FRAME_TX_TYPE` and typed-transaction RLP envelope. Only the `FRAME_TX_TYPE` payload layout changes.

Encoders MUST encode `nonce_key` and `nonce_seq` as canonical minimal-length RLP integers.

Decoders MUST reject a `FRAME_TX_TYPE` transaction if any of the following is true:

* the payload does not match the active schema for the block;
* `nonce_key` or `nonce_seq` is not encoded as a canonical RLP integer;
* `nonce_key` is not representable as a `uint256`;
* `nonce_seq` is not representable as a `uint64`.

Schema selection is based on the block timestamp:

* if `timestamp < FORK_TIMESTAMP`, clients MUST use the pre-fork EIP-8141 payload schema;
* if `timestamp >= FORK_TIMESTAMP`, clients MUST use the post-fork payload schema defined here.

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

The stricter exhaustion rule `tx.nonce_seq < MAX_NONCE_SEQ` is part of stateful validity. Therefore, `nonce_seq == 2**64 - 1` is structurally decodable but statefully invalid. A nonce domain whose current sequence is `MAX_NONCE_SEQ` is exhausted.

### Current nonce sequence

Define:

```text
current_nonce_seq(sender, nonce_key)
```

as:

* if `nonce_key == 0`, return `state[sender].nonce`;
* otherwise, return the keyed value stored for `(sender, nonce_key)` in protocol-managed keyed state, defaulting to `0` when the entry is absent.

Thus `nonce_key == 0` aliases the legacy nonce domain, and `nonce_key != 0` selects a protocol-managed keyed nonce domain.

### Keyed nonce state

All keyed nonces with `nonce_key != 0` are stored in protocol-managed state under Ethereum's main execution-state root. In this design, that state is realized as storage in a dedicated system contract at `NONCE_MANAGER_ADDRESS`.

Let:

* `DOMAIN_PREIMAGE` be the UTF-8 byte string `EIP-TBD:KEYED_NONCE_DOMAIN`, with no trailing NUL byte and no length prefix.
* `DOMAIN = keccak256(DOMAIN_PREIMAGE)`.
* `A` be the 20-byte `sender_address` left-padded with twelve zero bytes.
* `K` be the 32-byte big-endian encoding of `nonce_key`.

Then:

```text
slot(sender, nonce_key) = keccak256(DOMAIN || A || K)
```

At finalization, the final EIP MUST publish the resulting 32-byte `DOMAIN` value. The `DOMAIN` prefix isolates keyed-nonce slots from any other keccak-derived storage scheme that a future EIP might host in the same contract.

For `nonce_key != 0`, the value stored at `NONCE_MANAGER_ADDRESS[slot]` is interpreted as a `uint256` `raw` with the following semantics:

* `raw == 0`: entry absent; `current_nonce_seq == 0`;
* `raw > 0`: entry present; `current_nonce_seq == raw`.

The protocol never writes `raw == 0`. `current_nonce_seq == 0` is represented only by an absent slot.

The following accessors are protocol-private bookkeeping operations over the storage trie of `NONCE_MANAGER_ADDRESS`. They are not ordinary user-level `SLOAD` or `SSTORE` operations.

```text
keyed_nonce_read_raw(sender, nonce_key):                       # nonce_key != 0
    return read_storage_trie_value(
        NONCE_MANAGER_ADDRESS,
        slot(sender, nonce_key)
    )

get_keyed_nonce_seq(sender, nonce_key):                        # nonce_key != 0
    raw = keyed_nonce_read_raw(sender, nonce_key)
    return raw

set_keyed_nonce_seq(sender, nonce_key, next):                  # nonce_key != 0
    assert 1 <= next <= MAX_NONCE_SEQ
    write_storage_trie_value(
        NONCE_MANAGER_ADDRESS,
        slot(sender, nonce_key),
        next
    )
```

The account at `NONCE_MANAGER_ADDRESS` has inert runtime code. Execution at that address immediately reverts with empty returndata and cannot modify keyed-nonce storage. Only the protocol logic defined in this EIP writes keyed-nonce slots.

### Nonce manager initialization

During processing of the first execution payload whose `timestamp >= FORK_TIMESTAMP`, and before executing any transaction in that payload, clients MUST initialize `NONCE_MANAGER_ADDRESS` against that payload's parent state so that it exists as a protocol-owned system contract with:

* runtime code exactly equal to `NONCE_MANAGER_CODE`;
* empty storage;
* nonce at least `1`.

If the account does not exist, clients MUST create it with balance `0`, nonce `1`, code `NONCE_MANAGER_CODE`, and empty storage.

If the account already exists with empty code and empty storage, clients MUST set its code to `NONCE_MANAGER_CODE`, set its nonce to `max(existing_nonce, 1)`, preserve its balance, and leave storage empty.

Because `NONCE_MANAGER_ADDRESS` is required not to have non-empty code or non-empty storage on any intended activation network at finalization, this EIP does not define a normal activation transition that clears non-empty storage or overwrites non-empty code at that address.

This initialization runs exactly once at fork activation and MUST NOT be re-applied during normal chain progression after activation. Clients MUST handle reorgs across the fork boundary by applying or undoing this transition according to the canonical chain.

### Stateful validity

Let `tx_legacy_nonce` be the value of `state[tx.sender].nonce` observed from the transaction's actual pre-state within block execution order, before any frame executes.

A post-fork frame transaction is statefully valid only if:

```text
tx.nonce_seq == current_nonce_seq(tx.sender, tx.nonce_key)
AND
tx.nonce_seq < MAX_NONCE_SEQ
```

This check occurs at the same stage as EIP-8141's nonce check: after structural checks and before any frame executes.

Stateful validity is evaluated against the transaction's actual pre-state within block execution order. Therefore, two frame transactions using the same `(sender, nonce_key)` are valid in one block only if each transaction's `nonce_seq` equals the current sequence at its position in block execution order.

`tx_legacy_nonce` is transaction-scoped and immutable. It is exposed by `TXPARAM(0x0C)` throughout execution, even if payment approval, keyed-nonce consumption, account creation, `CREATE`, or `CREATE2` changes `state[tx.sender].nonce` during the transaction.

### Nonce consumption

EIP-8141 increments the sender nonce when payment approval succeeds. This EIP replaces that increment with consumption of the transaction's selected nonce.

```text
consume_nonce(sender, nonce_key, nonce_seq):
    if nonce_key == 0:
        increment_account_nonce(sender)
        return

    set_keyed_nonce_seq(sender, nonce_key, nonce_seq + 1)
```

For `nonce_key == 0`, `increment_account_nonce(sender)` is the same legacy account-nonce increment that EIP-8141 performs during payment approval. It increments the sender's current account nonce; it does not set the nonce to `tx.nonce_seq + 1`.

This preserves EIP-8141 behavior if an earlier frame in the same transaction has already changed the sender's legacy nonce, for example by deploying `tx.sender` or by executing `CREATE` or `CREATE2` at `tx.sender`.

If `increment_account_nonce(sender)` would make `state[sender].nonce` exceed `MAX_NONCE_SEQ`, the payment-scoped `APPROVE` fails with an exceptional halt and performs no approval effects.

For `nonce_key != 0`, stateful validity guarantees `tx.nonce_seq < MAX_NONCE_SEQ`, so `tx.nonce_seq + 1` is in the range accepted by `set_keyed_nonce_seq`.

An `APPROVE` is payment-scoped if its scope includes `APPROVE_PAYMENT`, i.e. if scope is `0x1` or `0x3`.

This EIP replaces only the legacy nonce-increment effect of EIP-8141 payment approval. All other EIP-8141 `APPROVE` rules remain unchanged unless explicitly modified here.

For a payment-scoped `APPROVE`, clients first apply all EIP-8141 `APPROVE` exceptional-condition checks and ordinary opcode execution costs, including any `RETURN`-like memory costs, but excluding the legacy nonce increment that this EIP replaces.

Only after those checks and costs succeed, and before any approval effect is committed, clients MUST perform:

1. If `tx.nonce_key != 0`, read:

   ```text
   raw_before = keyed_nonce_read_raw(tx.sender, tx.nonce_key)
   ```

   Otherwise skip to step 4.

2. If `raw_before == 0` and the current frame has less than `KEYED_NONCE_FIRST_USE_GAS` gas remaining, the `APPROVE` fails with an out-of-gas exceptional halt. The current frame's remaining gas is consumed according to ordinary out-of-gas rules, `payer_approved` remains `false`, and no keyed-nonce state changes.

3. If `raw_before == 0`, deduct `KEYED_NONCE_FIRST_USE_GAS` from the current frame's remaining gas.

4. Execute:

   ```text
   consume_nonce(tx.sender, tx.nonce_key, tx.nonce_seq)
   ```

5. Commit the remaining EIP-8141 payment-approval effects, excluding the legacy nonce increment replaced above. These include collecting the transaction maximum cost from the payment approver, recording the payer for the receipt and refund, setting `payer_approved = true`, and, for `APPROVE_PAYMENT_AND_EXECUTION`, setting `sender_approved = true`.

Steps 3 through 5 are a single approval transition. Either all are committed, or none are committed.

Nonce consumption, maximum-cost collection, payer recording, first-use gas charging, and approval-flag updates performed by a successful payment-scoped `APPROVE` are approval effects, not ordinary frame-local state changes. They MUST be journaled outside the current frame's revert journal and outside any `SENDER` atomic-batch snapshot. They MUST NOT be reverted by a later frame revert, by skipping later frames, or by restoring an atomic-batch state snapshot.

`consume_nonce` runs exactly once per transaction: on the unique successful payment-scoped `APPROVE` execution that sets `payer_approved = true`.

Gas deducted as `KEYED_NONCE_FIRST_USE_GAS` is gas used by the frame executing `APPROVE`. The surcharge is deducted only as part of the successful payment-approval transition that sets `payer_approved = true`; if payment approval does not succeed, no keyed-nonce surcharge is separately charged.

An out-of-gas failure while attempting to pay the surcharge follows ordinary out-of-gas semantics for the current frame. If the approving frame is a `VERIFY` frame, this failure is handled like any other `VERIFY` frame that exits without a successful required `APPROVE`: the frame transaction is invalid under EIP-8141. When charged, the surcharge is included in the frame's `gas_used` receipt value, transaction gas accounting, and EIP-8141 unpaid-gas refund calculation.

Keyed-nonce accesses performed by `current_nonce_seq(tx.sender, tx.nonce_key)` during stateful validity and by payment approval are protocol-private bookkeeping. They:

* do NOT modify `accessed_addresses` or `accessed_storage_keys`;
* are NOT charged under [EIP-2929](./eip-2929.md) account or storage access rules;
* are NOT charged under [EIP-2200](./eip-2200.md) `SSTORE` pricing;
* do NOT warm `NONCE_MANAGER_ADDRESS` or any keyed-nonce slot for later user-level access, even transiently.

They incur only `KEYED_NONCE_FIRST_USE_GAS` on first use of a non-zero key and no additional keyed-nonce surcharge on subsequent uses.

### First transaction and deployment

This EIP does not change EIP-8141 first-transaction or deployment-related behavior. Where EIP-8141 public-mempool policy recognizes a deployment frame, this EIP does not relax its placement rules.

A deployment frame is not a replay-protection mechanism. It executes before sender authentication and may be front-run under EIP-8141's deployment assumptions. Validation code for a newly deployed account must authenticate the selected nonce domain in the same way as validation code for an already deployed account; it must not treat `TXPARAM(0x01) == 0` alone as sufficient authorization for a first transaction.

Because the nonce check occurs before any frame execution, and because both a non-existent sender and an absent keyed entry evaluate to sequence `0`, a first frame transaction MAY use either:

* `nonce_key == 0, nonce_seq == 0`; or
* `nonce_key != 0, nonce_seq == 0`.

If a deployment frame creates `tx.sender` before payment approval, that deployment may change `state[tx.sender].nonce` before payment approval executes. For `nonce_key == 0`, payment approval increments the sender's then-current legacy account nonce. For `nonce_key != 0`, payment approval advances only the keyed nonce for `(tx.sender, tx.nonce_key)`.

### TXPARAM and FRAMEPARAM

This EIP preserves existing EIP-8141 `TXPARAM` index allocations, changes `TXPARAM(0x01)` to return the selected-domain sequence, and adds two indices:

| `param` | Return value                  |
| ------: | ----------------------------- |
|  `0x0B` | `nonce_key`                   |
|  `0x0C` | pre-state legacy sender nonce |

* `TXPARAM(0x01)` returns `tx.nonce_seq`.
* `TXPARAM(0x0B)` returns `tx.nonce_key`.
* `TXPARAM(0x0C)` returns `tx_legacy_nonce`, the value of `state[tx.sender].nonce` observed during stateful validity before any frame executes.
* `TXPARAM(0x08)` continues to return `compute_sig_hash(tx)`.
* `TXPARAM(0x0A)` continues to return the currently executing frame index.
* `FRAMEPARAM` remains the EIP-8141 mechanism for frame introspection.
* All other EIP-8141 `TXPARAM` indices are unchanged.
* Invalid `TXPARAM` values remain exceptional halts unless defined by this EIP or a later EIP.

For `nonce_key == 0`, stateful validity requires `TXPARAM(0x01) == TXPARAM(0x0C)` at transaction start.

For `nonce_key != 0`, `TXPARAM(0x01)` and `TXPARAM(0x0C)` may differ.

`TXPARAM(0x0C)` is transaction-scoped. It is not updated by payment approval, keyed-nonce consumption, account deployment, `CREATE`, or `CREATE2` within the same transaction.

### Canonical signature hash

This EIP preserves EIP-8141's canonical signature-hash procedure and applies it to the post-fork frame-transaction payload layout.

For post-fork frame transactions, `compute_sig_hash(tx)` is computed over the post-fork transaction object:

```text
[chain_id, nonce_key, nonce_seq, sender, frames,
 max_priority_fee_per_gas, max_fee_per_gas,
 max_fee_per_blob_gas, blob_versioned_hashes]
```

where each frame has the EIP-8141 layout:

```text
[mode, flags, target, gas_limit, value, data]
```

Before hashing, the `data` field of every `VERIFY` frame is elided exactly as in EIP-8141.

The hash is:

```text
keccak256(bytes([FRAME_TX_TYPE]) || rlp(tx_copy))
```

where `tx_copy` is the post-fork transaction object after `VERIFY`-frame data elision.

The transaction hash committed in the transaction trie is computed over the post-fork typed transaction bytes, not over the canonical signature-hash payload.

### CREATE, CREATE2, and other transaction types

`CREATE` and `CREATE2` semantics are unchanged.

A `CREATE` or `CREATE2` operation increments the nonce of the account whose code executes the opcode. If the opcode is executed at `tx.sender`, it advances the sender's legacy account nonce. If the opcode is executed at another account, it advances that account's nonce.

This EIP changes only the payment-approval nonce consumption for `tx.sender`.

For a frame transaction with `nonce_key == 0`, payment approval increments the current legacy account nonce of `tx.sender`. That current nonce may already have changed during the same transaction, for example because `tx.sender` was deployed or because `CREATE` or `CREATE2` was executed at `tx.sender`.

For a frame transaction with `nonce_key != 0`, payment approval advances only the keyed nonce for `(tx.sender, tx.nonce_key)`. It does not itself advance `tx.sender`'s legacy account nonce. However, account deployment and any `CREATE` or `CREATE2` executed at `tx.sender` still affect `tx.sender`'s legacy account nonce according to ordinary EVM rules.

`CREATE` address derivation is unchanged. If a frame transaction with `nonce_key != 0` executes `CREATE` at `tx.sender`, the created address depends on `tx.sender`'s legacy account nonce at execution time. Another transaction that advances `tx.sender`'s legacy nonce before inclusion can therefore change the `CREATE` address without invalidating the keyed transaction, unless validation authenticates the relevant legacy nonce through `TXPARAM(0x0C)`.

All non-frame transaction types are unchanged and continue to consume the transaction sender's legacy account nonce according to their own specifications. This includes legacy transactions, access-list transactions, dynamic-fee transactions, blob transactions, and [EIP-7702](./eip-7702.md) set-code transactions.

### Interaction with EIP-7702

Frame transactions do not include an EIP-7702 authorization list and do not set, clear, or otherwise modify EIP-7702 delegation indicators.

For EIP-7702-delegated EOAs:

* a frame transaction with `nonce_key == 0` advances the legacy account nonce during payment approval;
* a frame transaction with `nonce_key != 0` does not itself advance the legacy account nonce during payment approval;
* however, deployment and any `CREATE` or `CREATE2` executed at the delegated account address still affect that account's legacy nonce according to ordinary EVM rules.

EIP-7702-delegated EOAs MAY use keyed nonces. The delegation determines the account's executable code, while keyed nonce state is managed separately by the protocol.

Wallets SHOULD surface this distinction clearly.

`NONCE_MANAGER_ADDRESS` cannot be the authorizing account in an EIP-7702 authorization tuple: EIP-7702 requires the authority account's code to be empty or already delegated, and `NONCE_MANAGER_CODE` is neither empty nor a delegation indicator. Other accounts may still delegate to `NONCE_MANAGER_ADDRESS`; doing so delegates execution to inert code that reverts with empty returndata.

### JSON-RPC

`eth_getTransactionCount` is unchanged and returns the legacy account nonce.

Because keyed nonce state is represented as storage of `NONCE_MANAGER_ADDRESS`, raw keyed nonce entries are observable through ordinary state-inspection methods such as `eth_getStorageAt` and `eth_getProof`.

For a consumed non-zero key, the raw value at `slot(sender, nonce_key)` is `current_nonce_seq(sender, nonce_key)`. An absent slot represents sequence `0`.

Clients MAY expose:

```text
eth_getTransactionCountByKey(address, nonceKey, blockParameter) -> QUANTITY
```

Semantics:

* if `nonceKey == 0`, return the legacy account nonce;
* otherwise, return `current_nonce_seq(address, nonceKey)`.

`pending` semantics for `eth_getTransactionCountByKey` are implementation-defined until public-mempool policies for same-sender keyed concurrency are standardized or converge in practice.

### Public mempool policy

This EIP does not require changes to EIP-8141's public-mempool policy. A conservative node MAY continue to keep at most one pending frame transaction per sender.

Until a keyed-aware public-mempool policy is specified, nodes SHOULD NOT admit multiple same-sender frame transactions into the public mempool merely because their non-zero `nonce_key` values differ. Such transactions may still be handled through private mempools, builder APIs, relayers, or local policy.

A keyed-aware public-mempool rule that refers to nonce dependency would need to refer to the selected nonce-domain state: `state[sender].nonce` when `nonce_key == 0`, and protocol-managed keyed nonce state when `nonce_key != 0`.

A keyed-aware public-mempool rule that compares or replaces by transaction nonce would need to compare `(nonce_key, nonce_seq)`. Under a conservative one-pending-frame-transaction-per-sender policy, replacement SHOULD require the same `(sender, nonce_key, nonce_seq)` and the node's ordinary fee-bump rule.

A future policy MAY admit multiple pending frame transactions for the same sender when their non-zero `nonce_key` values differ, subject to validation-prefix dependency tracking, payer balance reservation, sender balance reservation, and replacement rules.

Distinct non-zero nonce keys remove only the selected-nonce replay dependency. They do not remove payer-balance dependencies, sender-balance dependencies, sender-storage dependencies, paymaster reservation dependencies, validation-trace dependencies, or legacy-nonce dependencies introduced by `TXPARAM(0x0C)`, account deployment, `CREATE`, or `CREATE2`.

A keyed-aware public mempool MUST reserve payment capacity for all pending transactions that can charge the same payer, including self-paying keyed transactions, or otherwise bound the number of such transactions.

A future public-mempool specification would need to extend EIP-8141 validation-prefix dependency tracking from sender storage slots to the selected nonce domain. If validation reads `TXPARAM(0x0C)`, that future policy SHOULD treat the transaction as dependent on the sender's legacy account nonce even when `nonce_key != 0`.

A block transaction that consumes `(sender, nonce_key)` invalidates or changes the validity of pending frame transactions depending on the same `(sender, nonce_key)`. A transaction that advances only the legacy nonce does not, by that fact alone, invalidate a pending frame transaction using a distinct non-zero `nonce_key`, unless the pending transaction's validation depends on the legacy nonce, for example through `TXPARAM(0x0C)`.

### Activation

This EIP MUST activate at or after the activation of [EIP-8141](./eip-8141.md). Co-activation with EIP-8141 is strongly preferred.

Let `B` be a block containing an execution payload.

* If EIP-8141 is not active for `B`, `FRAME_TX_TYPE` transactions are invalid.
* If EIP-8141 is active for `B` and `B.timestamp < FORK_TIMESTAMP`, clients MUST apply the pre-fork EIP-8141 `FRAME_TX_TYPE` schema and MUST NOT apply keyed-nonce logic.
* If `B.timestamp >= FORK_TIMESTAMP`, clients MUST apply the post-fork `FRAME_TX_TYPE` schema defined in this EIP.

During processing of the first execution payload `B` such that `B.timestamp >= FORK_TIMESTAMP`, clients MUST run the nonce-manager initialization defined above before executing any transaction in `B`.

Post-fork blocks MUST reject `FRAME_TX_TYPE` transactions encoded under the pre-fork payload layout.

Schema selection and nonce-manager initialization are determined per block from that block's timestamp and parent state. Clients MUST handle reorgs across the fork boundary by re-evaluating those rules for the new canonical chain.

If activated after EIP-8141, the frame-transaction payload changes atomically at the fork boundary. Pending pre-fork frame transactions become invalid and MUST be evicted from mempools, and any authorizations bound to the pre-fork canonical signature hash MUST be regenerated under the post-fork payload format. Historical pre-fork blocks continue to be interpreted under the pre-fork frame-transaction schema.

This EIP assumes full-state execution-layer payload validation. If it activates in a stateless or partial-stateless setting, the corresponding witness specification MUST include the `NONCE_MANAGER_ADDRESS` account and every keyed-nonce slot touched by stateful validity or payment approval.

## Rationale

### Scope and follow-on work

This EIP is a consensus replay-protection primitive. It does not by itself change fork choice, attestation contents, public-mempool propagation, or attester-side validity objects.

The following topics remain deliberately deferred:

* public-mempool propagation and replacement rules for same-sender concurrent keyed frame transactions;
* FOCIL omitted-transaction validity objects for keyed frame transactions;
* transaction witnesses under stateless or partial-stateless designs;
* execution proofs.

### Known tradeoffs

This draft intentionally uses a minimal realization: one dedicated system contract, one storage-slot derivation rule, and one payment-approval hook.

That choice carries three main tradeoffs:

* all keyed-nonce writes hit one hot `NONCE_MANAGER_ADDRESS` and rotate one shared `storageRoot`;
* public-mempool same-sender concurrency is enabled by this EIP's replay independence but still depends on client and builder policy adopting it;
* existing `VERIFY` code that assumes `TXPARAM(0x01)` is the legacy sender nonce must either enforce `nonce_key == 0` or migrate to `TXPARAM(0x0C)`.

### Why protocol-level keyed nonces

A contract-managed nonce table inside `VERIFY` cannot provide the same guarantee. `VERIFY` is static-call-like: it can read state but cannot write ordinary contract state. Deferring the spent-mark to a later `SENDER` frame breaks atomicity once payment approval can persist through later failure.

Protocol-managed keyed nonces move the replay check to the same stage as EIP-8141's nonce check and move nonce consumption to the same transition that atomically approves payment.

### Prior art: ERC-4337 semi-abstracted nonces

[ERC-4337](./eip-4337.md) already uses a key/sequence split by treating one 256-bit nonce as a key and a sequence. This EIP lifts the same basic idea into consensus for frame transactions, but uses explicit `(nonce_key, nonce_seq)` fields instead of packing so that `TXPARAM(0x01)` remains the scalar sequence value and verifiers avoid bit slicing.

### Main-state integration and forward compatibility

This EIP stores keyed-nonce state in the storage trie of a dedicated system contract, committed under `stateRoot` alongside all other execution state. No new top-level execution-state commitment is introduced, and no new EL/CL payload field or Engine API transport is required.

This choice optimizes for minimal consensus-surface change, not for optimal witness locality. In the current hexary state model, every keyed-nonce update mutates `NONCE_MANAGER_ADDRESS.storageRoot`; in a stateless or partial-stateless regime, this may be less locality-friendly than an account-scoped protocol-owned nonce map.

This design remains forward-compatible with future state-model transitions, including a unified binary tree. A follow-up EIP may optionally re-parent keyed-nonce state from the system contract's storage into a more direct account-scoped protocol-owned representation under the unified main state tree. This EIP does not require such a migration.

### Design choices

`nonce_key == 0` aliases the legacy nonce to preserve EIP-8141 replay behavior and legacy nonce progression. Payment approval advances the current legacy account nonce by one, while account deployment, `CREATE`, and `CREATE2` continue to affect account nonces by ordinary EVM rules.

`nonce_key` is `uint256` because privacy protocols often use 256-bit nullifiers derived from cryptographic commitments.

Storing the next sequence directly makes first-use detection a single storage read: an absent slot reads as zero, while any present entry represents at least one prior use and equals the next valid `nonce_seq`.

Consumption occurs at the first successful payment-scoped `APPROVE` because that transition occurs exactly once per transaction, is atomic with fee approval, and persists through later-frame reverts and `SENDER` atomic-batch rollback.

`TXPARAM(0x0B)` and `TXPARAM(0x0C)` are both exposed so verifier code can read the selected nonce key and the pre-state legacy account nonce explicitly, without inferring legacy-nonce semantics indirectly from `nonce_key == 0`.

`KEYED_NONCE_FIRST_USE_GAS = 20000` uses the present-day zero-to-nonzero state-creation reference point. This is an initial calibration choice, not a claim that the value fully internalizes every downstream proof-locality or caching externality of the current realization, and it remains subject to review during standardization.

Subsequent increments of an already-consumed non-zero key are not charged an EIP-2200-style nonzero-to-nonzero surcharge because keyed nonce progression is replay-protection bookkeeping analogous to legacy account nonce progression, not user contract storage. The first-use surcharge prices persistent state growth; later increments price only transaction execution and replay bookkeeping. This is an explicit calibration choice and may be revisited if witness-cost accounting becomes part of the gas model.

## Backwards Compatibility

Legacy account objects, non-frame transaction types, `eth_getTransactionCount`, and EIP-8141's existing `TXPARAM` indices are unchanged.

The frame-transaction payload layout changes only for `FRAME_TX_TYPE`.

`nonce_key == 0` preserves EIP-8141 replay behavior.

`TXPARAM(0x01)` continues to return the replay-protection sequence value, which equals the pre-state legacy nonce under zero-key and the per-domain sequence under non-zero keys.

`TXPARAM(0x0C)` provides explicit pre-state legacy-account-nonce access for verifier code that needs it.

Existing verifier code that implicitly treats `TXPARAM(0x01)` as the sender's legacy account nonce MUST be reviewed before use with non-zero-key frame transactions.

If this EIP activates after EIP-8141, pre-fork frame transactions and authorizations over the pre-fork EIP-8141 signature hash do not remain valid across the fork boundary.

## Security Considerations

### Threat model and guarantees

This EIP guarantees consensus-level uniqueness only for `(sender, nonce_key, nonce_seq)`. Equivalently, replay protection is scoped to the nonce domain selected by `(sender, nonce_key)`.

This EIP does not by itself guarantee confidentiality, global uniqueness of an application-level identifier across senders, successful downstream value delivery after payment approval, or freedom from ordinary shared-state conflicts between transactions using distinct keys.

`tx.nonce_seq == MAX_NONCE_SEQ` is invalid. A non-zero key may advance until `current_nonce_seq == MAX_NONCE_SEQ`, after which that key is exhausted and no further transaction on it is valid.

### Legacy nonce assumptions and application requirements

Under EIP-8141, `TXPARAM(0x01)` is naturally read as the sender's legacy account nonce. Under this EIP, `TXPARAM(0x01)` remains the replay-protection sequence value, which equals the legacy nonce only when `nonce_key == 0`.

Applications that require pre-state legacy-account-nonce semantics should read `TXPARAM(0x0C)`. Applications that require the legacy nonce domain specifically may additionally enforce `TXPARAM(0x0B) == 0`.

This EIP provides a counter, not a set. Applications that require strict single-use, such as nullifier schemes, must enforce a first-use invariant in `VERIFY`, for example by asserting `TXPARAM(0x01) == 0` and authenticating the expected `TXPARAM(0x0B)` value.

A verifier must not treat `TXPARAM(0x01) == 0` alone as a first-transaction or first-use authorization. For single-use keyed domains, the verifier should bind at least the selected sender, key, and sequence, and preferably the full canonical signature hash exposed by `TXPARAM(0x08)`.

Example single-use-key checks:

```text
assert TXPARAM(0x02) == expected_sender   # sender
assert TXPARAM(0x0B) == expected_key      # nonce_key
assert TXPARAM(0x01) == 0                 # first sequence in that key
# Prefer also authenticating TXPARAM(0x08), the canonical signature hash.
```

Different nonce keys remove only the replay-ordering dependency. Transactions on different keys may still conflict through sender balance, sender storage, payer balance, paymaster state, contract storage, account deployment, legacy-nonce advancement through `CREATE` or `CREATE2`, legacy-nonce-dependent validation through `TXPARAM(0x0C)`, or any other ordinary state dependency.

### CREATE address drift under non-zero keys

If a frame transaction with `nonce_key != 0` executes `CREATE` at `tx.sender`, the created contract address depends on the sender's legacy account nonce at execution time.

That legacy nonce is not part of `compute_sig_hash(tx)`. Therefore, another transaction that advances the sender's legacy nonce before inclusion can change the `CREATE` address without invalidating the keyed transaction.

Applications whose semantics depend on a `CREATE` address SHOULD use `CREATE2` or MUST authenticate the expected pre-state legacy nonce via `TXPARAM(0x0C)` and the expected creation result.

`CREATE2` address derivation does not depend on the creator's nonce, but `CREATE2` still changes the creator account's nonce according to ordinary EVM rules. Applications must account for that legacy-nonce side effect if later logic depends on it.

### Replay protection and malleability

`compute_sig_hash(tx)` commits to `chain_id`, `sender`, `nonce_key`, `nonce_seq`, all frame metadata, all non-`VERIFY` frame data, and every fee field. An authorization bound to it cannot be replayed across chains, senders, domains, sequences, fee configurations, or non-`VERIFY` frame payloads.

The preferred defense against transaction malleability is to bind the user's authorization directly to `TXPARAM(0x08)`. If the proof system cannot bind the full canonical hash, the verifier must explicitly authenticate every transaction field and later-frame field it depends on using EIP-8141's introspection opcodes.

At minimum, verifier logic should authenticate:

* `TXPARAM(0x02)` for sender;
* `TXPARAM(0x0B)` for `nonce_key`;
* `TXPARAM(0x01)` for `nonce_seq`;
* `TXPARAM(0x0A)` for the current frame index when frame position matters;
* `FRAMEPARAM` values for frame target, gas limit, mode, flags, data length, allowed scope, atomic-batch flag, and value;
* `FRAMEDATALOAD` or `FRAMEDATACOPY` for frame data it depends on.

It should also authenticate frame ordering, target, gas allocation, calldata commitment, payer-side fee ceilings, and any payer or paymaster terms it depends on.

If a verifier does not bind `TXPARAM(0x08)`, it must provide chain separation through its own authorization domain, because EIP-8141 does not expose `chain_id` as a separate `TXPARAM`.

### Nullifier-derived keys and observability

The nonce-key space is per sender. Applications that derive `nonce_key` from a per-use identifier must domain-separate by application identity within that sender's key space. Input fields should be fixed-width or length-delimited.

Example derivation:

```text
nonce_key = uint256(keccak256(
    "EIP-TBD:NONCE_KEY" ||
    uint256_to_be32(chain_id) ||
    sender ||
    app_id ||
    pool_id ||
    circuit_id ||
    per_use_identifier
))
```

Applications SHOULD reject or remap a derived `nonce_key` of zero, because zero selects the legacy nonce domain.

Privacy applications SHOULD use a domain-separated hash of the application nullifier, rather than a raw nullifier, unless revealing the raw nullifier in the transaction payload is explicitly intended.

For `nonce_key != 0`, the selected key is visible in the outer frame-transaction payload and is committed to by `compute_sig_hash(tx)`. This EIP therefore provides replay-domain separation, not confidentiality of key selection.

### Cancellation assumptions

A frame transaction with `nonce_key != 0` does not itself advance the legacy account nonce during payment approval. Advancing the sender's legacy account nonce with another transaction therefore does not, by itself, cancel or invalidate a pending non-zero-key frame transaction.

To cancel or replace a non-zero-key frame transaction, wallets should submit a replacement transaction with the same `(sender, nonce_key, nonce_seq)` under the relevant mempool or builder replacement rules, or submit another transaction on the same key that intentionally consumes the domain.

### EIP-7702 cancellation assumptions

For EIP-7702-delegated EOAs, the same cancellation distinction applies: a frame transaction with `nonce_key != 0` does not itself advance the legacy account nonce during payment approval.

However, deployment and `CREATE` or `CREATE2` executed at the delegated account address still can advance the legacy nonce. Wallets and offchain tooling should not rely on legacy "send another transaction to cancel" semantics unless the transaction being cancelled uses `nonce_key == 0` or the replacement targets the same keyed domain.

### State growth and proof locality

Each distinct `(sender, nonce_key != 0)` that has been consumed occupies one persistent slot in `NONCE_MANAGER_ADDRESS`'s storage trie. Entries are not deleted by this EIP.

Growth is priced by `KEYED_NONCE_FIRST_USE_GAS`. At `20000` gas per new slot, the maximum number of new keyed nonce slots in a block is bounded by the block gas limit divided by `20000`, before accounting for all other transaction costs.

Because all keyed nonces share one `storageRoot`, any keyed-nonce write invalidates cached proofs against `NONCE_MANAGER_ADDRESS` globally. This is a tradeoff of the current realization under the main execution-state commitment. Future stateless or partial-stateless optimizations may motivate an account-scoped nonce map or a dedicated execution-layer commitment. A later follow-up EIP may change the state representation without changing the keyed replay-domain semantics introduced here.

### Approval persistence

Per EIP-8141, approval effects persist through later-frame reverts. A single-use key consumed by `consume_nonce` is therefore spent even if a later frame responsible for value delivery reverts.

Nonce consumption that occurs during a successful payment-scoped `APPROVE` is also outside later `SENDER` atomic-batch rollback. Implementations must not journal keyed-nonce consumption as ordinary frame-local state that can be restored by a later frame revert.

Applications that consume single-use keys SHOULD minimize post-approval revert paths, for example by preferring pull escrow or other delivery patterns that avoid volatile external calls after consumption.

### Accidental transfers

Ordinary direct calls to `NONCE_MANAGER_ADDRESS` revert. However, the account may still receive ETH through force-send mechanisms where applicable. Any balance held at `NONCE_MANAGER_ADDRESS` is outside the scope of this EIP and is not recoverable by protocol logic defined here.

## Copyright

Copyright and related rights waived via [CC0](/LICENSE).