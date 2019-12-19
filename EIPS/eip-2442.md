---
eip: <to be assigned>
title: LOGQUERY(n) opcodes
author: pinkiebell (@pinkiebell)
discussions-to: <to be assigned>
status: Draft
type: Standards Track
category: Core
created: 2019-12-19
---

## Abstract

This EIP specifies new opcodes `LOGQUERY(x)`, which mirrors the semantics of the `LOG(n)` opcodes to gain the support
for querying/filtering the most recent log event of the current contract/EVM context.

## Motivation

To better support stateless(light)-clients, layer-2 scaling solutions and similiar applications,
gaining the ability to query the last emitted log event and having the log-data available inside a
contract has a huge benefit to an overall simpler system/application design.

In the context of optimistic-rollup solutions, one could imagine to use `LOG` events, corresponding `topics` as storage keys and log-data
as a way to signal state changes to light clients and simultaneously using it as a storage backend for the on-chain contract itself.

A rudimentary example:
```
// Layer-2 Bridge contract transfers AMOUNT of TOKEN from `Alice` to `Bob`.

let storageTopic = keccak256(Alice, Token)
// query Alice
let success = logquery1(memoryPtr, 0, 32, storageTopic)

// we had a past event
if (success) {
  // the data of the log contains the uint256 balance
  let aliceBalance = mload(memoryPtr)

  if (aliceBalance >= AMOUNT) {
    mstore(memoryPtr, aliceBalance - AMOUNT)
    // update Alice's new balance
    log1(memoryPtr, 32, storageTopic)

    // Bob's new (pre) balance
    mstore(memoryPtr, AMOUNT)
    let storageTopic = keccak256(Bob, Token)
    // query Bob
    success = logquery1(memoryPtr, 0, 32, storageTopic)
    if (success) {
      // update Bob's balance
      mstore(memoryPtr, mload(memoryPtr) + AMOUNT)
    }
    // log Bob's new balance
    log1(memoryPtr, 32, storageTopic)
  } else {
    // Alice has not enough AMOUNT
    revert()
  }

} else {
  // no event for (Alice, Token) emitted in the past - who is Alice?
  revert()
}
```

Other solutions like validating log events with past block-hashes are inconvienent and also of limited use.
Additionally, there is no trustless way of verifying if any given log was the latest/most recent  one.

## Specification

```
GAS_BASE = 100
GAS_BYTE = 3

```

`(t, f, s)` = copy `s` bytes from log's data at position `f` to mem at position `t`.

| Opcode                                             | Hex  | Gas cost                          | Notes                                          |
| -------------------------------------------------- | ---- | --------------------------------- | ---------------------------------------------- |
| logquery0(t, f, s)                                 | 0xb0 | `GAS_BASE + (s * GAS_BYTE)`       | No topic filter - fetch most recent log        |
| logquery1(t, f, s, topic1)                         | 0xb1 | `(GAS_BASE * 2) + (s * GAS_BYTE)` | Get last log with 1 topic and topic = `topic1` |
| logquery2(t, f, s, topic1, topic2)                 | 0xb2 | `(GAS_BASE * 3) + (s * GAS_BYTE)` | ...                                            |
| logquery3(t, f, s, topic1, topic2, topic3)         | 0xb3 | `(GAS_BASE * 4) + (s * GAS_BYTE)` | ...                                            |
| logquery4(t, f, s, topic1, topic2, topic3, topic4) | 0xb4 | `(GAS_BASE * 5) + (s * GAS_BYTE)` | ...                                            |


Common behaviour for all `logqueryX` opcodes:
- If there is no matching log
  - Push `0` to stack and do not touch memory(`t`, `s`).
- If there is a matching log
  - Push `1` to the stack and fill memory(`t` = memory pointer, `s` = size) with the log's `data` starting at `f` and size `s` bytes.
  - If `f + s` is greater than the log's `data`, then pad the remaining length with `0`'s.

## Rationale

As described in the motivation section, this opcode is widely useful and should help the ongoing Eth1.x efforts.

## Backwards Compatibility

There are no backwards compatibility concerns.

## Test Cases

TBD

## Implementation

TBD

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
