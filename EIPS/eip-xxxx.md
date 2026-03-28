---
eip: xxxx
title: Increase Maximum Contract Size to 64KiB
description: Raise the maximum contract code size from 24KiB to 64KiB and initcode size from 48KiB to 128KiB.
author: Giulio Rebuffo (@Giulio2002)
discussions-to: https://ethereum-magicians.org/t/increase-maximum-contract-size-to-48kb/24509
status: Draft
type: Standards Track
category: Core
created: 2026-03-28
requires: 170, 3860
---

## Abstract

This EIP proposes to raise the maximum allowed size for contract code deployed on Ethereum from 24,576 bytes to 65,536 bytes and the maximum initcode size from 49,152 bytes to 131,072 bytes.

## Motivation

The current 24KiB contract size limit, introduced by [EIP-170](./eip-170.md), is increasingly restrictive for modern smart contract development. Complex protocols, on-chain libraries, and feature-rich applications frequently hit this ceiling, forcing developers to split logic across multiple contracts with proxy patterns, increasing deployment cost, complexity, and attack surface.

Raising the limit to 64KiB provides meaningful headroom while remaining conservative relative to block gas limits and state growth. The 2:1 ratio between initcode and runtime code limits established by [EIP-3860](./eip-3860.md) is preserved.

## Specification

1. Update the [EIP-170](./eip-170.md) contract code size limit from 24KiB (`0x6000` bytes) to 64KiB (`0x10000` bytes).
2. Update the [EIP-3860](./eip-3860.md) initcode size limit from 48KiB (`0xC000` bytes) to 128KiB (`0x20000` bytes).

The `INITCODE_WORD_COST` of 2 gas per 32-byte word defined in [EIP-3860](./eip-3860.md) remains unchanged.

## Rationale

- **Developer flexibility:** Eliminates the most common reason for proxy-based contract splitting, reducing deployment complexity and gas overhead.
- **Power of two:** 64KiB (2^16) is a natural boundary that aligns with common memory page sizes and simplifies tooling.
- **Preserved ratio:** The 2:1 initcode-to-runtime ratio from [EIP-3860](./eip-3860.md) is maintained at 128KiB initcode for 64KiB runtime.
- **Bounded cost:** The `INITCODE_WORD_COST` still applies, so deploying a 64KiB contract costs proportionally more gas than a smaller one. The deployment cost for a max-size contract is approximately 4,096 words × 2 = 8,192 additional gas for initcode hashing, which is negligible relative to the intrinsic transaction cost and calldata costs.
- **Backward compatibility:** All existing contracts remain valid. Only new deployments may take advantage of the increased limit.

## Backwards Compatibility

This change is not backwards compatible and must be activated via a network upgrade (hard fork). After activation, contracts up to 64KiB in size will be deployable. Existing contracts are unaffected.

## Security Considerations

Larger contracts increase the worst-case cost of `EXTCODECOPY` and `EXTCODESIZE` operations. However, these opcodes already charge gas proportional to the size of the code accessed, so the economic cost scales accordingly.

The maximum single-contract code size of 64KiB remains small relative to the total state size and block gas limits. Deploying a maximum-size contract requires paying for the full calldata cost of the initcode, which at current gas prices acts as a natural economic deterrent against state bloat.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
