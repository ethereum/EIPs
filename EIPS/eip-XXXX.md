---
eip: XXXX
title: Separated Payer Transaction
author: Tomasz Stanczak (@tkstanczak), Ansgar Dietrichs (@adietrichs)
discussions-to: tbd
status: Draft
type: Standards Track
category: Core
created: 2023-11-03
---

## Simple Summary
This EIP creates a new transaction type that separates the roles of transaction sender and payer.

## Motivation
[EIP-2711](./eip-2711.md) tried to introduce sponsored transactions as part of a broader set of new transaction behaviors. As a result of the broad scope, the EIP was never accepted. This EIP implements the core concept of sponsored transactions in isolation.

## Specification

### Parameters

| Constant | Value |
| - | - |
| `SP_TX_TYPE` | `Bytes1(0x04)` |
| `SENDER_BYTE` | `Bytes1(0x00)` |
| `PAYER_BYTE`  | `Bytes1(0x01)` |

### Separated Payer Transaction

We introduce a new [EIP-2718](./eip-2718.md) transaction, "separated payer transaction", where the `TransactionType` is `SP_TX_TYPE` and the `TransactionPayload` is the RLP serialization of the following `TransactionPayloadBody`:

```python
[
    chain_id,
    nonce,
    max_priority_fee_per_gas,
    max_fee_per_gas,
    gas_limit,
    to,
    value,
    data,
    access_list,
    sender_y_parity,
    sender_r,
    sender_s,
    payer_y_parity,
    payer_r,
    payer_s
]
```

The fields `chain_id`, `nonce`, `max_priority_fee_per_gas`, `max_fee_per_gas`, `gas_limit`, `to`, `value`, `data`, and `access_list` follow the same semantics as [EIP-1559](./eip-1559.md).

The [EIP-2718](./eip-2718.md) `ReceiptPayload` for this transaction is `rlp([status, cumulativeGasUsed, logsBloom, logs])`.

#### Sender Signature

The signature values `sender_y_parity`, `sender_r`, and `sender_s` are calculated by constructing a secp256k1 signature over the following digest:

`keccak256(SP_TX_TYPE || SENDER_BYTE || rlp([chain_id, nonce, gas_limit, to, value, data, access_list]))`.

The `sender_address` is the address derived from the public key recovered from the sender signature.

#### Payer Signature

The signature values `payer_y_parity`, `payer_r`, and `payer_s` are calculated by constructing a secp256k1 signature over the following digest:

`keccak256(SP_TX_TYPE || PAYER_BYTE || rlp([chain_id, nonce, gas_limit, to, value, data, access_list]) || rlp([max_priority_fee_per_gas, max_fee_per_gas, sender_address]))`.

The `payer_address` is the address derived from the public key recovered from the payer signature.

### Behavior

The role of the `payer_address` is to pay for the execution of the transaction. All transaction fee payment logic uses the `payer_address` instead of `sender_address`.

The nonce verification and increment logic with respect to the `sender_address` remains unchanged. There is no nonce related logic (verification or increment) related to the `payer_address`.

Both the `sender_address` and the `payer_address` have to have empty code.

## Rationale
TBD

## Test Cases
TBD

## Implementation
TBD

## Security Considerations
TBD

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
