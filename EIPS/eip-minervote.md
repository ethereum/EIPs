---
eip: xxx
title: Generalized Version Bits Voting for Consensus Soft and Hard Forks
author: Wei Tang (@sorpaas)
discussions-to: https://github.com/sorpaas/EIPs/issues/5
status: Draft
type: Standards Track
category: Core
created: 2017-06-28
---

## Abstract

The following EIP tries to bring the best practices about how Bitcoin deals with consensus hard fork ([BIP-9](https://github.com/bitcoin/bips/blob/master/bip-0009.mediawiki) and [BIP-135](https://github.com/bitcoin/bips/blob/master/bip-0135.mediawiki)) into Ethereum. Rather than hard-code a block number as we currently do, each block mined emits support of the new consensus hard-fork. Only when a large enough portion of the network support it, the hard-fork is "locked-in" and will be activated.

## Motivation

**Best practices from Bitcoin**. [BIP-9](https://github.com/bitcoin/bips/blob/master/bip-0009.mediawiki), which uses version bits mined in each blocks to vote for consensus soft fork has be successfully conducted for several. Its upgraded version, BIP-135, aims to deal with both soft forks and hard forks alike.

**Potentially faster adoption of new consensus hard fork**. When dealing with emergency consensus hard fork for preventing network attacks, the developer would not need to artificially insert a "hard fork block number" (which must leave enough time for everyone else to upgrade their clients, and then wait for that block). The ETC coin holders and miners collectively decide when the hard fork happens, which potentially could be faster than hard coded block numbers.

## Terms and conventions

The version bits used by this proposal for signaling deployment of forks are
referred to as 'signaling bits' or shortened to 'bits' where unambiguous.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119.

## Specification

### Signaling bits

Ethereum's extraData field are 32-bytes, i.e. a 256-bit value. The field itself should be a RLP list that follows:

```
[ version: P, signalingBits: S, clientIdentity: B ]
```

For this EIP, `version` should equal to `1`, and `signalingBits` and `clientIdentity` fulfill the rest of the extraData field as long as it does not exceed the maximum size allowed. This allows us to have way more concurrent signalings and better backward compatibility than Bitcoin.

`signalingBits` are right-aligned, i.e. `0b1` has its bit at index 0 set, `0b10` has its bit at index 1 set, `0b100` has its bit at index 2 set.

### Deployment states

With each block and fork, we associate a deployment state. The possible states are:

* **DEFINED** is the first state that each fork starts out as. The genesis block for any chain SHALL by definition be in this state for each deployment.
* **STARTED** for blocks past the starttime.
* **LOCKED_IN** after STARTED, if at least threshold out of windowsize blocks have the associated bit set in `signalingBits` in `extraData` block header, measured at next height that is evenly divisible by the windowsize.
* **ACTIVE** for all blocks after the grace period conditions have been met.
* **FAILED** if past the timeout time and LOCKED_IN was not reached.

In accordance with BIP9, a block's state SHALL never depend on its own extraData; only on that of its ancestors.

### Fork deployment parameters

Each fork deployment is specified by the following per-chain parameters:

* The **name** specifies a very brief description of the fork, reasonable for use as an identifier. For deployments described in a single BIP, it is recommended to use the name "bipN" where N is the appropriate BIP number.
* The **bit** determines which bit in the extraData field of the block is to be used to signal the fork deployment.
* The **start** specifies a block number at which the bit gains its meaning.
* The **timeout** specifies a time at which the deployment is considered failed. If the current block number >= (start + timeout) and the fork has not yet locked in (including this block's bit state), the deployment is considered failed on all descendants of the block.
* The **windowsize** specifies the number of past blocks (including the block under consideration) to be taken into account for locking in a fork.
* The **threshold** specifies a number of blocks, in the range of 1..windowsize, which must signal for a fork in order to lock it in. The support is measured when the chain height is evenly divisible by the windowsize. If the windowsize is set to 2016 (as in BIP9) this coincides with the 2016-block re-targeting intervals.
* The **minlockedblocks** specifies a minimum number of blocks which a fork must remain in locked-in state before it can become active. Both minlockedblocks and minlockedtime (see below) must be satisfied before a fork can become active. If the current block number >= (minlockedblocks + the block number that locked in the fork), then the fork becomes activated. 

### Tallying

If a block's extraData specifies a version other than `1`, all its signaling bits MUST be treated as if they are '0'.

A signaling bit value of '1' SHALL indicate support of a fork and SHALL count towards its tally on a chain.

A signaling bit value of '0' SHALL indicate absence of support of a fork and SHALL NOT count towards its tally on a chain.

The signaling bits SHALL be tallied whenever the head of the active chain changes (including after reorganizations).

### State transitions

The genesis block of any chain SHALL have the state DEFINED for each deployment.

A given deployment SHALL remain in the DEFINED state until it either passes the start (and becomes STARTED) or the timeout time (and becomes FAILED).

Once a deployment has STARTED, the signal for that deployment SHALL be tallied over the the past windowsize blocks whenever a new block is received on that chain.

A transition from the STARTED state to the LOCKED_IN state SHALL only occur when all of these are true:

* the height of the received block is an integer multiple of the window size
* the current block number is below (start + timeout)
* at least threshold out of windowsize blocks have signaled support

A similar height synchronization precondition SHALL exist for the transition from LOCKED_IN to ACTIVE. These synchronization conditions are expressed by the "mod(height, windowsize) = 0" clauses in the diagram.

A transition from LOCKED_IN to ACTIVE state SHALL only occur if the height synchronization criterion is met and the below configurable 'grace period' conditions are fulfilled:

* current height MUST be at least minlockedblocks above LOCKED_IN height

NOTE: If minlockedblocks is set to 0, then the fork will proceed directly to ACTIVE state once the chain height reaches a multiple of the windowsize.

The ACTIVE and FAILED states are terminal; a deployment stays in these states once they are reached.

Deployment states are maintained along block chain branches. They need re-computation when a reorganization happens.

### New consensus rules

New consensus rules deployed by a fork SHALL be enforced for each block that has ACTIVE state.

### Optional operator notifications

An implementation SHOULD notify the operator when a deployment transitions
to STARTED, LOCKED_IN, ACTIVE or FAILED states.

It is RECOMMENDED that an implementation provide finer-grained notifications
to the operator which allow him/her to track the measured support level for
defined deployments.

An implementation SHOULD warn the operator if the configured (emitted) nVersion
has been overridden to contain bits set to '1' in contravention of the above
non-signaling recommendations for DEFINED forks.

It is RECOMMENDED that an implementation warn the operator if no signal has
been received for a given deployment during a full windowsize period after the
deployment has STARTED. This could indicate that something may be wrong with
the operator's configuration that is causing them not to receive the signal
correctly.

For undefined signals, it is RECOMMENDED that implementation track these and
alert their operators with supportive upgrade notifications, e.g.

* "warning: signaling started on unknown feature on version bit X"
* "warning: signaling on unknown feature reached X% (over last N blocks)"
* "info: signaling ceased on unknown feature (over last M blocks)"

Since parameters of these deployments are unknown, it is RECOMMENDED that
implementations allow the user to configure the emission of such notifications
(e.g. suitable N and M parameters in the messages above, e.g. a best-guess
window of 100 blocks).

## Rationale

The timeout into FAILED state allows eventual reuse of bits if a fork was not successfully activated.

A fallow period at the conclusion of a fork attempt allows some detection of buggy clients, and allows time for warnings and software upgrades for successful forks. The duration of a fallow period is not specified by this proposal, although a conventional fallow period of 3 months is RECOMMENDED.

## Guidelines

### Parameter selection guidelines

The following guidelines are suggested for selecting the parameters for a fork:

* **name** SHOULD be selected such that no two forks, concurrent or otherwise, ever use the same name.
* **bit** SHOULD be selected such that no two concurrent forks use the same bit. Implementors should make an effort to consult resources such as [2] to establish whether the bit they wish to use can reasonably be assumed to be unclaimed by a concurrent fork, and to announce their use ('claim') of a bit for a fork purpose on various project mailing lists, to reduce chance of collisions.
* **start** SHOULD be set to some block number in the future, approximately one month after a software release date which includes the fork signaling.  This allows for some release delays, while preventing triggers as a result of parties running pre-release software.
* **timeout** is RECOMMENDED to be a block number that is approximately 1 year after start.
* **windowsize** SHOULD be set large enough to allow reception of an adequately precise signal.
* **threshold** SHOULD be set as high as possible to ensure a smooth activation based on the estimated support and the nature of the proposed changes. It is strongly RECOMMENDED that threshold >= windowsize / 2 (rounded up) to ensure that a proposal is only activated by majority support.
* **minlockedblocks** is RECOMMENDED to be set >= windowsize, to ensure that a full window passes in LOCKED_IN state. Lower values will be ineffective as the transition from LOCKED_IN to ACTIVE is guarded by a synchronization based on the window size.

NOTE: If minlockedblocks is set to 0, then the fork will proceed to ACTIVE state when the chain height reaches a multiple of the windowsize.

A later deployment using the same bit is possible as long as the starttime is after the previous fork's timeout or activation, but it is discouraged until necessary, and even then recommended to have a pause in between to detect buggy software.

### Signaling guidelines

An implementation SHOULD signal '0' on a bit if one of the following holds true:

* the deployment parameters are not DEFINED (not configured or explicitly undefined)
* the deployment is DEFINED and has not yet reached the STARTED state
* the deployment has succeeded (it has become ACTIVE)
* the deployment has FAILED

An implementation SHOULD enable the operator to choose (override) whether to signal '0' or '1' on a bit, once its deployment has at least reached the STARTED state.

A supporting miner SHOULD signal '1' on a bit for which the deployment is LOCKED_IN state so that uptake is visible. However, this has no effect on consensus rules. Once LOCKED_IN, a deployment proceeds to ACTIVE solely based on the configured grace period parameters (see 'Fork deployment parameters' above).

A miner SHOULD signal '0' on a bit if they wish to suspend signaling of support for a fork that is DEFINED in their software.

It is NOT RECOMMENDED to signal '1' for bits where the meaning is undefined (i.e. bits which are unclaimed by proposals).

## Copyright

Copyright and related rights waived via
[CC0](https://creativecommons.org/publicdomain/zero/1.0/).
