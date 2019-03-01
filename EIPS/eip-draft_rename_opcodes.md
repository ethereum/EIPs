---
eip: <to be assigned>
title: Rename opcodes for clarity
author: Alex Beregszaszi (@axic)
type: Standards Track
category: Core
status: Draft
created: 2017-07-28
---

## Abstract

Rename the `BALANCE`, `SHA3`, `NUMBER`, `GASLIMIT` and `GAS` opcodes to reflect their true meaning.

## Specification

Rename the opcodes as follows:
- `BALANCE` to `EXTBALANCE` to be in line with `EXTCODESIZE` and `EXTCODECOPY`
- `SHA3` to `KECCAK256`
- `NUMBER` to `BLOCKNUMBER`
- `GASLIMIT` to `BLOCKGASLIMIT` to avoid confusion with the gas limit of the transaction
- `GAS` to `GASLEFT` to be clear what it refers to

## Backwards Compatibility

This has no effect on any code. It can influence what mnemonics assemblers will use.

## Implementation

Not applicable.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
