## Preamble

    EIP: <to be assigned>
    Title: Rent Collection for Blockchain Data
    Author: Daniel A. Nagy <daniel@ethereum.org>, Zsolt Felfoldi <zsolt@ethereum.org>
    Type: Standard Track
    Category: Core
    Status: Draft
    Created: 2017-11-01


## Simple Summary
Introducing a way to collect rent from accounts that is proportional 
to the cost that they impose on the network by storing a large state
over a long period of time.

## Abstract
A new global parameter called `rent` similar to `gasLimit` that can be 
modified by miner vote is introduced. It is initialized at 0 and is 
assumed to have been zero before its introduction. The miner validating 
a particular block can increase rent in a bounded way at the cost of 
forfeiting a proportional part of the mining reward. Similarly, if 
`rent` is more than zero, one can decrease it in a bounded way and 
receive the same additional mining reward that would need to be 
forfeited to raise it back.

With each new block, an account is chosen in a deterministically random 
fashion with a probability proportional to the amount of storage that 
they use. The current value of `rent` is subtracted from their balance 
and if the result is negative, the account gets removed from the state. 
Otherwise, account balance is updated by the result.

## Motivation
Currently, contracts storing a large state over a long period of time 
impose considerable cost on the network and do so for free, having 
insufficient incentives to keep their state small. This results in
an unreasonable waste of a scarce resource.

## Specification
### TODO
Both `rent` is available as readable environment to contracts.

## Rationale
The proposed rent control mechanism creates a *tragedy of commons* type 
coordination problem between miners, privatizing the costs of raising 
`rent` while the benefit is common and, conversely, privatizing the 
benefit of reducing `rent` while the cost is socialized. It is up to 
miners to coordinate through smart contracts; it is not part of the protocol.
In general, this bias towards reducing the rent is intended to keep 
rent in check and make it difficult for miners to raise rent beyond 
the actual cost of storing the state.

## Backwards Compatibility
The fact that both `rent` is initialized as zero and assumed to have been 
zero before introducing the protocol change, the entire history of the 
blockchain is conforming to the rules introduces in this protocol change. 
Since miners are beneficiaries of the change, no difficulty is expected 
with acceptance by miners.

## Test Cases
### TODO

## Implementation
### TODO

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
