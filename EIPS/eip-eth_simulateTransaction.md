---
eip: <to be assigned>
title: eth_simulateTransaction - transaction dry runs
author: Peter Jihoon Kim (@petejkim)
discussions-to: <tbd>
status: Draft
type: Standards Track
category (*only required for Standard Track): Interface
created: 2020-03-16
---

## Simple Summary

Wallet/DApp browser software should provide as much information as possible when presenting a transaction to the user to sign, as there may be unforeseen consequences including a potential loss of funds. A new JSONRPC method `eth_simulateTransaction` enables wallets to perform a dry run of the transaction so that it can provide more information about what might happen such as token movements.

## Abstract

This is a standard for a new JSONRPC endpoint `eth_simulateTransaction` that enables clients to perform a dry run (transaction simulation) before signing and submitting an actual transaction.

## Motivation

When transaction signing is requested and presented to the user, wallet/DApp browser software ("wallets") should attempt to inform the user of what the transaction entails and what the side effects may be.

Currently, most wallets simply show basic transaction parameters such as the recipient address, the value of ETH being transferred, the gas price/limit, and the encoded data. For well-known transaction types such as ERC20 `approve()` and `transfer()`, some wallets decode the call data and present additional information.

For most smart contract transactions however, what the transaction entails is completely opaque to average users, and a malicious transaction may even appear completely harmless (a smart contract transaction will show the value being transferred as zero as if no ETH is moved, but may nevertheless be moving other types of assets such as ERC20 tokens if an allowance was set previously).

This is terrible for user experience as it encourages users to be accustomed to signing transactions blindly, which may have adverse consequences such as loss of funds.

A new JSONRPC method `eth_simulateTransaction` aims to improve the situation by providing a way for wallets to perform a dry run and read events emitted (such as the ERC20 `Transfer` events), thereby enabling the user to make a more informed decision about whether to sign a transaction that is requested.

## Specification

#### eth_simulateTransaction

Performs a dry-run of the transaction and returns a transaction result object. The transaction will not be added to the blockchain. Note that the actual transaction may have a different result for a variety of reasons including EVM mechanics, node performance, and the difference in the state of the blockchain when the transaction is processed.

##### Parameters

1. `Object` - The transaction object
  - `from`: `DATA`, 20 Bytes - The address the transaction is send from.
  - `to`: `DATA`, 20 Bytes - (optional when creating new contract) The address the transaction is directed to.
  - `gas`: `QUANTITY`  - (optional, default: 90000) Integer of the gas provided for the transaction execution. It will return unused gas.
  - `gasPrice`: `QUANTITY`  - (optional, default: To-Be-Determined) Integer of the gasPrice used for each paid gas
  - `value`: `QUANTITY`  - (optional) Integer of the value sent with this transaction
  - `data`: `DATA`  - The compiled code of a contract OR the hash of the invoked method signature and encoded parameters. For details see [Ethereum Contract ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI)
  - `nonce`: `QUANTITY`  - (optional) Integer of a nonce. This allows to overwrite your own pending transactions that use the same nonce.

##### Example Parameters
```js
params: [{
  "from": "0x1111111111111111111111111111111111111111",
  "to": "0x2222222222222222222222222222222222222222",
  "gas": "0x200000",
  "gasPrice": "0x3b9aca00",
  "value": "0x0",
  "data": "0xdeadbeef000000000000000000000001111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000abcde"
}]
```

##### Returns

`Object` - A transaction result object.

  - `transactionHash`: `DATA`, 32 Bytes - hash of the transaction.
  - `from`: `DATA`, 20 Bytes - address of the sender.
  - `to`: `DATA`, 20 Bytes - address of the receiver. null when it's a contract creation transaction.
  - `gasUsed`: `QUANTITY` - The amount of gas used by this specific transaction alone.
  - `contractAddress`: `DATA`, 20 Bytes - The contract address created, if the transaction was a contract creation, otherwise `null`.
  - `logs`: `Array` - Array of log objects, which this transaction generated.

##### Example
```js
// Request
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{see above}],"id":1}'

// Result
{
  "id": 1,
  "jsonrpc": "2.0",
  "result": {
    "transactionHash": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "from": "0x1111111111111111111111111111111111111111",
    "to": "0x2222222222222222222222222222222222222222",
    "gasUsed": "0x123456",
    "contractAddress": "0x3333333333333333333333333333333333333333", // or null, if none was created
    "logs": [{
        // logs as returned by getFilterLogs, etc.
    }, ...]
  }
}
```

## Rationale

The request parameters are the same as `eth_sendTransaction`, and the response is a subset of a transaction receipt object you can obtain using `eth_getTransactionReceipt`, for consistency and familiarity.

Note that it does not require a signed transaction (raw tx), as the motivation is to provide more information to the user before signing happens.

## Implementation

There is an existing method `eth_estimateGas` that already performs transaction dry runs, but the method only returns the amount of gas used by the transaction. The code for `eth_estimateGas` may be reusable for the implementation of `eth_simulateTransaction`.

## Security Considerations

Wallets and DApp browsers utilizing `eth_simulateTransaction` must highlight that it can only provide an _estimated_ outcome and that the actual mileage may vary.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
