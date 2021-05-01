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

Defines a new transaction type with constraints on ancestor block hash, block author, and/or block timestamp.

## Abstract

We introduce a new EIP-2718 transaction type with the format `0x4 || rlp([chainId, chainContext, nonce, gasPrice, gasLimit, to, value, data, access_list, yParity, senderR, senderS])`. 

This proposed `chainContext` element adds a constraint on the validity of a transaction to a chain segment meeting the referenced value(s). Four contexts are defined as subclasses of this type:

- `segmentId`
- `eligibleMinerList`
- `ineligibleMinerList`
- `expiry`

These contexts can be used in arbitrary combinations. Annotated context value combinations are referenced by a composite integer prefix on the annotation.

## Motivation

Establish a protocol-based mechanism with which transactions are able to articulate constraints on eligible chain contexts.
Generally, these constraints give the consumer (the transactor) an ability to express requirements about the transaction's relationship to blockchain data and its provenance.

- Restrict transaction applicability to a chain context that is currently available and reasoned about under some subjective view.
    - Introduces a way for transactions to describe a dependency on their current view of a chain.
- Restrict transaction applicability to a chain context following some foregoing block (and its transactions).
    - Introduces a way for transactions to describe ancestral dependencies at a "macro" (block) level. 
    Indirectly, this offers a way for a transaction to depend on the presence of another, so long as the dependent transaction is in a different block.
- Restrict transaction applicability to blocks benefitting, or _not_ benefitting, a preferred/spurned miner address or addresses.
    - Introduces an opportunity/market for miners to compete for consumers' transactions; under the status quo, the current miner-transaction processing service is almost perfectly homogeneous from the consumer perspective.
- Restrict transaction applicability time span.
    - Introduces an alternative (to the status quo) way for consumers/transactors to have transactions invalidated/ejected from the transaction pool.

## Specification

### Parameters

- `FORK_BLOCK_NUMBER` `TBD`
- `TRANSACTION_TYPE_NUMBER` `0x4`.  See EIP-2718.

As of `FORK_BLOCK_NUMBER`, a new EIP-2718 transaction is introduced with `TransactionType` `TRANSACTION_TYPE_NUMBER`.

The EIP-2718 `TransactionPayload` for this transaction is `rlp([chainId, chainContext, nonce, gasPrice, gasLimit, to, value, data, access_list, yParity, senderR, senderS])`.

The EIP-2718 `ReceiptPayload` for this transaction is `rlp([status, cumulativeGasUsed, logsBloom, logs])`.

### Definitions

- `chainContext`. The transaction is only valid for blockchain data satisfying ALL OF the annotations.
- `ANNOTATION_COMPOSITE_PREFIX`. A positive integer between `1` and `0xff` that represents the set of subclass annotations in the `chainContext` (_ie._ _which_ chain context subclasses should the provided values be applied to). This value should be the sum of the subclass' `ANNOTATION_PREFIX`s.
- `ANNOTATION_PREFIX`s are defined for Subclasses as octal-derived positive integers, limited to the set `2^0,2^1,2^2,2^3,2^4,2^5,2^6,2^7`.

The `chainContext` value should be of the form `ANNOTATION_COMPOSITE_PREFIX || [{subclass value}...]`, where 
- `...` means "zero or more of the things to the left," and 
- `||` denotes the byte/byte-array concatenation operator.

The `chainContext` value should be encoded as `ANNOTATION_COMPOSITE_PREFIX || rlp[{subclass value}...]`.

### Validation

The values defined as subclasses below acts as constraints on transaction validity for specific chain contexts.
Transactions defining constraints which are not satisfied by their chain context should be rejected as invalid.
Blocks containing invalid transactions should be rejected as invalid themselves, per the _status quo_.

### Subclass Combination

`chainContext` values annotating more than one subclass reference should provide those values in the following sequential order:

1. `ANCESTOR_ID`
2. `ELIGIBLE_MINER_LIST`
3. `INELIGIBLE_MINER_LIST`
4. `EXPIRY`

As above, the `ANNOTATION_COMPOSITE_PREFIX` should be the sum of the designated subclass' `ANNOTATION_PREFIX`s.
### Subclasses

- An `ANNOTATION_PREFIX` value is used to represent each of the available context subclasses.

#### `ancestorId`

- `ANNOTATION_PREFIX` `1`.
- `ANCESTOR_ID` `bytes`. A byte array between 4 and 12 bytes in length.

The `ANCESTOR_ID` is a reference to a specific block by concatenating the byte representation of a block number and the first 4 bytes of its hash. 
The block number's should be encoded as a big endian value and should have left-padding 0's removed.
The block number value may be omitted in case of reference to the genesis block.

The `ANCESTOR_ID` value should be RLP encoded as a byte array for hashing and transmission.

#### `eligibleMinerList`

- `ANNOTATION_PREFIX` `2`.
- `ELIGIBLE_MINER_LIST` `[address...]`. A list of addresses.
- `MAX_ELEMENTS` `3`. The maximum number of addresses that can be provided.

The `ELIGIBLE_MINER_LIST` value is an array of unique, valid addresses.
Any block containing a transaction using this value must have a block beneficiary included in this set.

The `ELIGIBLE_MINER_LIST` value should be of the type `[{20 bytes}+]`, where `+` means "one or more of the thing to the left." 
Non-unique values are not permitted.

The `ELIGIBLE_MINER_LIST` value should be RLP encoded for hashing and transmission.

An `ELIGIBLE_MINER_LIST` value may NOT be provided adjacent to an `INELIGIBLE_MINER_LIST` value.

#### `ineligibleMinerList`

- `ANNOTATION_PREFIX` `4`.
- `INELIGIBLE_MINER_LIST` `[address...]`. A list of addresses.
- `MAX_ELEMENTS` `3`. The maximum number of addresses that can be provided.

The `INELIGIBLE_MINER_LIST` value is an array of unique, valid addresses.
Any block containing a transaction using this value must not have a block beneficiary included in this set.

The `INELIGIBLE_MINER_LIST` value should be of the type `[{20 bytes}+]`, where `+` means "one or more of the thing to the left." 
Non-unique values are not permitted.

The `INELIGIBLE_MINER_LIST` value should be RLP encoded for hashing and transmission.

An `INELIGIBLE_MINER_LIST` value may NOT be provided adjacent to an `ELIGIBLE_MINER_LIST` value.

#### `expiry`

- `ANNOTATION_PREFIX` `8`.
- `EXPIRY` `integer`. A positive, unsigned scalar.

The `EXPIRY` value is a scalar equal to the maximum valid block `timestamp` for a block including this transaction.

The `EXPIRY` value should be RLP encoded as an integer for hashing and transmission.

## Rationale

### Subclasses

Subclasses are defined with a high level of conceptual independence, and can be modified and/or extended independently from this EIP.
Their specification definitions allow arbitrary mutual (`AND`) combinations.

This design is intended to form a proposal which offers a concrete set of specifics while doing so with enough flexibility for extension or modification later.

#### `ANNOTATION_PREFIX`

`ANNOTATION_PREFIX` values' use of octal-derived values, ie. `1, 2, 4, 8, 16, 32, 64, 128`, follows a conventional pattern of representing combinations from a limited set uniquely and succinctly, eg. Unix-style file permissions.
This EIP defines four of the eight possible context subclasses; this seems to leave plenty of room for future growth in this direction if required.
If this limit is met or exceeded, doing so will require a hard fork _de facto_ (by virtue of making consensus protocol facing changes to transaction validation schemes), so revising this scheme as needed should be only incidental and trivial.

#### `ancestorId`

Constrains the validity of a transaction by referencing a prior canonical block by number and hash.
The transaction is only valid when included in a block which has the annotated block as an ancestor.

Practically, the "designated allowable chain segment" can be understood as the segment of blocks from `0..ancestorId` inclusive.

##### Redundancy to `chainId`

This pattern can be understood as a correlate of [EIP-155](./eip-155)'s `chainId` specification.
EIP155 defines the restriction of transactions between chains; limiting the applicability of any EIP-155 transaction to a chain with the annotated ChainID. 
`ancestorId` further restricts transaction application to one subsection ("segment") of one chain.

From this constraint hierarchy, we note that an implementation of `ancestorId` can make `chainId` conceptually redundant.

##### So why keep `chainId`?

`chainId` is maintained as an invariant because:

- The use of the transaction type proposed by this EIP is optional, implying the continued necessity of `chainId` in the protocol infrastructure and tooling for legacy and other transaction types.
- The presence of `ancestorId` in the transaction type proposed by this EIP is optional. If the value is not filled by an RCC transaction, the demand for `chainId` remains.
- A `chainId` value is not necessarily redundant to `ancestorId`, namely in cases where forks result in living chains. For example, an `ancestorId` reference to block `1_919_999` would be ambiguous between Ethereum and Ethereum Classic.
- It would be possible to specify the omission of `chainId` in case of `ancestorId`'s use. This would add infrastructural complexity for the sake of removing the few bytes `chainId` typically requires; we do not consider this trade-off worth making.
    - `chainId` is used as the `v` value (of `v,r,s`) in the transaction signing scheme; removing or modifying this incurs complexity at a level below encoded transaction fields, demanding additional infrastructural complexity for implementation.
- The proposed design for `ancestorId` does not provide perfect precision (at the benefit of byte-size savings). 
  In the small chance that the value is ambiguous, the `chainId` maintains an infallible guarantee for a transaction's chain specificity.

#### `eligibleMinerList`

The transaction is only valid when included in a block having an `etherbase` contained in the annotated list of addresses.
The use of "whitelist" (`eligibleMinerList`) in conjunction with a "blacklist" (`ineligibleMinerList`) is logically inconsistent; their conjunction is not allowed.

A `MAX_ELEMENTS` limit of `3` is chosen to balance the interests of limiting the potential size of transactions, and to provide a sufficient level of articulation for the user. At the time of writing, the top 3 miners of Ethereum (by block, measured by known public addresses) account for 52% of all blocks produced.

#### `ineligibleMinerList`

The transaction is only valid when included in a block having an `etherbase` _not_ contained in the annotated list of addresses.
The use of "blacklist" (`ineligibleMinerList`) in conjunction with a "whitelist" (`eligibleMinerList`) is logically inconsistent; their conjunction is not allowed.

A `MAX_ELEMENTS` limit of `3` is chosen to balance the interests of limiting the potential size of transactions, and to provide a sufficient level of articulation for the user. At the time of writing, the top 3 miners of Ethereum (by block, measured by known public addresses) account for 52% of all blocks produced.

#### `expiry`

The transaction is only valid when included in a block having a `timestamp` less than the value annotated.
A positive integer is used because that corresponds to the specified type of block `timestamp` header values.

### Subclass Combination

Since subclasses use octal-based values for `ANNOTATION_PREFIX`, they can be distinguishably combined as sums, provided as we assume annotation cardinality (ie ordering).
For example:

- `ANNOTATION_PREFIX` `1` signals `ancestorId` exclusively. 
- `ANNOTATION_PREFIX` `2` signals `eligibleMinerList` exclusively. 
- `ANNOTATION_PREFIX` `4` signals `ineligibleMinerList` exclusively. 
- `ANNOTATION_PREFIX` `8` signals `expiry` exclusively.
- `ANNOTATION_PREFIX` `1+2=3` combines `ancestorId` and `eligibleMinerList`.
- `ANNOTATION_PREFIX` `1+4=5` combines `ancestorId` and `ineligibleMinerList`. 
- `ANNOTATION_PREFIX` `1+8=9` combines `ancestorId` and `expiry`. 
- `ANNOTATION_PREFIX` `1+2+8=11` combines `ancestorId` and `eligibleMinerList` and `expiry`. 
- `ANNOTATION_PREFIX` `1+4+8=13` combines `ancestorId` and `ineligibleMinerList` and `expiry`. 
- `ANNOTATION_PREFIX` `2+4=6` is NOT PERMITTED. It would combine `eligibleMinerList` and `ineligibleMinerList`. 
- `ANNOTATION_PREFIX` `1+2+4+8=15` is NOT PERMITTED. It would combine `eligibleMinerList` and `ineligibleMinerList` (and `ancestorId` and `expiry`). 

Since ordering is defined and demanded for multiple values, annotated references remain distinguishable. For example:

- `chainContext` `3[e4e1c0e78b1ec3,[Df7D7e053933b5cC24372f878c90E62dADAD5d42]]` - Transaction can only be included in a block having a canonical ancestor block numbered `15_000_000` and with a hash prefixed with the bytes `e78b1ec3`, and if the containing block uses `Df7D7e053933b5cC24372f878c90E62dADAD5d42` as the beneficiary.
- `chainContext` `10[[Df7D7e053933b5cC24372f878c90E62dADAD5d42],1619008030]` - Transaction can only be included in a block naming `Df7D7e053933b5cC24372f878c90E62dADAD5d42` as the `etherbase` beneficiary, and which has a timestamp greater than `1619008030` (Wed Apr 21 07:27:10 CDT 2021).


### EIP-2930 Inheritance
The [EIP-2930 Optional Access List Type Transaction](https://eips.ethereum.org/EIPS/eip-2930) is used as an assumed "base" transaction type for this proposal. 
However, this is NOT a conceptual dependency; the included `accessList` portion of this proposal (the only differential from post-EIP-155 legacy transaction fields) can readily be removed. 
Standing on the shoulders of EIP-2930 is only intended to support and further the adoption of next-generation transactions.

### Signature target

The signature signs over the transaction type as well as the transaction data.
This is done to ensure that the transaction cannot be “re-interpreted” as a transaction of a different type.

## Backwards Compatibility

There are no known backward compatibility issues.

## Test Cases

| Segment ID | Block Number | Canonical Block Hash |
| --- | --- | --- |
| `e78b1ec3` | `0` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |
| `01e78b1ec3` | `1` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |
| `e4e1c0e78b1ec3` | `15_000_000` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |
| `e8d4a50fffe78b1ec3` | `999_999_999_999` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |
| `7fffffffffffffffe78b1ec3` | `9223372036854775807` | `0xe78b1ec31bcb535548ce4b6ef384deccad1e7dc599817b65ab5124eeaaee3e58` |

Further test cases, TODO.

## Security Considerations

### Why 4 bytes of a block hash is "safe enough" for the `ancestorId`

__TL;DR__: The chance of an ineffectual `ancestorId` is about 1 in between ~4 billion and ~40 billion, with the greater chance for intentional duplication scenarios, eg. malicious reorgs.

__If a collision _does_ happen__, that means the transaction will be valid on both segments (as is the case under the status quo).

Four bytes, instead of the whole hash (32 bytes), was chosen only to reduce the amount of information required to cross the wire to implement this value.
Using the whole hash would result in a "perfectly safe" implementation, and every additional byte reduces the chance of collision exponentially.

The goal of the `ancestorId` is to disambiguate one chain segment from another, and in doing so, enable a transaction to define with adequate precision which chain it needs to be on.
When a transaction's `ancestorId` references a block, we want to be pretty sure that that reference won't get confused with a different block than the one the author of the transaction had in mind.

We assume the trait of collision resistance is uniformly applicable to all possible subsets of the block hash value, so our preference of using the _first_ 4 bytes is arbitrary and functionally equivalent to any other subset of equal length.

For the sake of legibility and accessibility, the following arguments will reference the hex representation of 4 bytes, which is 8 characters in length, eg. `e78b1ec3`. 

The chance of a colliding `ancestorId` is `1/(16^8=4_294_967_296)` times whatever we take the chance of the existence of an equivalently-numbered block (on an alternative chain) to be. Assuming a generous ballpark chance of 10% (`1/10`) for any given block having a public uncle, this yields `(1/(16^8=4_294_967_296) * 1/10`. Note that this ballpark assumes "normal" chain and network behavior. In the case of an enduring competing chain segment, this value rises to 100% (`1`).

### `eligibleMinerList`

Miners who do not find themselves listed in an annotated `eligibleMinerList` should be expected to immediately remove the transaction from their transaction pool. 

In a pessimistic outlook, we should also expect that these ineligible nodes would not offer rebroadcasts of these transactions, potentially impacting the distribution (and availability) of the transactions to their intended miners. On the other hand, miners are incentivized to make themselves available for reception of such transactions, and there are many ways this is feasible both on-network and off-.

The author of a transaction using the `eligibleMinerList` must assume that the "general availability" of the blockchain state database for such a transaction will be lower than a nonrestrictive transaction (since only a subset of miners will be able to process the transaction). 

A final consideration is the economics of a whitelisted miner concerning the processing order of transactions in which they are whitelisted and those without whitelists.
Transactions without whitelists would appear at first glean to be more competitive, and thus should be processed with priority.
However, miners following such a strategy may find their reputation diminished, and, in the worst case, see the assertive preferences of transaction authors shift to their competitors and beyond their reach.

### `ineligibleMinerList`

In addition to the concerns and arguments presented by `eligibleMinerList` above, there is a unique concern for `ineligibleMinerList`: in order for a miner entity to avoid ineligibility by a blacklist, they only need to use an alternative adhoc address as the block beneficiary.
In principle, this is ineluctable.

However, there are associated costs to the "dodging" miner that should be considered.

- The creation of an account requires time and energy. But indeed, this work can be done at any convenient time and circumstance. Probably marginal, but non-zero.
- The transfer of funds from multiple accounts requires a commensurate number of transactions. Block rewards are applied after transactions are processed, so the miner is unable to simultaneously shift funds from an adhoc account to a target account in the same block they mine (which would otherwise be a "free" transaction).
- In using an adhoc address to dodge a blacklist, the miner may also cause their ineligibility from contemporary whitelist transactions.

### Validation costs

Miner lists and expiry depend on easily cached and contextually available conditions (ie. the containing block header). The infrastructural overhead costs for enforcing these validations are expected to be nominal.

Validation of `ancestorId` demands the assertion of a positive database hit by block number (thereby cross-referencing a stored block's hash). 
This necessary lookup can be (and maybe already is) cached, but we must expect less than 100% hits on cached values, since the lookup value is arbitrary.
With that in mind, however, the value provided to a transaction using a deep `ancestorId` is increasingly marginal, so we should expect
most transactions using this field to use a relatively small set of common, shallow, cache-friendly values.

### Transaction size increase

The proposed additional fields potentially increase transaction size.
The proposed fields are not associated with any gas costs, establishing no protocol-defined economic mitigation for potential spam.
However, transactions which are considered by a miner to be undesirable can be simply dropped from the transaction pool and ignored.

## Copyright

Copyright and related rights waved via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
