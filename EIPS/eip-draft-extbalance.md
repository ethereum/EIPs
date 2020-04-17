---
eip: <to be assigned>
title: EXTBALANCE rename and conditional pricing
author: wjmelements.eth <wjmelements@gmail.com> [@wjmelements](https://github.com/wjmelements)
discussions-to: [TODO Set Github Issue](https://github.com/ethereum/EIPS/pulls)
status: Draft
type: Standards Track
category: Core
created: 2020-04-16
requires: 1884
---

## Simple Summary
Renames BALANCE to EXTBALANCE and reduces EXTBALANCE cost when querying the current contract.


## Abstract
This EIP renames BALANCE to EXTBALANCE.
The gas cost of EXTBALANCE when the parameter matches the current address is reduced to a value slightly higher than the cost of SELFBALANCE.


## Motivation
As the primary purpose of EXTBALANCE following EIP1884 is to query external accounts, the name is updated accordingly.

EXTBALANCE existed prior to SELFBALANCE so it is used by several immutable contracts, including the Uniswap-V1 template, that predate the Istanbul hard fork.
These contracts use EXTBALANCE to query their own balance.

## Specification

At block `N`, the `EXTBALANCE` operation changes from 700 gas to a conditional cost:
- If the parameter matches the current call context address, the cost is `GasSlowStep`, currently `10`
- Else the gas cost is `700`

## Rationale
Matching the rationale of [EIP-1884](./eip-1884.md), when querying its own balance a contract does not request a trie operation.
SELFBALANCE is already on-hand because it is necessary for efficient operation of other opcodes such as CALL and CREATE.
However, the gas cost of EXTBALANCE for the current account should be higher than the cost of SELFBALANCE because of the necessary comparison of the parameter to the current address.
