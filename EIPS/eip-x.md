---
eip: 3198
title: BASEFEE opcode
author: Abdelhamid Bakhta (@abdelhamidbakhta)
discussions-to: URL
status: Draft
type: Standards Track
category: Core
created: 2021-01-13
requires: 1559
---

## Simple Summary
Add a `BASEFEE ($OPCODEVALUE)` that returns the value of the base fee at the `latest` block.

## Abstract


## Motivation
The intended use case would be for contracts to get the value of the base fee.

## Specification
Add a `BASEFEE` opcode at `($OPCODEVALUE)`, with gas cost `$OPCODEGASCOST`.

## Rationale

## Backwards Compatibility
This EIP is backwards-compatible.

## Test Cases

## Security Considerations

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
