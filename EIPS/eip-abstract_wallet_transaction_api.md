---
eip: <to be assigned>
title: Abstract Wallet Transaction API
description: JSON RPC methods for dealing with transactions that are more suitable for different kinds of wallets
author: Moody Salem (@moodysalem)
discussions-to: <URL>
status: Draft
type: Meta
created: 2022-10-17
---

## Abstract

Defines new JSON RPC methods for dapps to send transactions from the user's wallet, as well as check on the status
of said transactions. These methods are more abstract to handle the differences between different kinds of wallets, e.g.
smart contract wallets utilizing EIP-4337 or wallets that support bundled transactions via EIP-3074.

## Motivation

The current APIs to send transactions and check their status, `eth_sendTransaction` and `eth_getTransactionReceipt`,
do not work well in many cases for regular EOA accounts. In particular, they do not allow sending or checking the status
of bundles of transactions, or querying the status of a replaced-by-fee (sped up) transaction.

The case is significantly exacerbated with account abstracted wallets (e.g. EIP-4337 or EIP-3074), where the transaction
hash may not be known at
the time of submission.

A new more abstract wallet transaction API is thus required, so the wallet can handle differences between wallet
implementations. Some wallets may use EIP-3074 to deliver batches, whereas others will use smart contract accounts
via EIP-4337.

## Specification

Two new JSON RPC methods are added. Dapps may begin using these methods immediately, falling back
to `eth_sendTransaction`
and `eth_getTransactionReceipt` when they are not available.

### `wallet_sendMessageBundle`

Requests that the wallet deliver a bundle of messages on-chain.
The wallet should send these messages as a single transaction if possible.
Dapps MUST NOT rely on the messages being sent in a single transaction, i.e. other untrusted transactions may be
included between each of the transactions.
The wallet MUST send these messages in the order specified in the request.
The wallet MUST attempt to deliver all messages in the successful response case, and the wallet MUST NOT deliver any
messages
in the failure case.
The wallet may reject the request if the chain ID does not match the currently selected chain ID.
The wallet must reject the request if the `from` address does not match the enabled account.
The wallet may reject the request if one or more messages in the bundle will fail.

#### Parameters

The method takes an array containing one object element, with the following keys:

- `chainId`: `INTEGER` - The chain ID on which the transactions should be sent
- `from`: `ADDRESS` - The address of the wallet that should send the messages in the bundle
- `messages`: `ARRAY` - An array containing 1 or more message objects, where each message has the following keys:
    - `to`: `ADDRESS` - (optional when creating new contract) The address the message is directed to.
    - `gas`: `QUANTITY` - (optional) Integer of the gas provided for the message execution. Unused gas MAY be made
      available to subsequent messages.
    - `value`: `QUANTITY` - (optional) Integer of the value sent with this transaction.
    - `data`: `DATA` - The compiled code of a contract OR the message data to include with the call, e.g. encoded
      function signature and parameters.
    - `quiet`: `BOOLEAN` - (optional, default false) Whether the wallet should continue with subsequent messages when one of the previous messages has failed

##### Example

```json
[
  {
    "chainId": 1,
    "from": "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
    "messages": [
      {
        "to": "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
        "gas": "0x76c0",
        "value": "0x9184e72a",
        "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675",
        "quiet": true
      },
      {
        "to": "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
        "gas": "0xdefa",
        "value": "0x182183",
        "data": "0xfbadbaf01"
      }
    ]
  }
]
```

#### Return value

DATA, 32 Bytes - an identifier that represents the key of the transaction, for that particular wallet connection.

The dapp may track this identifier to check the status of the transaction in the future. The returned identifier value must be 
unique only for the given `from` address.

##### Example

```json
"0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331"
```

### `wallet_getBundleStatus`

Returns the status of a bundle that was sent via `wallet_sendMessageBundle`.
The wallet may also accept transaction hashes as parameters that are related to bundles.
Because the messages may be submitted in a single transaction, it is the wallet's job to surface the status of the
message
as well as any logs that were emitted by the message and the gas used.

#### Parameters

The method takes an array containing one string element, a bundle ID returned by `wallet_sendBundle`.

##### Example

```json
[
  "0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331"
]
```

#### Return value

Returns an object describing the status of each message in the bundle. Each message has its own status, even if all the
messages
were submitted as part of a single transaction.

- `id`: `DATA` - The identifier of the transaction. May not be the same as the request parameter, if the transaction
  hash was sent as a parameter instead of a bundle identifier.
- `statuses`: `Array` - An array of objects containing the status of each message in the original bundle
    - `status`: `Enum` - Either `"PENDING"` indicating the message is not yet confirmed, `"CONFIRMED"` indicating the message was included in a block
    - `receipt`: `Object` - (optional) An object containing the receipt for the given message, _iff_ status is `"CONFIRMED"`
      - `logs`: `Array` - An array of log objects describing logs that were emitted by the message
      - `success`: `BOOLEAN` - Whether the message succeeded when confirmed on chain
      - `blockHash`: `DATA` - The hash of the block in which the message was sent
      - `blockNumber`: `QUANTITY` - The block number of the block in which the message was sent
      - `transactionHash`: `DATA` - The hash of the transaction in which the message was sent

##### Example

```json
{
  "id": "0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331",
  "statuses": [
    {
      "status": "CONFIRMED",
      "receipt": {
        "logs": [
          {
            "address": "0xa922b54716264130634d6ff183747a8ead91a40b",
            "topics": [
              "0x5a2a90727cc9d000dd060b1132a5c977c9702bb3a52afe360c9c22f0e9451a68"
            ],
            "data": "0xabcd"
          }
        ],
        "success": true,
        "blockHash": "0xf19bbafd9fd0124ec110b848e8de4ab4f62bf60c189524e54213285e7f540d4a",
        "blockNumber": "0xabcd",
        "transactionHash": "0x9b7bb827c2e5e3c1a0a44dc53e573aa0b3af3bd1f9f5ed03071b100bb039eaff"
      }
    },
    {
      "status": "PENDING"
    }
  ]
}
```

## Rationale

Account abstracted wallets, either via EIP-3074 or EIP-4337 or other specifications, have more capabilities than regular
EOA accounts.
The antiquated `eth_sendTransaction` and `eth_getTransactionReceipt` methods limit the quality of in-dapp transaction
status. It's possible for dapps to stop tracking transactions altogether, but it is a better user experience for dapps
to show confirmation messages when transactions are successful, or error messages when they fail. Dapps will always have
more context than the wallets on the intent of the delivered messages.
Dapps need a way to communicate more complex kinds of transactions that is backwards compatible with existing wallets.
The newer methods allow for wallets to provide more accurate information about pending transactions to dapps, and
simplify
dapp transaction tracking in the interface.

## Backwards Compatibility

Wallets that do not support the following methods should return error responses to the new JSON RPC methods.
Dapps should attempt to send the same transaction via `eth_sendTransaction` when they receive a failure message.

## Reference Implementation

TODO: add a method for backwards compatibility

## Security Considerations

Dapp developers must assume that one or more of several messages in a bundle may fail, and also that others may be able to 
send messages in between bundle messages. Dapp developers MUST NOT assume that all messages are sent in a single transaction.  

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
