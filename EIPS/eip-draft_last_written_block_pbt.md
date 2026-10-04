---
title: Last-Written Block in PBT Leaves
description: Packs last_written_block write-age metadata into the account and storage leaves of the Partitioned Binary Tree.
author: Iman Kalyan Chakraborty (@astrion-coder), Wei Han Ng (@weiihann)
discussions-to: https://ethereum-magicians.org/t/eip-tbd-last-written-block-in-partitioned-binary-tree-leaves/29860
status: Draft
type: Standards Track
category: Core
created: 2026-10-04
requires: 7954, 8037, 8297
---

## Abstract
 
This proposal puts the `last_written_block` metadata defined in [EIP-8188](./eip-8188.md) directly into the leaves of the Partitioned Binary Tree (PBT) defined in [EIP-8297](./eip-8297.md).
 
For accounts, `last_written_block` is packed into the existing `BASIC_DATA` leaf. It takes the three reserved bytes plus one byte freed by narrowing `code_size` from four bytes in the original PBT design to three. For storage slots, the leaf value grows from 32 to 36 bytes: the unchanged 32-byte slot value, followed by a 4-byte big-endian `last_written_block`.
 
The rules that update `last_written_block` follow EIP-8188, with one difference: a storage write updates the slot's field only, not the account's. The metadata is part of each leaf's committed value, so anyone holding a leaf or a proof of it can retrieve the `last_written_block` of that account or storage slot at will. This proposal introduces no gas changes.
 
## Motivation
 
EIP-8188 gives clients a consensus-verified record of when each account and storage slot was last written. State-tiering designs such as [EIP-8295](./eip-8295.md) build on that record. EIP-8188 defines it for the Merkle Patricia Trie (MPT): it adds a fifth element to the account RLP list and wraps each storage slot in a two-element RLP list.
 
Neither encoding carries over to the PBT. The PBT has no RLP. Account fields are packed at fixed byte offsets in `BASIC_DATA`, and a storage slot leaf holds only the raw 256-bit word.
 
This proposal defines where `last_written_block` lives in PBT leaves, so tiering can be driven directly from the tree. It records the raw block number, for the reason EIP-8188 gives: any coarser value a pricing scheme needs can be derived from the block number, but not the reverse.
 
Like EIP-8188, this proposal covers only the metadata. It does not change gas costs or define a tiering policy.
 
## Specification
 
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.
 
### Parameters
 
| Parameter                           | Value |
| ----------------------------------- | ----- |
| `LAST_WRITTEN_BLOCK_SIZE`           | 4     |
| `ACCOUNT_LAST_WRITTEN_BLOCK_OFFSET` | 1     |
| `STORAGE_LAST_WRITTEN_BLOCK_OFFSET` | 32    |
| `STORAGE_LEAF_VALUE_LENGTH`         | 36    |
 
`last_written_block` is a fixed-width 4-byte big-endian unsigned integer. EIP-8188 stores the block number as an RLP integer, which has no fixed width: it uses as many bytes as the number needs, which is 4 for every current mainnet block, and would grow to 5 after block `2^32 - 1` without any protocol change. PBT leaves pack fields at fixed offsets, so this proposal fixes the width at 4 bytes (see "Why 4 bytes?" in the Rationale).
 
### Account encoding
 
EIP-8297 packs the `BASIC_DATA_LEAF_KEY` value as follows:
 
| Name        | Offset | Size |
| ----------- | ------ | ---- |
| `version`   | 0      | 1    |
| reserved    | 1      | 3    |
| `code_size` | 4      | 4    |
| `nonce`     | 8      | 8    |
| `balance`   | 16     | 16   |
 
This proposal changes it to:
 
| Name                 | Offset | Size |
| -------------------- | ------ | ---- |
| `version`            | 0      | 1    |
| `last_written_block` | 1      | 4    |
| `code_size`          | 5      | 3    |
| `nonce`              | 8      | 8    |
| `balance`            | 16     | 16   |
 
`nonce` and `balance` keep their offsets and widths. `code_size` narrows to three bytes, which holds values up to `2^24 - 1` (16,777,215) bytes. That is about 256 times the 64 KiB code size limit of [EIP-7954](./eip-7954.md), so no valid code exceeds it.
 
EIP-8297 specifies that setting any header field also sets `version` and the three reserved bytes to zero. This proposal replaces that rule: setting any header field sets `version` to zero and sets `last_written_block` according to the update rules below. A header write MUST NOT change `last_written_block` in any other way.
 
### Storage encoding
 
Every storage slot leaf carries a value of `STORAGE_LEAF_VALUE_LENGTH` (36) bytes. This applies to header slots 0..63, stored at sub-index `HEADER_STORAGE_OFFSET + storage_key` in the account's header stem, and to slots 64 and above, stored in `STORAGE_ZONE`. Storage keys do not change.
 
| Name                 | Offset | Size |
| -------------------- | ------ | ---- |
| `slot_value`         | 0      | 32   |
| `last_written_block` | 32     | 4    |
 
`slot_value` is the full 256-bit EVM storage word, unchanged and at the same offset it has in EIP-8297. `last_written_block` follows it, packed big-endian like the fields of `BASIC_DATA`.
 
```python
def is_storage_key(key: bytes) -> bool:
    if key[0] == STORAGE_ZONE:
        return True
    return (
        key[0] == ACCOUNT_ZONE
        and HEADER_STORAGE_OFFSET <= key[-1] < HEADER_STORAGE_OFFSET + HEADER_STORAGE_SLOTS
    )
 
def value_length(key: bytes) -> int:
    return STORAGE_LEAF_VALUE_LENGTH if is_storage_key(key) else 32
 
def encode_storage_leaf(slot_value: bytes, last_written_block: int) -> bytes:
    assert len(slot_value) == 32
    return slot_value + last_written_block.to_bytes(LAST_WRITTEN_BLOCK_SIZE, "big")
```
 
### Changes to EIP-8297 tree rules
 
**Value length.** EIP-8297's `state_root` asserts `len(value) == 32` for every entry. This proposal replaces that assertion with `len(value) == value_length(key)`. Merkelization does not change: `leaf_hash = H(LEAF_TAG || key || value)`.
 
**Zero and absence.** EIP-8297 turns a write of 32 zero bytes into a deletion. For storage leaves, this proposal applies that test to `slot_value` only. A storage write whose `slot_value` is 32 zero bytes MUST delete the leaf, metadata included. As before, no storage leaf holds a zero `slot_value`, and reading an absent slot returns zero. Non-storage leaves are unaffected.
 
**Account deletion.** [EIP-161](./eip-161.md) state clearing and same-transaction `SELFDESTRUCT` under [EIP-6780](./eip-6780.md) remove the account's header leaves and storage leaves, as specified in EIP-8297. Whether an account is empty depends on nonce, balance and code only. A nonzero `last_written_block` MUST NOT keep an otherwise empty account alive.
 
**Non-empty storage check.** The [EIP-7610](./eip-7610.md) check does not change: an address has non-empty storage exactly when a storage leaf exists for it.
 
```python
def storage_write(entries, address, storage_key, slot_value, block_number):
    key = get_tree_key_for_storage_slot(address, storage_key)
    old = entries.get(key)
    old_slot_value = old[:32] if old is not None else b"\x00" * 32
 
    if slot_value == old_slot_value:
        return                                   # no-op write: nothing changes
 
    if slot_value == b"\x00" * 32:
        entries.pop(key)                         # deletion: leaf and its metadata removed
    else:
        entries[key] = encode_storage_leaf(slot_value, block_number)
 
    # The account's BASIC_DATA leaf is not touched.
 
# Called by the account rules (balance, nonce, creation). Never called by storage_write.
def set_account_last_written_block(entries, address, block_number):
    key = get_tree_key_for_basic_data(address)
    data = bytearray(entries[key])
    start = ACCOUNT_LAST_WRITTEN_BLOCK_OFFSET
    data[start:start + LAST_WRITTEN_BLOCK_SIZE] = block_number.to_bytes(LAST_WRITTEN_BLOCK_SIZE, "big")
    entries[key] = bytes(data)
```
 
### Update rules
 
`last_written_block` is set to the current `block_number` when a piece of state is mutated. Writing again within the same block is idempotent: the field already equals `block_number`, so nothing further changes.
 
The rules below follow EIP-8188, with one difference: a storage write does not update the account's `last_written_block`. A slot's field and its account's field are independent.
 
#### Storage slot rules
 
* **Value change** (`SSTORE` nonzero → different nonzero): set the slot leaf's `last_written_block = block_number`.
* **Slot deletion** (`SSTORE` to zero): the slot leaf is removed from the tree together with its metadata, so there is no slot field left to update.
* **No-op write** (`SSTORE` same value): no change to the slot leaf.
* **New slot** (zero → nonzero): the slot leaf is created with `last_written_block = block_number`.
No storage slot rule changes the account's `BASIC_DATA` leaf. This holds for header slots 0..63 as well: they share the account's stem but are separate leaves.
 
#### Account rules
 
* **Balance transfer** (nonzero value): set `last_written_block = block_number` for both the sender and the receiver.
* **Nonce increment**: set `last_written_block = block_number`. This includes the authority nonce increment performed by each valid [EIP-7702](./eip-7702.md) authorization, so setting or clearing a delegation updates the authority's `last_written_block`.
* **New account**: the `BASIC_DATA` leaf is created with `last_written_block = block_number`.
* `SELFDESTRUCT`: follows the balance-transfer rule under EIP-6780. When the contract was not created in the same transaction, it is not removed, so set `last_written_block = block_number` on the self-destructing account and on the beneficiary whenever their balances change. There is no update when the beneficiary is the account itself, since its balance does not change. A contract created and destroyed in the same transaction is removed from the tree and carries no `last_written_block`. Only a surviving beneficiary whose balance changes is updated.
Balance and nonce mutations not named above, such as transaction fee payment, the priority fee credited to the fee recipient, and withdrawals, fall under the general rule at the top of this section.
 
#### Reads
 
Pure reads MUST NOT update `last_written_block`. This includes `SLOAD`, `BALANCE`, `EXTCODESIZE`, `EXTCODECOPY`, `EXTCODEHASH`, and call opcodes that do not mutate state. Retrieving `last_written_block` itself (see Retrieval) is also a pure read.
 
#### Reverts
 
When a call frame reverts, `last_written_block` is restored to its value from before the frame, exactly like `balance`, `nonce` and storage. Because the field sits in the same leaf value as the state it dates, it is journaled and reverted with that leaf. Implementations MUST NOT keep a `last_written_block` update whose accompanying state change was rolled back.
 
#### Scope
 
Code-zone leaves, `CODE_HASH_LEAF_KEY` leaves and `DELEGATION_LEAF_KEY` leaves carry no `last_written_block` of their own. This matches EIP-8188, which dates only accounts and storage slots. Those leaves change only alongside account creation or a nonce increment, and both of those update the account's `BASIC_DATA`.
 
### Retrieval
 
The `last_written_block` of any account or storage slot can be retrieved at will. It is part of the leaf's committed value, so reading it needs only the leaf: no transaction execution, no side index and no state change.
 
```python
def get_account_last_written_block(entries, address) -> int | None:
    value = entries.get(get_tree_key_for_basic_data(address))
    if value is None:
        return None                              # account does not exist
    start = ACCOUNT_LAST_WRITTEN_BLOCK_OFFSET
    return int.from_bytes(value[start:start + LAST_WRITTEN_BLOCK_SIZE], "big")
 
def get_storage_last_written_block(entries, address, storage_key) -> int | None:
    value = entries.get(get_tree_key_for_storage_slot(address, storage_key))
    if value is None:
        return None                              # slot is zero and carries no metadata
    start = STORAGE_LAST_WRITTEN_BLOCK_OFFSET
    return int.from_bytes(value[start:start + LAST_WRITTEN_BLOCK_SIZE], "big")
```
 
Retrieval has these properties:
 
* **Read-only.** Retrieval never updates `last_written_block` or any other state.
* **Location-independent.** The metadata travels inside the leaf, so it is read the same way whether the leaf is held in a client's primary database, a cold or archival store, a snapshot, or a block witness.
* **Verifiable.** `last_written_block` is covered by `leaf_hash`, so a standard EIP-8297 inclusion proof for a leaf also proves that leaf's `last_written_block` against the state root. Light clients and stateless verifiers can check it without trusting the node that served it.
* **Defined for legacy state.** State not written since activation returns `0` (see Backwards Compatibility).
Like EIP-8188, this proposal adds no EVM opcode, and the field stays invisible to contracts. Retrieval happens at the client, RPC and proof level. Clients MAY expose it through JSON-RPC; standardizing such a method is out of scope.
 
## Rationale
 
### Why pack the account field into `BASIC_DATA`?
 
Every account access already opens the `BASIC_DATA` leaf. Putting `last_written_block` there means reading or updating an account's write age needs no extra branch opening, and accounts grow by zero bytes, compared with 5 bytes per account under EIP-8188. One of the reserved header sub-indices between `CODE_HASH_LEAF_KEY` and `HEADER_STORAGE_OFFSET` could hold a separate field instead, but that would add one leaf per account.
 
### Why 4 bytes?
 
EIP-8188 encodes `last_written_block` as an RLP integer, which uses only as many bytes as the number needs. Every current mainnet block number needs 4. EIP-8188 notes that the field would need a fifth byte only after block `2^32 - 1` (about 4.29 billion), which is about 1,600 years away at 12-second slots and about 800 years at 6-second slots. Under RLP, that growth happens automatically.
 
PBT leaves have no RLP. Fields sit at fixed offsets, so `last_written_block` needs a fixed width, chosen once. Three bytes is too few: `2^24 - 1 = 16,777,215` is already below mainnet's block height. Four bytes is the most `BASIC_DATA` can give without taking space from `nonce` or `balance`. A fifth byte would have to come from `code_size`, and a 2-byte `code_size` tops out at 65,535, just under the 64 KiB code size limit. Storage leaves could hold a wider field, but they use the same 4 bytes so that an account and its slots store the block number the same way.
 
Unlike EIP-8188's field, this one cannot grow on its own. A block number of `2^32` or above cannot be encoded, so a later fork must widen the field, for example by moving it into its own header leaf, before mainnet reaches block `2^32`.
 
### Why narrow `code_size`?
 
`BASIC_DATA` has only three reserved bytes, so the fourth byte of `last_written_block` has to come from an existing field. `nonce` is 8 bytes because [EIP-2681](./eip-2681.md) caps nonces at `2^64 - 1`, so narrowing it would change a consensus limit. `balance` could give up a byte in practice, but its width is not tied to any protocol limit, so narrowing it would introduce a new consensus bound on balances. `code_size` is the only field whose range is already capped by a protocol limit far below its width.
 
### Why widen the storage leaf rather than pack into 32 bytes?
 
A storage slot holds a full 256-bit EVM word, and every byte of it is meaningful. There are no reserved bytes to reuse, and taking bits from the word would change what a contract can store. The alternatives are to widen the leaf or to add a parallel metadata leaf. A parallel leaf doubles the storage leaf count, needs its own key and branch, and must be kept in lockstep with the slot. Widening keeps the metadata inside the same leaf, so one read, one write and one proof cover both, and the metadata is deleted, reverted and migrated together with the slot automatically.
 
### Why 36 bytes?
 
The leaf needs exactly the 32-byte slot value and the 4-byte block number, so the value is 36 bytes. Across about 1.5 billion slots (EIP-8188's early-2026 estimate), that adds about 6 GB of raw data, less than the roughly 9 GB EIP-8188 adds with its 6-byte RLP framing.
 
The slot value comes first, so it stays at offset 0, where EIP-8297 puts it. Code that reads slot content takes the first 32 bytes, as before.
 
With the BLAKE3 hash used by EIP-8297's reference implementation, the extra 4 bytes do not add a compression. A leaf's hash preimage is `LEAF_TAG || key || value`: 71 bytes for a header slot and 103 bytes for a storage-zone slot. Each still fits in two 64-byte blocks, the same as with a 32-byte value. The merkelization hash is not final, so this should be rechecked once it is chosen.
 
### Why is there no storage-to-account cascade?
 
In EIP-8188, a storage write also updates the account's `last_written_block`. That follows from the MPT's shape: the account RLP contains `storageRoot`, so every storage write rewrites the account leaf anyway, and the field records that rewrite.
 
The PBT has no `storage_root`. An account's header and its storage slots are separate leaves, and a storage write never touches `BASIC_DATA`. A cascade would add a `BASIC_DATA` rewrite that the tree does not otherwise perform, in every block in which a contract's storage changes.
 
Without the cascade, each field dates its own leaf. The account's field records the last write to the header (balance, nonce, code), and each slot's field records the last write to that slot. In both trees, `last_written_block` is therefore the last block in which that leaf was written.
 
The cost is that an account's field no longer covers its storage, as it does under EIP-8188. A tiering rule that classifies each leaf by its own `last_written_block` applies directly. A rule that prices an `SSTORE` through the account leaf has no account write to price on the PBT.
 
### Why record the raw block number?
 
As in EIP-8188, the block number is the finest-grained primitive. Any coarser value a tiering or pricing scheme needs, such as the periods of EIP-8295, can be derived from it deterministically. Storing the finest granularity keeps this encoding independent of pricing parameters that are still being decided.
 
### Relation with state creation cost
 
Account leaves grow by zero bytes. Storage leaves grow by 4 bytes. For state-creation gas under [EIP-8037](./eip-8037.md) to track on-disk growth, `STATE_BYTES_PER_STORAGE_SET` SHOULD include the 4 additional bytes per storage leaf. `STATE_BYTES_PER_NEW_ACCOUNT` needs no adjustment for this proposal.
 
## Backwards Compatibility
 
* **Hard fork required.** This proposal changes the `BASIC_DATA` layout, the storage leaf value length and the storage deletion test, all of which affect the state root.
* **Activation with EIP-8297 is RECOMMENDED.** Activating this proposal in the same fork as EIP-8297 means the PBT is built with this layout from the start. Activating it later would require rewriting every `BASIC_DATA` leaf, because `code_size` moves, and every storage leaf, because its value widens.
* **EVM behavior.** `SLOAD` returns `slot_value` only. `BALANCE`, `EXTCODESIZE`, `EXTCODECOPY` and `EXTCODEHASH` are unchanged, and `code_size` keeps its meaning. No contract code changes.
* **Proof verifiers.** Any verifier of PBT proofs must handle the new `BASIC_DATA` layout and the 36-byte storage leaf value.
## Test Cases
 
The merkelization hash is not final, so digests are not pinned. `H(x)` denotes the 32-byte `key_hash` of `x`. Block numbers are illustrative. The example follows one contract, `A`, with 1,234 bytes of code and nonce 1.
 
**Block 30,000,000:** `A` **receives 1 ETH.** This is a nonzero balance transfer, so `A`'s `last_written_block` is set.
 
`BASIC_DATA` key: `0x00 || H(A) || 0x00`
 
| Field                | Offset | Bytes                                             | Decoded            |
| -------------------- | ------ | ------------------------------------------------- | ------------------ |
| `version`            | 0      | `00`                                              | 0                  |
| `last_written_block` | 1      | `01 C9 C3 80`                                     | 30,000,000         |
| `code_size`          | 5      | `00 04 D2`                                        | 1,234              |
| `nonce`              | 8      | `00 00 00 00 00 00 00 01`                         | 1                  |
| `balance`            | 16     | `00 00 00 00 00 00 00 00 0D E0 B6 B3 A7 64 00 00` | 10\^18 wei (1 ETH) |
 
**Block 30,000,500: one transaction sets slot 5 from 0 to 42 and slot 1000 from 7 to 8.**
 
Slot 5 lives in the header stem, since 5 < 64. It is a new slot.
 
* Key: `0x00 || H(A) || 0x45` (sub-index 64 + 5 = 69)
* Value (36 bytes): `00 × 31, 2A | 01 C9 C5 74`
Slot 1000 lives in the storage zone: `tree_index = 1000 // 256 = 3` and `sub_index = 1000 % 256 = 232`. It is a value change.
 
* Key: `0xFF || H(A) || H(A || 3) || 0xE8`
* Value (36 bytes): `00 × 31, 08 | 01 C9 C5 74`
Neither write touches `A`'s `BASIC_DATA` leaf. Its `last_written_block` stays at 30,000,000.
 
**Block 30,000,600: reads and a no-op write.** A transaction calls `SLOAD` on slot 1000, `BALANCE(A)` and `EXTCODESIZE(A)`, and writes 42 to slot 5 again. Nothing changes: the reads are pure, and the write is a no-op.
 
**Block 30,000,700: slot 1000 is set to 0.** The slot leaf at `0xFF || H(A) || H(A || 3) || 0xE8` is deleted together with its metadata. `A`'s `BASIC_DATA` leaf is unchanged.
 
**Block 30,000,800: a reverted write.** A call frame writes 43 to slot 5 and then reverts. The slot 5 leaf keeps `slot_value = 42` and `last_written_block = 30,000,500`.
 
**Block 30,000,900:** `A` **sends 0.25 ETH.** This is a nonzero balance transfer, so `A`'s `BASIC_DATA` bytes 1..4 become `01 C9 C7 04` (30,000,900). No storage leaf changes.
 
**Retrieval after block 30,000,900:**
 
| Query                                     | Leaf read                                | Result                |
| ----------------------------------------- | ---------------------------------------- | --------------------- |
| `get_account_last_written_block(A)`       | `0x00 \|\| H(A) \|\| 0x00`, bytes 1..4   | 30,000,900            |
| `get_storage_last_written_block(A, 5)`    | `0x00 \|\| H(A) \|\| 0x45`, bytes 32..35 | 30,000,500            |
| `get_storage_last_written_block(A, 1000)` | absent                                   | `None` (slot is zero) |
 
## Security Considerations
 
**Preimage injectivity.** EIP-8297's injectivity argument rests on the node tags, the explicit bit count in branch prefixes, and one fixed key length per zone. Under this proposal, a leaf's value length is a function of its key: the zone byte, and within `ACCOUNT_ZONE` the sub-index. `LEAF_TAG || key || value` therefore still parses uniquely, and no two distinct logical leaves share a preimage.
 
**State growth.** This proposal adds no new write operations. The field changes only in a leaf that the same operation is already writing, so every update rides on a write that is already paid for. The 4 additional bytes per storage leaf are real state growth and SHOULD be priced into state-creation gas; otherwise new slots are underpriced relative to their encoded size.
 
**Witness size.** Proofs of storage slots grow by 4 bytes per proven slot, because the leaf value is larger. Account proofs are unchanged.
 
`STATICCALL` **correctness.** `last_written_block` is consensus state and reads never update it, so the [EIP-214](./eip-214.md) guarantee that state is unchanged across a `STATICCALL` holds.
 
## Copyright
 
Copyright and related rights waived via [CC0](../LICENSE.md).