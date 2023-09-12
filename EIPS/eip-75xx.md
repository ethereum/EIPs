---
eip: 75xx
title: BLOBBASEFEE opcode
author: Carl Beekhuizen (@carlbeek)
discussions-to: 
status: Draft
type: Standards Track
category: Core
created: 2023-09-11
requires: 3198, 4844
---

## Simple Summary

Adds an opcode that gives the EVM access to the block's blob base-fee.

## Abstract

Add a `BLOBBASEFEE (0x49)` that returns the value of the blob base-fee of the current block it is executing in. It is the identical to EIP-3198 (`BASEFEE` opcode) except that it returns the blob base-fee as per EIP-4844.

## Motivation

The intended use case would be for contracts to get the value of the blob base-fee. This feature enables blob-data users to programmatically account for the blob gas price, eg:

- Allow rollup contracts to trustlessly account for blob data usage costs.
- Blob gas futures can be implemented based on it which allows for blob users to smooth out data blob costs.

## Specification

Add a `BLOBBASEFEE` opcode at `(0x49)`, with gas cost `G_base`.

| Op   | Input | Output | Cost |
|------|-------|--------|------|
| 0x49 | 0     | 1      | 2    |

## Rationale

### Gas cost

The value of the blob base-fee is needed to process data-blob transactions. That means its value is already available before running the EVM code.
The opcode does not add extra complexity and additional read/write operations, hence the choice of `G_base` gas cost. This is also identical to EIP-3198 (`BASEFEE` opcode)'s cost and it does the same thing.

## Backwards Compatibility

There are no known backward compatibility issues with this opcode.

## Test Cases

### Nominal case

Assuming current block's data-blob base-fee is `7 wei`.
This should push the value `7` (left padded byte32) to the stack.

Bytecode: `0x4900` (`BLOBBASEFEE, STOP`)

| Pc | Op          | Cost | Stack | RStack |
|----|-------------|------|-------|--------|
| 0  | BLOBBASEFEE | 2    | []    | []     |
| 1  | STOP        | 0    | [7]   | []     |

Output: 0x
Consumed gas: `2`

## Security Considerations

The value of the blob base-fee is not sensitive and is publicly accessible in the block header. There are no known security implications with this opcode.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
