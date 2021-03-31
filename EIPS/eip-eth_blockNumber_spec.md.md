---
eip: 3410
title: JSPON RPC eth_blockNumber Spec
author: <a list of the author's or authors' name(s) and/or username(s), or name(s) and email(s), e.g. (use with the parentheses or triangular brackets): FirstName LastName (@GitHubUsername), FirstName LastName <foo@bar.com>, FirstName (@GitHubUsername) and GitHubUsername (@GitHubUsername)>
discussions-to: https://github.com/ethereum-oasis/eth1.x-JSON-RPC-API-standard
status: Draft
type: Standards Track
category: Interface
created: 2021-03-17
requires (*optional): EIP-1474
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
<br/>MUST return an error if the node has not yet processed or failed to process the genesis block yet JSON RPC is operational. Some nodes MAY decide not to enable JSON RPC if the genesis block calculation has not been done yet.

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
Tha clarifications of the spec may require some breaking edge cases behaviour on the existing client implementations. If you have relied on the eth_blockNumber returning the fast sync progress information then you will need to expect 0 returned now.

## Test Cases
We need to define how we add test cases.

## Reference Implementation
A link to the Geth implementation needed.

## Security Considerations
Incorrect information returned by the eth_blockNumber may lead to an incorrect execution of transaction signing and sending by the integrators which may lead to losses.
<br/>If the node has not been synced yet returning 0 protects user from signing invalid nonce transactions or relying on non-verified blocks.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
