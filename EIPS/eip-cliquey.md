---
eip: 0000
title: Cliquey proof-of-authority consensus protocol
author: Aidan Hyman (@ChainSafe)
discussions-to: https://github.com/goerli/eips-poa
status: Draft
type: Standards Track
category: Core
created: 2019-04-19
requires: EIP-225
---

## Simple Summary

This document proposes a new proof-of-authority consensus engine that could be used by Ethereum testing and development networks in future.

## Abstract

_Cliquey_ is the second iteration of the _Clique_ proof-of-authority consensus protocol, previously discussed as _"Clique_v2"_. It comes with some usability and stability optimizations gained from creating the _Görli_ and _Kotti_ cross-client proof-of-authority networks that were implemented in Geth, Parity Ethereum, Pantheon, Nethermind, and various other clients.

## Motivation

The _Kotti_ and _Görli_ testnets running different implementations of the Clique engine got stuck multiple times due to minor issues discovered. These issues were partially addressed on the mono-client _Rinkeby_ by improving the Geth code.

However, optimizations across multiple clients should be properly specified and discussed. This working document is a result of a couple of months testing and running cross-client Clique networks, especially with the feedback gathered by several Pantheon, Nethermind, and Parity Ethereum engineers on different channels.

The overall goal is to simplify the setup and configuration of proof-of-authority networks and avoid the testnets to get stuck while maintaining and mimicking mainnet conditions.

For a general motivation on Proof-of-Authorty testnets, please refer to the exhaustive introduction in EIP-225 which this proposal is based on.

## Specification

We define the following constants:

 * **`EPOCH_LENGTH`**: The number of blocks after which to checkpoint and reset the pending votes. It is suggested to remain analogous to the mainnet `ethash` proof-of-work epoch (`30_000`).
 * **`BLOCK_PERIOD`**: The minimum difference between two consecutive block's timestamps. It is suggested to remain analogous to the mainnet `ethash` proof-of-work blocktime target (`15` seconds).
 * **`EXTRA_VANITY`**: The fixed number of extra-data prefix bytes reserved for signer _vanity_. It is suggested to retain the current extra-data allowance and/or use (`32` bytes).
 * **`EXTRA_SEAL`**: The fixed number of extra-data suffix bytes reserved for signer seal: `65 bytes` fixed as signatures are based on the standard `secp256k1` curve.
 * **`NONCE_AUTH`**: Magic nonce number `0xffffffffffffffff` to vote on adding a new signer.
 * **`NONCE_DROP`**: Magic nonce number `0x0000000000000000` to vote on removing a signer.
 * **`UNCLE_HASH`**: Always `Keccak256(RLP([]))` as uncles are meaningless outside of proof-of-work.
 * **`DIFF_NOTURN`**: Block score (difficulty) for blocks containing out-of-turn signatures. It should be set to `1` since it just needs to be an arbitrary baseline constant.
 * **`DIFF_INTURN`**: Block score (difficulty) for blocks containing in-turn signatures. It should be `3` to show a preference over out-of-turn signatures.
 * **`MIN_WAIT`**: The minimum time to wait for an out-of-turn block to be published. It is suggested to set it to `BLOCK_PERIOD / 2`.

We also define the following per-block constants:

 * **`BLOCK_NUMBER`**: The block height in the chain, where the height of the genesis is block `0`.
 * **`SIGNER_COUNT`**: The number of authorized signers valid at a particular instance in the chain.
 * **`SIGNER_INDEX`**: The index of the block signer in the sorted list of current authorized signers.
 * **`SIGNER_LIMIT`**: The number of consecutive blocks out of which a signer may only sign one. It must be `floor(SIGNER_COUNT / 3) + 1` to enforce at least `> 33%` consensus on a proof-of-authority chain.

We repurpose the `ethash` header fields as follows:

 * **`beneficiary`**: The address to propose modifying the list of authorized signers with.
   * Should be filled with zeroes normally, modified only while voting.
   * Arbitrary values are permitted nonetheless (even meaningless ones such as voting out non-signers) to avoid extra complexity in implementations around voting mechanics.
   * It **must** be filled with zeroes on checkpoint (i.e. epoch transition) blocks.
   * Transaction execution **must** use the actual block signer (see `extraData`) for the `COINBASE` opcode.
 * **`nonce`**: The signer proposal regarding the account defined by the `beneficiary` field.
   * It should be **`NONCE_DROP`** to propose deauthorizing `beneficiary` as a existing signer.
   * It should be **`NONCE_AUTH`** to propose authorizing `beneficiary` as a new signer.
   * It **must** be filled with zeroes on checkpoint (i.e., on epoch transition) blocks.
   * It **must** not take up any other value apart from the two above.
 * **`extraData`**: Combined field for signer vanity, checkpointing and signer signatures.
   * The first **`EXTRA_VANITY`** fixed bytes may contain arbitrary signer vanity data.
   * The last **`EXTRA_SEAL`** fixed bytes are the signer's signature sealing the header.
   * Checkpoint blocks **must** contain a list of signers (`N*20` bytes) in between, **omitted** otherwise.
   * The list of signers in checkpoint block extra-data sections **must** be sorted in ascending order.
 * **`mixHash`**: Reserved for fork protection logic, similar to the extra-data during the DAO.
   * It **must** be filled with zeroes during normal operation.
 * **`ommersHash`**: It **must** be **`UNCLE_HASH`** as uncles are meaningless outside of proof-of-work.
 * **`timestamp`**: It **must** be greater than the parent timestamp.
 * **`difficulty`**: It contains the standalone score of the block to derive the quality of a chain.
   * It **must** be **`DIFF_NOTURN`** if `BLOCK_NUMBER % SIGNER_COUNT != SIGNER_INDEX`
   * It **must** be **`DIFF_INTURN`** if `BLOCK_NUMBER % SIGNER_COUNT == SIGNER_INDEX`

For a detailed specification of the block authorization logic, please refer to EIP-225 by honoring the constants defined above. However, the following changes should be highlighted:

* Each singer is allowed to sign maximum one out of **`SIGNER_LIMIT`** consecutive blocks. The order is not fixed, but in-turn signing weighs more (**`DIFF_INTURN`**) than out of turn one (**`DIFF_NOTURN`**). In case an out-of-turn block is received, an **in-turn signer should continue to publish their block** to ensure the chain always prefers in-turn blocks in any case. This prevents in-turn validators to be prevented from publishing their block and potential network problems.

 * If a signer is allowed to sign a block (is on the authorized list and didn't sign recently).
   * Calculate the optimal signing time of the next block (parent + **`BLOCK_PERIOD`**).
   * If the signer is in-turn, wait for the exact time to arrive, sign and broadcast immediately.
   * If the signer is out-of-turn, delay signing by `MIN_WAIT + rand(SIGNER_COUNT * 500ms)`.

This small strategy will ensure that the in-turn signer (who's block weighs more) has a slight advantage to sign and propagate versus the out-of-turn signers. Also the scheme allows a bit of scale with the increase of the number of signers.

### Voting on signers

Every epoch transition (genesis block included) acts as a stateless checkpoint, from which capable clients should be able to sync without requiring any previous state. This means epoch headers **must not** contain votes, all non settled votes are discarded, and tallying starts from scratch.

For all non-epoch transition blocks:

 * Signers may cast one vote per own block to propose a change to the authorization list.
 * Only the latest proposal per target beneficiary is kept from a single signer.
 * Votes are tallied live as the chain progresses (concurrent proposals allowed).
 * Proposals reaching majority consensus **`SIGNER_LIMIT`** come into effect immediately.
 * Invalid proposals are **not** to be penalized for client implementation simplicity.

**A proposal coming into effect entails discarding all pending votes for that proposal (both for and against) and starting with a clean slate.**

#### Cascading votes

A complex corner case may arise during signer deauthorization. When a previously authorized signer is dropped, the number of signers required to approve a proposal might decrease by one. This might cause one or more pending proposals to reach majority consensus, the execution of which might further cascade into new proposals passing.

Handling this scenario is non obvious when multiple conflicting proposals pass simultaneously (e.g. add a new signer vs. drop an existing one), where the evaluation order might drastically change the outcome of the final authorization list. Since signers may invert their own votes in every block they mint, it's not so obvious which proposal would be "first".

To avoid the pitfalls cascading executions would entail, the Clique proposal explicitly forbids cascading effects. In other words: **Only the `beneficiary` of the current header/vote may be added to/dropped from the authorization list. If that causes other proposals to reach consensus, those will be executed when their respective beneficiaries are "touched" again (given that majority consensus still holds at that point).**

#### Voting strategies

Since the blockchain can have small reorgs, a naive voting mechanism of "cast-and-forget" may not be optimal, since a block containing a singleton vote may not end up on the final chain.

A simplistic but working strategy is to allow users to configure "proposals" on the signers (e.g. "add 0x...", "drop 0x..."). The signing code can then pick a random proposal for every block it signs and inject it. This ensures that multiple concurrent proposals as well as reorgs get eventually noted on the chain.

This list may be expired after a certain number of blocks / epochs, but it's important to realize that "seeing" a proposal pass doesn't mean it won't get reorged, so it should not be immediately dropped when the proposal passes.

## Test Cases

```go
// block represents a single block signed by a parcitular account, where
// the account may or may not have cast a Clique vote.
type block struct {
  signer     string   // Account that signed this particular block
  voted      string   // Optional value if the signer voted on adding/removing someone
  auth       bool     // Whether the vote was to authorize (or deauthorize)
  checkpoint []string // List of authorized signers if this is an epoch block
}

// Define the various voting scenarios to test
tests := []struct {
  epoch   uint64   // Number of blocks in an epoch (unset = 30000)
  signers []string // Initial list of authorized signers in the genesis
  blocks  []block  // Chain of signed blocks, potentially influencing auths
  results []string // Final list of authorized signers after all blocks
  failure error    // Failure if some block is invalid according to the rules
}{
  {
    // Single signer, no votes cast
    signers: []string{"A"},
    blocks:  []block{{signer: "A"}},
    results: []string{"A"},
  }, {
    // Single signer, voting to add two others (only accept first, second needs 2 votes)
    signers: []string{"A"},
    blocks:  []block{
      {signer: "A", voted: "B", auth: true},
      {signer: "B"},
      {signer: "A", voted: "C", auth: true},
    },
    results: []string{"A", "B"},
  }, {
    // Two signers, voting to add three others (only accept first two, third needs 3 votes already)
    signers: []string{"A", "B"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: true},
      {signer: "B", voted: "C", auth: true},
      {signer: "A", voted: "D", auth: true},
      {signer: "B", voted: "D", auth: true},
      {signer: "C"},
      {signer: "A", voted: "E", auth: true},
      {signer: "B", voted: "E", auth: true},
    },
    results: []string{"A", "B", "C", "D"},
  }, {
    // Single signer, dropping itself (weird, but one less cornercase by explicitly allowing this)
    signers: []string{"A"},
    blocks:  []block{
      {signer: "A", voted: "A", auth: false},
    },
    results: []string{},
  }, {
    // Two signers, actually needing mutual consent to drop either of them (not fulfilled)
    signers: []string{"A", "B"},
    blocks:  []block{
      {signer: "A", voted: "B", auth: false},
    },
    results: []string{"A", "B"},
  }, {
    // Two signers, actually needing mutual consent to drop either of them (fulfilled)
    signers: []string{"A", "B"},
    blocks:  []block{
      {signer: "A", voted: "B", auth: false},
      {signer: "B", voted: "B", auth: false},
    },
    results: []string{"A"},
  }, {
    // Three signers, two of them deciding to drop the third
    signers: []string{"A", "B", "C"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: false},
      {signer: "B", voted: "C", auth: false},
    },
    results: []string{"A", "B"},
  }, {
    // Four signers, consensus of two not being enough to drop anyone
    signers: []string{"A", "B", "C", "D"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: false},
      {signer: "B", voted: "C", auth: false},
    },
    results: []string{"A", "B", "C", "D"},
  }, {
    // Four signers, consensus of three already being enough to drop someone
    signers: []string{"A", "B", "C", "D"},
    blocks:  []block{
      {signer: "A", voted: "D", auth: false},
      {signer: "B", voted: "D", auth: false},
      {signer: "C", voted: "D", auth: false},
    },
    results: []string{"A", "B", "C"},
  }, {
    // Authorizations are counted once per signer per target
    signers: []string{"A", "B"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: true},
      {signer: "B"},
      {signer: "A", voted: "C", auth: true},
      {signer: "B"},
      {signer: "A", voted: "C", auth: true},
    },
    results: []string{"A", "B"},
  }, {
    // Authorizing multiple accounts concurrently is permitted
    signers: []string{"A", "B"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: true},
      {signer: "B"},
      {signer: "A", voted: "D", auth: true},
      {signer: "B"},
      {signer: "A"},
      {signer: "B", voted: "D", auth: true},
      {signer: "A"},
      {signer: "B", voted: "C", auth: true},
    },
    results: []string{"A", "B", "C", "D"},
  }, {
    // Deauthorizations are counted once per signer per target
    signers: []string{"A", "B"},
    blocks:  []block{
      {signer: "A", voted: "B", auth: false},
      {signer: "B"},
      {signer: "A", voted: "B", auth: false},
      {signer: "B"},
      {signer: "A", voted: "B", auth: false},
    },
    results: []string{"A", "B"},
  }, {
    // Deauthorizing multiple accounts concurrently is permitted
    signers: []string{"A", "B", "C", "D"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: false},
      {signer: "B"},
      {signer: "C"},
      {signer: "A", voted: "D", auth: false},
      {signer: "B"},
      {signer: "C"},
      {signer: "A"},
      {signer: "B", voted: "D", auth: false},
      {signer: "C", voted: "D", auth: false},
      {signer: "A"},
      {signer: "B", voted: "C", auth: false},
    },
    results: []string{"A", "B"},
  }, {
    // Votes from deauthorized signers are discarded immediately (deauth votes)
    signers: []string{"A", "B", "C"},
    blocks:  []block{
      {signer: "C", voted: "B", auth: false},
      {signer: "A", voted: "C", auth: false},
      {signer: "B", voted: "C", auth: false},
      {signer: "A", voted: "B", auth: false},
    },
    results: []string{"A", "B"},
  }, {
    // Votes from deauthorized signers are discarded immediately (auth votes)
    signers: []string{"A", "B", "C"},
    blocks:  []block{
      {signer: "C", voted: "D", auth: true},
      {signer: "A", voted: "C", auth: false},
      {signer: "B", voted: "C", auth: false},
      {signer: "A", voted: "D", auth: true},
    },
    results: []string{"A", "B"},
  }, {
    // Cascading changes are not allowed, only the account being voted on may change
    signers: []string{"A", "B", "C", "D"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: false},
      {signer: "B"},
      {signer: "C"},
      {signer: "A", voted: "D", auth: false},
      {signer: "B", voted: "C", auth: false},
      {signer: "C"},
      {signer: "A"},
      {signer: "B", voted: "D", auth: false},
      {signer: "C", voted: "D", auth: false},
    },
    results: []string{"A", "B", "C"},
  }, {
    // Changes reaching consensus out of bounds (via a deauth) execute on touch
    signers: []string{"A", "B", "C", "D"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: false},
      {signer: "B"},
      {signer: "C"},
      {signer: "A", voted: "D", auth: false},
      {signer: "B", voted: "C", auth: false},
      {signer: "C"},
      {signer: "A"},
      {signer: "B", voted: "D", auth: false},
      {signer: "C", voted: "D", auth: false},
      {signer: "A"},
      {signer: "C", voted: "C", auth: true},
    },
    results: []string{"A", "B"},
  }, {
    // Changes reaching consensus out of bounds (via a deauth) may go out of consensus on first touch
    signers: []string{"A", "B", "C", "D"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: false},
      {signer: "B"},
      {signer: "C"},
      {signer: "A", voted: "D", auth: false},
      {signer: "B", voted: "C", auth: false},
      {signer: "C"},
      {signer: "A"},
      {signer: "B", voted: "D", auth: false},
      {signer: "C", voted: "D", auth: false},
      {signer: "A"},
      {signer: "B", voted: "C", auth: true},
    },
    results: []string{"A", "B", "C"},
  }, {
    // Ensure that pending votes don't survive authorization status changes. This
    // corner case can only appear if a signer is quickly added, removed and then
    // readded (or the inverse), while one of the original voters dropped. If a
    // past vote is left cached in the system somewhere, this will interfere with
    // the final signer outcome.
    signers: []string{"A", "B", "C", "D", "E"},
    blocks:  []block{
      {signer: "A", voted: "F", auth: true}, // Authorize F, 3 votes needed
      {signer: "B", voted: "F", auth: true},
      {signer: "C", voted: "F", auth: true},
      {signer: "D", voted: "F", auth: false}, // Deauthorize F, 4 votes needed (leave A's previous vote "unchanged")
      {signer: "E", voted: "F", auth: false},
      {signer: "B", voted: "F", auth: false},
      {signer: "C", voted: "F", auth: false},
      {signer: "D", voted: "F", auth: true}, // Almost authorize F, 2/3 votes needed
      {signer: "E", voted: "F", auth: true},
      {signer: "B", voted: "A", auth: false}, // Deauthorize A, 3 votes needed
      {signer: "C", voted: "A", auth: false},
      {signer: "D", voted: "A", auth: false},
      {signer: "B", voted: "F", auth: true}, // Finish authorizing F, 3/3 votes needed
    },
    results: []string{"B", "C", "D", "E", "F"},
  }, {
    // Epoch transitions reset all votes to allow chain checkpointing
    epoch:   3,
    signers: []string{"A", "B"},
    blocks:  []block{
      {signer: "A", voted: "C", auth: true},
      {signer: "B"},
      {signer: "A", checkpoint: []string{"A", "B"}},
      {signer: "B", voted: "C", auth: true},
    },
    results: []string{"A", "B"},
  }, {
    // An unauthorized signer should not be able to sign blocks
    signers: []string{"A"},
    blocks:  []block{
      {signer: "B"},
    },
    failure: errUnauthorizedSigner,
  }, {
    // An authorized signer that signed recenty should not be able to sign again
    signers: []string{"A", "B"},
  blocks []block{
      {signer: "A"},
      {signer: "A"},
    },
    failure: errRecentlySigned,
  }, {
    // Recent signatures should not reset on checkpoint blocks imported in a batch
    epoch:   3,
    signers: []string{"A", "B", "C"},
    blocks:  []block{
      {signer: "A"},
      {signer: "B"},
      {signer: "A", checkpoint: []string{"A", "B", "C"}},
      {signer: "A"},
    },
    failure: errRecentlySigned,
  },,
}
```

## Implementation

A reference implementation is part of [go-ethereum](https://github.com/ethereum/go-ethereum/tree/master/consensus/clique) and has been functioning as the consensus engine behind the [Rinkeby](https://www.rinkeby.io) testnet since April, 2017.
## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
