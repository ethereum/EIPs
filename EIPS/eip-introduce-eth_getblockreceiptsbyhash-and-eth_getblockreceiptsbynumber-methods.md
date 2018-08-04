---
eip: undefined
title: Introduce eth_getBlockReceiptsByHash and eth_getBlockReceiptsByNumber JSON RPC methods
author: Jakub Lipinski <jakub.lipinski@gmail.com> 
discussions-to: https://github.com/ethereum/EIPs/issues/undefined
status: Draft
type: Standards Track
category: Interface
created: 2018-08-04
---
## Simple Summary
This is a proposal to give clients an ability to easily get the receipts for all the transactions from a particular block. 
## Abstract
This EIP proposes to introduce a new JSON RPC methods called `eth_getBlockReceiptsByHash` and `eth_getBlockReceiptsByNumber` which return all the receipts from a particular block
## Motivation
Currently, if you want to process all the receipts from a particular Ethereum block, you need to request the transaction hashes by calling `eth_getBlock()` and for each tx returned you need to call `eth_getTransactionReceipt(tx)` to retrieve its receipts. It may require more than 200 RPC calls (depending on the number of transactions in the block) to retrieve all the receipts for a particular block.
## Specification

#### eth_getBlockReceiptsByHash

Returns block receipts by hash.

##### Parameters

1. `DATA`, 32 Bytes - Hash of a block.

```js
params: [
   '0xc261fcd165d2394ee9dfd6041d165aeee5a3b226512f8f73b43c158ec8920ff2'
]
```

##### Returns

`Array` - Array of transaction receipt objects (see [eth_getTransactionReceipt](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionreceipt])), or an empty array if no receipts were found.

 ##### Example
 ```js
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockReceiptsByHash","params":["0xc261fcd165d2394ee9dfd6041d165aeee5a3b226512f8f73b43c158ec8920ff2"],"id":1}'
 // Result
{
	"id":1,
	"jsonrpc": "2.0",
	"result":[
        {
            "action": {
              "callType": "call",
              "from": "0xf2443ec06862560c4f9f435f5b0383384fe0b643",
              "gas": "0x15722",
              "input": "0x",
              "to": "0x9cfed76501ac8cf181a9d9fead5af25e2c901959",
              "value": "0x0"
            },
            "blockHash": "0xc261fcd165d2394ee9dfd6041d165aeee5a3b226512f8f73b43c158ec8920ff2",
            "blockNumber": 6082554,
            "result": {
              "gasUsed": "0xf505",
              "output": "0x"
            },
            "subtraces": 0,
            "traceAddress": [],
            "transactionHash": "0x363feb6c211ffd059560fed74e8cb188a7b4cea52671aae1f2839dc4bf2e5976",
            "transactionPosition": 273,
            "type": "call"
          },
          ... // rest of the receipts
	]
}
```

#### eth_getBlockReceiptsByNumber

Returns block receipts by block number.

##### Parameters

1. `QUANTITY|TAG` - a block number, or the string `"earliest"`, `"latest"` or `"pending"`, as in the [default block parameter](https://github.com/ethereum/wiki/wiki/JSON-RPC#the-default-block-parameter).

```js
params: [
   '0x5CCFFA', // 6082554
]
```

##### Returns

See `eth_getBlockReceiptsByHash` above

##### Example
```js
// Request
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockReceiptsByNumber","params":["0x5CCFFA"],"id":1}'
```

Result: see `eth_getBlockReceiptsByHash` above

## Rationale

Introducing the methods will allow to:
* Speed up the clients processing the Ethereum receipts
* Relief the nodes by reducing the number of requests from the clients 
* Make the JSON RPC API more consistent

## Backwards Compatibility
This proposal will not break anything that relies on existing behaviour.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
