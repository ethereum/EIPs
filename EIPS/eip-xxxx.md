---
eip: xxxx
title: Increase Maximum Contract Size to 64KiB
description: Raise the maximum contract code size from 32KiB to 64KiB and initcode
  size from 64KiB to 128KiB, with increased gas costs above 32KiB.
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
and the maximum initcode size from 64KiB to 128KiB. Code deployed
beyond the current 32KiB boundary incurs a higher per-byte creation
cost (500 gas/byte instead of 200 gas/byte), following the gas model
established by [EIP-2926](./eip-2926.md).

## Motivation

Even with [EIP-7954](./eip-7954.md) raising the limit from 24KiB to
32KiB, complex protocols and on-chain libraries continue to hit the
ceiling. Developers resort to proxy patterns and contract splitting,
which increase deployment cost, complexity, and attack surface.

A hard cap increase alone raises concerns about state bloat and
denial-of-service via large code deployments. By introducing a
tiered gas model — standard cost up to 32KiB, elevated cost above
— this EIP balances developer flexibility with economic deterrence
against gratuitous state growth.

The elevated cost of 500 gas per byte for the extended region is
inherited from [EIP-2926](./eip-2926.md), which establishes this
rate for code written beyond the legacy boundary in the context of
code merkleization. Reusing this constant ensures forward
compatibility with chunk-based code storage proposals.

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
| `STANDARD_CODE_DEPOSIT_COST` | `200` (gas per byte) |
| `EXTENDED_CODE_DEPOSIT_COST` | `500` (gas per byte) |
| `EXTENDED_THRESHOLD` | `32768` (`0x8000`, 32KiB) |

### Code size limits

1. The [EIP-170](./eip-170.md) contract code size limit is raised
   from 32KiB to `MAX_CODE_SIZE` (64KiB).
2. The [EIP-3860](./eip-3860.md) initcode size limit is raised
   from 64KiB to `MAX_INITCODE_SIZE` (128KiB).

### Contract creation gas cost

The gas cost for storing contract code during creation (`CREATE`,
`CREATE2`, or deployment transactions) is modified as follows.

For a contract with final code of `N` bytes:

- If `N <= EXTENDED_THRESHOLD`:
  the cost is `N * STANDARD_CODE_DEPOSIT_COST` (unchanged).
- If `N > EXTENDED_THRESHOLD`:
  the cost is
  `EXTENDED_THRESHOLD * STANDARD_CODE_DEPOSIT_COST + (N - EXTENDED_THRESHOLD) * EXTENDED_CODE_DEPOSIT_COST`.

In pseudocode:

```python
def code_deposit_cost(code_size):
    if code_size <= EXTENDED_THRESHOLD:
        return code_size * STANDARD_CODE_DEPOSIT_COST
    base = EXTENDED_THRESHOLD * STANDARD_CODE_DEPOSIT_COST
    extended = (code_size - EXTENDED_THRESHOLD) * EXTENDED_CODE_DEPOSIT_COST
    return base + extended
```

### Initcode cost

The `INITCODE_WORD_COST` of 2 gas per 32-byte word defined in
[EIP-3860](./eip-3860.md) remains unchanged and applies uniformly
to all initcode regardless of size.

## Rationale

### Tiered gas model

A flat increase to 64KiB with no repricing would lower the
economic cost of state bloat. The tiered model ensures that
contracts within the pre-existing 32KiB boundary pay exactly
what they pay today, while contracts that use the extended
space pay a 2.5x premium per byte. This discourages
unnecessary bloat while still making 64KiB contracts
economically feasible.

### Cost comparison

| Code size | Current (200/byte) | This EIP |
|---|---|---|
| 32KiB | 6,553,600 | 6,553,600 |
| 48KiB | Rejected | 14,745,600 |
| 64KiB | Rejected | 22,937,600 |

A maximum-size 64KiB contract costs ~23M gas to deploy,
which is within a single block's gas limit but expensive
enough to deter frivolous use.

### 500 gas per byte

The 500 gas/byte rate is inherited from
[EIP-2926](./eip-2926.md), which introduces this cost for
code chunks written beyond the legacy boundary in a
merkleization context. Reusing this constant avoids
introducing a new magic number and ensures compatibility
if chunk-based code storage is adopted in the future.

### Power-of-two boundary

64KiB (2^16) is a natural alignment boundary. It matches
common memory page sizes and simplifies tooling and analysis.

### Preserved initcode ratio

The 2:1 ratio between initcode and runtime code limits
from [EIP-3860](./eip-3860.md) is maintained (128KiB
initcode for 64KiB runtime).

## Backwards Compatibility

This change is not backwards compatible and MUST be activated
via a network upgrade. It assumes [EIP-7954](./eip-7954.md)
has already been activated.

After activation:

- Existing contracts are unaffected.
- Contracts up to 32KiB deploy at unchanged cost.
- Contracts between 32KiB and 64KiB deploy at the tiered
  cost defined above.

## Security Considerations

### State growth

The elevated cost above 32KiB acts as an economic deterrent.
Deploying a maximum-size 64KiB contract costs ~23M gas,
consuming most of a block's gas limit for the deployment
transaction alone.

### Code-accessing opcodes

`EXTCODECOPY` and `EXTCODESIZE` already charge gas
proportional to the size of the code accessed. No changes
to these opcodes are required.

### Forward compatibility with merkleization

The 500 gas/byte rate aligns with
[EIP-2926](./eip-2926.md). If chunk-based code
merkleization is adopted, the gas model introduced here
remains consistent and may be absorbed into the
merkleization framework.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
