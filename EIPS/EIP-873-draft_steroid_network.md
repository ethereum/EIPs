## Preamble

    EIP: <to be assigned>
    Title: EIP-873: Steroid Network
    Author: Angelos Hadjiphilippou <angelos@exevior.com>
    Type: Standard Track
    Category (*only required for Standard Track): Core 
    Status: Draft
    Created: 2018-02-06
    Requires (*optional): <EIP number(s)>
    Replaces (*optional): <EIP number(s)>

## Simple Summary
The suggestion implies a build-in pool and a change in the way new blocks are handled in the following manner. New block found -> Network broadcasts new pending block to miners, miners process, change status from pending to complete & add to chain.

## Abstract

Scalability to the number of transactions processed is a threshold subject to a number of factors, some of which are current network, diff etc, not to mention the 51% pool dominance issue. This EIP takes away the 51% issue and makes number of transactions per second only liable to hashrate availability and also considers a fairer distribution of rewards only based on work submitted and not just "luck"!

## Specification

* Steroid network pool build-in to core
*Implies that all miners are connected directly and not to 3rd-party pools

The Steroid pool gathers all the newly found blocks and applies a "Pending" status to them. It then broadcasts to the network for miners to pick-up and process. The Steroid pool can control the number of pending blocks required, for the current transaction load, dynamically using the traditional diff method.

Benefits
* Miners get paid based on work submitted (Fair distribution).
* Network scalability controlled by core diff algorithm.
* Number of transactions is subject to available hashrate.
* Network rewards are subject to typical supply&demand 
* More transactions = more work necessary => More rewards

## Backwards Compatibility
Unfortunately, traditional pooling would become obsolete, but the need for nodes is imminent. Perhaps a node reward would supply sufficient incentive to the community to run nodes.
An intermediate deployment stage would be needed where both traditional pool mining and Steroid mining is supported until the network stabilizes on Steroid core pool with 51% (Hostile Takeover).

* This binds perfectly with the proposed Casper update

## Test Cases
Tests are not yet completed at this stage. Looking for volunteers!

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
