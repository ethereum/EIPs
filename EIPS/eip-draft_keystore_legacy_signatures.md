---
title: Keystore Signatures for Execution Txs
description: Verify type-1 and type-2 transaction signatures through the Keystore so 1559 can use post-quantum authenticators
author: Chris Hunter (@chunter-cb) <chris.hunter@coinbase.com>
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-08-21
requires: 2718, 2930, 1559, 7702, 8130
---

## Abstract

On [EIP-8130](./eip-8130.md) chains, [EIP-2930](./eip-2930.md) and [EIP-1559](./eip-1559.md)
transactions authenticate through the Keystore instead of treating secp256k1 `ecrecover` as
authority. A 65-byte signature is always k1 and is checked against the account's **default EOA**,
with `from` unspecified — the same empty-sender path EIP-8130 uses for AA transactions. Any other
signature is `account || authenticator || data` and is checked against that account's Keystore
actors. Old wallets keep working until the default EOA is revoked; after that those types can be
post-quantum, and aggregatable if the authenticator allows it.

Legacy (type-0) transactions and the [EIP-7702](./eip-7702.md) transaction type are **not
supported**. The 7702 delegation indicator remains; [EIP-8130](./eip-8130.md) is the sole authority
that may set or clear it.

## Motivation

EIP-8130 makes accounts crypto-agile: actors point at authenticators, and a post-quantum authenticator
can be authorized without changing the account address. That agility only applies to the AA transaction
type. [EIP-2930](./eip-2930.md) and [EIP-1559](./eip-1559.md) transactions still treat
`ecrecover(hash, v, r, s) == from` as sufficient authority. An account that has rotated to a PQ key
— or revoked its default EOA — cannot originate a 1559 transfer with that key, and a k1 key that the
account intended to retire can still spend via those types.

This EIP closes that hole for type-1 and type-2. secp256k1 remains the 65-byte default-EOA path so
unmodified wallets continue to work for accounts that have not revoked it. Configured-actor
signatures use the same authenticator interface as EIP-8130, so a PQ (or aggregatable) authenticator
that is valid on the AA path is valid on these types too.

Type-0 is not supported: wallets use type-2 (or 8130). The [EIP-7702](./eip-7702.md) *transaction
type* is deprecated on these chains; the delegation indicator stays, and only 8130 (auto-delegation
and `account_changes`) may apply it. A chain that wants blobs uses that specialized transaction type.
The 8130 transaction type stays separate from that use case.

## Specification

The key words "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", and "MAY" in this document are to be
interpreted as described in RFC 2119 and RFC 8174.

This EIP applies only on chains that implement EIP-8130, from the activation of this EIP. Pre-fork
blocks are unchanged. [EIP-8130](./eip-8130.md) AA transactions (`AA_TX_TYPE`) are unchanged; they
already authenticate through the Keystore.

### Signature encoding

After activation, the [covered transaction types](#covered-transaction-types) carry a signature as a
byte string `sig` over the type's existing signing hash `H` (the hash secp256k1 currently signs;
`sig` is not part of `H`). Specialized types (blobs, and any future dedicated envelope) are out of
scope.

Where a type currently encodes secp256k1 as trailing RLP integers (`yParity, r, s`), clients MUST
also accept that historical encoding and canonicalize it to a 65-byte `sig` before the rules below:

```
sig = r (32) || s (32) || y_parity (1)
```

`y_parity` is `0` or `1`.

A type MAY instead encode a single trailing RLP bytes item `sig` directly.

### Two shapes

`sig` is interpreted by length. **Every shape is checked against the Keystore.** secp256k1 recovery
alone is never sufficient.

#### 65-byte: default EOA (k1)

If `len(sig) == 65`, the signature is always secp256k1. `from` is unspecified and recovered, matching
EIP-8130's empty-`sender` path:

1. Require `sig[64] ∈ {0, 1}`. Let `r = sig[0:32]`, `s = sig[32:64]`, `y_parity = sig[64]`.
2. Recover `account = ecrecover(H, y_parity, r, s)`. Reject if recovery fails.
3. Set `from = account` and `actorId = bytes32(uint256(uint160(account)))`.
4. Authorize as EIP-8130's **self-actor (native secp256k1) rule**: reject if `DEFAULT_EOA_REVOKED` is
   set on `account`; otherwise take `scope` and `expiry` from the inline default-EOA fields (all-zero
   = unrestricted, non-expiring admin). If `expiry` is non-zero, require `block.timestamp <= expiry`.

An unmodified EOA (no Keystore writes, flag unset) therefore keeps working: the implicit default EOA
is admin. An account that has revoked the default EOA cannot originate a covered type with a 65-byte
k1 signature.

#### Otherwise: `account || authenticator || data`

If `len(sig) != 65`, require `len(sig) >= 40` and decode:

```
account       = sig[0:20]        // 20 bytes; this is `from`
authenticator = sig[20:40]       // 20 bytes
data          = sig[40:]         // authenticator-specific
```

`len(sig) == 65` is reserved for the default-EOA path, so a configured-actor blob MUST NOT be 65
bytes. An authenticator whose natural `data` would make `40 + len(data) == 65` MUST use a different
`data` length (pad or length-prefix).

Then authenticate exactly as EIP-8130's configured-actor path, with `sender = account`:

1. Set `from = account`.
2. If `authenticator == K1_AUTHENTICATOR`, native-ecrecover `data` as `r || s || v` and set
   `actorId = bytes32(uint256(uint160(recovered_address)))`. Otherwise `STATICCALL`
   `authenticator.authenticate(H, data)` with the same canonical-vs-permissive acceptance policy as
   EIP-8130 (including the `MAX_AUTHENTICATION_GAS` bound), and take the returned `actorId`.
3. Authorize against the Keystore of `account`: the secp256k1 self-actor rule if this was the native
   k1 path and `actorId` is the self-actorId; otherwise SLOAD `actor_config(account, actorId)`,
   require the stored authenticator matches, and enforce `expiry`.
4. `address(0)` is never a valid authenticator selector.

### Scope

These transaction types always self-pay and always consume the account's EVM nonce. After
authentication, require:

```
scope == 0x00 || ((scope & SENDER) != 0 && (scope & SELF_PAYER) != 0 && (scope & POLICY) == 0)
```

That is **admin**, or **`SENDER` and `SELF_PAYER` without `POLICY`**. `POLICY` actors MUST NOT
originate these types; gated initiation stays on the EIP-8130 AA path, where the protocol can enforce
`call.to == manager`. This is not `Scopes.isOperator` alone (`isOperator` is admin or `SENDER`
without `POLICY`, and does not require `SELF_PAYER`).

`NONCE` is not consulted: it gates EIP-8130 2D nonce keys, not the EVM nonce these types use.
`SPONSOR_PAYER` is not consulted: these types have no payer field.

### Aggregation

`data` is authenticator-defined. An authenticator that supports aggregation MAY encode in `data` a
share, a proof, or a handle into an aggregate. `authenticate(H, data)` MUST still return the
`actorId` that authorized **this** transaction's hash. How shares are combined at block level (a
sidecar, an aggregate blob, a precompile) is defined by that authenticator; this EIP does not add a
transaction-type-specific aggregation envelope. An authenticator that does not support aggregation
is verified standalone, as on the EIP-8130 AA path.

### Covered transaction types

This EIP amends type `0x01` and type `0x02`. [EIP-8130](./eip-8130.md) `AA_TX_TYPE` is unchanged
(already Keystore-authenticated).

| Type | Spec | Signing hash `H` | Historical ECDSA fields |
|------|------|------------------|-------------------------|
| `0x01` | [EIP-2930](./eip-2930.md) | type-1 payload hash | `yParity, r, s` |
| `0x02` | [EIP-1559](./eip-1559.md) | type-2 payload hash | `yParity, r, s` |

**Not supported: type 0.** Legacy transactions are invalid after activation. Wallets use type `0x02`
or `AA_TX_TYPE`.

**Deprecated: [EIP-7702](./eip-7702.md) transaction type.** Type `0x04` is invalid after activation.
The 7702 **delegation indicator** (`0xef0100 || target`) remains, including code-loading semantics.
[EIP-8130](./eip-8130.md) is the **sole** authority that may set or clear it: auto-delegation to
`DEFAULT_ACCOUNT_ADDRESS` and the delegation entry in `account_changes`. No `authorization_list`, and
no other transaction type, may write the indicator.

**Out of scope: blob transactions.** [EIP-4844](./eip-4844.md) type `0x03` remains the specialized
blob envelope. A chain that wants blobs uses that type; 8130 stays separate from that use case.

**Out of scope: `ecrecover`.** The secp256k1 recovery precompile is unchanged. It remains a pure
function of `(hash, v, r, s)` and MUST NOT consult the Keystore. In-contract signature checks that
need Keystore authority use EIP-8130 `validateSignature` / account `isValidSignature` (and, if
enshrined, the native `validateSignature` precompile EIP-8130 already sketches). A companion EIP MAY
expose that precompile; this EIP MUST NOT retarget `ecrecover`.

### Gas

Authentication is metered as EIP-8130 `sender_auth_cost` (canonical authenticators: the enshrined
constant; others: `STATICCALL` bounded by `MAX_AUTHENTICATION_GAS`). The 65-byte default-EOA path is
native ecrecover plus the default-EOA slot read, same as EIP-8130's empty-sender path. Exact numbers
follow the chain's EIP-8130 [adoption profile](./eip-8130.md#adoption-profiles). Additional intrinsic
gas for this EIP: TBD.

## Rationale

**Why Keystore on type-1 and type-2, not a new type.** A new PQ transaction type would leave 1559 as
a k1 backdoor. Rotating off secp256k1 on ordinary calls and value transfers only works if those
origin paths consult the Keystore.

**Why type 0 is not supported.** Legacy encoding puts chain id in `v` and has no typed envelope.
Type-2 already covers the same execution; wallets migrate to it (or to 8130). Rejecting type 0 avoids
a second signature encoding and a k1-only path that would otherwise have to be Keystore-checked.

**Why the 7702 *transaction type* is deprecated, and why the indicator stays.** Type `0x04` is a
secp256k1 `authorization_list` for writing the delegation indicator. On an 8130 chain that is a k1
backdoor around Keystore-gated origin, and it duplicates the delegation entry 8130 already has.
The indicator itself (`0xef0100 || target`) and code-loading remain: 8130 auto-delegation and
`account_changes` are the only writers. Non-8130 chains keep using type `0x04` as today.

**Why not blobs here, and why not on 8130.** Blob data is a different job and already has a dedicated
type. 8130 is the AA execution envelope; it does not carry blob signatures or versioned hashes.
Chains that do not care about blobs never implement type `0x03`. Jamming blob fields into 8130 — or
rewriting 4844 inside this EIP — couples unrelated adoption. PQ blob originators, if needed, are a
companion change on the blob type.

**Why 65 bytes is always k1 default EOA.** That is the EIP-8130 empty-`sender` shape: `from` is not
on the wire, ecrecover yields it, the default EOA authorizes it. Reusing it means unmodified wallets
keep sending type-2 transactions for accounts that have not revoked k1. Length is the distinguisher
because type-1 and type-2 have no `sender` field.

**Why `account || authenticator || data` otherwise.** EIP-8130 configured-actor signatures are
`authenticator || data` with `sender` set separately. Type-1 and type-2 have no `sender` field, so the
account address is prepended. The rest of authentication — canonical set, `actor_config` bind,
expiry, adoption-profile acceptance — is identical, including aggregation wherever the authenticator
already allows it on the AA path.

**Why not `ecrecover` here.** Transaction origin and in-EVM recovery are different layers.
`ecrecover` is a pure cryptographic primitive with a fixed `(hash, v, r, s)` ABI: it cannot carry
`authenticator || data`, so it cannot authenticate a PQ actor no matter what Keystore rule is bolted
on. Existing bytecode also uses it for keys that are not accounts (ephemeral signing keys, not 8130
actors). Tying it to `DEFAULT_EOA_REVOKED` would mix "whose secp256k1 key" with "does this account
still speak k1." EIP-8130 already specifies the replacement: `validateSignature`, optionally as a
native precompile. That is a separate EIP.

**PQ deprecation path.** Authorize a PQ actor (8130 AA tx or a Keystore call signed with the still-live
default EOA). Start originating type-2 transactions with `account || pq_authenticator || data`.
Revoke the default EOA. 65-byte k1 signatures fail on type-1 and type-2. The account address does not
change. Type 0 and type `0x04` are already invalid. Blob origin, if the chain implements it, is
unchanged until a blob-type companion applies the same rule.

## Backwards Compatibility

Pre-fork blocks are unchanged. After activation:

- Type 0 and type `0x04` are invalid. Wallets that sent legacy or 7702 transactions switch to type
  `0x02` or `AA_TX_TYPE`. Existing 7702 indicators persist; only 8130 may update them.
- Accounts that have not set `DEFAULT_EOA_REVOKED` still originate type-1 and type-2 with a 65-byte
  k1 signature (historical `yParity, r, s` encodings included). Vanilla EOAs are unaffected on those
  types.
- Accounts that have revoked the default EOA, or were created without a k1 self-actor, MUST use
  `account || authenticator || data` on type-1 and type-2. Wallets that only produce 65-byte
  signatures cannot originate for those accounts — that is the deprecation.
- EIP-8130 AA transactions are unaffected.
- [EIP-4844](./eip-4844.md) type `0x03` is unaffected.
- The `ecrecover` precompile is unaffected.
- Non-8130 chains are unaffected (type 0 and type `0x04` remain valid there).

## Security Considerations

**k1 is not authority.** `ecrecover` identifies a candidate `from`; the default-EOA slot decides
whether that key still speaks for the account. Clients MUST NOT accept a 65-byte signature for an
account with `DEFAULT_EOA_REVOKED`.

**Length collision.** `len(sig) == 65` is exclusively the default-EOA path. A configured-actor
encoding of total length 65 is invalid as that path (and would ecrecover garbage). Authenticators
MUST NOT emit 25-byte `data` without padding.

**Scope.** Require admin, or `SENDER | SELF_PAYER` with `POLICY` unset. A `SENDER` actor without
`SELF_PAYER` cannot self-pay an EIP-8130 AA transaction and MUST NOT self-pay a type-2 transaction
either. `POLICY` keys cannot originate these types (no `tx.to` gate here; they stay on the AA path).

**Inner 7702 auths.** Type `0x04` is invalid, so `authorization_list` cannot write the indicator.
Delegation on these chains is only 8130 auto-delegation and `account_changes`, which already
Keystore-authenticate the sender. There is no remaining k1-only path to set or clear code
delegation.

**Authenticator acceptance.** The same EIP-8130 adoption-profile rules apply. A canonical-only chain
MUST NOT accept a non-canonical authenticator on a type-2 transaction any more than on an AA
transaction.

**In-contract `ecrecover`.** This EIP closes k1 as *transaction origin* for the covered types. It
does not close k1 as *in-EVM recovery*: a revoked default EOA can still satisfy `ecrecover` in
Permit, Permit2, and similar callers. That is intentional and residual. Callers that mean "does this
account authorize this hash" MUST use EIP-8130 `validateSignature` / ERC-1271. Enshrining that as a
precompile is a companion EIP.

**Replay.** Signing hashes and EVM nonces are unchanged. A signature valid for type 2 is not valid for
type 1; a Keystore-authorized actor cannot replay across types. Chain id remains in `H`.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
