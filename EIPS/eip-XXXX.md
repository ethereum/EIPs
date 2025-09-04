---
eip: 999999
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


The two warm updates straddles between gas debit and nonce change actually being as single update and tx sending ETH being two updates; rather than having 2 prices for tx not sending value and one that does.

## Backwards Compatibility

Simple ETH transfers drop from `21,000` to `8,000`. No opcode pricing changes. Requires hardfork.

## Security Considerations

As this increases the max tx per block by 162.5% that carries risk. 


Block gaslimit | Old tx/bk (21k) | TPS @ 12s | TPS @ 6s | TPS @ 3s | New tx/bk (8k) | TPS @ 12s | TPS @ 6s | TPS @ 3s
--:| --:| --:| --:| --:| --:| --:| --:| --:|
45M | 2,143 | 179 | 357 | 714 | 5,625 | 469 | 938 | 1,875
60M | 2,857 | 238 | 476 | 952 | 7,500 | 625 | 1,250 | 2,500
100M | 4,762 | 397 | 794 | 1,587 | 12,500 | 1,042 | 2,083 | 4,167
200M | 9,524 | 794 | 1,587 | 3,175 | 25,000 | 2,083 | 4,167 | 8,333
400M | 19,048 | 1,587 | 3,175 | 6,349 | 50,000 | 4,167 | 8,333 | 16,667
800M | 38,095 | 3,175 | 6,349 | 12,698 | 100,000 | 8,333 | 16,667 | 33,333
1,600M | 76,190 | 6,349 | 12,698 | 25,397 | 200,000 | 16,667 | 33,333 | 66,667


However this pricing should be the same as performing the component changes inside the a transaction.

Current gaslimit testing mostly uses a block with a single tx; so this should should not cause unexpected load compared to what already being tested.

Tests should be created with blocks of just ETH transfers however to esure the pricing is correct.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
