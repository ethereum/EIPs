# Methodology: enumerating the targeted accounts

This document describes how the list of accounts targeted by the EIP was constructed, and how to reproduce or independently verify it. It is a companion to the main EIP and is the empirical evidence underlying the claim that the published list is complete.

## Goal

We need every Ethereum Mainnet account whose state, today, satisfies all of:

- `nonce == 0`,
- `codeHash == keccak256("") == 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470` (henceforth `EmptyCodeHash`),
- `storageRoot != keccak256(RLP("")) == 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421` (henceforth `EmptyRootHash`).

Such an account can only have been produced by a pre–Spurious-Dragon contract creation — either via the `CREATE` opcode or via a contract-creation transaction (one with an empty `to` field) — whose init code wrote to storage and finished without returning any deploy bytes. A minimal example of such init code is:

```
60 42       PUSH1 0x42
60 00       PUSH1 0x00
55          SSTORE        ; storage[0] = 0x42
00          STOP          ; halt with no return data → empty deployed code
```

This is illustrative only: any init code path that performs at least one `SSTORE` and then halts with empty return data (whether via `STOP`, falling off the end of the bytecode, or `RETURN` with zero length) yields the same outcome. (Note that `PUSH1 0x00 PUSH1 0x00 RETURN` is semantically equivalent to `STOP` here but costs more gas and three extra code bytes; the form above is the cheapest minimal example.)

After Spurious Dragon ([EIP-161](../../EIPS/eip-161.md), part a), both contract-creation transactions and the `CREATE` opcode increment the new contract's nonce to 1 *before* the init code runs, so a contract whose code is empty but whose storage is non-empty necessarily has nonce ≥ 1. The set is therefore closed: no new account can enter it. Once an account is in this state, it is also stable — `SELFDESTRUCT` can only run from inside the contract, but the contract has no code.

The relevant cutoff for enumeration is therefore **block 2,675,000** (the Spurious Dragon / EIP-161 activation block on Mainnet), the earliest moment at which the population is closed. (Geth's chain config exposes this boundary under the legacy field name `EIP158Block`. The two names refer to the same fork block; the field name predates the renumbering of the underlying state-clearing rules to EIP-161 and is kept here for code-reference fidelity only.)

## Why block 2,675,000 is a superset, and why we additionally filter on `latest`

[EIP-161](../../EIPS/eip-161.md)'s "empty" predicate (no code, zero nonce, zero balance) does **not** consider storage. So a zero-balance account in our shape is still EIP-161-empty, and any subsequent "touch" of it deletes the account from the trie. Many accounts present at block 2,675,000 have therefore been swept by EIP-161 in the years since.

Concretely, with `S(b)` being the matching set at block `b`:

```
S(2,675,000)   ⊇   S(latest)
```

This EIP scopes itself to `S(latest)` — accounts that still exist on Mainnet at the proposed fork block — because those are the only accounts whose state we need to mutate. The full enumeration is performed in two stages:

1. Scan at block 2,675,000 for the **superset** (224 entries at the time of writing).
2. Filter that superset against Mainnet `latest` via `eth_getProof`, keeping only accounts whose live state still satisfies the predicate (28 entries; published as [still-matching.json](./still-matching.json)).

[EIP-7523](../../EIPS/eip-7523.md) closes the loop on the second stage: every `S(latest)` account has non-zero balance, because any zero-balance account satisfying our predicate would have been EIP-161-empty and therefore deleted by the state-clearing transaction described in EIP-7523. The surviving 28 entries thus all have non-zero balance, which is exactly the invariant the EIP relies on.

## Scanner pipeline

The empirical scan was carried out on a fork of Geth `v1.13.15` (the last release on the `release/1.13` branch that retains pre-merge / PoW execution rules — required to replay pre-Spurious-Dragon blocks).

### Why v1.13.15 and not master

Geth `v1.14+` removed support for legacy chain configs: a node refuses to bootstrap a chain whose genesis lacks `terminalTotalDifficulty`. Mainnet pre-Spurious-Dragon execution requires PoW-era processing rules, so the scan can't run on master. `v1.13.15` is the last release on `release/1.13`; it predates the post-merge–only refactor and still supports PoW execution, while having Era1 import infrastructure (added late in the v1.13 line). It is **not** an ancestor of master — it lives on the sealed `release/1.13` branch.

`download-era` itself is **not** in `v1.13.15`. The user fetches Era1 files with a newer Geth release and feeds the on-disk archive to the v1.13 build; the era1 file format is stable across versions.

### Replay vs. scan-only

The scanner has two modes:

1. **Replay mode** (`geth snapshot find-zero-nonce-replay <era-dir>`) — replays the chain from genesis to block 2,675,000 using Era1 archives, builds a snapshot at the boundary state root, and walks the snapshot. Self-contained; produces the canonical evidence.
2. **Scan-only mode** (`geth snapshot find-zero-nonce [<root>]`) — scans an existing snapshot. Useful on a snap-synced or fully-synced node, or for re-verification after replay.

Both honour `--zero-nonce.matches <path>` (default `./zero-nonce-matches.jsonl`) and append in dedup-friendly fashion (a startup pass over the file populates an "already emitted" set, so re-runs are idempotent). The output filename is configurable; in the rest of this document we refer to the **boundary-block scan output** as the file written by this flag, regardless of its concrete name on disk.

### Replay configuration

The replay uses `chain.InsertChain` (which executes each block) rather than `ImportHistory` (which uses `InsertReceiptChain` and skips execution). Key `core.CacheConfig` settings:

- `Preimages = true` — every state-trie and storage-trie `Update` populates the trie database's preimage table on commit, so `keccak256(address) → address` and `keccak256(slot) → slot` can be reversed afterwards via `rawdb.ReadPreimage`. Without this, the scan would only know hashed keys.
- `TrieDirtyDisabled = true` (archive mode) — every block's state lands on disk before `InsertChain` returns. Cost: ~30–50% slower replay, larger chaindata. Benefit: a non-graceful exit (panic, SIGKILL, OOM) loses at most one block's work, vs. multi-hour rewinds under the default buffered mode.
- `SnapshotLimit = 0` — the snapshot is **not** built incrementally during replay. It is built once at the boundary, after replay finishes (`snapshot.New(snapshot.Config{NoBuild: false, AsyncBuild: false}, …)`); the `defer snap.waitBuild()` inside `snapshot.New` blocks until the disk-layer snapshot is fully populated for the boundary state root.

### Walking the snapshot

Geth's snapshot uses a flat key layout (see `core/rawdb/schema.go`):

- `SnapshotAccountPrefix = "a"` — accounts at `a + keccak256(address)`, value is `types.SlimAccountRLP(account)`.
- `SnapshotStoragePrefix = "o"` — storage slots at `o + keccak256(address) + keccak256(slot_key)`, value is `rlp(stripLeadingZeros(slotValue))`.

For each account whose decoded `SlimAccount` matches the predicate, the scanner:

1. reverses the address hash via `rawdb.ReadPreimage(db, accountHash)`,
2. walks the per-account storage range via `rawdb.IterateStorageSnapshots`,
3. reverses each slot hash via `rawdb.ReadPreimage`,
4. emits one JSON-Lines record on the matches file.

This is purely state-based: no tracer is attached to the EVM during replay (`vm.Config{}`). The methodology depends on the *post-state* of block 2,675,000, which is fully determined by chain execution.

## Output schema

Each line of the boundary-block scan output is one JSON object:

```jsonc
{
  "address":     "0xabc…",        // 20-byte preimage; always present from replay,
                                  //   present opportunistically from snapshot scan
                                  //   (only when the preimage is on disk).
  "addressHash": "0x4f2c…",       // keccak256(address) — always present
  "balance":     "0x0",           // hexutil.Big
  "codeHash":    "0xc5d2…a470",   // EmptyCodeHash for matches
  "storageRoot": "0x71b9…",       // non-empty for matches
  "storage": [
    {
      "key":     "0x0000…0007",   // 32-byte slot preimage; optional, depends on
                                  //   whether the trie database has the preimage
      "keyHash": "0xa6ee…cb49"    // keccak256(key) — always present
    },
    ...
  ]
}
```

The published [still-matching.json](./still-matching.json) is the same schema, additionally decorated with `currentStorageHash` (the `storageHash` returned by `eth_getProof(address, [], "latest")`), and packed into a JSON array.

Both preimages (account address and storage slot key) are mandatory in the published list. Some clients key the trie by hashed address and hashed slot, others retain the preimages directly; including both lets every client apply the EIP without an out-of-band lookup.

## Verification

Two independent checks, both run from `verify.sh` in the same repository:

### 1. Mainnet liveness (`eth_getProof` against `latest`)

For each address in the superset, call `eth_getProof(address, [], "latest")`. Keep only those whose response still has `nonce == 0`, `codeHash == EmptyCodeHash`, and `storageHash != EmptyRootHash`. Decorate the kept entries with `currentStorageHash`. This filter reduces the 224-entry superset to the 28-entry survivor set.

This is the step that takes us from `S(2,675,000)` to `S(latest)`.

### 2. Storage-root reconstruction (`cmd/verify-storage-root`)

For each survivor, call `eth_getProof(address, [our_slot_keys…], "latest")` to obtain the current value of every slot the scanner listed. Build an in-memory storage MPT from the `(keccak256(slot_key), rlp(stripLeadingZeros(value)))` pairs, and compare its computed root to the `storageHash` Mainnet itself reports.

- `match=true` → the scan captured every non-zero slot for that account; the published list is complete for that account.
- `match=false` → either we missed slots, or storage actually changed since block 2,675,000 (which shouldn't happen for code-less accounts, since they have no way to execute `SSTORE`).

Across the 28 survivors in [still-matching.json](./still-matching.json), every account verifies `match=true`: the slot lists are complete, and the reconstructed storage root equals the Mainnet-reported `storageHash`. This is the strongest available end-to-end check that the published list of `(address, slot_key, slot_value)` triples is faithful to live state.

## Reproducing the scan

The reproduction is run end-to-end from the Geth fork in `clients/go-ethereum` on branch `remove-account-with-state-which-is-not-eoa-Geth-v-1-13-15`. The artifacts in this asset directory are the exact output of the procedure below.

```bash
# 1. Download Era1 archives (use any modern geth release with download-era).
geth-1.17 --datadir /tmp/era-download download-era \
    --era.server https://data.ethpandaops.io/era1/mainnet/ \
    --block 0-2675000

# Era files end up at:
ERA_DIR=/tmp/era-download/geth/chaindata/ancient/chain/era

# 2. Build the v1.13.15-based geth fork on the scan branch.
git checkout remove-account-with-state-which-is-not-eoa-Geth-v-1-13-15
go build -o ./build/bin/geth ./cmd/geth

# 3. Replay + snapshot + scan. ~1.5h on a typical SSD.
./build/bin/geth --datadir /tmp/zero-nonce-replay \
    snapshot find-zero-nonce-replay $ERA_DIR

# Output: ./zero-nonce-matches.jsonl (default; configurable via --zero-nonce.matches).
# At the time of writing this is the 224-entry superset at block 2,675,000.

# 4. (optional) Re-verify against the same datadir's snapshot.
./build/bin/geth --datadir /tmp/zero-nonce-replay snapshot find-zero-nonce

# 5. Filter to mainnet survivors + verify storage trie roots.
go build -o ./verify-storage-root ./cmd/verify-storage-root
cat zero-nonce-matches.jsonl | ./verify.sh > still-matching.jsonl
# stdout: matches still satisfying the condition on `latest`
# stderr: per-address trie-verification verdicts
```

The scan is idempotent. A boundary-block scan output produced by step 3 can be regenerated from a clean datadir and is fully determined by the canonical chain — anyone running the procedure should obtain the same set of matching `(address, slot_key)` pairs (modulo line ordering, which is deterministic per snapshot iteration).

### Code layout

```
cmd/geth/zero_nonce.go          The scanner. Two subcommands:
                                  geth snapshot find-zero-nonce-replay <era-dir>
                                  geth snapshot find-zero-nonce [<root>]
cmd/geth/zero_nonce_test.go     Synthetic-snapshot unit test for scanSnapshot.
cmd/geth/snapshot.go            Subcommand registration.
cmd/verify-storage-root/main.go Standalone trie-reconstruction verifier.
verify.sh                       Orchestration: liveness filter + trie verify.
```

## Caveats

### Genesis pre-allocations

A handful of Mainnet genesis allocations set storage directly without going through any contract-creation path. They appear in the scan and are legitimately part of the targeted set: their storage is present, their code is empty, and their nonce is zero, exactly the predicate the EIP addresses. They are kept in the published list.

### Snapshot completeness

`find-zero-nonce` requires `rawdb.ReadSnapshotRoot(db) != 0`. Running it on a node mid-snap-sync, or on a hash-scheme datadir whose snapshot wasn't ever fully built, will miss accounts. The `find-zero-nonce-replay` pipeline guarantees a complete snapshot via `snapshot.New(NoBuild: false, AsyncBuild: false)` at the boundary root, which is why it is the canonical method.

### Boundary block semantics

The scan operates at block 2,675,000 *inclusive* — the *first* block at which EIP-161 rules are active. A contract created in that block (whether by `CREATE` or by a contract-creation transaction) already has nonce 1 by the new rule, so it cannot appear in the matching set. Earlier blocks (created with nonce 0) settle into the post-state of block 2,675,000 unchanged.

### Operational gotchas

- **One datadir per build family.** Geth `v1.17` added a `flushOffset` field to the freezer-table metadata; `v1.13` cannot decode it (`rlp: input list has too many elements for rawdb.freezerTableMeta`). Don't share a `--datadir` between `v1.17` and `v1.13`. Use a fresh directory for the v1.13 replay.
- **`checksums.txt` length must equal era file count.** If you hand-fetch an era subset, trim `checksums.txt` to match the number of `.era1` files (the scanner verifies counts and order). The first N lines of upstream `checksums.txt` correspond to era epochs `0..N-1`.
- **Repair on partial chaindata.** Without archive mode set on this branch, a crash mid-replay can trigger a long "head state missing, repairing" walk on the next startup as the chain rewinds to the most recent committed root. Archive mode is enabled by default on this branch (`TrieDirtyDisabled: true` in `cmd/geth/zero_nonce.go`), so this should not bite reproductions starting today.

## Open follow-ups

- Inline the storage *value* into the boundary-block scan output so verification can be fully offline (no RPC). Roughly 10 LoC plus a test update — decode `stIter.Value()` via `rlp.DecodeBytes`, pad to 32 bytes, attach as `Value common.Hash` on `zeroNonceSlot`. The verifier would then consume it directly instead of re-querying `eth_getProof`.
- A `--block <n>` flag on `find-zero-nonce-replay` to scan at a block other than the Spurious Dragon activation block. Currently hard-wired to that fork block, since that is the only point at which the matching set is closed by construction.

## Files in this asset directory

- [still-matching.json](./still-matching.json) — the 28-entry survivor set on Mainnet `latest`. This is the list the EIP's irregular state transition operates on.

The full 224-entry superset (the boundary-block scan output) is not bundled in the EIP because the EIP's normative scope is `S(latest)`. Anyone reproducing the procedure in [Reproducing the scan](#reproducing-the-scan) will regenerate it from a clean datadir.
