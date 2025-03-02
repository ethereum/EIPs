---
title: Uncouple execution payload from beacon block
description: Separates the execution payload from beacon block to independently transmit them
author: Gajinder Singh <@g11tech>
discussions-to: https://ethereum-magicians.org/t/uncouple-execution-payload-from-beacon-block/23029
status: Draft
type: Standards Track
category: Core
created: 2025-03-01
---

## Abstract

Currently, the beacon block in Ethereum Consensus embed transactions within `ExecutionPayload` field of `BeaconBlockBody`. This EIP proposes to replace `ExecutionPayload` with `ExecutionPayloadHeader` in `BeaconBlockBody` and to independently transmit `ExecutionPayloadWithInclusionProof`.

However, this EIP makes no change to the block import mechanism, with the exception that block availability now includes waiting for the availability of `ExecutionPayloadWithInclusionProof`, making it different and simpler from proposals like ePBS.

But this availability requirement can infact be restricted to `gossip` import while allowing optimistic syncing of the execution layer (EL) on checkpoint/range sync as EL can pull full blocks from their peers in optimistic sync as they do now.

## Motivation

Ethereum protocol has an ambitious goal to grow the `gasLimit` of the execution payloads (possibly by 10X). This leads to larger messages, negatively affecting the networking and block processing pipelines of the consensus layer (CL) clients leading to following issues:

1. Higher latencies for the arrival of beacon blocks increase, requiring larger bandwidth resources to be made available for the beacon node.
2. The greater number and size of transactions directly increase the merkelization compute time, increasing the import time of the block.

We know from timing games that the block import latency greatly affects a client's performance to make correct head attestations. With this EIP, block transmission and block import processes will be decongested, allowing for greater flexibility in receiving a larger `ExecutionPayloadWithInclusionProof`, while the beacon block can simultaneously undergo processing. 

In addition, EL clients can also independently participate in forwarding and receiving larger execution blocks. That mechanism however can be independently developed and is out of scope for this EIP.

Additional benefits obtained from this EIP:

- Consensus clients don't need to store and serve blocks with transactions, providing greater efficiency and reduced resource requirements for running a beacon node.
- the PBS pipleline becomes more efficient by proposer transmitting the signed block directly to the p2p network while also submitting to the builder/relay for independent reveal of the `ExecutionPayloadWithInclusionProof`.
- in future with ZK proof of the EL block execution, one could treat the transactions just like blobs leveraging DAS mechanisms for the availability without worrying about their execution validity.

## Specification

- `ExecutionPayload` in the `BeaconBlockBody` is replaced by `ExecutionPayloadHeader`
- `ExecutionPayloadWithInclusionProof` is computed by the proposer/builder and transmitted independently on a gossip channel.
- data availability checks now also wait for availability of a `VALID` `ExecutionPayloadWithInclusionProof`
- `newPayload` on engine api is modified to now accept `newPayloadHeader` and a new method for `newExecutionPayload` is introduced to check the vailidity of the `ExecutionPayload` recieved within `ExecutionPayloadWithInclusionProof`

ELs can optionally introduce `getExecutionPayload` method (like `getBlobs`) to help fast recovery of execution payload from the EL p2p network but as noted above that mechanism could be independently speced and is not part of this EIP.

<-- TODO: add spec details -->

## Rationale

There is another choice we could have made to go for `SignedExecutionPayload` instead of `ExecutionPayloadWithInclusionProof` and having a `SignedExecutionPayloadHeader` with builder signing these messages (validator is the builder in local block building). But without builder enshrinment tight gossip validation of `SignedExecutionPayload` would be an issue and could become a DOS vector.

The benefit of `SignedExecutionPayload` design is that it could be transmitted ahead of even the `SignedExecutionPayloadHeader` inclusion in beacon block and is especially usedful in PBS pipeline where the proposal to builder/relay latency can be reduced significantly.

## Backwards Compatibility

This change isn't backward compatible and a new hardfork is required to activate this EIP.

## Test Cases

<-- TODO -->

## Reference Implementation

<-- TODO -->

## Security Considerations

<-- TODO -->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
