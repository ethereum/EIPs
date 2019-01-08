---
eip: <to be assigned>
title: Temporal Replay Protection
author: Martin Holst Swende (@holiman)
discussions-to: https://ethereum-magicians.org/t/temporal-replay-protection/2355
status: Draft
type: Standards Track
category Core
created: 2019-01-08
---

## Simple Summary

This EIP proposes adding a 'temporal' replay protection to transactions, in the form of a `valid-until` timestamp. 


## Motivation

There are a couple of different motivators for introducing a timebased transaction validity. 

- If any form of dust-account clearing is introduced, e.g. (https://github.com/ethereum/EIPs/issues/168), it will be necessary
to introduce a replay protection, such as https://github.com/ethereum/EIPs/issues/169 . Having temporal replay protection removes the need
to change nonce-behaviour in the state, since transactions would not be replayable at a later date than explicitly set by the user. 
- In many cases, such as during ICOs, a lot of people want their transactions to either become included soon (within a couple of hours) or not at all. Currently, 
transactions are queued and may not execute for several days, at a cost for both the user (who ends up paying gas for a failing purchase) and the network, dealing with the large transaction queues.  
- Node implementations have no commonly agreed metric for which transactions to keep, discard or propagate. Having a TTL on transactions would make it easier to remove stale transactions from the system. 

## Specification

The roll-out would be performed in two phases, `X` (hardfork), and `Y` (softfork).

At block `X`, 

- Add an optional field `valid-until` to the RLP-encoded transaction, defined as a `uint64` (same as `nonce`). 
- If the field is present in transaction `t`, then
  - `t` is only eligible for inclusion in a block if `block.timestamp` < `t.valid-until`. 

At block `Y`, 
- Make `valid-until` mandatory, and consider any transaction without `valid-until` to be invalid. 

## Rationale

For the dust-account clearing usecase, 
- This change is much less invasive in the consensus engine. 
  - No need to maintain a consensus-field of 'highest-known-nonce' or cap the number of transactions from a sender in a block. 
  - Only touches the transaction validation part of the consensus engine
  - Other schemas which uses the `nonce` can have unintended side-effects, 
    - such as inability to create contracts at certain addresses.
    - more difficult to integrate with offline signers, since more elaborate nonce-schemes requires state access to determine. 
    - More intricate schemes like `highest-nonce` are a lot more difficult, since highest-known-nonce will be a consensus-struct that is incremented and possibly reverted during transaction execution, requireing one more journalled field.  


## Backwards Compatibility

This EIP means that all software/hardware that creates transactions need to add timestamps to the transactions, or will otherwise be incapable of signing transactions after block `Y`. Note: this EIP does not introduce any maximum `valid-until` date, so it would still be possible to create
transactions with near infinite validity. 

## Test Cases

todo

## Implementation

None yet

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

