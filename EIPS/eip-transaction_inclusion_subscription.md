---
title: Transaction Inclusion Subscription
description:  Submit transactions and subscribe to transaction inclusion events using eth_subscribe
author: Łukasz Rozmej (@LukaszRozmej)
discussions-to: <TBD>
status: Draft
type: Standards Track
category: Interface
created: 2025-10-31
---

## Abstract

This EIP extends the existing `eth_subscribe` JSON-RPC method with a new subscription type `transactionInclusion` that enables clients to receive real-time notifications when transactions are included in blocks. This subscription-based approach provides efficient transaction confirmation monitoring without blocking connections, supporting both combined transaction submission and monitoring in a single call, as well as monitoring of already-submitted transactions.

## Motivation

Current transaction submission workflows require separate calls to `eth_sendRawTransaction` followed by repeated polling of `eth_getTransactionReceipt`, creating unnecessary latency and network overhead. While [EIP-7966](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-7966.md) proposes `eth_sendRawTransactionSync` to address this through a synchronous blocking approach, blocking HTTP connections presents significant drawbacks:

- **Connection hogging**: Each transaction blocks one HTTP connection until confirmation or timeout
- **Limited scalability**: Cannot efficiently monitor multiple transactions over a single connection
- **Timeout complexity**: Requires careful tuning of timeout parameters for different blockchain slot times
- **Resource inefficiency**: Repeated polling consumes bandwidth and server resources

The subscription-based approach leverages the battle-tested `eth_subscribe` mechanism already implemented across all major Ethereum clients, providing superior resource efficiency and scalability while maintaining feature parity with synchronous approaches.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### New Subscription Type

A new subscription type `transactionInclusion` is added to the `eth_subscribe` method.

### Subscription Request

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["transactionInclusion", {
    "transaction": "0x...",
    "includeReorgs": false
  }]
}
```

Or for monitoring an already-submitted transaction:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["transactionInclusion", {
    "hash": "0x...",
    "includeReorgs": false
  }]
}
```

### Parameters

The subscription parameters object accepts the following fields:

- `transaction` (DATA, optional): Signed transaction data to submit and monitor. When provided, the node MUST immediately submit this transaction to the network.
- `hash` (DATA, 32 bytes, optional): Transaction hash to monitor for already-submitted transactions.
- `includeReorgs` (boolean, optional, default: `false`): Controls reorg monitoring behavior.
  - If `false`: Subscription auto-unsubscribes immediately after first inclusion notification. Reorgs are not monitored.
  - If `true`: Subscription actively monitors for reorgs and sends notifications for reorgs, re-inclusions, and finalization.

**Exactly one** of `transaction` or `hash` MUST be provided. If both or neither are provided, the node MUST return a JSON-RPC error with code `-32602` (Invalid params).

### Subscription Response

Upon successful subscription, the node MUST return a subscription ID:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x1234567890abcdef"
}
```

### Notification Format

When the transaction status changes, the node MUST send a notification:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "0x1234567890abcdef",
    "result": {
      "status": "included",
      "blockHash": "0x...",
      "blockNumber": "0x...",
      "transactionIndex": "0x...",
      "receipt": {
        "transactionHash": "0x...",
        "transactionIndex": "0x...",
        "blockHash": "0x...",
        "blockNumber": "0x...",
        "from": "0x...",
        "to": "0x...",
        "cumulativeGasUsed": "0x...",
        "gasUsed": "0x...",
        "contractAddress": null,
        "logs": [],
        "logsBloom": "0x...",
        "status": "0x1"
      }
    }
  }
}
```

The `status` field MAY be one of:
- `"included"`: Transaction has been included in a block
- `"finalized"`: Transaction's block has reached finality (only sent when `includeReorgs` is `false`)
- `"reorged"`: Transaction was removed from the canonical chain (only sent if `includeReorgs` is `true`)

The `receipt` field MUST contain the complete transaction receipt object as defined by `eth_getTransactionReceipt`.

### Behavior

The node MUST implement the following behavior:

1. **When `transaction` is provided**:
   - The node MUST immediately submit the transaction to the network using the same semantics as `eth_sendRawTransaction`
   - The node MUST derive the transaction hash and begin monitoring for inclusion
   - If submission fails, the node MUST return a JSON-RPC error and MUST NOT create the subscription

2. **Transaction Already Included**:
   - If the monitored transaction is already included in a block at subscription time:
     - If `includeReorgs` is `false`: The node MUST immediately send an inclusion notification and automatically unsubscribe
     - If `includeReorgs` is `true`: The node MUST immediately send an inclusion notification and continue monitoring until finalization

3. **Pending Transaction**:
   - The node MUST monitor the transaction pool and canonical chain
   - When the transaction is included in a block, the node MUST send an inclusion notification
   - If `includeReorgs` is `false`, the node MUST then automatically unsubscribe
   - If `includeReorgs` is `true`, the node MUST continue monitoring

4. **Reorg Monitoring** (when `includeReorgs` is `true`):
   - The node MUST continue monitoring the transaction after initial inclusion
   - If the transaction is removed from the canonical chain due to a reorg, the node MUST send a notification with `"status": "reorged"`
   - If the transaction is re-included in a different block, the node MUST send a new inclusion notification with `"status": "included"`
   - When the block containing the transaction reaches finality, the node MUST send a finalization notification with `"status": "finalized"`
   - The node MUST automatically unsubscribe after sending the finalization notification

5. **Auto-unsubscribe**:
   - If `includeReorgs` is `false`, the node MUST automatically unsubscribe after sending the first inclusion notification
   - The node SHOULD send an `eth_subscription` unsubscribe confirmation

6. **Transaction Not Found**:
   - If monitoring a transaction by `txHash` that doesn't exist in the mempool or chain, the subscription remains active
   - The node SHOULD monitor for the transaction appearing in the future
   - Clients MAY manually unsubscribe if desired

## Rationale

### Why Subscription Over Synchronous?

Subscriptions provide several advantages over the synchronous approach proposed in EIP-7966:

- **Non-blocking**: Clients can perform other operations while waiting for confirmation
- **Multiplexing**: Multiple transactions can be monitored over a single WebSocket connection
- **No timeout complexity**: Subscriptions naturally handle varying confirmation times without timeout parameters
- **Proven infrastructure**: Leverages existing `eth_subscribe` implementation present in all major clients

The addition of the `transaction` parameter provides complete feature parity with `eth_sendRawTransactionSync` by enabling submission and monitoring in a single call.

### Why Extend `eth_subscribe`?

The `eth_subscribe` mechanism is battle-tested and already implemented across all major Ethereum clients. Extending it with a new subscription type requires minimal implementation effort compared to introducing entirely new RPC methods.

### Why Support Both `transaction` and `hash`?

Supporting both parameters provides maximum flexibility:

- `transaction`: Optimal for new transactions, matching the convenience of synchronous methods
- `hash`: Enables monitoring of transactions submitted through other means or by other parties

### Why Support Reorg Monitoring?

Applications requiring high confidence in transaction finality benefit from reorg notifications. This is particularly important on chains with faster block times where reorgs may be more common. The optional nature of this feature allows applications to choose the appropriate trade-off between functionality and resource usage.

### Resource Efficiency

A single WebSocket connection can support unlimited concurrent transaction subscriptions, whereas synchronous approaches require one blocking HTTP connection per transaction. This represents a significant improvement in resource utilization for applications monitoring multiple transactions.

### Why Always Auto-unsubscribe?

Both modes auto-unsubscribe to prevent unbounded subscription accumulation and provide clear lifecycle management:

- **`includeReorgs: false`**: Unsubscribes immediately after first inclusion for fast feedback with minimal resource usage. Users accepting this mode understand the transaction may still be reorged and can manually monitor if needed.
- **`includeReorgs: true`**: Unsubscribes after finalization when reorgs are no longer possible, providing complete transaction lifecycle monitoring.

The key difference is the level of guarantee:
- `includeReorgs: false`: Fast notification, transaction is included (may still reorg)
- `includeReorgs: true`: Complete lifecycle tracking until finality (cannot reorg)

## Backwards Compatibility

This EIP is fully backwards compatible. It extends the existing `eth_subscribe` method with a new subscription type. Clients that have not implemented this feature will return a standard JSON-RPC error indicating the subscription type is not supported. Existing applications continue to function unchanged.

## Test Cases

### Test Case 1: Submit and Monitor

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["transactionInclusion", {
    "transaction": "0xf86c098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a76400008025a028ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa636276a067cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83"
  }]
}
```

**Expected Behavior:**
1. Node submits transaction to network
2. Node returns subscription ID
3. When transaction is included, node sends notification with `"status": "included"` and receipt
4. Subscription automatically closes immediately

### Test Case 2: Monitor Existing Transaction

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["transactionInclusion", {
    "hash": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
    "includeReorgs": false
  }]
}
```

**Expected Behavior:**
1. If transaction already included, immediately send notification with `"status": "included"`
2. If transaction pending, wait and send notification upon inclusion
3. Subscription automatically closes immediately after notification

### Test Case 3: Reorg Monitoring

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["transactionInclusion", {
    "hash": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
    "includeReorgs": true
  }]
}
```

**Expected Behavior:**
1. Send inclusion notification when transaction is included (with `"status": "included"`)
2. Continue monitoring for reorgs
3. If reorg occurs, send reorg notification (with `"status": "reorged"`)
4. If re-included, send new inclusion notification (with `"status": "included"`)
5. When block is finalized, send finalization notification (with `"status": "finalized"`)
6. Subscription automatically closes after finalization

### Test Case 4: Invalid Parameters

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["transactionInclusion", {
    "includeReorgs": false
  }]
}
```

**Expected Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Invalid params: exactly one of transaction or hash must be provided"
  }
}
```

## Reference Implementation

A minimal reference implementation can be realized by:

1. For `signedTransaction` parameter: Call internal `eth_sendRawTransaction` logic and capture the transaction hash
2. Register the transaction hash in a subscription manager
3. Monitor the transaction pool and canonical chain for the transaction
4. When the transaction is included in a block, query the receipt and send notification
5. If `includeReorgs` is false, automatically unsubscribe after first inclusion
6. If `includeReorgs` is true, continue monitoring for chain reorganizations

Implementation pseudo-code:

```python
def handle_transaction_inclusion_subscription(params):
    if 'transaction' in params:
        tx_hash = submit_transaction(params['transaction'])
    elif 'hash' in params:
        tx_hash = params['hash']
    else:
        raise InvalidParamsError()
    
    include_reorgs = params.get('includeReorgs', False)
    subscription_id = generate_subscription_id()
    
    register_subscription(subscription_id, tx_hash, include_reorgs)
    return subscription_id

def on_block_added(block):
    for tx in block.transactions:
        subscriptions = get_subscriptions_for_tx(tx.hash)
        for sub in subscriptions:
            receipt = get_transaction_receipt(tx.hash)
            send_notification(sub.id, 'included', receipt)
            if not sub.include_reorgs:
                unsubscribe(sub.id)

def on_chain_reorg(old_blocks, new_blocks):
    removed_txs = get_transactions_from_blocks(old_blocks)
    for tx_hash in removed_txs:
        subscriptions = get_subscriptions_for_tx(tx_hash)
        for sub in subscriptions:
            if sub.include_reorgs:
                send_notification(sub.id, 'reorged', None)

def on_block_finalized(block):
    for tx in block.transactions:
        subscriptions = get_subscriptions_for_tx(tx.hash)
        for sub in subscriptions:
            receipt = get_transaction_receipt(tx.hash)
            send_notification(sub.id, 'finalized', receipt)
            unsubscribe(sub.id)
```

## Security Considerations

### Transaction Submission Validation

When `transaction` is provided, nodes MUST perform the same validation as `eth_sendRawTransaction` before creating the subscription. Invalid transactions MUST result in an error response without creating a subscription.

### Privacy Considerations

Monitoring transactions by hash does not introduce new privacy concerns beyond existing `eth_getTransactionReceipt` polling. However, applications should be aware that subscribing to transaction hashes reveals interest in those transactions to the node operator.

### Reorg Attack Considerations

Applications using `includeReorgs: true` should implement appropriate logic to handle reorg notifications, particularly on chains where reorgs may be used maliciously. The notification mechanism provides transparency but does not prevent reorg-based attacks.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
