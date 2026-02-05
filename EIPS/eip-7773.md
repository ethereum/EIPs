---
eip: 7773
title: Hardfork Meta - Glamsterdam
description: EIPs included in the Glamsterdam Ethereum network upgrade.
author: Tim Beiko (@timbeiko), Alex Stokes (@ralexstokes), Ansgar Dietrichs (@adietrichs)
discussions-to: https://ethereum-magicians.org/t/eip-7773-glamsterdam-network-upgrade-meta-thread/21195
status: Draft
type: Meta
created: 2024-09-26
requires: 7607, 7723
---

## Abstract

This Meta EIP lists the EIPs formally Proposed, Considered, Declined for & Scheduled for Inclusion in the Glamsterdam network upgrade.

## Specification

Definitions for `Scheduled for Inclusion`, `Considered for Inclusion`, `Declined for Inclusion` and `Proposed for Inclusion` can be found in [EIP-7723](./eip-7723.md).

### EIPs Scheduled for Inclusion

* [EIP-7732](./eip-7732.md): Enshrined Proposer-Builder Separation
* [EIP-7928](./eip-7928.md): Block-Level Access Lists

### Considered for Inclusion

* [EIP-2780](./eip-2780.md): Reduce intrinsic transaction gas
* [EIP-7688](./eip-7688.md): Forward compatible consensus data structures
* [EIP-7708](./eip-7708.md): ETH transfers emit a log
* [EIP-7778](./eip-7778.md): Block Gas Accounting without Refunds
* [EIP-7843](./eip-7843.md): SLOTNUM opcode
* [EIP-7904](./eip-7904.md): General Repricing
* [EIP-7954](./eip-7954.md): Increase Maxiumum Contract Size
* [EIP-7976](./eip-7976.md): Increase Calldata Floor Cost
* [EIP-7981](./eip-7981.md): Increase Access List Cost
* [EIP-7997](./eip-7997.md): Deterministic Factory Predeploy
* [EIP-8024](./eip-8024.md): Backward compatible SWAPN, DUPN, EXCHANGE
* [EIP-8037](./eip-8037.md): State Creation Gas Cost Increase
* [EIP-8038](./eip-8038.md): State-access gas cost increase
* [EIP-8045](./eip-8045.md): Exclude slashed validators from proposing
* [EIP-8061](./eip-8061.md): Increase exit and consolidation churn
* [EIP-8070](./eip-8070.md): Sparse Blobpool
* [EIP-8080](./eip-8080.md): Let exits use the consolidation queue

### Declined for Inclusion

* [EIP-2926](./eip-2926.md): Chunk-based code merkelization
* [EIP-5920](./eip-5920.md): PAY opcode
* [EIP-6404](./eip-6404.md): SSZ transactions
* [EIP-6466](./eip-6466.md): SSZ receipts
* [EIP-7619](./eip-7619.md): Precompile Falcon512 generic verifier
* [EIP-7668](./eip-7668.md): Remove bloom filters
* [EIP-7686](./eip-7686.md): Linear EVM memory limits
* [EIP-7692](./eip-7692.md): EVM Object Format (EOFv1) Meta
* [EIP-7745](./eip-7745.md): Trustless log index
* [EIP-7782](./eip-7782.md): Reduce Block Latency
* [EIP-7791](./eip-7791.md): GAS2ETH opcode
* [EIP-7793](./eip-7793.md): Conditional Transactions
* [EIP-7805](./eip-7805.md): Fork-choice enforced Inclusion Lists (FOCIL)
* [EIP-7819](./eip-7819.md): SETDELEGATE instruction
* [EIP-7886](./eip-7886.md): Delayed execution
* [EIP-7903](./eip-7903.md): Remove Initcode Size Limit
* [EIP-7907](./eip-7907.md): Meter Contract Code Size And Increase Limit
* [EIP-7919](./eip-7919.md): Pureth Meta
* [EIP-7923](./eip-7923.md): Linear, Page-Based Memory Costing
* [EIP-7932](./eip-7932.md): Secondary Signature Algorithms
* [EIP-7937](./eip-7937.md): EVM64 - 64-bit mode EVM opcodes
* [EIP-7942](./eip-7942.md): Available Attestation
* [EIP-7971](./eip-7971.md): Hard Limits for Transient Storage
* [EIP-7973](./eip-7973.md): Warm Account Write Metering
* [EIP-7979](./eip-7979.md): Call and Return Opcodes for the EVM
* [EIP-8011](./eip-8011.md): Multidimensional Gas Metering
* [EIP-8013](./eip-8013.md): Static relative jumps and calls for the EVM
* [EIP-8030](./eip-8030.md): P256 transaction support
* [EIP-8032](./eip-8032.md): Size-Based Storage Gas Pricing
* [EIP-8051](./eip-8051.md): Precompile for ML-DSA signature verification
* [EIP-8053](./eip-8053.md): Milli-gas for High-precision Gas Metering
* [EIP-8057](./eip-8057.md): Inter-Block Temporal Locality Gas Discounts
* [EIP-8058](./eip-8058.md): Contract Bytecode Deduplication Discount
* [EIP-8059](./eip-8059.md): Gas Units Rebase for High-precision Metering
* [EIP-8062](./eip-8062.md): Add sweep withdrawal fee for 0x01 validators
* [EIP-8068](./eip-8068.md): Neutral effective balance design
* [EIP-8071](./eip-8071.md): Prevent using consolidations as withdrawals

### Proposed for Inclusion

* [EIP-7610](./eip-7610.md): Revert creation in case of non-empty storage
* [EIP-7872](./eip-7872.md): Max blob flag for local builders
* [EIP-7949](./eip-7949.md): Schema for `genesis.json` files

### Activation

| Network Name | Activation Epoch | Activation Timestamp |
| ------------ | ---------------- | -------------------- |
| Sepolia      |                  |                      |
| Holešky      |                  |                      |
| Mainnet      |                  |                      |

**Note**: rows in the table above will be filled as activation times are decided by client teams.

## Rationale

This Meta EIP provides a global view of all changes included in the Glamsterdam network upgrade, as well as links to full specification.

## Security Considerations

None.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
