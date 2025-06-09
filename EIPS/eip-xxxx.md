---
eip: XXXX
title: Increase LOG Opcode Data Cost to 32 Bytes
status: Draft
author: Giulio Rebuffo (@Giulio2002), Ben Adams (@benadams)
discussions-to: <URL or platform for discussion>
type: Core
category: Core
created: 2025-06-09
requires: 1
---

## Simple Summary

Increase the cost granularity of the `data` field for the LOG opcodes (LOG0-LOG4) from 8 bytes to 32 bytes per gas accounting, to better accommodate higher block gas limits and ensure that the maximum event data per block does not exceed the 10 MiB devp2p block size limit until at least 300 million gas per block.

## Abstract

This EIP proposes to change the gas cost calculation for the `data` field of the LOG opcodes from being charged per 8 bytes to per 32 bytes. This adjustment is intended to maintain network stability and prevent blocks from exceeding the devp2p 10 MiB size limit as block gas limits increase.

## Motivation

Currently, the LOG opcodes charge gas for the `data` field in increments of 8 bytes. With increasing block gas limits, this allows for a large amount of event data to be included in a single block, risking blocks that exceed the 10 MiB devp2p protocol limit. By increasing the granularity to 32 bytes, the network can safely support higher gas limits (up to 300 million gas per block) without risking oversized blocks.

## Specification

- The gas cost for the `data` field of LOG opcodes (LOG0, LOG1, LOG2, LOG3, LOG4) is changed from being charged per 8 bytes to per 32 bytes.
- The per-byte cost remains unchanged; only the granularity of charging is updated.
- For example, if the current cost is `Glogdata * ceil(data_length / 8)`, it becomes `Glogdata * ceil(data_length / 32)`.

## Rationale

- **Network Stability:** Prevents blocks from exceeding the devp2p 10 MiB limit as block gas limits increase.
- **Future-Proofing:** Allows for safe increases in block gas limit up to 300 million gas per block.
- **Minimal Disruption:** The change is simple and only affects the granularity of gas accounting for LOG data.

## Backwards Compatibility

This change is not backwards compatible and must be activated via a network upgrade (hard fork). Contracts that emit large amounts of event data will see increased gas costs.

## Security Considerations

This change reduces the risk of denial-of-service attacks via oversized blocks filled with event data.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
