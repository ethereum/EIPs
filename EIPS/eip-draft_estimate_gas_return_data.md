---
eip: _
title: Estimate gas return data
author: Jules Goullée (@julesGoullee)
discussions-to: _
status: Draft
type: Standards Track
category: Interface
created: 2020-06-15
---

## Simple Summary
This EIP intends to modify RPC to return transaction data for `eth_estimateGas` method. When transaction required state modification, (not a Solidity view or pure, it can't be executed without a transaction), the estimate endpoint returns the amount of gas needed but omit the returned value. The propose of this change is to add the return value in the response.

## Motivation
Pure of view function can be call without cost to "read" information and free of cost. State modifier function can be estimate to know the cost and if it will not fail, but there is no way to know the return value before executing the transaction in live. 

## Specification
`eth_estimateGas` Response:

In place of:
```json
{ "result": 123456 }
```

Returns:
```json
{"result": { "gasUsed": 123456, "returnData": "0x" } }
```

Where `returnData` is typed `Bytes`

## Backwards Compatibility
Sadly this modification required a breaking change in the RPC in the response format.
Can also be a new endpoint to avoid breaking change.

## Implementation
PR in go-ethereum repo:
[https://github.com/ethereum/go-ethereum/pull/21225](https://github.com/ethereum/go-ethereum/pull/21225)
