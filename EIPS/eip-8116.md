---
eip: 8116
title: Replace cumulative receipt fields
description: Replace cumulativeGasUsed with gasUsed in on-chain receipt
author: Etan Kissling (@etan-status), Gajinder Singh (@g11tech)
discussions-to: https://ethereum-magicians.org/t/eip-8116-replace-cumulative-receipt-fields/27359
status: Draft
type: Standards Track
category: Core
created: 2025-12-30
---

## Abstract

This EIP describes how to change the on-chain receipt data to track gas per transaction instead of cumulatively.

## Motivation

Currently, on-chain receipts track a `cumulativeGasUsed` field which contains the running sum of all gas spent for all transactions in the block so far. This has a number of shortcomings:

1. **Inefficient verification:** RPC clients that want to verify individual transaction `gasUsed` requires computation based on `cumulativeGasUsed` across consecutive receipts.

2. **Limited parallelism:** Receipt contents are stateful, even for transactions accessing mutually exclusive state.

The `logIndex` field exposed via JSON-RPC is currently also tracking an incremental block level index instead of a per-receipt index, with similar shortcomings.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### `Receipt` construction

All receipts emitted after this EIP activates track the individual transaction's `gasUsed` instead of the incremental `cumulativeGasUsed` value.

### JSON-RPC API

Within `logs`, the `logIndex` field is changed to indicate the log index position in the individual receipt, rather than in the entire block.

## Rationale

This EIP is a step towards aligning on-chain data with the RPC data actually being consumed by client applications. Stateful components of receipts (`cumulativeGasUsed` / `logIndex`) are replaced with per-transaction equivalents.

## Backwards Compatibility

Applications using verified `gasUsed` / `cumulativeGasUsed` values need to adapt to the new on-chain data semantics.

Applications relying on the per block `logIndex` need adaptation, as `logIndex` now refers to an index per receipt. Note that this is solely an RPC change. Relative log ordering can be emulated by estimating `logIndex` as `transactionIndex * 4 + logIndex` (guaranteed to have same order as before, but absolute index values may be higher than before).

## Security Considerations

None

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
