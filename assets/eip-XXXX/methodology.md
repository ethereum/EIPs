# Methodology: enumerating the targeted accounts

How the published list was constructed, and how to re-verify it. The full implementation lives on a Geth fork; this document is a high-level overview, with code references for anyone wanting to reproduce the scan in detail. This document shows how to produce the Mainnet list, and the numbers or constant should be changed accordingly when targeting a different branch.

## Predicate

We need every Mainnet account satisfying:

- `nonce == 0`,
- `codeHash == keccak256("")` (`EmptyCodeHash`),
- `storageRoot != keccak256(RLP(""))` (`EmptyRootHash`).

Such an account can only have been produced by a pre–Spurious-Dragon contract creation (via the `CREATE` opcode or a contract-creation transaction) whose init code wrote storage and returned no deploy bytes. After [EIP-161](../../EIPS/eip-161.md), both creation paths bump the new contract's nonce to 1 before init code runs, so the set is closed: no new account can enter it.

## Two-stage enumeration

The matching set shrinks over time: [EIP-161](../../EIPS/eip-161.md)'s "empty" predicate (no code, zero nonce, zero balance) ignores storage, so a zero-balance account in our shape is EIP-161-empty and gets deleted on the next "touch". With `S(b)` the matching set at block `b`, `S(2,675,000) ⊇ S(latest)`. We enumerate in two stages:

1. **Boundary scan** at the Spurious Dragon activation block (2,675,000), wich is the earliest moment at which the population is closed. Note that the fork block itself does not have to be checked, as this already sets a possible contract nonce to 1. Output: 224 entries, published as [zero-nonce-matches.jsonl](./zero-nonce-matches.jsonl).
2. **`latest` filter** via `eth_getProof(address, [], "latest")`, keeping only addresses whose live state still satisfies the predicate. Output: 28 entries, published as [targeted-accounts.json](./targeted-accounts.json). [EIP-7523](../../EIPS/eip-7523.md) implies every survivor has non-zero balance.

## Boundary scan

Implemented on a fork of Geth `v1.13.15` (the last `release/1.13` build with PoW execution and Era1 import. `v1.14+` cannot bootstrap a chain without `terminalTotalDifficulty`, which Mainnet pre-Spurious-Dragon lacks). The scanner:

1. Replays mainnet from genesis to block 2,675,000 with `Preimages = true` (such that we can walk the state/snapshot later and find the preimages necessary for the BAL for both the addresses and the storage keys) and archive mode (`TrieDirtyDisabled = true`, so a crash loses at most one block).
2. Builds a snapshot at the boundary state root via `snapshot.New(NoBuild: false, AsyncBuild: false)`.
3. Walks the flat snapshot key layout (`SnapshotAccountPrefix = "a"`, `SnapshotStoragePrefix = "o"`); for each `SlimAccount` matching the predicate, reverses the address hash and walks per-account storage via `rawdb.IterateStorageSnapshots`, reversing each slot hash.

Output schema (one JSON object per line):

```jsonc
{
  "address":     "0xabc…",       // 20-byte preimage
  "addressHash": "0x4f2c…",      // keccak256(address)
  "balance":     "0x…",
  "codeHash":    "0xc5d2…a470",  // EmptyCodeHash
  "storageRoot": "0x71b9…",      // != EmptyRootHash
  "storage": [{ "key": "0x…", "keyHash": "0x…" }, …]
}
```

The published [targeted-accounts.json](./targeted-accounts.json) is the same schema, additionally decorated with `currentStorageHash` (from `eth_getProof`) and packed into a JSON array.

## Verification

Two checks against Mainnet `latest`:

1. **Liveness filter** (`eth_getProof(address, [], "latest")`): keeps the 28 accounts that still satisfy the predicate. This is the step from `S(2,675,000)` to `S(latest)`.
2. **Storage-root reconstruction**: for each survivor, `eth_getProof(address, [our_slot_keys], "latest")` returns the live values; rebuild the storage MPT from `(keccak256(slot), rlp(stripLeadingZeros(value)))` pairs and compare to the `storageHash` Mainnet reports. All 28 survivors verify, which proves the slot list is complete and consistent with live state.

## Reproduction

Reproducing the scan end-to-end requires the Geth fork on branch `remove-account-with-state-which-is-not-eoa-Geth-v-1-13-15`:

```bash
# 1. Fetch Era1 archives (any modern geth release, or a manual download also works).
geth-1.17 --datadir /tmp/era download-era \
    --era.server https://data.ethpandaops.io/era1/mainnet/ --block 0-2675000

# 2. Build the scan branch.
go build -o ./build/bin/geth ./cmd/geth

# 3. Replay + snapshot + scan (re-run: ~9h, snapshot generation: ~1.5h, so approx half a day in total).
./build/bin/geth --datadir /tmp/zn snapshot find-zero-nonce-replay \
    /tmp/era/geth/chaindata/ancient/chain/era

# 4. Filter + verify storage roots.
go build -o ./verify-storage-root ./cmd/verify-storage-root
cat zero-nonce-matches.jsonl | ./verify.sh > targeted-accounts.jsonl
jq -s '.' targeted-accounts.jsonl > targeted-accounts.json
```

The scan is deterministic per snapshot iteration; running it on a clean datadir yields the same `(address, slot_key)` pairs.

## Caveats

- **Genesis pre-allocations.** A few Mainnet genesis allocations set storage directly. They satisfy the predicate and are kept in the list.
- **Snapshot completeness.** The scan-only mode requires a fully built snapshot; the replay pipeline guarantees this at the boundary root.
- **Boundary block inclusivity.** Block 2,675,000 is the *first* EIP-161-active block, so any contract created in it already has nonce 1.

## Files

- [targeted-accounts.json](./targeted-accounts.json): 28-entry survivor set on `latest` (the EIP's normative list).
- [zero-nonce-matches.jsonl](./zero-nonce-matches.jsonl): 224-entry boundary-block superset.
