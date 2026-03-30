---
eip: 8208
title: Increase Maximum Contract Size to 64KiB
description: Raise the maximum contract code size from 32KiB to 64KiB and initcode
  size from 64KiB to 128KiB.
author: Giulio Rebuffo (@Giulio2002)
discussions-to: https://ethereum-magicians.org/t/increase-maximum-contract-size-to-48kb/24509
status: Draft
type: Standards Track
category: Core
created: 2026-03-28
requires: 170, 3860, 7954
---

## Abstract

This EIP raises the maximum contract code size from 32KiB to 64KiB
and the maximum initcode size from 64KiB to 128KiB.

## Motivation

Even with [EIP-7954](./eip-7954.md) raising the limit from 24KiB to
32KiB, complex protocols and on-chain libraries continue to hit the
ceiling. Developers resort to proxy patterns and contract splitting,
which increase deployment cost, complexity, and attack surface.

Raising the limit to 64KiB provides meaningful headroom while
remaining conservative relative to block gas limits and state growth.
The 2:1 ratio between initcode and runtime code limits established
by [EIP-3860](./eip-3860.md) is preserved.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY",
and "OPTIONAL" in this document are to be interpreted as described
in RFC 2119 and RFC 8174.

### Parameters

| Parameter | Value |
|---|---|
| `MAX_CODE_SIZE` | `65536` (`0x10000`, 64KiB) |
| `MAX_INITCODE_SIZE` | `131072` (`0x20000`, 128KiB) |

### Code size limits

1. The [EIP-170](./eip-170.md) contract code size limit is raised
   from 32KiB to `MAX_CODE_SIZE` (64KiB).
2. The [EIP-3860](./eip-3860.md) initcode size limit is raised
   from 64KiB to `MAX_INITCODE_SIZE` (128KiB).

The `INITCODE_WORD_COST` of 2 gas per 32-byte word defined in
[EIP-3860](./eip-3860.md) remains unchanged.

## Rationale

- **Developer flexibility:** Eliminates the most common reason for
  proxy-based contract splitting, reducing deployment complexity
  and gas overhead.
- **Power of two:** 64KiB (2^16) is a natural boundary that aligns
  with common memory page sizes and simplifies tooling.
- **Preserved ratio:** The 2:1 initcode-to-runtime ratio from
  [EIP-3860](./eip-3860.md) is maintained at 128KiB initcode for
  64KiB runtime.
- **Backward compatibility:** All existing contracts remain valid.
  Only new deployments may take advantage of the increased limit.

## Backwards Compatibility

This change is not backwards compatible and MUST be activated via a
network upgrade. It assumes [EIP-7954](./eip-7954.md) has already
been activated.

After activation, contracts up to 64KiB in size will be deployable.
Existing contracts are unaffected.

## Security Considerations

Larger contracts increase the worst-case cost of `EXTCODECOPY` and
`EXTCODESIZE` operations. However, these opcodes already charge gas
proportional to the size of the code accessed, so the economic cost
scales accordingly.

The maximum single-contract code size of 64KiB remains small
relative to the total state size and block gas limits. Deploying a
maximum-size contract requires paying for the full calldata cost of
the initcode plus the code deposit cost, which acts as a natural
economic deterrent against state bloat.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
