---
eip: XXXX
title: Set MAX_RECEIPTS_MESSAGE_SIZE for GetReceipts in devp2p
status: Draft
author: Giulio Rebuffo (@Giulio2002)
discussions-to: https://ethereum-magicians.org/t/set-max-receipts-message-size/24511
type: Networking
category: Networking
created: 2025-06-11
requires: 8
---

## Abstract

This EIP proposes to set a specific maximum size limit (`MAX_RECEIPTS_MESSAGE_SIZE`) for the `GetReceipts` message in the devp2p protocol. The goal is to prevent excessively large receipt messages that could negatively impact network stability and client resource usage.

## Motivation

Currently, there is a global upper bound on devp2p message size of 10 MiB, but as block gas limits increase, the `GetReceipts` message can reach this global limit too early. This restricts the ability to safely raise the block gas limit, as large receipt messages may cause blocks to approach or exceed the devp2p protocol's maximum message size. By setting a specific limit for `GetReceipts`, we ensure that the network remains robust and that block gas limit increases do not inadvertently lead to network instability or message propagation failures.

## Specification

- Introduce a constant `MAX_RECEIPTS_MESSAGE_SIZE` (e.g., 15 MiB) for the `GetReceipts` message in the devp2p protocol.
- Any `GetReceipts` message exceeding this size MUST be rejected by the receiving node.
- Nodes SHOULD NOT send `GetReceipts` messages that would exceed this limit.
- If a node receives a message exceeding the limit, it MAY disconnect the peer or ignore the message.
- The value of `MAX_RECEIPTS_MESSAGE_SIZE` is set to 15,728,640 bytes (15 MiB).

## Rationale

A fixed upper bound prevents resource exhaustion attacks and ensures that all clients can safely process receipt messages. The 15 MiB value is chosen to balance efficiency and safety, and is in line with other devp2p message size limits.

## Backwards Compatibility

This change is not backwards compatible for clients that currently allow larger `GetReceipts` messages. However, it is expected that most clients already implement some form of limit for practical reasons.

## Security Considerations

Setting a maximum message size reduces the risk of denial-of-service attacks and helps maintain healthy peer-to-peer connections.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
