---
eip: <to be assigned>
title: Expirable Trainsaction 
description: This EIP adds a new transaction type of that includes expiration with a blocknum 
author: Zainan Victor Zhou <zzn@zzn.im> (@Xinbenlv)
discussions-to: <to be assigned></to>
status: Draft
type: Standards Track
category: Core
created: 2022-05-06
requires: 155, 2718
---

## Abstract
This EIP adds a new transaction type of that includes expiration with a blocknum.

## Parameters
- FORK_BLKNUM
- CHAIN_ID
- TX_TYPE = 0x02

## Motivation

When a user sends a transaction `tx0` with a low gas price, some times
it might not be high enough to be executed. A common result is that
same user bumps the gas price
again as `tx1`, hoping to have better chance of being executed.

That previous `tx0` can theoretically be included in any time in the future.

When network is congested, gas price are high, for critical
transactions user might try gas price that is much higher than
an average day. This cause the `tx0` choose might be very easy
to executed in the average day.

If user already uses a `tx1` with different nonce or from another
account to execute the intended transaction, there is currently no
clean way except for signing a new `tx0'` that shares the same nonce
but with higher gas fee hoping that it will execute to *preempt*- than `tx0`.

Given `tx0` was already high gas price, the current way of *preempting* `tx0`
could be both unreliable and very costly.


## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

As of `FORK_BLOCK_NUMBER` for `CHAIN_ID`, we introduce a new [EIP-2718](./eip-2718.md) transaction type, with the format 
  
```cpp
TX_TYPE || rlp([chain_id, expire_by, nonce, gas_price, gas_limit, to, value, data, signature_y_parity, signature_r, signature_s])
```

The `expirer_by` is a block number the latest possible block to
execute this transaction. Any block with a block number `block_num > expired_by` MUST NOT execute this transaction.

## Rationale
TODO

## Backwards Compatibility
TODO

## Test Cases
TODO

## Reference Implementation
An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Security Considerations

1. If `current_block_num` is available, client MUST drop and stop propagating/broadcasting any transactions that has a
`transacton_type == TX_TYPE` AND `current_block_num > expire_by`

2. It is suggested but not required that a `currentBlockNum` SHOULD be made available to client. Any client doing PoW calculation on blocks expired tx or propagating such are essentially penalized for wasting of work, mitigating possible denial of service attack.

3. It is suggested but not required that client SHOULD introduce a 
`gossip_ttl` in unit of block_num as a safe net so that it only propagate
a tx if `current_block_num + gossip_ttl <= expired_by`. Backward compatibility:
for nodes that doesn't have `current_block_num` or `gossip_ttl` available,
they should be presume to be `0`.
  
4. It is suggested by not required that any propagating client SHOULD properly deduct the `gossip_ttl` 
based on the network environment it sees fit.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
