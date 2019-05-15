---
eip: <to be assigned>
title: Grant Standard
author: Arnaud Brousseau (@ArnaudBrousseau), James Fickel (@JFickel)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2019-04-30
---

## Abstract
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
This document outlines a standard interface to propose, vote on, and distribute grants.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

In short, the motivation is social scalability. We believe that a grant standard is necessary to coordinate grant efforts across the Ethereum community. Having a specified interface will more easily enable wallets, DAOs and blockchain UI providers more generally to integrate with a broader grants ecosystem.

TODO:
* what kinds of solutions are out there already?
* why do we need a standard? (e.g. what's the problem with the current status quo?)
* how does having a standard for grants makes the situation better?

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
Contract interface for grant management (`Grant`)
* `grantee(s)`: an address receiving funds when they're unlocked or array of addresses receiving unlocked funds in order of priority
* `amount(s)`: grant size or array of grant sizes corresponding to elements in grantee array
* `grant_manager` (optional): an address that manages the distribution of funds (i.e. can unlock portions of the grant after milestones have been achieved)
* `fund`: a payable interface to receive money. Funds sent there are retained until they're released by a vote threshold (see below), fund threshold, grant manager or some combination thereof
* `withdraw`: a withdrawal interface for grantors to withdraw funds at any time prior to a fund threshold being hit
* `currency`: (can be null) if null, amount is in wei, otherwise this should be set to an ERC20-compliant contract address
* `payout`: called from `tally` if proposal `votes` satisfy rules of `type`
* `votes`: (data) array of (`address`, `vote_value`)
* `type`: one of:
    * `MAJORITY_THRESHOLD` (X% of votes necessary to unlock funds with a `minimum_token_threshold`)
    * `VOTE_THRESHOLD` (unlocks funds after X tokens signal in favor)
    * `FUND_THRESHOLD` (unlocks funds as soon as fund threshold is reached)
    * `VOTE_AND_FUND_THRESHOLD` (unlocks funds when vote threshold AND fund threshold is reached)
    * `OPAQUE` (custom rules)
* `vote_values`: array of acceptable vote values. Example:
    * [true, false] if type is `OPAQUE` or `MAJORITY_THRESHOLD`
    * null if `type` is `FUND_THRESHOLD` or `VOTE_THRESHOLD`
* `current_token_signal`: returns number of tokens signaling for grant
* `expiration`: block number after which votes and funds cannot be sent
* `withdraw_all`: a withdrawal interface that can be triggered after expiration and returns all funds to grantors
* `vote`:
   * if run after `expiration`, throws error
   * if run before `expiration`, adds caller address to `votes`
* `tally` (takes in votes, returns a boolean, can optionally trigger payout):
   * for `MAJORITY_THRESHOLD`:
       * if run when `minimum_token_threshold` > `current_token_signal`, returns true or false based on `type`'s rules, but does not trigger `payout`
       * if run when `minimum_token_threshold` < `current_token_signal`
           * tallies up the votes and/or checks money according to `type`'s rules
           * calls `payout`
  * for `VOTE_THRESHOLD`:
       * tallies up the votes
       * calls `payout` if threshold is reached
  * for `FUND_THRESHOLD`:
       * tallies up the funds
       * calls `payout` if threshold is reached
  * for `OPAQUE`:
       * shrugs. Run the function.

TODO:
* Interface definition with Solidity
* Reasoning on what to leave out of the standard vs what to bake in (what do we want to be immutable?)


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

* What other options did we leave out while designing the interface above?
* Why do we think the current interface is the best?
* Why do we think the parts we left out should be left out?

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->


## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
TODO: write a sample contract with test cases

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
TODO: deploy a contract utilizing the proposed grant mechanism. This is hard. Alternative: standardize on someone else's already-in-use contract. This is easier.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
