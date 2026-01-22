---
eip: 8007
title: Glamsterdam Gas Repricings
description: Directory of EIPs introducing changes to the gas pricing model for the Glamsterdam fork
author: Maria Silva (@misilva73), Ansgar Dietrichs (@adietrichs)
discussions-to: https://ethereum-magicians.org/t/eip-8007-glamsterdam-gas-repricings-meta-eip/25206
status: Draft
type: Meta
created: 2025-08-21
requires: 2780, 2926, 7686, 7778, 7904, 7923, 7971, 7973, 7976, 7981, 8011, 8032, 8037, 8038, 8053, 8057, 8058, 8059
---

## Abstract

This Meta EIP documents all the proposals for Glamsterdam related to the gas repricing effort. The goal of this effort is to harmonize gas costs across the EVM, thereby reducing the impact of specific bottlenecks on scaling. Proposals include changes to the cost of single EVM operations, as well as bigger changes to the gas model. This Meta EIP is purely informational and does not aim to have an active role in the governance process for the Glamsterdam fork. Instead, it serves as a directory for all repricing-related proposals, helping to organize the work and keeping the community informed about the status of each EIP.

## Motivation

The main objective of the Glamsterdam fork is to improve L1 scalability. A crucial aspect of this initiative is to create a better alignment between gas costs and actual resource usage. Currently, the gas model often misprices operations, resulting in inefficiencies and unintended incentives. For instance, within the pure compute operations, there is a high variance in execution time per gas unit, which indicates that a single unit of computation is not priced equally across the various opcodes.

By standardizing gas costs across EVM operations and other resources, we can reduce bottlenecks and enhance the utilization of EVM resources, which will subsequently enable further scalability. The EIPs listed below constitute a significant first step in that direction. We expect that further iteration will be necessary in future hardforks.

## Specification

The following table lists all EIPs related to repricings that are being discussed in the scope of the Glamsterdam fork. There are three types of EIPs in this list:

1. **Broad harmonization**. These EIPs reprice a class of operations with the goal of harmonizing them and removing single bottlenecks.
2. **Pricing extension**. These EIPs make targeted changes to a specific opcode or component of the gas model, usually coupled with a new mechanism.
3. **Supporting**. These EIPs are not directly doing a repricing, but instead introduce a change that support other repricing EIPs or enhance the scalability potential of repricings.

This list will continue to be updated as more gas repricing EIPs are proposed.

### EIP list

| EIP | Description | Type | Resource class | Status |
|:---:|---|---|:---:|:---:|
| [EIP-2780](./eip-2780.md) | Reduce intrinsic transaction gas and charge 25k when a value transfer creates a new account. | Broad harmonization | Multi-resource | Considered for Inclusion |
| [EIP-2926](./eip-2926.md) | Introduce code-chunking in an MPT context. | Pricing extension | State | Declined for Inclusion |
| [EIP-7686](./eip-7686.md) | Adjust memory limits and gas limits of sub-calls to create a clear linear bound on how much total memory an EVM execution can consume. | Pricing extension | Memory | Declined for Inclusion |
| [EIP-7778](./eip-7778.md) | Prevent Block Gas Limit Circumvention by Excluding Refunds from Block Gas Accounting. | Pricing extension | General Accounting | Considered for Inclusion |
| [EIP-7904](./eip-7904.md) | Gas Cost Repricing to reflect computational complexity and transaction throughput increase | Broad harmonization | Compute | Considered for Inclusion |
| [EIP-7923](./eip-7923.md) | Linearize Memory Costing and replace the current quadratic formula with a page-based cost model. | Pricing extension | Memory | Declined for Inclusion |
| [EIP-7971](./eip-7971.md) | Decrease costs for `TLOAD` and `TSTORE` with a transaction-global limit. | Pricing extension | Memory | Declined for Inclusion |
| [EIP-7973](./eip-7973.md) | Introduce warm account writes, decreasing the cost of writing to an account after the first write. | Pricing extension | State | Declined for Inclusion |
| [EIP-7976](./eip-7976.md) | Further increase calldata cost to 15/60 gas per byte to reduce maximum block size. | Pricing extension | Data | Considered for Inclusion |
| [EIP-7981](./eip-7981.md) | Introduce floor pricing for access lists to reduce maximum block size. | Pricing extension | Data | Considered for Inclusion |
| [EIP-8011](./eip-8011.md) | Gas accounting by EVM resource, increasing throughput and improving resource usage controls, with minimal changes to the protocol and UX. | Supporting | NA | Declined for Inclusion |
| [EIP-8032](./eip-8032.md) | Makes `SSTORE` gas cost scale with a contract's storage size to discourage state bloat. | Pricing extension | State | Declined for Inclusion |
| [EIP-8037](./eip-8037.md) | Harmonization and increase of state creation gas costs to mitigate state growth and unblock scaling. | Broad harmonization | State | Considered for Inclusion |
| [EIP-8038](./eip-8038.md) | Increases the gas cost of state-access operations to reflect Ethereum’s larger state. | Broad harmonization | State | Considered for Inclusion |
| [EIP-8053](./eip-8053.md) | Adds `milli-gas` as the EVM’s internal gas accounting unit, reducing rounding errors without impacting UX. | Supporting | NA | Declined for Inclusion |
| [EIP-8057](./eip-8057.md) | Multi‑block temporal locality discounts for state and account access. | Pricing extension | State | Declined for Inclusion |
| [EIP-8058](./eip-8058.md) | Reduces gas costs for deploying duplicate contract bytecode via access-list based mechanism. | Pricing extension | State | Declined for Inclusion |
| [EIP-8059](./eip-8059.md) | Gas parameters and variables are increased to a factor of `REBASE_FACTOR` to reduce rounding errors without major changes to the EVM. | Supporting | NA | Declined for Inclusion |

## Rationale

Discussed in the individual EIPs.

## Security Considerations

Discussed in the individual EIPs.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
