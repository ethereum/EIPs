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
requires: 2718, 2929, 3541, 3607, 7702
---

## Abstract

This EIP extends the delegation designator system introduced by
[EIP-7702](./eip-7702.md) to support **native key delegation** — permanently
converting an EOA's authentication from ECDSA over secp256k1 to an alternative
signature scheme. A new code prefix `0xef0101` designates an account whose
authentication key is an Ed25519 public key embedded directly in the account's
code field. Once set, the original ECDSA key is rendered permanently inert. A
companion transaction type allows these accounts to originate transactions
authenticated via Ed25519.

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
| `SET_NATIVE_KEY_TX_TYPE` | `Bytes1(0x05)` | Transaction type for setting native keys |
| `NATIVE_KEY_TX_TYPE` | `Bytes1(0x06)` | Transaction type for native-key-authenticated transactions |
| `NATIVE_KEY_MAGIC` | `0x06` | Domain separator for native key authorization signing |
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

### Set Native Key Transaction (Type `0x05`)

A new [EIP-2718](./eip-2718.md) transaction type carries native key
authorization tuples:

```
0x05 || rlp([
    chain_id,
    nonce,
    max_priority_fee_per_gas,
    max_fee_per_gas,
    gas_limit,
    destination,
    value,
    data,
    access_list,
    native_key_authorization_list,
    signature_y_parity,
    signature_r,
    signature_s
])
```

The outer transaction is signed with ECDSA by the submitter (any EOA). The
submitter need not be the authority whose key is being set.

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

#### Processing Rules

The `native_key_authorization_list` MUST NOT be empty. For each tuple, in
order:

1. Verify `chain_id` is `0` or equals the current chain ID. Otherwise skip.
2. Verify `pubkey` is exactly 32 bytes. Otherwise skip.
3. Verify `nonce < 2^64 - 1`. Otherwise skip.
4. Set `msg_hash = keccak256(NATIVE_KEY_MAGIC || rlp([chain_id, pubkey, nonce]))`.
5. Set `authority = ecrecover(msg_hash, y_parity, r, s)`. If recovery fails, skip.
6. Verify `authority`'s code is empty, begins with `0xef0100`, or begins
   with `0xef0101`. Otherwise skip.
7. Verify `authority`'s nonce equals `nonce`. Otherwise skip.
8. Add `authority` to `accessed_addresses` (as defined by [EIP-2929](./eip-2929.md)).
9. Increment `authority`'s nonce by one.
10. Set `authority`'s code to `0xef0101 || pubkey`.
11. Charge `PER_NATIVE_AUTH_BASE_COST` gas, plus `PER_EMPTY_ACCOUNT_COST` if
    the account was previously empty.

If multiple tuples target the same authority, the last valid tuple wins.

### ECDSA Rejection Rule

Once an account's code is set to `0xef0101 || pubkey`:

- ECDSA-signed transactions (Types 0x00–0x04) with that account as sender
  MUST be rejected during transaction validation.
- EIP-7702 authorization tuples recovering to that account MUST be rejected.
- Native key authorization tuples (Type 0x05) signed by that account's
  ECDSA key MUST be rejected.

The account is permanently governed by its embedded Ed25519 key.

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
6. Any party submits a Type `0x05` transaction containing the authorization
   tuple `[chain_id, pk, 0, y_parity, r, s]`.

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

### Native Key Transaction (Type `0x06`)

Transactions originating from native-key accounts use a new
[EIP-2718](./eip-2718.md) type:

```
0x06 || rlp([
    chain_id,
    nonce,
    max_priority_fee_per_gas,
    max_fee_per_gas,
    gas_limit,
    to,
    value,
    data,
    access_list,
    sender,
    signature
])
```

| Field | Type | Description |
|-------|------|-------------|
| `sender` | `address` | The 20-byte address of the originating native-key account |
| `signature` | `bytes64` | Ed25519 signature over the transaction hash |

The signed payload is:

```
tx_hash = keccak256(NATIVE_KEY_TX_TYPE || rlp([
    chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas,
    gas_limit, to, value, data, access_list, sender
]))
```

**Note:** Unlike all previous transaction types, `sender` is an explicit field
rather than being recovered from the signature. Ed25519 does not support public
key recovery, so the sender must be stated. This is not a limitation — it
eliminates an elliptic curve operation from transaction parsing.

#### Validation

1. Verify `sender`'s code begins with `ED25519_DESIGNATION` and is exactly
   35 bytes. Otherwise the transaction is invalid.
2. Extract `pubkey = sender.code[3..35]`.
3. Verify `Ed25519_Verify(pubkey, tx_hash, signature)` per
   [RFC 8032 §5.1.7](https://www.rfc-editor.org/rfc/rfc8032#section-5.1.7).
   If verification fails, the transaction is invalid.
4. Verify `nonce == sender.nonce`. Otherwise the transaction is invalid.
5. Proceed with standard transaction execution.

`ED25519_VERIFY_COST` is added to the transaction's intrinsic gas cost,
replacing the implicit ecrecover cost.

#### Transaction Origination

This EIP extends the [EIP-3607](./eip-3607.md) exception established by
EIP-7702: accounts whose code begins with `0xef0101` MAY originate
transactions (via Type `0x06`), in addition to accounts whose code begins with
`0xef0100`.

### Key Rotation

A native-key account MAY rotate its Ed25519 public key by including a
**rotation authorization** in a Type `0x06` transaction. The transaction calls
the `NATIVE_KEY_ROTATION` precompile at address `0xNKR` with calldata:

```
new_pubkey (32 bytes)
```

The precompile:

1. Verifies `msg.sender` has `0xef0101` code.
2. Sets `msg.sender`'s code to `0xef0101 || new_pubkey`.
3. Returns success.

Because the Type `0x06` transaction is already authenticated by the current
Ed25519 key, no additional signature is required. Key rotation is simply a
precompile call within an authenticated transaction.

### Interaction with EIP-7702

| From | To | Permitted? |
|------|----|-----------|
| Empty / EOA | `0xef0101` (native key) | Yes, via Type `0x05` authorization |
| `0xef0100` (code delegation) | `0xef0101` (native key) | Yes, via Type `0x05` authorization signed by ECDSA key |
| `0xef0101` (native key) | `0xef0100` (code delegation) | **No.** ECDSA signatures are permanently rejected. |
| `0xef0101` (native key) | `0xef0101` (new key) | Yes, via key rotation precompile |

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

### One-Way Conversion

Making the ECDSA → native key conversion irreversible eliminates the entire
class of "dormant key" attacks. Once converted, there is no ECDSA key that
could be leaked, phished, or quantum-broken to hijack the account. For
crafted-signature accounts, this is a mathematical guarantee. For
ephemeral-key accounts, it is a protocol-enforced guarantee independent of
key destruction procedures.

The irreversibility also simplifies the security model: validators need only
check the account's code prefix to determine the authentication scheme. There
is no need to track historical key states or handle mixed-mode authentication.

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

### Scheme-Specific Prefixes

Using distinct 3-byte prefixes per scheme (`0xef0101` for Ed25519, `0xef0102`
for a future scheme, etc.) rather than a generic prefix with a scheme byte:

1. **Fixed code sizes.** Each scheme has a known pubkey length. The code size
   is fixed and can be validated without parsing.
2. **Independent activation.** Each scheme is its own EIP. Consensus clients
   can support schemes incrementally.
3. **No version negotiation.** The prefix fully determines the verification
   algorithm.

### Explicit Sender in Type `0x06`

Ed25519 does not support public key recovery from signatures. The sender
address must be stated explicitly. This is a departure from Ethereum's
"recover sender from signature" convention, but provides a tangible benefit:
transaction deserialization no longer requires an elliptic curve operation.

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

- Type `0x05` transaction with a single native key authorization tuple.
- Type `0x05` transaction with a crafted-signature (keyless) authorization.
- Type `0x06` transaction from a native-key account (valid Ed25519 signature).
- Type `0x06` transaction rejected due to invalid Ed25519 signature.
- ECDSA-signed transaction (Type `0x00`–`0x04`) rejected from a native-key
  account.
- EIP-7702 authorization tuple rejected when recovering to a native-key
  account.
- Key rotation via the `NATIVE_KEY_ROTATION` precompile.
- `EXTCODESIZE`, `EXTCODECOPY`, and `EXTCODEHASH` behavior for native-key
  accounts.

## Backwards Compatibility

This EIP introduces new behavior gated behind new transaction types and an
explicit opt-in authorization. No existing accounts or transaction types are
affected unless the account owner explicitly converts via a native key
authorization.

1. **New delegation designator** (`0xef0101`). No conflict with `0xef0100`
   or pre-[EIP-3541](./eip-3541.md) contracts, which cannot have
   `0xef`-prefixed code.
2. **New transaction types** (`0x05`, `0x06`). Standard
   [EIP-2718](./eip-2718.md) typed transaction rollout. Unrecognized types
   are ignored by older clients.
3. **Extended [EIP-3607](./eip-3607.md) exception.** Transaction origination
   is now permitted for both `0xef0100` and `0xef0101` code prefixes.
4. **ECDSA rejection for converted accounts.** This is a new validation
   rule, but applies only to accounts that explicitly opted in. No existing
   account is affected without an explicit on-chain authorization.

## Security Considerations

### ECDSA Key Exposure Window (Ephemeral Key Path)

When creating an account via the ephemeral key path, the ECDSA private key
exists in memory for the duration of the authorization signing. Implementors
should prefer the crafted-signature path. When using ephemeral keys,
implementors must generate and destroy the key in a secure, memory-safe
context and must not persist the key to disk.

### Ed25519 Implementation Correctness

Signature verification must conform strictly to
[RFC 8032](https://www.rfc-editor.org/rfc/rfc8032). In particular:

- Non-canonical signatures (where `s >= L`, with `L` the Ed25519 group order)
  must be rejected.
- Small-order public keys must be rejected.
- Batch verification, if used, must provide the same accept/reject outcomes
  as individual verification.

Consensus-critical divergence between Ed25519 implementations is a chain-split
risk. Implementations should use the same audited library or produce
test-vector compatibility proofs.

### Front-Running

Native key authorization tuples can be observed in the mempool and front-run.
The impact is limited: the front-runner can cause the native key to be set
earlier than intended, but the resulting account state is identical (the
pubkey is embedded in the tuple). A front-runner cannot substitute a different
key.

### Replay Protection

- **Cross-chain.** `chain_id` in both authorization tuples and Type `0x06`
  transactions. Setting `chain_id = 0` in an authorization permits
  intentional multi-chain use.
- **Same-chain.** Nonce in both authorization tuples and transactions.

### Account Recovery

Native key delegation is irreversible by design. Loss of the Ed25519 private
key results in permanent loss of access to the account and all associated
assets. This is the same failure mode as losing a secp256k1 key for a
standard EOA. Users requiring recovery guarantees should establish a recovery
mechanism (e.g., via EIP-7702 code delegation to a social recovery contract)
before or as part of the native key setup.

### Deterministic Keyless Addresses

The crafted-signature method produces addresses that depend on `(chain_id, pk,
r, s, y_parity)`. Users should use the recommended deterministic `r`
construction to ensure addresses are publicly reproducible. Non-deterministic
`r` values are not unsafe but prevent third-party verification that the
account is provably rootless.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
