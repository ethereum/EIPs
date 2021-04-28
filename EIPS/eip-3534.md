---
eip: 3534
title: Restricted Chain Context Type Transactions
author: Isaac Ardis (@whilei)
discussions-to: https://ethereum-magicians.org/t/eip-3534-restricted-chain-context-transaction-type/6112
status: Draft
type: Standards Track
category: Core
created: 2021-04-20
requires: 2718, 2930
---

## Simple Summary

Add a transaction type which contains a _Chain Context_ value restricting a transaction's validity
to a chain meeting certain contextual requirements.

## Abstract

We introduce a new EIP-2718 transaction type with the format `0x45 || rlp([chainId, chainContext, nonce, gasPrice, gasLimit, to, value, data, access_list, yParity, senderR, senderS])`. 

This proposed `chainContext` element adds a constraint on the validity of a transaction to a chain segment meeting
the referenced value(s). Several contexts are tentatively defined as subclasses of this type:

- `segmentId`
- `eligibleMinerList`
- `expiry`

These contexts can be used in arbitrary combinations. These contexts are referenced by an integer prefix on
the annotation.

## Motivation

Establish a protocol-based mechanism with which transactions are able to articulate constraints on 
eligible chain contexts.

- Restrict transaction applicability to a chain context that is currently available and reasoned about under some subjective view.
- Restrict transaction applicability to a chain context following some foregoing block (and its transactions).
- Restrict transaction applicability (and associated processing fee benefits) to blocks benefitting a preferred miner address or addresses.
- Restrict transaction applicability timespan.

Generally, these constraints introduce more expressable preferences for transactions, giving the consumer
(the transactor) an ability to express requirements about the transaction's relationship
to blockchain data and its provenance.

- Introduces an opportunity for miners to compete for consumers' transactions (consumers can prefer miners, where -- under the status quo -- the current miner-transaction processing service is almost perfectly homogenous from the consumer perspective).

## Specification


### Parameters

- `FORK_BLOCK_NUMBER` `TBD`
- `TRANSACTION_TYPE_NUMBER` `0x45/TBD`.  See EIP-2718.

As of `FORK_BLOCK_NUMBER`, a new EIP-2718 transaction is introduced with `TransactionType` `TRANSACTION_TYPE_NUMBER`.

The EIP-2718 `TransactionPayload` for this transaction is `rlp([chainId, chainContext, nonce, gasPrice, gasLimit, to, value, data, access_list, yParity, senderR, senderS])`.


### Definitions

- `chainContext`. The transaction is only valid for blockchain data satisfying ALL OF the annotations.
- `ANNOTATION_PREFIX`. An integer used to describe the set of subclass annotations in the `chainContext` (_ie._ _which_ chain context subclasses should the provided values be applied to).

### Subclasses

Annotation prefixes (`ANNOTATION_PREFIX`) are used to represent combinations of the available context subclasses.

`chainContext` is of form `<ANNOTATION_PREFIX>[subclass...]`, where `...` means "zero or more of the things to the left." 

Subclasses are defined independently, and can be modified independently from this proposal.

#### `segmentId`

- `ANNOTATION_PREFIX` `1`.
- `SEGMENT_ID` `bytes`. A byte array between 4 and 12 bytes in length. 

Constrains the validity of a transaction by a chain context subclass referencing prior canonical block by number and hash.
The transaction is only valid when included in a block having the annotated block as an ancestor.

It accomplishes this by describing a unique value referencing a canonical block, where the referenced block must be included in any chain segment also including this transaction.

Practically, the "designated chain segment" can be understood as the segment of blocks from `0..segmentId` inclusive.

This pattern can be understood as a correlate of EIP-155's `chainId` specification. EIP155 defines the restriction of transactions between chains; limiting the applicability of any EIP-155 transaction to a chain with the annotated ChainID. 
`segmentId` further restricts transaction application to one subsection ("segment") of one chain.

From this constraint hierarchy, we note that it is possible an implementation of `segmentId` to make `chainId` redundant.

##### Construction

The value is generally constructed as a concatenated `BlockNumber``BlockHashPrefix`, where `BlockHashPrefix` is __the first 4 bytes of the block hash of the canonical block with number `BlockNumber`__.

If the referenced `BlockNumber` is `0` it may be omitted. Otherwise, `BlockNumber` should be a __little endian encoded value with trailing zero values truncated__.
This scheme yields a minimum of 0 bytes and a maximum of 8 bytes (uint64).

Decoding can be done by chomping the last 4 bytes of the value as the required prefix of a block hash.
The remaining bytes (those preceeding the last 4 bytes, if any) can be decoded from a little endian into a uint64 or equivalent type.
In case of 0 bytes for the block number, 0 (genesis block) can be safely assumed.

Example values are given below.

| Segment ID | Block Number | Canonical Block Hash |
| --- | --- | --- |
| `e78b1ec3` | `0` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |
| `01e78b1ec3` | `1` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |
| `c0e1e4e78b1ec3` | `15_000_000` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |
| `ff0fa5d4e8e78b1ec3` | `999_999_999_999` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |
| `ffffffffffffff7fe78b1ec3` | `9223372036854775807` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |

##### Encoding

Encoding should follow the same rules as the optional `data` value.

#### `eligibleMinerList`

- `ANNOTATION_PREFIX` `2`.
- `ELIGIBLE_MINER_LIST` `[address...]`. A list of addresses.
- `MAX_ELEMENTS` `10`. The maximum number of addresses that can be provided.

Constrains the validity of a transaction by a chain context subclass referencing the miner address of the block including
the transaction.
The transaction is only valid when included in a block having an `etherbase` contained in annotated list of addresses.

##### Encoding

Encoding should follow the same rules as the optional `accessList` value.

#### `expiry`

- `ANNOTATION_PREFIX` `4`. 

Constrains the validity of a transaction by a chain context subclass referencing the timestamp of the block including the transaction (in seconds-since Unix epoch).
The transaction is only valid when included in a block having a `timestamp` less than the value annotated.

##### Encoding

Encoding should follow the same rules as other transaction integer values, eg. `nonce`, `gasPrice`, `gasLimit`, etc.

### Subclass Combination

Since subclasses use octal values for `ANNOTATION_PREFIX`, they can be distinguishably combined as long as
we assume annotation cardinality (ie ordering).

For example:

- `ANNOTATION_PREFIX` `1` signals `segmentId` exclusively. 
- `ANNOTATION_PREFIX` `2` signals `eligibleMinerList` exclusively. 
- `ANNOTATION_PREFIX` `3` combines `segmentId` and `eligibleMinerList`.
- `ANNOTATION_PREFIX` `4` signals `expiry` exclusively.
- `ANNOTATION_PREFIX` `5` combines `segmentId` and `expiry`. 
- `ANNOTATION_PREFIX` `6` combines `eligibleMinerList` and `expiry`. 
- `ANNOTATION_PREFIX` `7` combines `segmentId` and `eligibleMinerList` and `expiry`. 


Annotation values are provided in an array.

For example:

- `chainContext` `1[c0e1e4e78b1ec3]` Transaction can only be included in a block having a canonical ancestor block numbered `15_000_000` and with a hash prefixed with the bytes `e78b1ec3`.
- `chainContext` `2[[Df7D7e053933b5cC24372f878c90E62dADAD5d42]]` Transaction can only be included in a block naming `Df7D7e053933b5cC24372f878c90E62dADAD5d42` as the `etherbase` beneficiary.
- `chainContext` `3[1619008030]` Transaction can only be included in a block having a timestamp with value less than the time signaled by the Unix-epoch value `1619008030` (generally, the transaction expires after Wed Apr 21 07:27:10 CDT 2021).


## Rationale

__EIP2930: Optional Access List Type Transactions__ is used as an assumed "base" transaction type for this
proposal. However, this is NOT a conceptual dependency; the included `accessList` portion of this proposal
can readily be removed. Standing on the shoulders of EIP2930 is only intended to support and further
the adoption of next-generation transactions.


## Copyright

Copyright and related rights waved via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
