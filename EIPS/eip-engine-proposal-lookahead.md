---
eip: TBD
title: Engine API proposal lookahead
description: The consensus layer tells the execution layer, ahead of time, at which slots it will ask for a payload
author: Csaba Kiraly (@cskiraly)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-10-19
requires: 7917
---

## Abstract

This EIP adds an Engine API method, `engine_proposalLookaheadUpdatedV1`, with which a consensus
layer client (CL) tells its execution layer client (EL) the slots, timestamps, fee recipients and
target gas limits of the blocks its validators are scheduled to propose in the current and next
epoch. It is a notice, not a command: it starts no build, names no parent block and changes no
consensus rule. The EL uses it to prepare for those blocks in ways that do not need the parent
block: fetching blob data, warming the state, pre-executing pending transactions, and keeping its
own heavy work and network traffic away from the slot.

## Motivation

### What the EL knows, and when

In the Engine API up to and including Amsterdam, an EL learns that it has to produce a block when
the CL calls `engine_forkchoiceUpdated` with payload attributes, which also starts the build. The
call names the head to build on, and the attributes depend on it: the parent beacon block root,
and `prevRandao` and the withdrawals, computed from the parent's state advanced to the proposal
slot. A CL can send attributes before the parent arrives, but they then start a build on its
current head, which will not be the parent. In practice, the notice starts when the parent is
imported.

When CLs send it varies. Before Gloas, Prysm, Teku and Grandine send it on the parent's import,
Lighthouse and Lodestar 4 seconds before the slot, and Nimbus 1.5 seconds before; only
Lighthouse's lead can be configured. Even the earliest leaves only what remains after the parent
arrives: at least 8 seconds when the parent is on time, by 4 seconds into its slot, and more only
when the slot before it was empty.

The CL knows much earlier. Since [EIP-7917](./eip-7917.md) the proposer lookahead for the current
and next epoch is part of the beacon state, so every proposal is known at least one epoch, 6.4
minutes, before its slot. Of the payload attributes, the timestamp, the fee recipient and the
target gas limit are known as early. In the consensus specifications for Gloas, the consensus side
of the fork that brings [EIP-7732](./eip-7732.md), a CL already
[lists these slots](https://github.com/ethereum/consensus-specs/blob/460fd37c3a58f6baf8a9a285d2adf71c4f818929/specs/gloas/validator.md#broadcasting-signedproposerpreferences)
for its validators and may broadcast its preferences for them, the fee recipient and the target
gas limit, to builders. Its own EL is not told.

### Preparation that does not need the parent

A large part of what an EL can do to produce a block well does not depend on the parent block.
Only the EL knows how much time it needs for this preparation, so trying to drive it with the
timing of `engine_forkchoiceUpdated` is not ideal. Some examples, without trying to be exhaustive:

- **Blob data.** With the sparse blobpool ([EIP-8070](./eip-8070.md)), an EL fetches the full
  blobs of only some blob transactions and samples the rest, but to include a blob transaction it
  needs its full blobs. EIP-8070 therefore has local builders fetch the full blobs of every blob
  transaction they may include, all the time, at about four times a sampling node's blob
  bandwidth. It mentions the option of switching to that mode 2 to 3 slots before building, and
  advises against it because the switch is a visible pattern that compromises the builder's
  privacy and raises its risk of denial of service. Without notice an EL cannot make the switch at
  all; with notice minutes ahead it can make it at a randomized time, which gives limited
  protection where the node has no other.
- **State.** Executing the chain keeps warm the state that recent blocks touched, but not the state
  that pending transactions will touch. That can be read into the EL's caches before the slot, so
  that the build does not wait on the disk for it.
- **Pre-execution.** Pending transactions can be executed ahead of time with the announced
  timestamp, fee recipient and gas limit, and the results carried from head to head. A result can
  be reused only while everything it depended on still holds: the state it read, the block context
  it used, and what the transactions before it in the block changed.
- **The EL's own heavy work.** Database compaction, flushing state to disk, history pruning and
  similar maintenance can be kept away from the proposal slot.
- **Bandwidth.** Around its slot, the EL can hold back its own transaction and blob gossip, as far
  as its role in the network allows, so that the CL's block and data columns
  ([EIP-7594](./eip-7594.md)) get the node's uplink. Like the switch to full blobs, this is visible
  to peers and needs the same care.

A node that builds every slot, as a professional builder does, can do all of this all the time. A
validator proposes rarely. Without notice, whatever it prepares is mostly for blocks it will not
build: it can prepare continuously and pay for it, prepare within a small budget and gain little,
or not prepare at all.

### Shrinking timelines

Several changes shorten the time between knowing the parent and the slot, or add work to it:

- With enshrined proposer-builder separation (EIP-7732), an execution payload is revealed after
  the beacon block that commits to it, by the middle of the slot. A proposer that builds on that
  payload can form its payload attributes only once the payload is imported. By the deadlines, the
  time between a parent on time and the next slot shrinks from 8 seconds (a beacon block is on time
  until 4 seconds into its slot) to 6 (a payload is on time until 6 seconds into its slot), before
  the time it takes to import it. Building on the parent without its payload is possible sooner,
  but fork choice selects that only when the payload is late or missing. The proposer's own
  payload must still be complete at the start of its slot, because its beacon block commits to the
  payload's hash.
- The gas limit was raised to 60M ([EIP-7935](./eip-7935.md)), and core developers have agreed on
  200M for Glamsterdam, the fork that brings EIP-7732 and [EIP-7928](./eip-7928.md), more than
  three times that. Sepolia, where Glamsterdam activated in October 2026, runs at about 200M.
  Block-level access lists (EIP-7928) let validators read state and execute transactions in
  parallel, but a block's builder has to discover the dependencies itself. As limits rise on the
  strength of faster validation, building can become the limit for a local builder on the
  hardware [EIP-7870](./eip-7870.md) recommends.
- [EIP-8198](./eip-8198.md) (Quick Slots), considered for Hegotá, the fork after Glamsterdam, as of
  October 2026, shortens the slot from 12 seconds to 8 (to 10 in the current consensus
  specification draft), and [EIP-7782](./eip-7782.md) proposes 6. The gas limit shrinks with the
  slot, but fixed costs, such as waiting on the disk and the network, do not.
- With FOCIL ([EIP-7805](./eip-7805.md)), scheduled for Hegotá as of October 2026, a payload must
  satisfy the inclusion lists of the previous slot. Timely lists arrive by 9 seconds into that
  slot, so a self-building proposer may get them only 3 seconds before its payload must be
  complete. They are drawn from the public mempool, so an EL that has prepared the mempool's
  transactions in advance has less left to do when they arrive.

### Who benefits

Every validator, not only those that build all their blocks themselves. Consensus clients request
a local payload alongside an external builder's bid, as a fallback and to compare their values
(all six major ones, as of October 2026), so that payload has to be ready at the slot too; under
EIP-7732, proposers can still build their own payloads. Keeping local building viable on
recommended hardware as limits rise also keeps validators from depending on external builders for
every block, which censorship resistance relies on. For a CL, supporting the method costs about one
call per epoch, with data it already holds.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT",
"RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as
described in RFC 2119 and RFC 8174.

### Structures

#### ProposalV1

All fields are required.

- `slot`: `QUANTITY`, 64 bits: the beacon slot of the proposal.
- `timestamp`: `QUANTITY`, 64 bits: the timestamp of the block, as it will appear in the payload
  attributes, computed with the slot duration that applies at `slot`.
- `suggestedFeeRecipient`: `DATA`, 20 bytes: the fee recipient the CL would put in the payload
  attributes if `slot` were the next slot.
- `targetGasLimit`: `QUANTITY`, 64 bits: the target gas limit the CL would put in the payload
  attributes if `slot` were the next slot.

### Methods

#### engine_proposalLookaheadUpdatedV1

Request:

- method: `engine_proposalLookaheadUpdatedV1`
- params:
  1. `proposals`: `Array of ProposalV1`, the upcoming proposals of the validators attached to the
     CL, in strictly increasing `slot` order, at most 256 entries.
- timeout: 1s

Response:

- result: `null`
- error: code and message set in case an exception happens while processing the call.

Specification:

1. `proposals` is the complete set of upcoming proposals the CL knows for its validators. The call
   replaces the set the EL holds; an empty array clears it. The EL need not keep the set across
   restarts.
2. The EL MUST validate the whole request before replacing the set, and MUST leave the set
   unchanged when it returns an error:
   - `-38004: Too large request` if `proposals` has more than 256 entries;
   - `-32602: Invalid params` if an entry lacks a field or a field is malformed, or if `slot` or
     `timestamp` does not strictly increase from one entry to the next.
3. The call is advisory. The EL MAY ignore the proposals, or entries whose `timestamp` is not later
   than its head's or that it cannot use, but MUST still validate the request as in item 2. It MUST
   NOT start a build because of the call: a build starts, as before, with
   `engine_forkchoiceUpdated` and payload attributes, which alone determine the parent and the
   attributes of the payload. Where they differ from an announced proposal, the payload
   attributes apply.
4. The EL MAY use the proposals to prepare: fetch blob data, warm its caches, pre-execute
   transactions with the announced timestamps, fee recipients and gas limits, schedule its
   maintenance and network traffic. It decides when and how much to prepare. It SHOULD bound the
   total resources it spends preparing, and SHOULD NOT let preparation delay the import of blocks
   or its responses to other Engine API calls. It SHOULD start preparation that peers can observe
   at a randomized time, and SHOULD NOT expose the proposals through public RPC, metrics or logs.
5. The EL MUST process calls to this method in the order it receives them. The CL SHOULD NOT send
   a call before the previous one has returned.
6. Where several CLs share one EL, only the one that calls `engine_forkchoiceUpdated` MAY call this
   method: each call replaces the whole set, so calls from several CLs would overwrite each other.
7. The CL SHOULD call this method when it starts, after each `engine_exchangeCapabilities`
   exchange, at least once per epoch, and when its proposals change: when the dependent root of
   the current or next epoch changes, when validators are added or removed, and when a fee
   recipient or target gas limit changes. It MAY call it at any time.
8. The CL MUST NOT include proposals of validators it does not run.

### Optional support

Support for the method is optional on both sides, and not tied to a fork.

- An EL MAY implement the method. An EL that implements it MUST list it in the methods exchanged
  with `engine_exchangeCapabilities`. It validates every call (item 2), and uses as many of the
  proposals as it chooses, or none (item 3).
- A CL MAY implement the method. It MUST NOT call it on an EL that does not list it, and SHOULD
  call it as in item 7 on one that does.
- If either side does not implement the method, nothing changes: the CL does not call it, and the
  EL builds from `engine_forkchoiceUpdated` and the payload attributes, as before. A failed call
  MUST NOT affect the CL's other use of the Engine API.

## Rationale

**How this differs from `engine_preparePayload`.** The Engine API's first drafts had a method,
`engine_preparePayload`. It took the parent block's hash with the timestamp, `random` and fee
recipient, started building a payload on that parent and returned the build's identifier. In 2021
it was folded into `engine_forkchoiceUpdated` as optional payload attributes, to avoid "potential
synchronicity issues that arise when the methods are decoupled" (ethereum/execution-apis#83): a
build started on one parent by a separate call could disagree with a fork choice update naming
another head. That reasoning holds for a build command bound to a parent, and folding it into
fork choice was the right fix. It does not apply to a notice. The race came from naming a parent
and starting a build, not from telling the EL that a block will be needed, and no Engine API
method has ever told it that before the parent is known. This method is such a notice. It carries
only values that are fixed before the parent exists and it never starts a build: what a block
builds on, and with which attributes, is still decided only by `engine_forkchoiceUpdated`, so there
is nothing in this call for fork choice to disagree with. An EL can also safely disregard it, and
start building, and preparing to build, on `engine_forkchoiceUpdated` as it does today.

**Why this interface.** Preparing a block needs two kinds of knowledge, on the two sides of the
Engine API. The CL knows the schedule: which of its validators propose, at which slots, with which
fee recipient and target gas limit. The EL knows how to prepare: its state layout and caches, its
disk, its mempool and blob pool, its maintenance jobs and its network, and how long each of these
takes on its hardware. The method carries what the EL cannot know, the schedule, and nothing about
how to use it.

- **Facts, not instructions.** The CL states when blocks will be needed; it does not ask for a
  prefetch or a pre-execution. Methods of that kind would put today's preparation techniques into
  an interface every client has to implement, and each new technique would need a new method.
  With a schedule, ELs prepare in their own ways, change how without touching the interface, and
  can compete on it.
- **The EL sets its own timers.** How far ahead to start depends on the EL's hardware and on what
  it prepares: minutes to fetch blobs or to warm a slow disk, seconds for a fast one. Only the EL
  can tell, so the CL sends the whole schedule and the EL decides when to act on each entry.
- **Values the CL already has.** Each entry carries what the CL will later put in the payload
  attributes, which since the Amsterdam Engine API (PayloadAttributesV4) include the slot number
  and the target gas limit. The same fee recipient and gas limit already travel from the
  validator client to the beacon node through the beacon API (proposer preparation, validator
  registration and, from Gloas, signed proposer preferences, which the CL also gossips to
  builders). This method is the next leg, from the CL to its own EL. Nothing new has to be
  computed.
- **Schedule, not authority.** The call informs; `engine_forkchoiceUpdated` decides. Keeping the
  two in separate methods is what lets the schedule be sent before the parent exists.

**Why optional.** Nothing depends on the method for correctness. Every block is still built from
`engine_forkchoiceUpdated` and its payload attributes, so clients that do not implement the method
build exactly as today, and clients that do can ship it without waiting for a fork. Whether
preparing pays, and how much, depends on each EL's design and hardware, so each EL decides whether
to use the proposals.

**Precedents.** The Engine API already passes the EL information from the CL that changes nothing
in consensus, only how the EL runs: since Amsterdam, `engine_forkchoiceUpdatedV4` carries the CL's
custody columns (`custodyColumns`) for the sparse blobpool. Methods that are optional and not tied
to a fork exist too: `engine_getBlobsV1` was introduced after Cancun and defined as
backwards-compatible with it.

**Why not a longer payload preparation lookahead.** A CL can send payload attributes earlier than
its default, but they name a head: sent before the parent is known, they start a build on a block
that will not be the parent. The preparation in the motivation needs no parent: it should not have
to wait for one, nor pay for builds on the wrong one.

**Why not let the EL look up the duties.** An EL could poll a beacon node for proposer duties, but
it would have to know which validators it serves, which only the CL and its validator client know,
and follow the duties as they change, when an epoch's dependent root changes and as validators are
added or removed, which the CL already does.

**A full set per call.** Sending the complete set every time, instead of additions and removals,
makes the call idempotent: the CL corrects the EL after reorgs, restarts or failed calls by calling
again, and an EL that restarted gets the set back at the next call.

**What is sent.** The timestamp, fee recipient and target gas limit are the payload attributes the
CL knows in advance. Pre-execution needs the timestamp and the gas limit, and the gas limit also
bounds how much is worth preparing. Most transactions do not depend on the fee recipient: an EL can
pre-execute them with a placeholder and move the fee to the real recipient when it reuses the
result, as some execution clients already do for pending transactions. Transactions that read
`COINBASE` or touch the fee recipient's account need the real one. The values are those the CL would
use if the slot were next; the payload attributes, sent later, are authoritative. The timestamp is
sent rather than derived from the slot because the EL does not know the beacon chain's genesis time
and slot length, and EIP-8198 would make the slot length a setting that can change at a fork. The
parent block, `prevRandao` and the parent beacon block root are not known in advance; preparation
that depends on them has to wait for the build. The base fee follows from the parent. The slot
identifies the entry for logging and replacement, and matches the slot number of the payload
attributes.

**The bound.** EIP-7917 fixes the proposer lookahead for the current and next epoch, so a CL knows
at most 64 proposals at a time, however many validators it runs. The bound is 256 so that a longer
lookahead does not need a new version of the method; it only limits the size of a request.

**No response data.** The EL has nothing the CL needs back.

## Backwards Compatibility

The method is new, optional on both sides and not tied to a fork (see Optional support): clients
that do not implement it are unaffected. No other method changes.

## Test Cases

The [test vectors](../assets/eip-engine-proposal-lookahead/test-vectors.json) pair each request with the outcome an EL
must return for it, whatever calls came before. Only error codes are checked; messages differ
between clients.

- Success (`null`): 0, 1 and 256 proposals; entries already in the past; timestamps whose spacing
  changes, as across a fork that shortens the slot; the largest 64-bit values; upper-case hex
  digits.
- `-38004`: 257 proposals.
- `-32602`: a missing or `null` field; a `QUANTITY` that is a JSON number, lacks the `0x` prefix,
  is empty, has a leading zero or exceeds 64 bits; a fee recipient that is not 20 bytes of hex; a
  `slot` or `timestamp` that repeats or decreases; `proposals` that is `null` or an object, not
  an array; no parameter. The call fails as a whole, also when only one of its entries is
  malformed.

For example, this call announces two proposals, one in the current epoch and one in the next, by
validators with different fee recipients and target gas limits:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "engine_proposalLookaheadUpdatedV1",
  "params": [
    [
      {
        "slot": "0xecd10d",
        "timestamp": "0x6adffcf3",
        "suggestedFeeRecipient": "0x1111111111111111111111111111111111111111",
        "targetGasLimit": "0x3938700"
      },
      {
        "slot": "0xecd12d",
        "timestamp": "0x6adffe73",
        "suggestedFeeRecipient": "0x2222222222222222222222222222222222222222",
        "targetGasLimit": "0xbebc200"
      }
    ]
  ]
}
```

It returns `{"jsonrpc": "2.0", "id": 1, "result": null}`. With the second `slot` set to the
first's, `"0xecd10d"`, it returns an error with code `-32602`.

Further cases involve the EL's state or other methods:

- A later call replaces an earlier one; an empty array clears the set; a failed call leaves the
  set unchanged.
- A call starts no build: the EL returns no payload identifier for it, and a later
  `engine_forkchoiceUpdated` with payload attributes starts a build as usual.
- A build whose payload attributes differ from the announced proposal for its slot (timestamp, fee
  recipient or target gas limit) uses the payload attributes.
- Entries whose timestamp is not later than the head's may be ignored, but the request is still
  validated.

## Security Considerations

- **Privacy.** The EL learns when its validators propose. It runs for the same operator, which
  already learns it a few seconds before each slot from the payload attributes; a remote or shared
  EL learns it minutes earlier, and so can anyone who reads the Engine API traffic, which JWT
  authenticates but does not encrypt. The method adds nothing on the network, but preparation that
  peers can see may: fetching full blobs, changing how much the node gossips, or connecting to more
  peers before a slot tells them the node will propose soon. Proposer duties are public, so what
  this reveals is which node runs the validator, a step towards targeting it; fee recipients can
  also link validators to their operator. Specification item 4 asks ELs to start such preparation
  at a randomized time, which a notice minutes ahead makes possible, and to keep the proposals out
  of public RPC, metrics and logs; EIP-8070 discusses the same concern for blob fetching.
- **Denial of service.** Only an authenticated CL can make the call, and a request is bounded at
  256 entries. A faulty CL can only waste the EL's preparation, which the EL bounds (specification
  item 4).
- **Correctness.** The call cannot change what a block builds on (specification item 3). A prepared
  result is used only if everything it depended on still holds for the actual parent and payload
  attributes, which an EL implementing preparation is responsible for checking.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
