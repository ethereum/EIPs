---
eip: TBD
title: AA Transaction Type
description: A transaction type with batched calls, gas sponsorship, 2D nonces, and in-band code delegation
author: Chris Hunter (@chunter-cb) <chris.hunter@coinbase.com>
discussions-to: https://ethereum-magicians.org/t/eip-8130-account-abstraction-by-account-configurations/25952
status: Draft
type: Standards Track
category: Core
created: 2026-09-23
requires: 1559, 2718, 2929, 7623, 7702
---

## Abstract

This proposal introduces a new [EIP-2718](./eip-2718.md) transaction type (`AA_TX_TYPE`), split out of [EIP-8130](./eip-8130.md) as an independent transaction type with no Keystore dependency. It works for today's EOAs with native secp256k1 authentication, giving them call batching with phased atomicity, native value in calls, gas sponsorship with bound and open payers, two-dimensional nonces with a nonce-free mode, and in-band [EIP-7702](./eip-7702.md)-style code delegation. Its authenticator selector, actor-resolution hook, and reserved account-change types let other account models plug in without a new transaction type. EIP-8130 specifies one such integration, for the Keystore.

## Motivation

Wallets want to batch calls, have a third party pay gas, run independent transaction lanes in parallel, and set code delegation in the same transaction that uses it. Today these require an [ERC-4337](./eip-4337.md) bundler stack, several transactions, or a smart account for every user.

This proposal provides these capabilities as protocol features of one transaction type. Validation is fixed-cost: nodes verify a secp256k1 signature per role and check nonce, balance, and validity window, and never simulate wallet code to decide whether a transaction is valid.

The wire format is designed so that richer authentication can be added later without a new transaction type. The sender and payer authorization fields already carry an authenticator selector, account changes are a typed registry, and the actor-resolution step is a named hook. [EIP-8130](./eip-8130.md) (Keystore Accounts) specifies how the Keystore fills these in (**Keystore integration**). This document refers to it only where an extension point needs naming.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Constants

| Name | Value | Comment |
|------|-------|---------|
| `AA_TX_TYPE` | `0x79` | [EIP-2718](./eip-2718.md) transaction type |
| `AA_PAYER_TYPE` | `0x7A` | Magic byte for payer signature domain separation |
| `REPLAY_ID_TYPE` | `0x7901` | Magic prefix for `replay_id` domain separation |
| `AA_BASE_COST` | `15000` | Base intrinsic gas cost |
| `K1_AUTHENTICATOR` | `address(1)` | Selector for native secp256k1 authentication |
| `K1_AUTH_COST` | `5100` | Fixed secp256k1 authentication cost: ecrecover (3,000) plus one cold account-state read (2,100). See [Intrinsic Gas](#intrinsic-gas) |
| `TX_VALUE_COST` | `6000` | Per value-bearing call: the recipient balance write and the transfer log. Charged statically because `to` and `value` are signed fields |
| `DELEGATION_COST` | `4600` | Delegation indicator deposit (200 × 23 bytes) |
| `NONCE_MANAGER_ADDRESS` | `0x813000000000000000000000000000000000aa01` | Nonce Manager precompile |
| `NONCE_KEY_MAX` | `2^256 - 1` | Nonce-free mode |
| `TIMESTAMP_MS_THRESHOLD` | `100_000_000_000` | Unit-detection boundary for `valid_after`/`valid_before` |
| `REPLAY_BUFFER_CAPACITY` | chain parameter | Capacity of the nonce-free `replay_id` ring buffer (consensus) |
| `NONCE_FREE_EXPIRY_WINDOW` | chain parameter | Maximum `valid_before − now` for nonce-free transactions (consensus) |
| `MAX_AUTHENTICATION_GAS` | configurable (suggested 100,000) | Bound on payer-authentication gas metered outside `gas_limit` |

### Transaction Type

A new [EIP-2718](./eip-2718.md) transaction with type `AA_TX_TYPE`:

```
AA_TX_TYPE || rlp([
  chain_id,
  sender,             // empty = recover from sender_auth | 20-byte address
  nonce_key,          // uint256: nonce channel selector
  nonce_sequence,     // uint64: sequence number
  valid_after,        // uint64: Unix timestamp (ms or s, auto-detected); 0 = no lower bound
  valid_before,       // uint64: Unix timestamp (ms or s, auto-detected); 0 = no expiry
  max_priority_fee_per_gas,
  max_fee_per_gas,
  gas_limit,
  account_changes,    // typed entries | empty
  calls,              // [[call, ...], ...] | empty
  metadata,           // opaque attribution/annotation bytes | empty
  payer,              // empty = self-pay | 0x00 = open | 20-byte payer address
  sender_auth,
  payer_auth
])

call = rlp([to, value, data])   // to: address, value: uint256, data: bytes
```

#### Field Definitions

| Field | Description |
|-------|-------------|
| `chain_id` | Chain ID per [EIP-155](./eip-155.md) |
| `sender` | **Empty**: the sender is recovered from `sender_auth`. **20-byte address**: the named sender, authenticated by `sender_auth` (see [Authentication](#authentication)) |
| `nonce_key` | `uint256` nonce channel selector. `0` for standard sequential ordering, `1` through `NONCE_KEY_MAX - 1` for parallel channels, `NONCE_KEY_MAX` for nonce-free mode |
| `nonce_sequence` | `uint64` expected sequence number within `nonce_key`. Must match the current sequence for `(sender, nonce_key)`, which for `nonce_key == 0` is the account nonce (see [Nonces](#nonces)). Incremented after inclusion regardless of execution outcome. Must be `0` when `nonce_key == NONCE_KEY_MAX` |
| `valid_after` | `uint64` Unix timestamp, milliseconds or seconds (see [Timestamp Normalization](#timestamp-normalization)). After normalization, the transaction is invalid when `block.timestamp * 1000 < valid_after`. `0` means no lower bound. Many mempools will not hold a not-yet-active transaction and MAY reject one whose `valid_after` is in the future |
| `valid_before` | `uint64` Unix timestamp, milliseconds or seconds. After normalization, the transaction is invalid when `block.timestamp * 1000 > valid_before`. `0` means no expiry. Must be non-zero when `nonce_key == NONCE_KEY_MAX` |
| `max_priority_fee_per_gas` | Maximum priority fee per gas unit ([EIP-1559](./eip-1559.md)) |
| `max_fee_per_gas` | Maximum fee per gas unit ([EIP-1559](./eip-1559.md)) |
| `gas_limit` | Maximum gas for sender-intrinsic gas and call execution. Payer authentication is metered separately (see [Intrinsic Gas](#intrinsic-gas)) |
| `account_changes` | **Empty**: no account changes. **Non-empty**: array of typed entries (see [Account Changes](#account-changes)) |
| `calls` | **Empty**: no calls. **Non-empty**: array of call phases (see [Call Execution](#call-execution)) |
| `metadata` | **Empty**: no metadata. **Non-empty**: opaque attribution or annotation bytes (see [Transaction Metadata](#transaction-metadata)) |
| `payer` | **Empty**: sender pays. **`0x00`** (the single byte): open payer, recovered from `payer_auth`. **20-byte address**: that payer is required. See [Payer Modes](#payer-modes) |
| `sender_auth` | Sender authorization (see [Authentication](#authentication)) |
| `payer_auth` | Payer authorization. Empty for self-pay (see [Payer Modes](#payer-modes)) |

##### Timestamp Normalization

`valid_after` and `valid_before` MAY be expressed in either seconds or milliseconds. The unit is a fixed function of each value against `TIMESTAMP_MS_THRESHOLD`:

- a value below `TIMESTAMP_MS_THRESHOLD` is interpreted as seconds and normalized to milliseconds as `value * 1000`;
- a value at or above `TIMESTAMP_MS_THRESHOLD` is interpreted as milliseconds and used as-is;
- `0` means "no bound" and is not normalized.

A 64-bit Unix timestamp in seconds does not reach 10^11 until the year 5138, while any Unix timestamp in milliseconds has exceeded 10^11 since 1973, so the rule is unambiguous and consensus-safe. All validity-window comparisons in this specification operate on the normalized millisecond value.

The effective resolution of the window equals the chain's block-timestamp resolution. The millisecond form exists for off-chain clock compatibility and forward-compatibility with sub-second block times.

### Authentication

`sender_auth` and `payer_auth` share one shape rule. When the corresponding identity is **recovered** (not named in the transaction), the blob is a raw 65-byte ECDSA signature `r || s || v`. When the identity is **named** by a 20-byte address, the blob is `authenticator (20 bytes) || data`.

| `sender` | `sender_auth` | Resolved sender |
|----------|---------------|-----------------|
| empty | `r \|\| s \|\| v` (65 bytes) | ecrecover of the sender signature hash |
| 20-byte address | `K1_AUTHENTICATOR \|\| r \|\| s \|\| v` | `sender`; the recovered address MUST equal `sender` |

Without Keystore integration, `K1_AUTHENTICATOR` is the only accepted authenticator, and the recovered address MUST equal the named account. Any other authenticator selector or blob length is invalid. The shape is decided by whether the identity is named, never by blob length.

**Resolved actor.** Validation resolves an *actor* for each authorization: the identity that signed, and the authority it holds on the account. Without Keystore integration the resolved actor is always the account's own key, which holds full authority. Every authorization rule in this specification is written as a requirement on the resolved actor, so these rules are trivially satisfied without Keystore integration and become meaningful with it.

#### Signature Payload

Sender and payer use different type bytes for domain separation.

**Sender signature hash**, all fields through `payer`, excluding `sender_auth` and `payer_auth`:

```
keccak256(AA_TX_TYPE || rlp([
  chain_id, sender, nonce_key, nonce_sequence, valid_after, valid_before,
  max_priority_fee_per_gas, max_fee_per_gas, gas_limit,
  account_changes, calls, metadata,
  payer
]))
```

**Payer signature hash**:

```
keccak256(AA_PAYER_TYPE || rlp([
  chain_id, sender, nonce_key, nonce_sequence, valid_after, valid_before,
  max_priority_fee_per_gas, max_fee_per_gas, gas_limit,
  account_changes, calls, metadata,
  payer
]))
```

The `sender` field in the payer signature hash MUST be the resolved sender address. When `sender` is empty in the wire format, the recovered sender address MUST be substituted before computing this hash. This binds every payer signature, including an open-mode one, to one specific sender (see [Security Considerations](#security-considerations)). The `payer` field is the wire value (empty, `0x00`, or the address).

#### Payer Modes

| `payer` | `payer_auth` | Mode | Resolved payer |
|---------|--------------|------|----------------|
| empty | empty | Self-pay | `sender` |
| `0x00` | `r \|\| s \|\| v` (65 bytes) | Open | ecrecover of the payer signature hash |
| `sender` | `K1_AUTHENTICATOR \|\| r \|\| s \|\| v` | Self-pay, explicit | `sender`; the recovered address MUST equal `sender` |
| other address | `K1_AUTHENTICATOR \|\| r \|\| s \|\| v` | Sponsored | `payer`; the recovered address MUST equal `payer` |

In open mode the sender does not name a payer: any key willing to pay signs the payer hash, which already binds to the resolved sender and the full transaction body. Open mode is always secp256k1, because an identity that is recovered rather than named has no address to resolve another authenticator against.

The explicit self-pay form is redundant without Keystore integration. It is kept so that a dedicated gas key on the sender's own account (see [EIP-8130](./eip-8130.md)) is a widening of an existing shape rather than a new one.

### Nonces

`nonce_key` `0` uses the sender's account nonce, the same nonce used by other transaction types: `nonce_sequence` MUST equal it, and inclusion increments it. Keys `1` through `NONCE_KEY_MAX - 1` are held by a precompile at `NONCE_MANAGER_ADDRESS`, separate from the account nonce. The protocol reads and increments them directly during transaction processing; the precompile exposes a read-only `getNonce()` interface to the EVM.

| `nonce_key` Range | Name | Description |
|-------------------|------|-------------|
| `0` | Standard | The account nonce, shared with other transaction types. Sequential ordering, mempool default |
| `1` through `NONCE_KEY_MAX - 1` | User-defined | Parallel transaction channels defined by wallets |
| `NONCE_KEY_MAX` | Nonce-free | No nonce state read or incremented |

#### Nonce-Free Mode (`NONCE_KEY_MAX`)

When `nonce_key == NONCE_KEY_MAX`, the protocol neither reads nor increments a nonce counter; `nonce_sequence` MUST be `0` and `valid_before` MUST be non-zero. Replay protection uses `replay_id` deduplication held in a fixed-capacity circular buffer that is consensus state: a `seen` map (`replay_id → valid_before`) of live entries plus a ring that evicts the oldest entry once elapsed. A still-live `replay_id` is rejected, and a buffer full of still-live entries rejects the transaction. `REPLAY_BUFFER_CAPACITY` MUST be at least `peak accepted nonce-free throughput × NONCE_FREE_EXPIRY_WINDOW` so an entry always elapses before its ring slot is reused. Entries are ephemeral, so there is no permanent state growth.

##### Replay Identifier

```
replay_id = keccak256(REPLAY_ID_TYPE || rlp([
  chain_id, resolved_sender, valid_after, valid_before,
  account_changes, calls, metadata,
  payer
]))
```

`nonce_key` and `nonce_sequence` are omitted because they are constant in nonce-free mode. `resolved_sender` keeps the identifier unique per sender when `sender` is empty. `replay_id` excludes the fee fields and `gas_limit`, so a fee bump does not change identity, and excludes `sender_auth` and `payer_auth`, which are non-deterministic and can be re-signed without changing the logical transaction. It includes the `payer` wire field, so retargeting a transaction at a different named payer is a new logical transaction. In open mode two submissions of the same body with different payers share a `replay_id`.

The full transaction hash MUST NOT be used for nonce-free deduplication or replacement.

##### Mempool Replacement

- **Standard and 2D transactions** (`nonce_key != NONCE_KEY_MAX`): two pending transactions sharing `(sender, nonce_key, nonce_sequence)` are replacement candidates. For `nonce_key == 0` the sequence is the account nonce, so a pending transaction of another type from the same sender with the same nonce is also a replacement candidate.
- **Nonce-free transactions**: two pending transactions from the same `sender` with the same `replay_id` are replacement candidates, and block builders MUST NOT include two transactions with the same `(sender, replay_id)` in one block.

In both modes a replacement MUST increase both `max_fee_per_gas` and `max_priority_fee_per_gas` by at least the node's configured minimum bump and MUST be independently valid, including a fresh `payer_auth` when sponsored, since `payer_auth` commits to the fee fields and `gas_limit`.

### Account Changes

`account_changes` is an array of typed entries. Each entry is `rlp([type, ...])`.

| Type | Name | Defined by |
|------|------|------------|
| `0x00` | Reserved | Future entry types |
| `0x01` | Delegation | This specification |
| `0x02`+ | Reserved | Future entry types |

A transaction containing an entry type not accepted on the chain is invalid. At most one delegation entry is allowed.

#### Delegation Entry

A delegation entry sets [EIP-7702](./eip-7702.md)-style code delegation for the sender, replacing the need for an `authorization_list`. It is authorized by `sender_auth`; no separate signature is required.

```
rlp([
  0x01,               // type: delegation
  target              // address: delegate to this contract, or address(0) to clear
])
```

Rules:

- At most one delegation entry per transaction.
- The sender MUST have been authenticated through the native secp256k1 path (`sender` empty, or `K1_AUTHENTICATOR`) with the resolved actor being the sender's own key with full authority.
- `code(sender)` MUST be empty or begin with the delegation designator `0xef0100`. Non-delegation bytecode is never replaced.
- `target != address(0)` sets `code(sender) = 0xef0100 || target`. `target == address(0)` clears the indicator and resets the code hash to the empty code hash.

#### Delegation Indicator

An account is delegated when its code is exactly `0xef0100 || target`. All code-executing operations targeting a delegated account load code from `target`. Because this transaction type depends on the indicator directly, it MUST be supported on chains that adopt this proposal even where standalone [EIP-7702](./eip-7702.md) transactions are not enabled. This proposal never delegates an account automatically.

### Transaction Metadata

`metadata` is optional opaque bytes for attribution or annotation, for example builder or app attribution, a payment reference, or a commitment to off-chain data. It is covered by both signature payloads, charged through `tx_payload_cost`, and does not affect validation or execution.

### Call Execution

The protocol dispatches calls directly from `sender`:

| Parameter | Value |
|-----------|-------|
| caller / `msg.sender` at target | `sender` |
| `tx.origin` | `sender` |
| `to` | `call.to` |
| `msg.value` | `call.value` |
| `data` | `call.data` |

`call.value` is transferred from `sender` to `call.to` as part of the call frame and is reverted with it. If `sender` cannot cover `call.value` when the call runs, the call fails as a `CALL` with insufficient balance would, and its phase reverts. Block validity does not depend on the sender's balance covering call values; mempools check it at entry (see [Mempool Acceptance](#mempool-acceptance)). If `call.value > 0` and `call.to` does not exist, the account-creation charge applies after the balance check and before the callee's code runs. It is charged at runtime because whether `call.to` exists is only known when the call executes. A non-zero transfer to an address other than `sender` emits the transfer log of [EIP-7708](./eip-7708.md) where that EIP is active.

#### Call Phases

`calls` is an ordered array of **phases**, each an ordered array of calls (`[[call, ...], [call, ...]]`). Phases execute in order from a single gas pool. Within a phase, calls are atomic: if any call reverts, all state changes of that phase are discarded and remaining phases are skipped. Completed phases persist.

Common patterns:

- **Simple call**: `[[call]]`
- **Atomic batch**: `[[call_a, call_b, call_c]]`
- **Sponsor + user**: `[[sponsor_payment], [user_action_a, user_action_b]]`; the sponsor payment commits in phase 0 and can be a plain value transfer

### Intrinsic Gas

```
intrinsic_gas = AA_BASE_COST + tx_payload_cost + nonce_key_cost + value_transfer_cost
              + account_changes_cost + sender_auth_cost + payer_auth_cost

sender_intrinsic_gas = intrinsic_gas - payer_auth_cost
execution_gas_available = gas_limit - sender_intrinsic_gas
effective_gas_limit = gas_limit + payer_gas_reserve
```

Sender-intrinsic gas is bounded by `gas_limit`. `payer_auth_cost` is metered separately and charged to the payer on top of `gas_limit`: `payer_auth` is excluded from both signature hashes and chosen by the payer, so if it drew from `gas_limit` a payer could starve `calls`.

`payer_gas_reserve` is `payer_floor` from the calldata floor below: `0` for self-pay (`payer` empty), otherwise fixed by the authenticator and the serialized `payer_auth` bytes. A transaction whose `payer_gas_reserve` exceeds `MAX_AUTHENTICATION_GAS` is rejected. The gas charged never exceeds `effective_gas_limit`.

| Component | Value |
|-----------|-------|
| `AA_BASE_COST` | 15,000: transaction decoding, sender resolution, nonce-mode dispatch, payer settlement, receipt assembly |
| `tx_payload_cost` | 16 gas per non-zero byte and 4 per zero byte ([EIP-2028](./eip-2028.md)) over the RLP-serialized transaction excluding `payer_auth`, subject to the calldata floor below |
| `nonce_key_cost` | `0`: 0 (account nonce, covered by `AA_BASE_COST`). `NONCE_KEY_MAX`: 13,000 (ring-buffer replay state). Otherwise 22,100 for first use of a `nonce_key`, 5,000 for an existing key |
| `value_transfer_cost` | `TX_VALUE_COST` for each call with `value > 0` and `to != sender` |
| `account_changes_cost` | `DELEGATION_COST` for a delegation entry, else 0 |
| `sender_auth_cost` | `K1_AUTH_COST` |
| `payer_auth_cost` | 0 for self-pay (`payer` empty). Otherwise `K1_AUTH_COST + payer_data_cost`, where `payer_data_cost` is 16 gas per non-zero byte and 4 per zero byte over the serialized `payer_auth`, subject to the calldata floor below |

`K1_AUTH_COST` includes one cold account-state read that validation without Keystore integration does not perform. It is charged regardless so that secp256k1 transactions cost the same gas before and after Keystore integration activates (see [Rationale](#charging-the-keystore-read-before-the-keystore)).

**Calldata floor.** As in [EIP-7623](./eip-7623.md), the floor applies to the transaction as a whole, including the `payer_auth` bytes. Let `payload_tokens = zero_bytes + 4 * nonzero_bytes` over the bytes `tx_payload_cost` covers, `payer_tokens` the same count over the serialized `payer_auth` (`0` for self-pay), and `execution_gas_used` the gas used by `calls`:

```
sender_floor = (sender_intrinsic_gas - tx_payload_cost) + 10 * payload_tokens
payer_floor  = (payer_auth_cost - payer_data_cost) + 10 * payer_tokens

gas_used = max(
    sender_intrinsic_gas + execution_gas_used + payer_auth_cost,
    sender_floor + payer_floor
)
```

A transaction whose `gas_limit` is below `sender_floor` is invalid. `payer_floor` is `0` for self-pay. Because `payer_gas_reserve == payer_floor >= payer_auth_cost`, both branches stay within `effective_gas_limit`.

**Gas-schedule profiles.** On a base layer the values above are protocol constants, changeable only through a hard fork (**L1 profile**). An L2 or other high-throughput chain MAY adopt a different schedule fixed under its own consensus (**L2 profile**), but MUST keep the formula's structure and MUST NOT set the calldata-floor rate below `4` or drop the floor.

### Fees

Fees follow [EIP-1559](./eip-1559.md), applied over `effective_gas_limit`. With `base_fee` the block's base fee per gas:

```
priority_fee_per_gas = min(max_priority_fee_per_gas, max_fee_per_gas - base_fee)
effective_gas_price  = base_fee + priority_fee_per_gas
```

The transaction is invalid if `max_fee_per_gas < base_fee` or if the payer's balance is below `max_fee_per_gas * effective_gas_limit`. `GASPRICE` returns `effective_gas_price`.

Before execution the payer is precharged `effective_gas_limit * effective_gas_price`. After execution, with `gas_used` as defined in [Intrinsic Gas](#intrinsic-gas), the payer is charged `gas_used * effective_gas_price` and refunded the difference. `gas_used * priority_fee_per_gas` goes to the block's fee recipient and `gas_used * base_fee` is burned.

### Validation Flow

#### Mempool Acceptance

1. Parse and structurally validate the transaction: accepted `account_changes` entry types and counts, and `sender_auth` / `payer_auth` shapes per [Authentication](#authentication).
2. Resolve the sender and its actor.
3. If a delegation entry is present, verify `code(sender)` is empty or a delegation indicator, and that the resolved actor may delegate.
4. Resolve the payer and its actor per [Payer Modes](#payer-modes). Reject if `payer_gas_reserve > MAX_AUTHENTICATION_GAS`.
5. Verify the validity window (after normalization), that `gas_limit` covers `sender_floor`, that `max_fee_per_gas` covers the current base fee, and that the payer's balance covers `max_fee_per_gas * effective_gas_limit` (see [Fees](#fees)). Also verify that the sender's balance covers the sum of `call.value` over all calls, plus `max_fee_per_gas * effective_gas_limit` when the sender is the payer.
6. Verify the nonce: `nonce_sequence` equals the sender's account nonce for key `0`, or `current_sequence(sender, nonce_key)` for keys `1` through `NONCE_KEY_MAX - 1`; for `NONCE_KEY_MAX`, require `nonce_sequence == 0`, a non-zero `valid_before` no farther out than `NONCE_FREE_EXPIRY_WINDOW`, and a fresh `replay_id`.
7. Apply per-payer pending limits and the [Mempool Replacement](#mempool-replacement) rules.

Nodes MAY reject a transaction whose `valid_before` is too near to be reliably included, and MAY reject rather than hold one whose `valid_after` is not yet active.

#### Block Execution

1. Check [Fees](#fees) validity and precharge the payer.
2. If `nonce_key == 0`, increment the sender's account nonce. If `nonce_key` is `1` through `NONCE_KEY_MAX - 1`, increment the Nonce Manager sequence for `(sender, nonce_key)`. If `nonce_key == NONCE_KEY_MAX`, record `replay_id`.
3. Apply `account_changes` in order.
4. Execute `calls` per [Call Execution](#call-execution).

Settlement charges the payer for `gas_used` per [Fees](#fees): sender-intrinsic gas plus executed `calls` (together bounded by `gas_limit`) plus `payer_auth_cost`, subject to the calldata floor. It refunds the rest of the precharge. Payer authentication gas is never refundable.

### Receipts

The [EIP-2718](./eip-2718.md) `ReceiptPayload` for this transaction type is `rlp([status, cumulative_gas_used, logs_bloom, logs])`, as for [EIP-1559](./eip-1559.md) receipts. `status` is `1` if every phase succeeded (or `calls` was empty) and `0` otherwise. Logs from reverted phases are discarded with their state changes.

`status == 0` does not imply no state change: committed earlier phases, applied `account_changes`, nonce consumption, and fee payment persist.

### RPC Extensions

**`eth_getTransactionCount`**: extended with an optional `nonceKey` parameter (`uint256`). Omitted or `0` returns the account nonce; other keys read the Nonce Manager.

**`eth_getTransactionReceipt`**: in addition to the standard fields, receipts for this type include:

- `payer` (address): the resolved payer (`sender` for self-pay, the named payer, or the payer recovered in open mode).
- `phaseStatuses` (uint8[]): one entry per phase, `0x01` (success) or `0x00` (reverted). Phases after a revert are not executed and are reported as `0x00`. Empty if `calls` was empty.
- `gasUsed` is `gas_used` from [Intrinsic Gas](#intrinsic-gas), including payer authentication.

**`eth_estimateGas`** / **`eth_call`**: accept the transaction's fields (`sender`, `nonceKey`, `accountChanges`, `calls`, `validAfter`, `validBefore`, `metadata`, `payer`, `senderAuth`, `payerAuth`) alongside the standard request object, and execute the request as an `AA_TX_TYPE` transaction. The sender is taken from `sender` or `from`; if both are present they MUST be equal. Signatures are never verified.

- **Default: secp256k1.** When `senderAuth` or `payerAuth` is omitted, the node assumes the role is authenticated by the account's own secp256k1 key with full authority. It prices a placeholder of the shape [Authentication](#authentication) requires: a 65-byte signature when the identity is recovered, `K1_AUTHENTICATOR` followed by 65 bytes when it is named. `payer` omitted means self-pay, with no payer placeholder.
- **Supplied blob.** When `senderAuth` or `payerAuth` is supplied, its shape and length are used for pricing and its contents are ignored.
- **Placeholder pricing.** Placeholder and supplied auth bytes are priced as non-zero bytes, so a zero-filled dummy never underestimates.

Other authentication mechanisms, such as the Keystore, define how requests select them (see [EIP-8130](./eip-8130.md)).

## Rationale

### Why Delegation via Account Changes?

[EIP-7702](./eip-7702.md) introduced `authorization_list` with a separate signature per authorization. Here delegation is authorized by `sender_auth`, in the same nonce stream as the calls that use the new code. It is restricted to the native secp256k1 path so it stays portable to chains that only support EIP-7702.

### Why a Metadata Field?

Attribution and annotation data traditionally rides as a suffix on `tx.input`. The structured `calls` array has no such location, so `metadata` gives it a signed home.

### Charging the Keystore Read Before the Keystore

`K1_AUTH_COST` includes the account-state read that Keystore integration performs for a secp256k1 self-actor. Charging it before that integration activates means signed `gas_limit` values and wallet estimates do not change when it does, so accounts without Keystore state see identical validity, execution, and gas with or without the integration.

## Backwards Compatibility

No breaking changes. Existing transaction types and accounts are unaffected. `nonce_key` `0` uses the account nonce, so this type and other transaction types from one account share one sequence at that key; other keys live in the Nonce Manager. Adoption is opt-in: an account sends this transaction type or does not. No account is delegated automatically. Activating Keystore integration does not change validity, execution results, or gas for accounts without Keystore state.

## Reference Implementation

### INonceManager (Precompile)

```solidity
interface INonceManager {
    function getNonce(address account, uint256 nonceKey) external view returns (uint64);
}
```

Read-only. For `nonceKey == 0` it returns the account nonce. Gas is a base cost plus a cold (2,100) or warm (100) read per [EIP-2929](./eip-2929.md) access rules.

## Security Considerations

**Replay Protection.** Transactions include `chain_id`, a 2D nonce, and a validity window. For `nonce_key != NONCE_KEY_MAX`, inclusion increments `(sender, nonce_key)`, so each `(sender, nonce_key, nonce_sequence)` is included at most once. Nonce-free transactions rely on a short `valid_before` bound and `replay_id` deduplication. The transaction hash must not be used for nonce-free deduplication: fee bumps, re-signed `payer_auth`, and randomized or malleable ECDSA signatures all change it without changing the logical transaction, and all resolve to the same `replay_id`. The validity window cannot be extended through replacement, because `valid_after` and `valid_before` are part of `replay_id`.

**Payer Security.** `AA_TX_TYPE` and `AA_PAYER_TYPE` domain separation prevents reuse of signatures between roles. A bound payer is committed in the sender hash. The payer's exposure is bounded by `max_fee_per_gas * effective_gas_limit`. Payer authentication is metered outside `gas_limit`, so the payer's choice of `payer_auth` cannot affect execution.

**Cross-sender Payer Replay.** The payer hash substitutes the resolved sender. Without this, two EOAs that construct identical transaction bodies would produce identical payer hashes, letting one reuse a payer signature issued for the other. This matters most in open mode, where the sender does not name the payer: the substitution is what binds an open-mode payer signature to one sender.

**Open Payer Replacement.** In open mode a third party that sees a pending transaction may attach its own `payer_auth` and submit it as a replacement. The body and sender are unchanged, and the replacement must pay the minimum fee bump, so the only effect is who pays.

**Value in Calls.** Value transfers are executed as part of each call frame and revert with their phase. `status == 0` does not mean no value moved: transfers in committed earlier phases persist.

**Delegation.** Delegation requires native secp256k1 authentication as the account's own key, never replaces non-delegation bytecode, and is authorized by the transaction's own signature in the same nonce stream as the calls.

**Keystore Integration.** Security properties of actors, scopes, and policies, and the checks the Keystore integration adds to this transaction type, are specified in [EIP-8130](./eip-8130.md).

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
