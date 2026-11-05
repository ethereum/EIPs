---
eip: TBD
title: Keystore Expired Actor Pruning
description: Consensus garbage-collection of expired EIP-8130 actors via a co-located actor record and a deterministic seeded trie sweep, with no persistent bookkeeping
author: Chris Hunter (@chunter-cb) <chris.hunter@coinbase.com>
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-08-23
requires: 8130
---

## Abstract

This proposal reclaims the storage that expired [EIP-8130](./eip-8130.md) actors leave behind. It
does two things. First, it fixes the Keystore's actor storage as a **co-located, stride-aligned
3-word record** — `actor_config`, `policy_manager`, `policy_commitment` at contiguous slots — with a
`CLEANABLE` marker bit in the `actor_config` reserved bytes. Second, each block the protocol walks a
bounded number of records (`MAX_ACTOR_CHECKS_PER_BLOCK`) from a **deterministic pseudo-random**
position seeded by the block, and deletes any record whose actor has expired. There is **no queue or
per-actor index to maintain** — the walk reads the records that already exist, keeping at most a
single optional cursor word.

Deletion is sound because an expired actor authorizes nothing: EIP-8130 validation treats an expired
actor, a revoked actor, and one that was never created identically, all returning *unauthorized*.
Reaping maps "expired" onto "never-created," which no account can observe, while returning state that
short-lived actors (session keys, subscriptions, JIT grants) would otherwise leave in the trie
forever. The sweep is **best-effort**: authorization never depends on a record having been reaped, so
the per-block work is a hard bound, not a correctness parameter.

## Motivation

EIP-8130 authorizes an actor by writing one `actor_config` slot (and, for policy actors, two adjacent
policy slots), and an actor MAY carry an `expiry`. After `expiry` the actor can no longer
authenticate, but its slots are never reclaimed: EIP-8130 deletes them only on an explicit
`revokeActor`, which needs admin authority and a transaction no account will send for a key it already
considers dead. Session keys, subscription keys, and JIT grants are exactly the actors that carry a
short `expiry` and are expected in volume; each leaves a permanent record. That is unbounded state
growth for authority that no longer exists.

Two properties of EIP-8130 make consensus cleanup uniquely safe here, unlike arbitrary contract
storage:

- **One place, protocol-defined.** Authority lives in a flat `actor_config` slot the protocol reads
  directly, and the liveness rule (`expiry == 0 || now <= expiry`) is part of the protocol, so
  "expired" is well-defined for every account without executing wallet code.
- **Expired, revoked, and never-created are indistinguishable.** An `actor_config` read resolves to
  *unauthorized* in all three cases, so deleting an expired record changes no observable result.

## Specification

The key words "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", and "MAY" in this document are to be
interpreted as described in RFC 2119 and RFC 8174.

### Why not a scan or an index

The Keystore holds no on-chain actor enumeration (EIP-8130 enumerates via logs, off-chain), and
storage keys are hashed into the trie, so records have no expiry order and cannot be range-queried. A
full scan is O(all state) per block; a maintained expiry index adds one persistent entry per live
expiring actor — state added to remove state, and carried for the actor's whole life (an actor may
expire years out). This EIP instead samples existing records with a bounded, deterministic walk and
keeps **zero** persistent bookkeeping.

### Co-located Actor Record

This EIP fixes the layout EIP-8130 leaves implementation-defined: an actor's three fields MUST occupy
**contiguous, stride-aligned** slots so the whole record is one deletable unit.

```
recordBase(account, actorId) = keccak256(actorId ‖ account ‖ ACTOR_RECORD_BASE) & ~0x3

  base + 0   actor_config       authenticator(20) ‖ scope(1) ‖ expiry(6) ‖ policyType(1) ‖ reserved(4)
  base + 1   policy_manager     manager(20) ‖ reserved                       // zero if policyType == 0
  base + 2   policy_commitment  bytes32                                       // zero if policyType == 0
```

The base is masked to a multiple of 4 (`& ~0x3`) so a record never straddles a 256-slot group; under
a slot-grouping tree all three words share one stem. The `actor_config` packing is unchanged from
EIP-8130 except that the **low bit of byte 31** (within the `reserved` region EIP-8130 requires to be
zero) is redefined as `CLEANABLE`. This EIP therefore relaxes that "reserved MUST be zero" rule for
that one bit; all field reads (`authenticator`, `scope`, `expiry`, `policyType`) MUST mask the marker
so it cannot leak into a field value.

- **Actor record.** `authorizeActor` sets `CLEANABLE = 1`. The record is reap-eligible; whether it is
  ever reaped depends on `expiry`.
- **Account-state record.** The packed account-state slot (holding the inline self-actor and account
  flags) is written at its own aligned base with `CLEANABLE = 0`, so it is never reaped. Its
  `base + 1` / `base + 2` MAY carry per-account bookkeeping (lock, channel, epoch, default-EOA flag);
  those words are never read as record heads (see below).

The pruned domain — the Keystore account whose storage the sweep walks — MUST contain **only** these
aligned 3-word records. Per-account bookkeeping that fits SHOULD be folded into the account-state
record's `base + 1` / `base + 2` words. Any Keystore state that is not an aligned 3-word record — a
variable-length or globally-shared structure such as the replay ring or a global sweep cursor — MUST
live in a separate storage account the sweep never visits. This is a real restructuring of the
EIP-8130 storage account, which today co-mingles these structures, and it is the layout precondition
on which the sweep's safety rests; it keeps the walked domain homogeneous.

### Record Identification

A trie walk yields a slot's value and hashed key, not its `(account, actorId)` preimage, so the
reaper cannot name a record from its position. It decides from **structure plus one bit**, which is
exact:

1. **Position.** Because every record is stride-aligned, the `actor_config` head is always at a slot
   `≡ 0 (mod 4)`. The reaper reads **only** aligned head slots as candidates; `policy_manager`
   (`≡ 1`) and `policy_commitment` (`≡ 2`) are never interpreted as heads. This is what lets the
   32-byte commitment remain full-entropy: it can carry any bytes, including ones that look like an
   `actor_config`, and still never be mistaken for one, because the reaper never reads it as a head.
2. **Marker.** At an aligned head, `CLEANABLE` distinguishes a reap-eligible actor (`1`) from the
   account-state record (`0`). Both are protocol-written, so the bit is deterministic, not
   attacker-chosen.

With (1) and (2), identification is exact with no false positives, in a single Keystore account and
with no separate storage domain and no change to how policy actors store or read their commitment.

### Reaping a Record

Reaping requires addressing all three words of a discovered record. Under a **slot-grouping tree**
(Verkle, or a binary tree with stem grouping) a mapping value's three consecutive slots co-locate in
one stem, so a stem walk lands on the record and clears `base`, `base + 1`, `base + 2` **by trie
position** — no preimage, no EVM `SSTORE`. Under the current hexary MPT the three `keccak(base + i)`
scatter, so a discovered head cannot address `base + 1` / `base + 2` without the preimage; on such a
chain the sweep is disabled (`MAX_ACTOR_CHECKS_PER_BLOCK = 0`) and only the **layout** from this EIP
is enshrined. The layout is the immutable part (storage derivation cannot change once accounts
exist), so it MUST ship first; the reaper activates unchanged when the chain adopts a grouping tree.

At an aligned head with value `w0`, the reaper prunes the record iff:

```
(w0 & CLEANABLE) != 0  and  expiry(w0) != 0  and  block.timestamp > expiry(w0)
```

and otherwise skips. Reaping clears all three words and emits **nothing** — a reaped actor is
indistinguishable from one that expired by timestamp, so pruning is invisible on-chain and to
indexers (which already treat the actor as dead once `now > expiry`).

The self-actor's `actor_config(self)` record (a non-secp256k1 self authenticator) MUST carry
`expiry == 0`; EIP-8130 makes the self-actor non-expirable, so the `expiry != 0` term keeps it from
ever being reaped even though it is written as a `CLEANABLE` record.

### Deterministic Seeded Sweep

During each block's EIP-8130 processing, after transactions, the protocol runs the sweep:

1. Derive a **key-space** start from the block:
   `start_key = keccak(SWEEP_DOMAIN ‖ block.prevRandao ‖ block.number)`. The walk begins at the first
   existing record head whose trie key is `>= start_key`, wrapping cyclically to the smallest key at
   the end of the key space. Using a key, not an ordinal `seed mod M`, means the sweep needs no record
   count `M` and has no empty-domain edge case.
2. Visit up to `MAX_ACTOR_CHECKS_PER_BLOCK` aligned record heads in **trie-key order** from the start
   (sequential and cyclic, so the touched set is a contiguous key window — cheap to iterate in DB
   order and provable as one range multiproof).
3. For each visited head, prune it iff the condition in [Reaping a Record](#reaping-a-record) holds;
   otherwise skip. Non-`CLEANABLE` heads (account-state) in the window are skipped, not counted
   against safety.

The sweep MUST NOT touch any slot in another storage account. It is deterministic: every node
replaying the block reproduces the identical start key, window, and cleared set.

A chain MAY maintain a single global cursor `sweep_next` — **the last trie key reached** (one word,
O(1) chain state, not per-actor) — and start each block's window there instead of reseeding. A
key-space cursor advances monotonically and does not drift as records are inserted or deleted, giving
gapless coverage. Chains whose `block.prevRandao` (or equivalent per-block entropy) is weak or
operator-controlled — many L2 sequencers — MUST use the cursor: with a static seed the reseeded start
is identical every block and the stateless walk never advances past its first window. Where per-block
entropy is strong, the cursor is optional and the per-block seed makes the walk stateless.

The per-block cost is bounded **work**, not only witness: up to `MAX_ACTOR_CHECKS_PER_BLOCK` trie
descents and up to `clears_per_block` slot clears every block — unpriced protocol work each node
performs during block processing. `n` MUST be sized to this as well as to the witness (see
[Coverage](#coverage-and-tuning)).

### Constants

| Name | Value | Comment |
| ---- | ----- | ------- |
| `MAX_ACTOR_CHECKS_PER_BLOCK` | chain parameter (see [Coverage](#coverage-and-tuning)); `0` disables the sweep | Record heads visited per block. Bounds reaper witness/I-O per block; **not** a correctness parameter |
| `CLEANABLE` | bit 0 of byte 31 of `actor_config` (within `reserved` 28–31) | Set on actor records, clear on the account-state record; masked out of all field reads |
| `ACTOR_RECORD_BASE` | domain constant | Base for `recordBase` derivation |
| `SWEEP_DOMAIN` | ASCII `"EIP-8130-SWEEP"` | Domain separator for the seed |

Under the [EIP-8130 L1 profile](./eip-8130.md#adoption-profiles) `MAX_ACTOR_CHECKS_PER_BLOCK` is a
protocol constant; under the L2 profile it is a chain-configurable parameter, like the intrinsic-gas
schedule. On any chain not yet using a slot-grouping tree it MUST be `0`.

### Coverage and Tuning

Let `n = MAX_ACTOR_CHECKS_PER_BLOCK`, `M` the live record count, `p` the expired fraction of `M`, and
`E` the number of actors entering expiry per block. Then:

```
// full-sweep length (every existing record head visited once)
blocks_per_sweep          = ceil(M / n)                 // with the O(1) global cursor
blocks_per_sweep (seeded) ≈ (M / n) * ln(M / n)         // stateless reseed; coupon-collector factor

reclaim_latency (worst)   = blocks_per_sweep            // ~half on average
clears_per_block          = n * p
standing_dead (steady)    ≈ E * M / n                   // dead records not yet reclaimed

// to bound a full sweep to T blocks:
n >= M / T
```

`n` is chosen from the witness/compute budget, then `T = M / n` is the resulting sweep period. Because
record bases are `keccak`-scattered, each record occupies its **own** stem (its three words share one
stem, but distinct records do not), so a window of `n` records is ~`n` stems and costs ~`n` leaf
openings — there is **no** `1/SLOTS_PER_STEM` stem-packing amortization. The only witness saving is
that the window is a **contiguous key-range** of adjacent stems, so its range multiproof shares upper
internal trie nodes; this is a modest constant factor, not a factor of `SLOTS_PER_STEM`. Size `n` to
~one opening per record: a large `n` is comfortably provable inside an L2 witness budget but may be
too heavy for L1's, so L1 will run a smaller `n` (longer `T`) than an L2.

**Worked example.** `M = 100,000,000`, 12-second blocks, global cursor:

| `n` | `blocks_per_sweep` | wall-clock per sweep |
| --- | --- | --- |
| 1,000 | 100,000 | ~13.9 days |
| 10,000 | 10,000 | ~1.4 days |
| 100,000 | 1,000 | ~3.3 hours |

A daily full sweep of 100M records needs `n >= 100M / 7200 ≈ 13,889` — an `n`, and a per-block witness
of ~that many openings, that suits an L2 far better than L1. Stateless reseed (no cursor) multiplies
the sweep length by `ln(M/n)` (~9× at `n = 10,000`), the price of holding zero state.

## Rationale

**Best-effort is the enabling property.** Authorization correctness never depends on a record having
been reaped: an expired actor is *unauthorized* whether or not its record still exists. So `n` can be
a hard per-block bound, the sweep can lag during expiration spikes, and it can take many blocks — none
of which touches validity or consensus. This is what lets the whole mechanism be bounded and cheap.

**Co-location instead of folding.** An earlier design folded the policy commitment into `actorId` to
remove the one full-entropy value from the walked domain. Co-locating the record and reading **only
aligned heads** achieves the same safety without folding: the commitment stays a plain stored slot,
`getPolicy` stays a single SLOAD, and nothing new is threaded through execution or `payer_auth`. The
commitment can be any bytes because it is never read as a head. Position does the work a `type` tag
would otherwise do.

**One bit, not a tag byte.** Only two record kinds share the pruned domain — actor and account-state
— and both are protocol-written, so a single `CLEANABLE` bit in the already-`reserved` region
separates them exactly, at no extra storage and no change to the single-SLOAD validation read.

**Ship the layout before the reaper.** Storage derivation is effectively immutable once accounts
exist, so the co-located, aligned, marked layout MUST be enshrined at or before EIP-8130 launch. The
reaper itself is a forkable switch: it stays off (`n = 0`) until the chain runs a slot-grouping tree,
then turns on with no migration because the records are already laid out for it.

**Deterministic pseudo-random.** Consensus cannot be truly random. Seeding from `prevRandao` makes
every node clear the same set. A proposer can grind RANDAO, but since only already-expired
(unauthorized) records are ever deleted, grinding can at most *avoid* cleaning — griefing reclamation,
never security — so the manipulability is harmless.

**Sequential window, not random probes.** Independent random probes are coupon-collector
(`~(M/n)·ln M` to cover everything) and cause random I/O and `n` scattered proofs across the trie. A
sequential window from a seeded start covers the trie in `M/n` with a key-space cursor and iterates
the DB in key order. Placement is scattered (bases are `keccak` outputs), so the window is still ~`n`
stems; what it buys over random probes is **locality** — one contiguous key-range whose range
multiproof shares internal nodes and whose DB reads are sequential — not a `1/SLOTS_PER_STEM`
reduction in openings.

**No stored index.** An expiry index would carry one entry per live expiring actor for that actor's
whole life, including far-future expiries — adding the very state this EIP removes. Sampling existing
records needs nothing persistent (or one global cursor word, at chain option).

## Backwards Compatibility

This EIP fixes Keystore storage layout (co-located, stride-aligned 3-word records with a `CLEANABLE`
marker, other Keystore state in separate accounts) and so MUST be adopted at or before EIP-8130 launch
on a chain; it is not a post-hoc change. Given the layout, it alters no EIP-8130 authorization or
validation outcome: `actor_config`, `policy_manager`, and `policy_commitment` are read exactly as
before, an expired actor behaves the same before and after it is reaped, `authorizeActor` (an upsert,
so a reaped `actorId` MAY be re-authorized) and `revokeActor` are unchanged, and a chain that sets
`MAX_ACTOR_CHECKS_PER_BLOCK` to `0` (mandatory before it uses a slot-grouping tree) simply never
reaps.

Two changes are layout-only and invisible to callers of `getActor` / `getPolicy`: it repurposes one
previously-reserved `actor_config` bit as `CLEANABLE` (relaxing EIP-8130's "reserved MUST be zero" for
that bit, with reads masking it), and it relocates non-record Keystore structures (e.g. the replay
ring) out of the config storage account. Both are storage-derivation changes and so MUST be fixed at
launch.

## Security Considerations

**No authority is removed.** A record is cleared only when `block.timestamp > expiry`; such an actor
cannot authenticate a transaction, config change, or [ERC-1271](./eip-1271.md) signature, so no
capability is taken and a *usable* key cannot be pruned. The non-expirable self-actor is protected by
the same term: its record MUST carry `expiry == 0`, which the `expiry != 0` gate never reaps.

**No false positives.** The reaper reads only stride-aligned heads and prunes only on `CLEANABLE`, so
a `policy_manager` or full-entropy `policy_commitment` at `base + 1` / `base + 2` can never be
misread as an actor, and the account-state record (`CLEANABLE = 0`) is never reaped. Positional
structure plus one protocol-written bit makes the value-only decision exact.

**Domain isolation.** Safety depends on the pruned account containing only aligned 3-word records; any
other Keystore state MUST live in a separate account. A chain that violates this could expose
unrelated state at aligned offsets to the head test — hence the layout requirement is normative, not
advisory.

**Timestamp boundary.** The reaper uses the same `now > expiry` comparison, at the same block
timestamp, as EIP-8130 liveness, so no block both authenticates an actor and reaps it.

**Manipulation is denial-of-reclamation only.** A proposer grinding the seed, or an adversary
inflating `M` with many expiring actors, can only *delay* reclamation (bounded, deterministic per
block); neither can affect an authorization decision, which never waits on the sweep. Enqueue-free
means the only cost an attacker pays is the ordinary authorization cost of the actors they create.

**Stateless verification.** The swept window enters the block's state-access witness at ~one opening
per visited record (~`n` stems, since scattered bases put one record per stem); the contiguous
key-range shares internal nodes but there is no `1/SLOTS_PER_STEM` stem-packing saving. `n` MUST be
sized to the chain's witness budget accordingly — smaller on L1 than on L2.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
