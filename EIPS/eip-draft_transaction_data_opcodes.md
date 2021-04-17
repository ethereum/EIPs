---
eip: <to be assigned>
title: Transaction Data Opcodes
author: Alex Papageorgiou (@alex-ppg)
discussions-to: https://ethereum-magicians.org/t/eip-draft-transaction-data-opcodes/6017
status: Draft
type: Standards Track
category: Core
created: 2021-04-16
---

## Simple Summary

Provide access to original transaction data.

## Abstract

This EIP introduces the following four EVM instructions: `ORIGINDATALOAD`, `ORIGINDATASIZE`, `ORIGINDATACOPY` and `ENTRYPOINT`.

The first three instructions are meant to provide access to the original transaction's `data` payload whereas the last instruction is meant to provide access to the original recipient of the transaction, the `to` address.

## Motivation

It is undeniable that smart contracts are becoming more interconnected than ever. Up until this point, smart contracts have entirely relied on compliant interfaces and introspection to introduce a new step in the call chain of a complex multi-contract interaction. However, this presents a forwards-only approach which limits the types of interactions that can manifest.

The purpose of this EIP is to provide a way via which a contract is able to identify the entry-point of a transaction on the blockchain and deduce what was the original intention of the transaction by applying introspection on the original transaction data itself.

This EIP enables the development of new types of smart contracts as it can open new pathways for [EIP-721](https://eips.ethereum.org/EIPS/eip-721) NFTs and [EIP-20](https://eips.ethereum.org/EIPS/eip-20) tokens to detect which action their transaction is part of, such as detecting a liquidity provision to a decentralized exchange or a loan within a collateralized lending protocol.

As a side-effect, it acts as an enhanced "substitute" to the `ORIGIN` check that the [EIP-3074](https://eips.ethereum.org/EIPS/eip-3074) breaks, enabling a greater level of granularity to be applied to the introspection of a transaction f.e. by validating the `ENTRYPOINT` being equal to the currently executed contract.

## Specification

### ORIGINDATALOAD (`0x47`), ORIGINDATASIZE (`0x48`) and ORIGINDATACOPY (`0x49`)

These instructions are meant to operate identically to their `CALL`-prefixed counterparts with the exception that they instead operate on the original `data` of a transaction instead of the current call's data. As the data is retrieved once again from the execution environment, the costs for the three instructions will be `G_verylow`, `G_base` and `G_base + G_verylow * (number of words copied, rounded up)` respectively.

### ENTRYPOINT (`0x4a`)

The `ENTRYPOINT` instruction uses 0 stack arguments and pushes the original `to` member of the transaction onto the stack. The address yielded by the instruction is a 160-bit value padded to 256-bits. The operation costs `G_base` to execute, similarly to `ORIGIN` (`0x32`).

### Compiler Specification

High-level programming languages that compile to EVM bytecode should provide support for these new instructions from a high-level perspective by introducing new members to the transactional context they already support for the `ORIGIN` instruction.

## Rationale

### Naming Conventions

The `ORIGIN`-prefixed instructions attempted to conform to the existing naming convention of `CALL`-prefixed instructions given the existence of the `ORIGIN` instruction which is equivalent to the `CALLER` (`0x33`) instruction but on the original transaction's context.

The `ENTRYPOINT` instruction came to be by defining a sensible name that immediately and clearly depicts what it is meant to achieve by signaling the first interaction with the blockchain, i.e. the entry-point.

### Instruction Address Space

The instruction address space of the `0x30-0x3f` has been exhausted by calls that already provide information about the execution context of a call so a new range had to be identified that is suitable for the purposes of the EIP.

Given that the [EIP-1344](https://eips.ethereum.org/EIPS/eip-1344) `CHAINID` opcode was included at `0x46`, it made sense to include additional transaction-related data beyond it since the Chain ID is also included in transaction payloads apart from the blocks themselves, rendering the `0x46-0x4f` address space reserved for more transaction-related data that may be necessary in the future, such as the EOA's nonce.

### Gas Costs

The gas costs necessary for a particular instruction must weight the computational expense it brings to the system to assess a particular number. In the case of the instructions proposed by this EIP, this assessment was relatively straightforward given that identical instructions have already been introduced to the EVM and the instructions themselves would operate in an equivalent manner.

### Instruction Space Pollution

One can argue that multiple new EVM instructions pollute the EVM instruction address space and could cause issues in assigning sensible instruction codes to future instructions. This particular issue was assessed and a methodology via which the raw RLP encoded transaction may be accessible to the EVM was ideated. This would *future-proof* the new instruction set as it would be usable for other members of the transaction that may be desired to be accessible on-chain in the future, however, it would also cause a redundancy in the `ORIGIN` opcode.

## Backwards Compatibility

The EIP does not alter or adjust existing functionality provided by the EVM and as such, no known issues exist.

## Test Cases

TODO.

## Reference Implementation

A reference implementation will be provided for `go-ethereum` (Golang) which other implementations can be stemmed from should the EIP be moved to **`Accepted`** status.

## Security Considerations

### Introspective Contracts

Atomically, the `ORIGINDATALOAD` and `ORIGINDATACOPY` values should be considered insecure as they can easily be spoofed by creating an entry smart contract with the appropriate function signature and arguments that consequently invokes other contracts within the call chain. To this end, the EIP has introduced the `ENTRYPOINT` instruction that should be validated along with the original data payload.

Additionally, this type of introspection should solely be applied on pre-approved contracts rather than user-defined ones as the value stemming from this type of introspection entirely relies on a contract's code immutability and proper function, both of which a user supplied contract can easily bypass.

### Denial-of-Service Attack

An initial concern that may arise from this EIP is the additional contextual data that must be provided at the software level of nodes to the EVM in order for it to be able to access the necessary data via the `ORIGINDATALOAD` and `ORIGINDATACOPY` instructions.

This would lead to an increase in memory consumption, however, this increase should be negligible if at all existent given that the data of a transaction should already exist in memory as part of its execution process; a step in the overall inclusion of a transaction within a block.

### Multi-Contract System Gas Reduction

Given that most complex smart contract systems deployed on Ethereum today rely on cross-contract interactions whereby values are passed from one contract to another via function calls, the `ORIGIN`-prefixed instruction set would enable a way for smart contract systems to acquire access to the original `ENTRYPOINT` function arguments at any given step in the call chain execution which could result in cross-contract calls ultimately consuming less gas if the data passed between them is reduced as a side-effect of this change.

The gas reduction, however, would be an implementation-based optimization that would also be solely applicable for rudimentary memory arguments rather than storage-based data, the latter of which is most commonly utilized in these types of calls. As a result, the overall gas reduction observed by this change will be negligible.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
