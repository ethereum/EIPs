---
title: Stateless mempool transaction
description: Specification for submitting and including transactions statelessly
author: Gajinder Singh (@g11tech), Guillaume Ballet (@gballet), Ignacio Hagopian (@jsign)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2023-02-24
---

## Abstract

This EIP provides specification for submitting transactions to stateless block builder and their subsequent inclusion in the block. Such mempool transactions carry with themselves pre state witnesses for accesses which are made against a fixed parent block state and hence their inclusion is conditional to the availability of the accesses the transaction might make while being included in the block at some modified state. This is because transaction execution is turing complete and might dynamically access previously not included accesses in witnesses because of change in computation params/pre state at the inclusion time. If that happens then the transaction can become invalid for inclusion unless stateless block builder can requests the required witnesses for those access from a full node or from something like a portal network.

Furthermore the transactions carry with themselves the pre state nodes needed to prove the witnesses to the block pre state as well as any extra state nodes needed to constuct post state root. For example in binary as well as verkle trees this would imply bundling all children nodes of the path nodes of the witnesses. For merkle trees it might still imply additional nodes if there is a delete compressing a path. Again the transaction could be dropped if the post state proof can't be constructed.

Given the above constraint, the block builder should be able to construct a post state proof for the entire block given it has state proof nodes for pre transactions and post transactions system updates/contract processing. Infact in the ZKP paradigm, the block builder should be able to constuct the ZKP of the block execution as well.

## Motivation

In the Stateless and ZK ethereum world, it is likely that the validators will not be full nodes and might not even store the execution state. This would impede a stateless validator from local block production which is a centralization risk.

This EIP allows for one to send transactions to the builders (local or otherwise) with the state diff and optionally with the the ZK proof for the computation.

## Specification

The specification described below is agnostic to the RLP or SSZ encoding. The transaction type should be appropriately consumed by the encoding format and the properties extended in append only manner to the transaction payload.

<-- TODO complete the specification -->
| Constant | Value |
| `TRANSACTION_TYPE` | TBD|

Transaction object will be updated with addition of execution witness which will encode execution witness type (merkle, verkle, binary tree), parent state root, state diff, post state root and the diff proof and an optional ZK execution proof.

figure out:
 - is post state root required or just tree commitment diff is good enough?
 - how will it look for zk

```python
class Transaction
  ...
  execution_witness: ExecutionWitness
```


## Rationale

TBD

## Backwards Compatibility


No backward compatibility issues found.

## Test Cases


## Reference Implementation


## Security Considerations


Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
