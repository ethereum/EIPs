---
eip: XXXX
title: Reduce Intrinsic Gas From 21k to 8k
description: Reduce intrinsic transaction gas from 21k to 8k increasing base txs per gas by 162.5%.
author: Ben Adams (@benaadams)
discussions-to: https://ethereum-magicians.org/t/eip-7999-unified-multidimensional-fee-market/25010
status: Draft
type: Standards Track
category: Core
created: 2025-09-03
requires: 2718, 2929, 2930, 1559
---

## Abstract

Set the intrinsic base to `8,000`, priced as:

```
ECRECOVER_COST = 3,000
ACCESS_LIST_ADDRESS_COST = 2,400
WARM_ACCOUNT_WRITE_COST = 100

TX_BASE_COST = ECRECOVER_COST
         + 2 * ACCESS_LIST_ADDRESS_COST (warm sender + to, at access-list address price)
         + 2 * WARM_ACCOUNT_WRITE_COST  (warm-account writes: gas debit + nonce)
         = 8,000
```

## Motivation

`21,000` is overpriced and should be priced based on it's component parts.

Change to charging for signature verification, explicit warming of `sender` and `to`, and two warm account updates.

## Specification

In `transactions.py`

```
TX_BASE_COST = Uint(21000)
"""
Base cost of a transaction in gas units. This is the minimum amount of gas
required to execute a transaction.
"""
```

Becomes

```
TX_BASE_COST = Uint(8000)
"""
Base cost of a transaction in gas units. This is the minimum amount of gas
required to execute a transaction.
"""
```

EIP‑1559/2930/7702 transactions that currently reference the `21,000` base inherit this new constant of `8,000`.

## Rationale

* Use [EIP-7702](./eip‑7702.md)'s & ecrecover precompile price = `3,000`.
* Use [EIP-2930](./eip-2930.md)'s address entry price `2,400` as the canonical warming cost for sender and to.
* Include two warm account updates at `100` each for gas debit and nonce increment.

## Backwards Compatibility

Simple ETH transfers drop from `21,000` to `8,000`. No opcode pricing changes. Requires hardfork.

## Security Considerations

As this more than doubles the pontential number of transactions per gaslimit that carries risk. 

| Block gas limit | Old @21,000 | New @8,000 | % increase |
| --------------: | ----------: | ---------: | ---------: |
|      45,000,000 |       2,142 |      5,625 |     162.6% |
|      60,000,000 |       2,857 |      7,500 |     162.5% |
|     100,000,000 |       4,761 |     12,500 |     162.5% |
|     200,000,000 |       9,523 |     25,000 |     162.5% |
|     400,000,000 |      19,047 |     50,000 |     162.5% |
|     800,000,000 |      38,095 |    100,000 |     162.5% |
|   1,600,000,000 |      76,190 |    200,000 |     162.5% |

However this pricing should be the same as performing the component changes inside the a transaction.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
