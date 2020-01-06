---
eip: <to be assigned>
title: Time Based Upgrade Transitions
author: Danno Ferrin (@shemnon)
discussions-to: https://ethereum-magicians.org/t/time-based-upgrade-transitions/3902
status: Draft
type: Standards Track
category: Core
created: 2020-01-02
---

## Simple Summary

A process to specify network upgrades relative to a point in time instead of a fixed block number.

## Abstract

Instead of assigning network upgrade transitions to occur on `TRANSITION_BLOCK` ahead of time a
`TRANSITION_TIME` is chosen. On the second "round" block after the `TRANSITION_TIME` occurs the
transition to the network upgrade will occur. Meta-EIPs will first list the TIME and later be
updated to the historical BLOCK when the upgrade transitioned.

## Motivation

<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

For the Muir Glacier and Istanbul upgrades there were a total of at least 4 times when the planned
upgrade occurred well away from the intended date. For Ropsten the Istanbul upgrade occurred earlier
because of the sudden addition of hashing power, and for Muir Glacier it happened much later because
of the removal of that hashing power. For Mainnet the Istanbul transition was days later and the
Muir Glacier transition was days sooner because of the unpredictable impact of the Difficulty Bomb.

Such unpredictability is bad for node operators such as exchanges and block explorers. Particularly
an earlier fork may disrupt their maintenance plans. A much shorter window of unpredictability would
benefit node operators and developers monitoring the upgrade.

## Specification

A 'Transition Eligible Block' is defined as a block where the number of blocks preceding the block
is evenly divisible by the `TRANSITION_INCREMENT`, i.e.
`(block.number % TRANSITION_INCREMENT) == 0`.

An upgrade will activate at a Transition Eligible Block if

- The timestamp of the block is on or after the `TRANSITION_TIME`
- The previous Transition Eligible Block was on or after the `TRANSITION_TIME`

Once activated the upgrade remains activated for all future blocks.

If multiple upgrades would activate on a Transition Eligible Block all such transitions will
activate. Note that most network upgrades are defined as "previous upgrade + new rules" so the
effect may be that only the most recent network upgrade would appear to activate.

After the upgrade transition completes the Hard Fork Coordinator will update the Meta-EIP to note
what the transition block was, in addition to preserving the transition time. Clients may
incorporate this block into their genesis files as an aid to synchronization. This transition block
number is only advisory and the time base transition rules have precedence.

For Mainnet the `TRANSITION_INCREMENT` will be 1000. For testnets a `TRANSITION_INCREMENT` of 1024
is recommended.

## Rationale

Previously when determining upgrade transitions a specific block number was chosen. This number was
typically a multiple of 1000. For testnets a practice developed of making the numbers decimal
palindromes. Retaining the mainnet tradition is easy, but specifying a palindrome algorithm for
testnets seemed excessive. As a compromise round decimal numbers (ending in `000`) are proposed for
mainnet and round hexadecimal numbers (ending in `0x000`, `0x400`, `0x800`, or `0xc00`) is proposed
for testnets.

The next concern was the reliability of the timestamp in the block header. The only rules enforced
for this by clients are from (a) always incrementing and (b) not being too far in the future. Only
the fist rule produces a consensus error and clients can co-operate on the second rule. Apart from
these checks miners can lie about the time and manipulate it for their own ends. Because of the
incrementing timestamp rule it is expected that any gains would be short lived, and the timestamp is
not used in fork selection rules either, only in difficulty calculations.

A related concern to miner manipulation would be chain reorganizations. If the transition were to
occur immediately then there is a chance one side of a reorganization would activate and the other
side would not. Hence the 1000-1999 block delay in the activation of the fork. It is not expected
that a chain reorganization would occur much past 100 blocks. In the
[Ethereum Classic 51% attack](https://blog.coinbase.com/ethereum-classic-etc-is-currently-being-51-attacked-33be13ce32de)
the longest reorganizations were less than 150 blocks, so a re-organization of over 1000 blocks is
not expected.

The two eligible block activation process mirror's Casper's (and by extension Ethereum 2.0) block
finalization process. A block is first justified, and then finalized when another block that later
builds on that block is also justified. In this spec a transition occurs when the second Transition
Eligible Block past the transition time occurs.

This delay of 1000 to 1999 blocks provides a small window where the transition block can be presumed
prior to it's actual arrival. It also has a smaller window of uncertainty around when it will
arrive, which is the principal motivating impact of this design.

| Block Time | Mean Transition | Earliest Transition | Latest Transition |
| ---------- | --------------- | ------------------- | ----------------- |
| 13 seconds | 5h 25m          | 3h 36m 40s          | 7h 13m 7s         |
| 15 seconds | 6h 15m          | 4h 10m              | 8h 19m 45s        |
| 30 seconds | 12h 30m         | 8h 20m              | 16h 39h 30s       |

Based on the expected transition period instead of targeting noon UTC on a Wednesday the transitions
should become eligible at 0600 UTC on a Wednesday, which would result in a transition during EMEA
business hours.

## Backwards Compatibility

<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

### EIP-2124 - Fork identifier for chain compatibility checks

EIP-2124 describes a fork identifier for chain compatibility checks, however it is defined in terms
of future expected fork blocks. Since the exact block number is not known this format would need to
be changed to accommodate the fork time. One alternative is to always communicate the
`TRANSITION_TIME`. This will produce no conflicts with blocks until mainnet reaches 1.4 billion
blocks (on the order of 700 years). Another alternative is to communicate the `TRANSITION_TIME`
before the transition and then `TRANSITION_BLOCK` after transition. The downside to this alternative
is that between the time of the transition and when clients upgrade their genesis files that
unsynced nodes may not be able to find peers.

### Fast Sync, Warp Sync, and Beam Sync

There will be minor impacts on all of the non-archival synchronization mechanisms. Generally
speaking when these protocols start executing the blocks they will need to know what the current
upgrade is and will need to be able to detect it based on timestamps in the header.

For Fast Sync (currently Geth, Besu, and Nethermind) the blocks are not executed until both the
complete set of block headers and complete world state for the pivot point is downloaded. Clients
will have all of the data on-hand to make the calculations. Up to two previous Transition Eligible
Blocks will need to be examined.

For Warp Sync (Parity) a similarly complete database is available before block execution starts.
Similarly up to two previous Transition Eligible Blocks will need to be examined.

For Beam Sync (Trinity) block execution begins prior to the complete history of block headers and
downloading of world state finishes. In this case the two previous Transition Eligible Block headers
will need to be downloaded and examined prior to the execution of the first block.

For all of Fast, Warp, and Beam sync the historically noted transition block can be recorded in the
genesis file as an aid to determining where the relevant transitions should occur, but the time
transitions should still be verified. Hence it would not be advisable to simply switch to the
historical node values for a time based transition.

## Test Cases

<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

> To be completed once Eligible for Inclusion

## Implementation

<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

> To be completed once Eligible for Inclusion

## Security Considerations

<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->

> Miners may game the "timestamp" to pull up/push back the activation block. (a) future timestamps
> are limited to 2 hours (b) timestamps must always increase (c) 1-2k block delay removes most of
> the incentive. I should elaborate on this once deemed eligible for inclusion.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
