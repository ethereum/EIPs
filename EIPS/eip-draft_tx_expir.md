---
eip: <to be assigned>
title: Transaction Expiration
description: Proposes a Transaction Expiration Block for every transaction.
author: Lucas Vinzon (@SnowPrimate)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2022-01-25
---

## Abstract
When in Ethereum Mempool, every transaction should expire after a certain amount of blocks resulting in no cost to its users. 15.000 blocks would effectively have every transaction on the Mempool for two days.

## Motivation
Gas cost, usability and serving its purpose for its users. Prevents unexperienced users to waste resources.

## Specification
Once in the Mempool ALL transactions MUST expire after a certain amount of blocks. It is OPTIONAL to lower the amount of blocks it will be live on the Mempool. It SHALL NOT result in gas cost to users.

## Rationale
Ethereum currently has a lot of pending transactions. Those transactions have little to no value to its users and the network since most of them will fail or never occur. Their existence in the Mempool inflates gas cost since they are referred to when estimating transaction costs for users. This significantly reduces usability and increases friction. It would also be forgiving to unexperienced users who set transactions that are not meant to fulfill, further wasting resources. This proposal highly values usability and preventing wasting resources, serving its purpose as a network.

## Backwards Compatibility
--

## Test Cases
--

## Reference Implementation
--

## Security Considerations
--

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
