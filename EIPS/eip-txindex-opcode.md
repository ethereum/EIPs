---
title: TXINDEX opcode
description: Opcode to get index of transaction within block
author: Marc Harvey-Hill (@Marchhill), Ahmad Bitar (@smartprogrammer93)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2024-10-17
---

## Abstract

This EIP proposes to add a new opcode that returns the index of the transaction being executed within the current block.

## Motivation

The new opcode aims to better support encrypted mempools in the protocol. In order to be secure, the validity of a transaction sent to an encrypted mempool should be tied to its correct inclusion by a proposer. This means that the transaction should only be valid if it is included at the correct slot, and the correct index within a block according to the encrypted mempool's ordering rules. This can be enforced in two ways:
- Enshrinement: a block will not be valid if it does not include encrypted mempool transactions in the correct order.
- Smart contract: encrypted mempool transactions invoke a smart contract that enforces inclusion in the correct order. If a single transaction is not included correctly, then all encrypted mempool transactions are invalidated.

This proposal enables smart contract solutions to check their own transaction index, so they can enforce inclusion at the correct index. These out-of-protocol smart contract solutions could be used for experimentation until a design appropriate for enshrinement in protocol is agreed upon.

## Specification

The instruction `TXINDEX` is introduced at `TBD`. The opcode pushes the transaction index as 4 byte uint in big endian encoding to the top of the stack. 

Following the yellow paper spec, it should be considered part of `W_base` for gas pricing.

## Rationale

TBD

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

TBD

## Security Considerations

TBD

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
