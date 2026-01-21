---
eip: 7981
title: Increase Access List Cost
description: Price access lists for data to reduce maximum block size
author: Toni Wahrstätter (@nerolation)
discussions-to: https://ethereum-magicians.org/t/eip-7981-increase-access-list-cost/24680
status: Draft
type: Standards Track
category: Core
created: 2024-12-27
requires: 2930, 7623
---

## Abstract

This EIP charges access lists for their data footprint, preventing the circumvention of the [EIP-7623](./eip-7623.md) floor pricing. This effectively reduces the worst-case block size by ~21% with minimal impact on users.

## Motivation

Access lists are only priced for storage but not for their data.

Furthermore, access lists can circumvent the [EIP-7623](./eip-7623.md) floor pricing by contributing to EVM gas while still leaving a non-negligible data footprint. This enables achieving the maximal possible block size by combining access lists with calldata at a certain ratio.

## Specification

| Parameter                              | Value | Source |
| -------------------------------------- | ----- | ------ |
| `ACCESS_LIST_ADDRESS_COST`            | `2400` | [EIP-2930](./eip-2930.md) |
| `ACCESS_LIST_STORAGE_KEY_COST`        | `1900` | [EIP-2930](./eip-2930.md) |
| `TOTAL_COST_FLOOR_PER_TOKEN`          | `10`   | [EIP-7623](./eip-7623.md) |

Let `access_list_nonzero_bytes` and `access_list_zero_bytes` be the count of non-zero and zero bytes respectively in the addresses (20 bytes each) and storage keys (32 bytes each) contained within the access list.

Let `tokens_in_access_list = access_list_zero_bytes + access_list_nonzero_bytes * 4`.

The access list cost formula changes from [EIP-2930](./eip-2930.md) to include data cost:

```python
access_list_cost = (
    ACCESS_LIST_ADDRESS_COST * access_list_addresses
    + ACCESS_LIST_STORAGE_KEY_COST * access_list_storage_keys
    + TOTAL_COST_FLOOR_PER_TOKEN * tokens_in_access_list
)
```

The [EIP-7623](./eip-7623.md) floor calculation is modified to include access list tokens:

```python
tokens_in_calldata = zero_bytes_in_calldata + nonzero_bytes_in_calldata * 4
total_data_tokens = tokens_in_calldata + tokens_in_access_list

data_floor_gas_cost = TX_BASE_COST + TOTAL_COST_FLOOR_PER_TOKEN * total_data_tokens
```

The gas used calculation becomes:

```python
tx.gasUsed = (
    21000
    +
    max(
        STANDARD_TOKEN_COST * tokens_in_calldata
        + execution_gas_used
        + isContractCreation * (32000 + INITCODE_WORD_COST * words(calldata))
        + access_list_cost,
        TOTAL_COST_FLOOR_PER_TOKEN * total_data_tokens
    )
)
```

Any transaction with a gas limit below `21000 + TOTAL_COST_FLOOR_PER_TOKEN * total_data_tokens` or below its intrinsic gas cost is considered invalid.

## Rationale

Access list data is always charged at floor rate (added to `access_list_cost`), and access list tokens are included in the floor calculation. This ensures:

- Access list data always pays floor rate regardless of execution level
- Access lists cannot be used to bypass the calldata floor pricing
- Consistent pricing across all transaction data sources

## Backwards Compatibility

This is a backwards incompatible gas repricing that requires a scheduled network upgrade.

Requires updates to gas estimation in wallets and nodes. Normal usage patterns remain largely unaffected.

## Reference Implementation

```python
def calculate_access_list_tokens(access_list: Tuple[Access, ...]) -> Uint:
    """Count data tokens in access list addresses and storage keys."""
    zero_bytes = Uint(0)
    nonzero_bytes = Uint(0)

    for access in access_list:
        for byte in access.account:
            if byte == 0:
                zero_bytes += Uint(1)
            else:
                nonzero_bytes += Uint(1)
        for slot in access.slots:
            for byte in slot:
                if byte == 0:
                    zero_bytes += Uint(1)
                else:
                    nonzero_bytes += Uint(1)

    return zero_bytes + nonzero_bytes * Uint(4)


def calculate_intrinsic_cost(tx: Transaction) -> Tuple[Uint, Uint]:
    """
    Calculate intrinsic gas cost and floor gas cost.
    Returns (intrinsic_gas, floor_gas).
    """
    # Calldata tokens
    calldata_zero_bytes = Uint(0)
    for byte in tx.data:
        if byte == 0:
            calldata_zero_bytes += Uint(1)
    tokens_in_calldata = (
        calldata_zero_bytes + (ulen(tx.data) - calldata_zero_bytes) * Uint(4)
    )

    # Access list tokens and cost
    tokens_in_access_list = Uint(0)
    access_list_cost = Uint(0)
    if has_access_list(tx):
        tokens_in_access_list = calculate_access_list_tokens(tx.access_list)
        for access in tx.access_list:
            access_list_cost += TX_ACCESS_LIST_ADDRESS_COST
            access_list_cost += ulen(access.slots) * TX_ACCESS_LIST_STORAGE_KEY_COST
        # EIP-7981: Always charge data cost
        access_list_cost += tokens_in_access_list * TOTAL_COST_FLOOR_PER_TOKEN

    # EIP-7981: Floor includes all data tokens
    total_data_tokens = tokens_in_calldata + tokens_in_access_list
    floor_gas = TX_BASE_COST + total_data_tokens * TOTAL_COST_FLOOR_PER_TOKEN

    # Intrinsic gas
    calldata_cost = tokens_in_calldata * STANDARD_TOKEN_COST
    create_cost = TX_CREATE_COST + init_code_cost(tx.data) if is_create(tx) else Uint(0)

    intrinsic_gas = TX_BASE_COST + calldata_cost + create_cost + access_list_cost

    return intrinsic_gas, floor_gas
```

## Security Considerations

This EIP closes a loophole that allows circumventing [EIP-7623](./eip-7623.md) floor pricing. Without this fix, attackers can achieve larger blocks than intended by combining access lists with calldata. All transaction data sources now contribute to the floor calculation consistently.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
