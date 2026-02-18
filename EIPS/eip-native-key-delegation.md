---
eip: XXXX
title: Native Key Delegation for EOAs
description: Allows EOAs to permanently replace ECDSA with alternative signature schemes via an extended delegation designator.
author: Gregory Markou (@GregTheGreek) <gregorymarkou@gmail.com>, James Prestwich (@prestwich) <james@prestwi.ch>
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-02-17
requires: 2, 2718, 2929, 3541, 3607, 4844, 7702
---

## Abstract

This EIP extends the delegation designator system introduced by
[EIP-7702](./eip-7702.md) to support **native key delegation** — permanently
converting an EOA's authentication from ECDSA over secp256k1 to an alternative
signature scheme. A new code prefix `0xef0101` designates an account whose
authentication key is an Ed25519 public key embedded directly in the account's
code field. Once set, the original ECDSA key is rendered permanently inert. A
single new transaction type supports both ECDSA-signed key migration and
Ed25519-authenticated transaction origination.

Accounts may be created without any party ever possessing the ECDSA private
key, using a crafted-signature technique analogous to Nick's method for keyless
contract deployment.

## Motivation

EIP-7702 brought code delegation to EOAs but retained ECDSA over secp256k1 as
the sole native authentication mechanism. This constrains the ecosystem to a
single signature scheme with known limitations:

- **Quantum vulnerability.** secp256k1 ECDSA is vulnerable to quantum
  attacks. Ed25519 shares this property, but the framework established here
  generalizes to post-quantum schemes via future `0xef01XX` designators.
- **Hardware ecosystem mismatch.** Secure enclaves and hardware security
  modules increasingly ship with native Ed25519 (or Ed448, secp256r1)
  support. Forcing ECDSA introduces bridging complexity and enlarges the
  trusted computing base.
- **Smart contract wallet overhead.** Smart contract wallets and EIP-7702 code delegation
  can achieve alternative authentication today, but at the cost of EVM
  execution for every transaction validation. Native key delegation moves
  signature verification into the protocol, eliminating per-transaction
  contract overhead.
- **Provably rootless accounts.** The crafted-signature creation path
  produces accounts where the ECDSA private key *never existed*, providing a
  cryptographic guarantee — not merely a procedural one — that no backdoor
  key can override the installed scheme.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in RFC 2119 and RFC 8174.

### Constants

| Name | Value | Description |
|------|-------|-------------|
| `NATIVE_KEY_TX_TYPE` | `Bytes1(0x05)` | Transaction type for native key operations |
| `NATIVE_KEY_MAGIC` | `0x07` | Domain separator for native key authorization signing |
| `ED25519_DESIGNATION` | `0xef0101` | 3-byte code prefix for Ed25519 native key accounts |
| `PER_NATIVE_AUTH_BASE_COST` | `12500` | Gas charged per native key authorization tuple |
| `PER_EMPTY_ACCOUNT_COST` | `25000` | Additional gas if the authority account was previously empty |
| `ED25519_VERIFY_COST` | `3450` | Intrinsic gas for Ed25519 signature verification |

### Delegation Designator Space

EIP-7702 defines the code prefix `0xef0100` for code delegation. This EIP
extends the `0xef01XX` namespace:

| Prefix | Code length | Semantics |
|--------|-------------|-----------|
| `0xef0100` | 23 bytes | Code delegation ([EIP-7702](./eip-7702.md)) |
| `0xef0101` | 35 bytes | Ed25519 native key (this EIP) |
| `0xef0102`–`0xef01ff` | varies | Reserved for future signature schemes |

An account whose code is exactly `0xef0101 || pubkey` (35 bytes) is a
**native-key account**. The 32-byte `pubkey` is an Ed25519 public key used for
all subsequent transaction authentication.

### Native Key Transaction (Type `0x05`)

A new [EIP-2718](./eip-2718.md) transaction type serves both native key
migration and native-key-authenticated transaction origination:

```
0x05 || rlp([
    chain_id,
    nonce,
    max_priority_fee_per_gas,
    max_fee_per_gas,
    gas_limit,
    to,
    value,
    data,
    access_list,
    native_key_authorization_list,
    sender,
    signature
])
```

The fields `chain_id`, `nonce`, `max_priority_fee_per_gas`, `max_fee_per_gas`,
`gas_limit`, `to`, `value`, `data`, and `access_list` follow the same semantics
as [EIP-4844](./eip-4844.md). A null `to` is not valid.

| Field | Type | Description |
|-------|------|-------------|
| `native_key_authorization_list` | `list` | Authorization tuples for setting native keys (may be empty) |
| `sender` | `bytes` | Empty for ECDSA mode, or 20-byte address for Ed25519 mode |
| `signature` | `bytes` | 65-byte ECDSA signature or 64-byte Ed25519 signature |

The `sender` field determines the transaction's authentication mode:

- **ECDSA mode** (`sender` is empty): The transaction is signed with ECDSA.
  `signature` is 65 bytes, encoding `y_parity || r || s`. The transaction
  sender is recovered via `ecrecover`. Any EOA may submit this transaction;
  the submitter need not be the authority whose key is being set.
- **Ed25519 mode** (`sender` is 20 bytes): The transaction is signed with
  Ed25519 by the native-key account at `sender`. `signature` is 64 bytes.

The signing payload for both modes is:

```
tx_hash = keccak256(NATIVE_KEY_TX_TYPE || rlp([
    chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas,
    gas_limit, to, value, data, access_list,
    native_key_authorization_list, sender
]))
```

In ECDSA mode, `sender` is empty in the payload, so the signing domain is
distinct from Ed25519 mode where `sender` is 20 bytes.

#### Native Key Authorization Tuple

Each entry in `native_key_authorization_list` has the form:

```
auth = [chain_id, pubkey, nonce, y_parity, r, s]
```

| Field | Type | Description |
|-------|------|-------------|
| `chain_id` | `uint256` | Target chain ID, or `0` for any chain |
| `pubkey` | `bytes32` | Ed25519 public key to install |
| `nonce` | `uint64` | Current nonce of the authority account |
| `y_parity` | `uint8` | ECDSA recovery parameter |
| `r` | `uint256` | ECDSA signature component |
| `s` | `uint256` | ECDSA signature component |

The authorization message is:

```
msg_hash = keccak256(NATIVE_KEY_MAGIC || rlp([chain_id, pubkey, nonce]))
```

The **authority** is recovered via `ecrecover(msg_hash, y_parity, r, s)`.

#### Transaction Validation

If `sender` is empty (ECDSA mode):

1. Verify `signature` is exactly 65 bytes. Otherwise the transaction is
   invalid.
2. Parse `y_parity = signature[0]`, `r = signature[1..33]`,
   `s = signature[33..65]`.
3. Recover the transaction sender via `ecrecover(tx_hash, y_parity, r, s)`.
   If recovery fails, the transaction is invalid.
4. Proceed with standard sender validation (nonce, balance, etc.).

If `sender` is 20 bytes (Ed25519 mode):

1. Verify `sender`'s code begins with `ED25519_DESIGNATION` and is exactly
   35 bytes. Otherwise the transaction is invalid.
2. Add `sender` to `accessed_addresses` (as defined by [EIP-2929](./eip-2929.md)).
3. Extract `pubkey = sender.code[3..35]`.
4. Verify `Ed25519_Verify(pubkey, tx_hash, signature)` using cofactorless
   verification per [RFC 8032 §5.1.7](https://www.rfc-editor.org/rfc/rfc8032#section-5.1.7),
   with the following additional constraints:
   - The encoded point `pubkey` MUST be a canonical encoding of a point on
     Ed25519. Non-canonical encodings MUST be rejected.
   - The scalar `s` component of `signature` MUST satisfy `s < L`, where `L`
     is the Ed25519 group order (`2^252 + 27742317777372353535851937790883648493`).
     Signatures with `s >= L` MUST be rejected.
   - Points of small order (order 1, 2, 4, or 8) MUST NOT be accepted as
     `pubkey`.
   - Verification MUST NOT use cofactor multiplication. The verification
     equation is `[8][s]B = [8]R + [8][k]A`, NOT `[s]B = R + [k]A`.
   If verification fails, the transaction is invalid.
5. Verify `nonce == sender.nonce`. Otherwise the transaction is invalid.
6. Proceed with standard transaction execution.

`ED25519_VERIFY_COST` is added to the transaction's intrinsic gas cost in
Ed25519 mode, replacing the implicit ecrecover cost.

If `sender` is any other length, the transaction is invalid.

#### Authorization List Processing

The `native_key_authorization_list` is processed before transaction execution
but after the sender's nonce is incremented, mirroring EIP-7702 semantics. The
list MAY be empty.

For each tuple, in order:

1. Verify `chain_id` is `0` or equals the current chain ID. Otherwise skip.
2. Verify `pubkey` is exactly 32 bytes. Otherwise skip.
3. Verify `nonce < 2^64 - 1`. Otherwise skip.
4. Verify `s <= secp256k1n / 2`, as per [EIP-2](./eip-2.md). Otherwise skip.
5. Set `msg_hash = keccak256(NATIVE_KEY_MAGIC || rlp([chain_id, pubkey, nonce]))`.
6. Set `authority = ecrecover(msg_hash, y_parity, r, s)`. If recovery fails, skip.
7. Verify `authority`'s code is empty, begins with `0xef0100`, or begins
   with `0xef0101`. Otherwise skip.
8. Verify `authority`'s nonce equals `nonce`. Otherwise skip.
9. Add `authority` to `accessed_addresses` (as defined by [EIP-2929](./eip-2929.md)).
10. Increment `authority`'s nonce by one.
11. Set `authority`'s code to `0xef0101 || pubkey`.
12. Charge `PER_NATIVE_AUTH_BASE_COST` gas, plus `PER_EMPTY_ACCOUNT_COST` if
    the account was previously empty.

If multiple tuples target the same authority, the last valid tuple wins.

### ECDSA Rejection Rule

Once an account's code is set to `0xef0101 || pubkey`:

- ECDSA-signed transactions (Types 0x00–0x04, and Type 0x05 in ECDSA mode)
  whose recovered sender is a native-key account MUST be rejected during
  transaction validation.
- EIP-7702 authorization tuples whose recovered authority is a native-key
  account MUST be rejected.
- Native key authorization tuples whose recovered authority is a native-key
  account MUST be rejected.

The account is permanently governed by its embedded Ed25519 key. The ECDSA
private key — whether unknown, destroyed, or still held — has no protocol
significance.

### Keyless Account Creation (Crafted-Signature Method)

An account MAY be created where **no party has ever possessed the ECDSA
private key**:

1. The creator generates an Ed25519 keypair `(sk, pk)`.
2. The creator computes the authorization message for a fresh (nonce-0)
   account:
   ```
   msg_hash = keccak256(NATIVE_KEY_MAGIC || rlp([chain_id, pk, 0]))
   ```
3. The creator selects `r` as the x-coordinate of a secp256k1 curve point
   whose discrete logarithm is unknown (e.g., output of hash-to-curve on a
   public seed), and selects an arbitrary non-zero `s`.
4. The creator computes `authority = ecrecover(msg_hash, y_parity, r, s)`.
   This yields a deterministic address for which no party knows the private
   key.
5. Any party funds `authority` with ETH.
6. Any party submits a Type `0x05` transaction (ECDSA mode) containing the
   authorization tuple `[chain_id, pk, 0, y_parity, r, s]`.

The account at `authority` is now authenticated exclusively by the Ed25519 key
`pk`. Because deriving the ECDSA private key from the recovered public key
requires solving the Elliptic Curve Discrete Logarithm Problem, the account is
**provably rootless** — no ECDSA backdoor exists.

The `authority` address is deterministic given `(chain_id, pk, r, s,
y_parity)`, enabling counterfactual address computation and pre-funding before
the Type `0x05` transaction is submitted.

**Recommended construction for `r`:** Compute `r_seed = keccak256("nkd-v1" ||
chain_id || pk)`, then find the smallest valid secp256k1 x-coordinate ≥
`r_seed mod p`. Set `s = 1`. This makes the derivation publicly verifiable:
anyone can reproduce the computation and confirm that no trapdoor was used.

#### Transaction Origination

This EIP extends the [EIP-3607](./eip-3607.md) exception established by
EIP-7702: accounts whose code begins with `0xef0101` MAY originate
transactions (via Type `0x05` in Ed25519 mode), in addition to accounts whose
code begins with `0xef0100`.

### Key Rotation

Key rotation for native-key accounts — replacing the embedded Ed25519 public
key with a new one — requires a mechanism for mutating the account's code field
from within an authenticated transaction. This involves novel EVM semantics (a
precompile or system contract that writes to the caller's code) and is
specified in a companion EIP.

This EIP guarantees that key rotation is possible: the `0xef0101` prefix is
recognized by the processing rules (step 7), so a native-key account MAY be
the target of a new native key authorization tuple. A companion EIP will
define a practical rotation mechanism that does not require re-exposing the
original ECDSA key.

### Interaction with EIP-7702

| From | To | Permitted? |
|------|----|-----------|
| Empty / EOA | `0xef0101` (native key) | Yes, via Type `0x05` authorization list |
| `0xef0100` (code delegation) | `0xef0101` (native key) | Yes, via Type `0x05` authorization list (ECDSA-signed) |
| `0xef0101` (native key) | `0xef0100` (code delegation) | **No.** ECDSA signatures are permanently rejected. |
| `0xef0101` (native key) | `0xef0101` (new key) | Yes, via companion key rotation EIP |

#### Code-Reading Operations

| Opcode | Behavior for `0xef0101` accounts |
|--------|----------------------------------|
| `EXTCODESIZE` (`0x3b`) | Returns `35` |
| `EXTCODECOPY` (`0x3c`) | Copies from the 35-byte designator |
| `EXTCODEHASH` (`0x3f`) | Returns keccak256 of the 35-byte designator |
| `CODESIZE` (`0x38`) | Within the account's own context: `35` |
| `CODECOPY` (`0x39`) | Within the account's own context: copies the designator |

#### Code-Execution Operations

`CALL` (`0xf1`), `CALLCODE` (`0xf2`), `DELEGATECALL` (`0xf4`), and
`STATICCALL` (`0xfa`) targeting a native-key account execute no code. The
account behaves as an EOA for execution purposes.

## Rationale

### Permanent Delegation

Native key delegation is permanent. Once an account's code is set to
`0xef0101 || pubkey`, the ECDSA key is dead — the protocol will never accept
it again. This is a deliberate and safe design choice for two reasons.

First, permanence is safe because the new key is the root key. The holder of
the installed Ed25519 private key can always rotate to a new key (via a
companion key rotation EIP). There is no loss of authority: the account
owner retains full, exclusive control through the current native key. Reverting
to ECDSA would only re-introduce a weaker authentication scheme with no
benefit.

Second, permanence eliminates the entire class of "dormant key" attacks. If
the conversion were revocable, a leaked or quantum-broken ECDSA key could
always hijack the account by reverting the delegation. Irreversibility means
there is no second key to protect, no fallback to worry about, and no ambiguity
about which key controls the account. For crafted-signature accounts this is a
mathematical guarantee (the ECDSA key never existed). For ephemeral-key
accounts it is a protocol-enforced guarantee independent of key destruction
procedures.

The permanence also simplifies the security model: validators need only check
the account's code prefix to determine the authentication scheme. There is no
need to track historical key states or handle mixed-mode authentication.

### Embedded Keys vs. Contract Delegation

EIP-7702 delegates to code at an address. Native key delegation embeds the key
directly in the account's code field. This is the correct design because:

1. **No code execution is involved.** The key authenticates transactions at
   the protocol level. There is no contract to delegate to.
2. **Self-contained verification.** Validators verify signatures without
   loading external code or crossing the EVM boundary.
3. **No delegation chain concerns.** EIP-7702 must handle chains of
   `ef0100` pointers. Native key accounts are terminal — no indirection.
4. **Minimal storage.** 35 bytes per account vs. a full contract deployment.

### Native-Key Accounts as Pure EOAs

Native-key accounts intentionally have no code execution capability. They
cannot use EIP-7702 code delegation for batching, sponsorship, or privilege
de-escalation. This is a deliberate scope constraint, not an oversight.

The purpose of this EIP is to replace the authentication primitive, not to
replicate the full EIP-7702 feature set. Combining native key authentication
with code delegation is a valid goal but introduces significant complexity:
the account's code field would need to encode both a delegation target and an
authentication key, and the interaction between the two must be carefully
specified. A future EIP MAY define a combined designator (e.g., one that
embeds both a pubkey and a delegation address) or allow `0xef0101` accounts
to also carry `0xef0100` delegation. This EIP provides the authentication
foundation that such extensions would build on.

### Post-Quantum Migration Path

This EIP is not itself a post-quantum resistance mechanism. Ed25519 is
vulnerable to the same quantum attacks as secp256k1 ECDSA. The purpose of this
EIP is to establish a credible, tested migration route — not to provide the
final destination.

Adding Ed25519 as the first native key scheme may appear counterintuitive
given its quantum vulnerability. But Ed25519 is immediately useful (hardware
support, key hygiene, provable rootlessness), and the migration mechanism it
exercises is exactly the mechanism a future post-quantum scheme will use. A
post-quantum emergency that requires migrating billions of dollars of account
value is not the time to deploy an untested migration path. By deploying the
framework with Ed25519 first, the ecosystem gains real-world experience with
the migration flow — wallet UX, tooling, client implementation, edge cases —
before the stakes become existential. Without a tested route, any real
post-quantum migration is strictly riskier.

The migration path itself is straightforward. A single Type `0x05` transaction
(in ECDSA mode) atomically replaces an account's authentication scheme. Because the `0xef01XX`
prefix space is extensible, a future post-quantum designator (e.g., `0xef0103`
for a hash-based or lattice-based scheme) slots directly into the same
framework. The migration is one transaction, one block, one atomic state
change — no intermediate contract deployments, no multi-step approval chains,
and no window during which the account is authenticated by both the old and new
key.

The crafted-signature path further strengthens this: new accounts can be created
directly under a post-quantum scheme, bypassing ECDSA entirely. The combination
of in-place migration for existing accounts and native creation for new accounts
provides a credible migration path without requiring a new account model or a
hard fork beyond the initial activation of the relevant `0xef01XX` designator.

### Choice of Ed25519

secp256r1 (P-256) ECDSA was considered as the initial scheme. However,
secp256r1 verification is better served by precompile availability (e.g.,
RIP-7212), which allows any EIP-7702 delegate or smart contract wallet to
verify secp256r1 signatures without protocol-level account changes. A
precompile is the correct abstraction for "make this signature scheme available
to the EVM." Native key delegation is the correct abstraction for "replace the
account's authentication primitive." Ed25519 is not available via precompile on
Ethereum mainnet and provides distinct benefits (simpler implementation,
deterministic signatures, no malleability, widespread hardware support) that
justify protocol-level integration.

### Scheme-Specific Prefixes

Using distinct 3-byte prefixes per scheme (`0xef0101` for Ed25519, `0xef0102`
for a future scheme, etc.) rather than a generic prefix with a scheme byte:

1. **Fixed code sizes.** Each scheme has a known pubkey length. The code size
   is fixed and can be validated without parsing.
2. **Independent activation.** Each scheme is its own EIP. Consensus clients
   can support schemes incrementally.
3. **No version negotiation.** The prefix fully determines the verification
   algorithm.

### Single Transaction Type with Dual Authentication Mode

This EIP uses a single transaction type (`0x05`) for both setting native keys
(ECDSA mode) and originating transactions from native-key accounts (Ed25519
mode). The `sender` field acts as the discriminant: empty for ECDSA, 20 bytes
for Ed25519. This avoids consuming two [EIP-2718](./eip-2718.md) type numbers
and enables a capability that two separate types could not: a native-key
account can submit migration authorizations for other accounts in the same
transaction it uses to send value or call contracts.

The `native_key_authorization_list` MAY be empty in either mode. In ECDSA
mode, a transaction with an empty list is invalid (there is no reason to use
Type `0x05` without authorizations or Ed25519 signing). In Ed25519 mode, an
empty list is the common case — a native-key account simply sending a
transaction.

Ed25519 does not support public key recovery from signatures. The `sender`
address must be stated explicitly in Ed25519 mode. This is a departure from
Ethereum's "recover sender from signature" convention, but provides a tangible
benefit: transaction deserialization no longer requires an elliptic curve
operation.

### Crafted-Signature Creation

The crafted-signature method is strictly stronger than the ephemeral-key
method:

| Property | Ephemeral key | Crafted signature |
|----------|--------------|-------------------|
| ECDSA key ever existed in memory | Yes | No |
| Requires secure key destruction | Yes | No |
| Side-channel risk during signing | Yes | No |
| Verifiable by third parties | No | Yes (reproducible `r` derivation) |

The technique is battle-tested: Nick's method and
[ERC-2470](./eip-2470.md) use identical cryptographic reasoning for keyless
contract deployment.

## Test Cases

Test cases are required for consensus-affecting changes and will be provided in
`assets/eip-XXXX/` before this EIP advances beyond Draft status. Key scenarios
to cover:

- Type `0x05` in ECDSA mode with a single native key authorization tuple.
- Type `0x05` in ECDSA mode with a crafted-signature (keyless) authorization.
- Type `0x05` in Ed25519 mode from a native-key account (valid signature).
- Type `0x05` in Ed25519 mode rejected due to invalid Ed25519 signature.
- Type `0x05` in Ed25519 mode with non-empty authorization list (dual use).
- Type `0x05` in ECDSA mode with empty authorization list (must be rejected).
- ECDSA-signed transaction (Type `0x00`–`0x04`) rejected from a native-key
  account.
- EIP-7702 authorization tuple rejected when recovering to a native-key
  account.
- `EXTCODESIZE`, `EXTCODECOPY`, and `EXTCODEHASH` behavior for native-key
  accounts.

## Backwards Compatibility

This EIP introduces new behavior gated behind a new transaction type and an
explicit opt-in authorization. No existing accounts or transaction types are
affected unless the account owner explicitly converts via a native key
authorization.

1. **New delegation designator** (`0xef0101`). No conflict with `0xef0100`
   or pre-[EIP-3541](./eip-3541.md) contracts, which cannot have
   `0xef`-prefixed code.
2. **New transaction type** (`0x05`). Standard
   [EIP-2718](./eip-2718.md) typed transaction rollout. Unrecognized types
   are ignored by older clients.
3. **Extended [EIP-3607](./eip-3607.md) exception.** Transaction origination
   is now permitted for both `0xef0100` and `0xef0101` code prefixes.
4. **ECDSA rejection for converted accounts.** This is a new validation
   rule, but applies only to accounts that explicitly opted in. No existing
   account is affected without an explicit on-chain authorization.

## Security Considerations

### Post-Quantum Threat Model

The post-quantum threat to Ethereum accounts is not uniform. It depends on
whether the account's public key has been exposed on-chain:

- **ECDSA-only accounts with nonce > 0** have broadcast at least one signed
  transaction, exposing their secp256k1 public key on-chain. A quantum
  attacker can recover the private key from the public key and drain the
  account. These accounts are vulnerable at rest — no race condition is
  required.
- **ECDSA-only accounts with nonce = 0** have never transacted. Their public
  key is not on-chain (only the address, which is a hash). These accounts are
  safe until they transact, at which point they become vulnerable.
- **EIP-7702 delegations at rest** are not post-quantum secure. The
  `0xef0100` delegation was set by an ECDSA-signed authorization. A quantum
  attacker who recovers the ECDSA key can submit a new authorization tuple
  that overwrites the delegation, redirecting the account to attacker-
  controlled code.
- **EIP-7702 delegations in flight** (authorization tuples pending inclusion)
  depend on timely inclusion. A quantum attacker who observes the pending
  authorization must recover the ECDSA key and submit a competing
  authorization before the original is included. This assumes that quantum
  key recovery requires non-trivial expenditure of time and resources — i.e.,
  that quantum attacks are expensive, not instantaneous.
- **Native-key accounts** (this EIP) are immune to ECDSA-based quantum
  attacks. The ECDSA key is permanently rejected by the protocol. However,
  Ed25519 native-key accounts remain vulnerable to quantum attacks on
  Ed25519 itself. True post-quantum security requires migration to a
  quantum-resistant `0xef01XX` designator.

The critical observation is that delegations — both 7702 and any future
migration mechanism — are only secure in flight if quantum attacks are
expensive. This EIP does not change that assumption. What it does provide is a
permanent conversion that eliminates the "at rest" vulnerability: once
migrated, no quantum attack on the original ECDSA key can affect the account.

### ECDSA Key Exposure Window (Ephemeral Key Path)

When creating an account via the ephemeral key path, the ECDSA private key
exists in memory for the duration of the authorization signing. Implementors
should prefer the crafted-signature path. When using ephemeral keys,
implementors must generate and destroy the key in a secure, memory-safe
context and must not persist the key to disk.

### Ed25519 Implementation Correctness

The Ed25519 verification algorithm is specified precisely in the Type `0x05`
Ed25519 mode validation rules to avoid the ambiguities in RFC 8032 that have caused
consensus failures in other protocols (notably Zcash and Solana). The
specification requires cofactorless verification with explicit rejection of
non-canonical encodings, `s >= L` signatures, and small-order public keys.
This corresponds to the "strict" verification mode, not the permissive
ZIP-215 interpretation.

Consensus-critical divergence between Ed25519 implementations is a chain-split
risk. All implementations must produce identical accept/reject decisions for
every possible (pubkey, message, signature) triple. Implementors should
validate against a shared test vector suite (to be provided in
`assets/eip-XXXX/`) and should not rely on library defaults, as different
libraries implement different verification strictness levels.

### Front-Running

Native key authorization tuples can be observed in the mempool and front-run.
The impact is limited: the front-runner can cause the native key to be set
earlier than intended, but the resulting account state is identical (the
pubkey is embedded in the tuple). A front-runner cannot substitute a different
key.

### Replay Protection

- **Cross-chain.** `chain_id` in both authorization tuples and Type `0x05`
  transactions. Setting `chain_id = 0` in an authorization permits
  intentional multi-chain use.
- **Same-chain.** Nonce in both authorization tuples and transactions.

### Account Recovery

Native key delegation is irreversible by design. Loss of the Ed25519 private
key results in permanent loss of access to the account and all associated
assets. This is the same failure mode as losing a secp256k1 key for a standard
EOA.

Native-key accounts as specified in this EIP have no on-chain recovery path.
Because they cannot execute code (no EIP-7702 delegation), smart-contract-based
social recovery is not available. Users who require recovery guarantees should
evaluate whether native key delegation is appropriate for their use case, or
wait for a companion EIP that combines native key authentication with code
delegation.

### Cross-Chain Authorization Replay

Authorization tuples with `chain_id = 0` are valid on all EVM chains. For the
crafted-signature creation path, this means an attacker who observes the
authorization tuple can replay it on any chain, establishing the same account
(same address, same Ed25519 key) on chains the creator did not intend. The
account state on those chains (pre-existing balance, nonce, or code) may
differ from the creator's expectations.

Creators who do not intend multi-chain deployment should set `chain_id` to the
target chain. Creators who intentionally use `chain_id = 0` for multi-chain
deployment should be aware that any party can trigger the migration on any
chain once the authorization tuple is public.

### Transaction Pool Considerations

Native-key accounts share the same transaction pool challenges as EIP-7702
delegated accounts: a key rotation (once specified in a companion EIP) could
invalidate pending transactions. Clients should accept at most one pending
Type `0x05` transaction per native-key account to minimize the number of
transactions that can be invalidated by a single state change.

### Deterministic Keyless Addresses

The crafted-signature method produces addresses that depend on `(chain_id, pk,
r, s, y_parity)`. Users should use the recommended deterministic `r`
construction to ensure addresses are publicly reproducible. Non-deterministic
`r` values are not unsafe but prevent third-party verification that the
account is provably rootless.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
