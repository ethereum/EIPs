---
title: Keystore Signatures for Execution Txs
description: Verify legacy execution-transaction signatures through the Keystore so 1559 and 7702 can use post-quantum authenticators
author: Chris Hunter (@chunter-cb) <chris.hunter@coinbase.com>
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-08-21
requires: 155, 2718, 2930, 1559, 7702, 8130
---

## Abstract

On [EIP-8130](./eip-8130.md) chains, general execution transaction types (legacy, [EIP-2930](./eip-2930.md),
[EIP-1559](./eip-1559.md), [EIP-7702](./eip-7702.md)) authenticate through the Keystore instead of
treating secp256k1 `ecrecover` as authority. A 65-byte signature is always k1 and is checked against
the account's **default EOA**, with `from` unspecified — the same empty-sender path EIP-8130 uses for
AA transactions. Any other signature is `account || authenticator || data` and is checked against
that account's Keystore actors. Old wallets keep working until the default EOA is revoked; after that
those types can be post-quantum, and aggregatable if the authenticator allows it.

## Motivation

EIP-8130 makes accounts crypto-agile: actors point at authenticators, and a post-quantum authenticator
can be authorized without changing the account address. That agility only applies to the AA transaction
type. Type-0, [EIP-2930](./eip-2930.md), [EIP-1559](./eip-1559.md), and [EIP-7702](./eip-7702.md)
transactions still treat `ecrecover(hash, v, r, s) == from` as sufficient authority. An account that
has rotated to a PQ key — or revoked its default EOA — cannot originate a 1559 transfer with that
key, and a k1 key that the account intended to retire can still spend via those types.

This EIP closes that hole for the **general execution types**. secp256k1 remains the 65-byte
default-EOA path so unmodified wallets continue to work for accounts that have not revoked it.
Configured-actor signatures use the same authenticator interface as EIP-8130, so a PQ (or
aggregatable) authenticator that is valid on the AA path is valid on these types too.

A chain that wants blobs uses that specialized transaction type. The 8130 transaction type stays
separate from that use case.

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

Where a type currently encodes secp256k1 as trailing RLP integers (`v, r, s` for type 0;
`yParity, r, s` for typed transactions), clients MUST also accept that historical encoding and
canonicalize it to a 65-byte `sig` before the rules below:

```
sig = r (32) || s (32) || y_parity (1)
```

`y_parity` is `0` or `1`. A type-0 `v` of `27` or `28` canonicalizes to `0` or `1`; an [EIP-155](./eip-155.md)
`v` is reduced to its y-parity the same way. The signing hash `H` for type 0 remains the EIP-155 hash
(chain id is in `H`, not in `sig`).

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
is admin. An account that has revoked the default EOA cannot originate any transaction type with a
65-byte k1 signature.

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

This EIP amends only the general execution types. [EIP-8130](./eip-8130.md) `AA_TX_TYPE` is unchanged
(already Keystore-authenticated, and it does not carry blob fields).

| Type | Spec | Signing hash `H` | Historical ECDSA fields |
|------|------|------------------|-------------------------|
| 0 | legacy / [EIP-155](./eip-155.md) | EIP-155 payload hash | `v, r, s` |
| `0x01` | [EIP-2930](./eip-2930.md) | type-1 payload hash | `yParity, r, s` |
| `0x02` | [EIP-1559](./eip-1559.md) | type-2 payload hash | `yParity, r, s` |
| `0x04` | [EIP-7702](./eip-7702.md) | type-4 payload hash | `yParity, r, s` |

**Out of scope: blob transactions.** [EIP-4844](./eip-4844.md) type `0x03` remains the specialized
blob envelope. This EIP MUST NOT add blob hashes, sidecars, or blob signatures to 8130, and MUST NOT
rewrite type `0x03`. Chains that do not want blobs omit that type. A later EIP MAY apply the same
Keystore signature shapes to type `0x03` if a chain wants PQ blob originators.

**[EIP-7702](./eip-7702.md) `authorization_list`.** The outer type-4 transaction signature is
Keystore-checked. Inner authorization tuples remain secp256k1, so that 7702 delegations stay portable
to non-8130 chains. PQ-capable delegation on 8130 chains uses EIP-8130 `account_changes`, not this
list.

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

**Why Keystore on the general execution types, not a new type.** A new PQ transaction type would
leave 1559 and 7702 as k1 backdoors. Rotating off secp256k1 on ordinary calls and value transfers
only works if those origin paths consult the Keystore.

**Why not blobs here, and why not on 8130.** Blob data is a different job and already has a dedicated
type. 8130 is the AA execution envelope; it does not carry blob signatures or versioned hashes.
Chains that do not care about blobs never implement type `0x03`. Jamming blob fields into 8130 — or
rewriting 4844 inside this EIP — couples unrelated adoption. PQ blob originators, if needed, are a
companion change on the blob type.

**Why 65 bytes is always k1 default EOA.** That is the EIP-8130 empty-`sender` shape: `from` is not
on the wire, ecrecover yields it, the default EOA authorizes it. Reusing it means unmodified wallets
keep sending type-2 transactions for accounts that have not revoked k1. Length is the distinguisher
because legacy types have no `sender` field.

**Why `account || authenticator || data` otherwise.** EIP-8130 configured-actor signatures are
`authenticator || data` with `sender` set separately. Legacy types have no `sender` field, so the
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
default EOA). Start originating 1559/7702 transactions with `account || pq_authenticator || data`.
Revoke the default EOA. 65-byte k1 signatures fail on the types this EIP covers. The account address
does not change. Blob origin, if the chain implements it, is unchanged until a blob-type companion
applies the same rule.

## Backwards Compatibility

Pre-fork blocks are unchanged. After activation:

- Accounts that have not set `DEFAULT_EOA_REVOKED` still originate every legacy type with a 65-byte
  k1 signature (historical `v,r,s` / `yParity,r,s` encodings included). Vanilla EOAs are unaffected.
- Accounts that have revoked the default EOA, or were created without a k1 self-actor, MUST use
  `account || authenticator || data`. Wallets that only produce 65-byte signatures cannot originate
  for those accounts — that is the deprecation.
- EIP-8130 AA transactions are unaffected (and still carry no blob fields).
- [EIP-4844](./eip-4844.md) type `0x03` is unaffected.
- The `ecrecover` precompile is unaffected.
- Non-8130 chains are unaffected.

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

**Inner 7702 auths.** Leaving `authorization_list` on secp256k1 means a revoked default EOA can still
*receive* 7702 delegations signed by its historical k1 key if those tuples are accepted as ECDSA
authority. This EIP does not close that; 8130 chains that need PQ delegation already have
`account_changes`. A later EIP MAY Keystore-check inner tuples.

**Authenticator acceptance.** The same EIP-8130 adoption-profile rules apply. A canonical-only chain
MUST NOT accept a non-canonical authenticator on a type-2 transaction any more than on an AA
transaction.

**In-contract `ecrecover`.** This EIP closes k1 as *transaction origin* for the covered types. It
does not close k1 as *in-EVM recovery*: a revoked default EOA can still satisfy `ecrecover` in
Permit, Permit2, and similar callers. That is intentional and residual. Callers that mean "does this
account authorize this hash" MUST use EIP-8130 `validateSignature` / ERC-1271. Enshrining that as a
precompile is a companion EIP.

**Replay.** Signing hashes and EVM nonces are unchanged. A signature valid for type 2 is not valid for
type 4; a Keystore-authorized actor cannot replay across types. Chain id remains in `H`.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
