---
eip: 3410
title: JSPON RPC eth_blockNumber Spec
author: Tomasz K. Stanczak (@tkstanczak)
discussions-to: https://github.com/ethereum-oasis/eth1.x-JSON-RPC-API-standard
status: Draft
type: Standards Track
category: Interface
created: 2021-03-17
requires: 1474
---

## Simple Summary
This EIP specifies in details expected behaviour of the eth_blockNumber Eth 1.x JSON RPC endpoint.

## Abstract
We cover basic behaviour and edge cases for various sync modes.

## Motivation
eth_blockNumber is the most commonly called JSON RPC endpoint, yet it has some undefined edge cases that needs specification so that the behaviour is consistent in all situation on all Ethereum 1.x client implementations.

## Specification

### eth_blockNumber

### Description

Returns the number of the block that is the current chain head (the latest best processed and verified block on the chain).
<br/>The number of the chain head is returned if the node has ability of serving the header, body, and the full state starting from the state root of the block having the number in a finite time.
 * If the node is in the process of fast sync then it should return 0.
 * If the node is in the process of beam sync then it should return 0.
 * If the node is in the process of snap sync then it should return 0.
 * If the node is a light client then it should assume that it is capable of delivering a full state and return the current chain head number.
 * If the node is in the process of archive sync then it should return the latest fully processed block number.
  
<br/>The node may know a higher block number but still return a lower one if the lower number block has higher total difficulty or if the higher number block has not been fully processed yet.
<br/>Provides no promise on for how long the node will keep the block details so if you request the block data for the given block number any time after receiving the block number itself, you may get a null response.
<br/>Returns an error if the node has not yet processed or failed to process the genesis block. Some nodes MAY decide not to enable JSON RPC if the genesis block calculation has not been done yet.

##### Parameters

_(none)_

##### Returns

{[`Quantity`](https://eips.ethereum.org/EIPS/eip-1474#quantity)} - number of the latest block

##### Example

```sh
# Request
curl -X POST --data '{
    "id": 1337,
    "jsonrpc": "2.0",
    "method": "eth_blockNumber",
    "params": []
}' <url>

# Response
{
    "id": 1337,
    "jsonrpc": "2.0",
    "result": "0xc94"
}
```

## Rationale
The definition of being able to serve the full state has been introduced to clarify the behaviour in the midst of fast sync and similar.

## Backwards Compatibility
The clarifications of the spec may require some breaking edge cases behaviour on the existing client implementations. If you have relied on the eth_blockNumber returning the fast sync progress information then you will need to expect 0 returned now.

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Reference Implementation
An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Security Considerations
All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
