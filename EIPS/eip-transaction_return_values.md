## Preamble

    EIP: <to be assigned>
    Title: Return values for eth_sendTransaction and eth_sendRawTransaction RPC requests
    Author: Jack Peterson <jack@tinybike.net>
    Type: Standard Track
    Category: Interface
    Status: Draft
    Created: 2017-11-09


## Simple Summary
Provide a way for external callers to access return values of functions executed during Ethereum transactions.

## Abstract
When a new transaction is submitted successfully to an Ethereum node, the node responds with the transaction's hash.  If the transaction involved the execution of a contract function that returns a value, the return value is simply discarded.  If the return value is state-dependent, which is common, there is not a straightforward way for the caller to access or compute the return value.  This EIP proposes that when a transaction is submitted, the caller may subscribe to the transaction's hash.  The Ethereum node would then push a notification to the caller when the transaction is sealed (and again if/when the transaction is affected by chain reorganizations).

## Motivation
External callers presently have no way of accessing return values from Ethereum, if the function was executed via `eth_sendTransaction` or `eth_sendRawTransaction` RPC request.  Access to return value is in many cases a desirable feature.  Making return values available to external callers also addresses the inconsistency between _internal_ callers, which have access to return values within the context of the transaction, and external callers, which do not.  The typical workaround is to log the return values, which is bad for several reasons: it contributes to chain bloat, it imposes additional gas costs on the caller, and it can result in many unused logs being written if the externally called function involves other (internal) function calls that log their return values.

## Specification
A transaction is submitted via `eth_sendTransaction` or `eth_sendRawTransaction` RPC request and has the transaction hash `"0x00000000000000000000000000000000000000000000000000000000deadbeef"`.  The sender can then subscribe to the transaction's return value by sending an `eth_subscribe` request with the transaction hash as a parameter:

```json
{"jsonrpc": "2.0", "id": 1, "method": "eth_subscribe", "params": ["0x00000000000000000000000000000000000000000000000000000000deadbeef"]}
```

The Ethereum node responds with a subscription ID:

```json
{"jsonrpc": "2.0", "id": 1, "result": "0x00000000000000000000000000000b0b"}
```

When the transaction is sealed (mined), the Ethereum node computes the return value (`"0x000000000000000000000000000000000000000000000000000000000000002a"`) and pushes a notification to the subscriber:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "result": "0x000000000000000000000000000000000000000000000000000000000000002a",
    "subscription": "0x00000000000000000000000000000b0b"
  }
}
```

Unlike other subscriptions, the subscriber only receives notifications about a transaction's return value in two cases: first when the transaction is sealed, and again (with an extra `"removed": true` field) if the transaction is affected by a chain reorganization.

## Rationale
[A recent EIP](https://github.com/ethereum/EIPs/pull/658) originally proposed adding return values to transaction receipts.  However, return data is not charged for (as it is not presently stored on the blockchain), so adding it to transaction receipts could result in DoS and spam opportunities. Instead, a simple Boolean `status` field was added to transaction receipts.  This was included in the Byzantium hard fork.

The primary advantage of using a push notification is that no extra data needs to be stored on the blockchain.  One ramification of this design is that after-the-fact lookups of the return value are impossible.  However, this is consistent with how return values are normally used: they are only accessible to the caller when the function returns, and are not stored for later use.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
