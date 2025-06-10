---
eip: XXXX
title: Increase LOG Opcode Cost
status: Draft
author: Giulio Rebuffo (@Giulio2002), Ben Adams (@benadams)
discussions-to: https://ethereum-magicians.org/t/increase-log-opcode-cost/24510
type: Core
category: Core
created: 2025-06-09
requires: 1
---

## Abstract

This EIP proposes to change the gas cost calculation for the `data` field of the LOG opcodes from being charged 8 gas per byte to 32 gas per byte. This adjustment is intended to maintain network stability and prevent blocks from exceeding the devp2p 10 MiB size limit as block gas limits increase. Additionally, it increases both the base cost for LOGN opcodes and the additional cost per topic to 1095 gas from 375 gas.

## Motivation

The current cost of LOG operations no longer reflects the real impact that log data has on block size and network stability, especially as the block gas limit increases. Excessively large blocks risk exceeding the 10 MiB devp2p protocol limit, causing propagation and synchronization issues.

## Specification

Change the gas cost calculation for LOG opcodes as follows:

- The per-byte cost for the `data` field in LOG opcodes is increased from 8 gas to 32 gas. (4x increase)
- The base cost for each LOGN opcode and the additional cost per topic are increased from 375 gas to 1095 gas.

These changes apply to all LOG variants (LOG0, LOG1, LOG2, LOG3, LOG4).

## Rationale

Increasing the per-byte cost of logs discourages excessive use of LOG as a cheap storage mechanism, aligning the cost with the actual network impact. Raising the base and per-topic costs reflects the computational and propagation complexity associated with LOG operations. We are targeting a 32 gas per byte of the raw rpl receipt. this is accomplished by 3x the Glog and 4x the GlogData costs. with this parameter, each byte is worth 32 gas, which allows us for a Gas Limit increase up to `300mn`.

`300_000_000/32=9_375_000` bytes, which is 9.3 MiB, well within the devp2p protocol limit of 10 MiB.

## Backwards Compatibility

This change is not backwards compatible.

## Security Considerations

Increasing the costs reduces the risk of DoS attacks based on excessive logs and helps keep block sizes within manageable limits.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
