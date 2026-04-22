---
eip: 8115
title: Batch priority fees at end of block
description: Delay all priority fee credits from transactions to end of block
author: Etan Kissling (@etan-status), Gajinder Singh (@g11tech)
discussions-to: https://ethereum-magicians.org/t/eip-8115-batch-priority-fees-at-end-of-block/27358
status: Draft
type: Standards Track
category: Core
created: 2025-12-30
requires: 1559, 4895
---

## Abstract

This EIP defines how to optimize processing of priority fees from [EIP-1559](./eip-1559.md) fee market transactions.

## Motivation

Priority fees are credited at the end of each transaction, leading to these complications:

1. **Limited parallelization:** Each transaction writes to the fee recipient account balance.

2. **Mempool complexities:** A transaction sender may become solvent only after prior transactions in a block have been processed.

3. **Accounting complexities:** The fee recipient gets hundreds of micropayments for what could logically be a single credit.

4. **Inaccurate logs:** Proposals to emit logs on ETH transfers either have to omit priority fees, limiting their usefulness due to inaccuracies, or have to emit an extra entry for each individual fee, making them expensive.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Priority fee processing

[EIP-1559](./eip-1559.md) priority fees SHALL no longer be credited after each individual transaction. Instead, they SHALL be summed up and credited after all transactions of a block are processed but before [EIP-4895](./eip-4895.md) withdrawals are processed.

## Rationale

This EIP is one step towards fully accurate ETH balance logs. Batched crediting of priority fees improves parallel execution of transactions, as a transaction can no longer start with insufficient fees and only become eligible for execution after incremental priority fees have been credited.

## Backwards Compatibility

The fee recipient now receives priority fees at the end of the block rather than incrementally after each transaction, making it only possible to spend them in the next block. This may require updates to block builder infrastructure and change liquidity requirements for MEV use cases.

## Security Considerations

No security impact.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
