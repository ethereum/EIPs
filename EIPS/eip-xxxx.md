---
eip: xxxx
title: Increase Maximum Contract Size to 64KiB
description: Raise the maximum contract code size from 32KiB to 64KiB and initcode
  size from 64KiB to 128KiB, with chunk-based gas costs above 32KiB.
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
beyond the current 32KiB boundary incurs a chunk-based surcharge
using a 31-byte chunk size, following the chunking model established
by [EIP-2926](./eip-2926.md).

## Motivation

Even with [EIP-7954](./eip-7954.md) raising the limit from 24KiB to
32KiB, complex protocols and on-chain libraries continue to hit the
ceiling. Developers resort to proxy patterns and contract splitting,
which increase deployment cost, complexity, and attack surface.

A hard cap increase alone raises concerns about state bloat and
denial-of-service via large code deployments. By introducing a
chunk-based surcharge for code beyond 32KiB — where each 31-byte
chunk incurs an additional cost — this EIP balances developer
flexibility with economic deterrence against gratuitous state
growth.

The chunk size of 31 bytes and the per-chunk gas cost are inherited
from [EIP-2926](./eip-2926.md), which establishes this model for
code merkleization. Reusing these constants ensures forward
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
| `CHUNK_SIZE` | `31` (bytes) |
| `STANDARD_CODE_DEPOSIT_COST` | `200` (gas per byte) |
| `EXTENDED_CHUNK_COST` | `500` (gas per chunk) |
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

- The standard deposit cost of
  `N * STANDARD_CODE_DEPOSIT_COST` applies to ALL bytes.
- If `N > EXTENDED_THRESHOLD`, an additional chunk-based
  surcharge is applied for the extended region:
  `ceil((N - EXTENDED_THRESHOLD) / CHUNK_SIZE) * EXTENDED_CHUNK_COST`.

The total deposit cost is:

```
deposit_cost = N * 200
if N > 32768:
    extended_bytes = N - 32768
    extended_chunks = (extended_bytes + 30) // 31
    deposit_cost += extended_chunks * 500
```

### Initcode cost

The `INITCODE_WORD_COST` of 2 gas per 32-byte word defined in
[EIP-3860](./eip-3860.md) remains unchanged and applies uniformly
to all initcode regardless of size.

## Rationale

### Chunk-based surcharge

Rather than repricing the per-byte cost above 32KiB, this EIP
applies a per-chunk surcharge on top of the standard deposit cost.
The 31-byte chunk size matches [EIP-2926](./eip-2926.md) and
represents the natural unit of account in a merkleized code trie.
Larger code requires more chunks in the trie, more proof hashes
in witnesses, and more storage overhead — the surcharge reflects
this marginal cost.

### Cost comparison

| Code size | Standard deposit | Chunk surcharge | Total |
|---|---|---|---|
| 32KiB | 6,553,600 | 0 | 6,553,600 |
| 48KiB | 9,830,400 | 528,500 | 10,358,900 |
| 64KiB | 13,107,200 | 529,000 | 13,636,200 |

Contracts within the 32KiB boundary pay exactly what they pay
today. A maximum-size 64KiB contract costs ~13.6M gas to deploy,
which fits in a single block but carries a meaningful chunk
surcharge of ~529K gas.

### 31-byte chunk size

The chunk size of 31 bytes is inherited from
[EIP-2926](./eip-2926.md). Each chunk in a merkleized code trie
is stored as `FIO || code_chunk` (1 byte first-instruction-offset
+ 31 bytes code = 32 bytes), aligning with hash input sizes.

### 500 gas per chunk

The 500 gas per-chunk cost is inherited from
[EIP-2926](./eip-2926.md), which establishes this rate for chunks
written beyond the legacy boundary. Reusing this constant avoids
introducing new magic numbers and ensures compatibility if
chunk-based code storage is adopted.

### Power-of-two boundary

64KiB (2^16) is a natural alignment boundary. It matches common
memory page sizes and simplifies tooling and analysis.

### Preserved initcode ratio

The 2:1 ratio between initcode and runtime code limits from
[EIP-3860](./eip-3860.md) is maintained (128KiB initcode for
64KiB runtime).

## Backwards Compatibility

This change is not backwards compatible and MUST be activated
via a network upgrade. It assumes [EIP-7954](./eip-7954.md)
has already been activated.

After activation:

- Existing contracts are unaffected.
- Contracts up to 32KiB deploy at unchanged cost.
- Contracts between 32KiB and 64KiB deploy at the standard
  per-byte cost plus the chunk-based surcharge defined above.

## Security Considerations

### State growth

The chunk surcharge acts as an economic deterrent against
unnecessary use of the extended region. Deploying a 64KiB
contract costs ~13.6M gas, a meaningful fraction of a block's
gas limit.

### Code-accessing opcodes

`EXTCODECOPY` and `EXTCODESIZE` already charge gas proportional
to the size of the code accessed. No changes to these opcodes
are required by this EIP.

### Forward compatibility with merkleization

The chunk size and per-chunk cost align with
[EIP-2926](./eip-2926.md). If chunk-based code merkleization is
adopted, the gas model introduced here remains consistent and
may be absorbed into the merkleization framework with no
repricing needed for the extended region.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
