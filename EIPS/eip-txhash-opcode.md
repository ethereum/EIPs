---
title: TXHASH opcode
description: Opcode to get the current transaction hash
author: Marc Harvey-Hill (@Marchhill)
discussions-to: 
status: Draft
type: Standards Track
category: Core
created: 2025-06-20
---

## Abstract

This EIP proposes to add a new opcode `TXHASH` (`0x4d`), that returns the hash of the transaction currently being executed.

## Motivation

The proposal aims to improve support for encrypted mempools. Transactions in an encrypted mempool are ordered while the transactions are encrypted, before being decrypted and included onchain at the top of the block. If the builder does not respect the order when including the decrypted transactions then they could frontrun decrypted transactions. The new opcode can be used to make this impossible; when used in conjunction with [EIP-7793](./eip-7793), the hashes and indexes of encrypted mempool transactions can be stored onchain so that their ordering can be checked before execution of the following transaction.

## Specification

A new opcode `TXHASH` is introduced at `0x4d`. It shall return one stack element.

### Output

One element `TransactionHash` is added to the stack; it is the 32 byte keccak-256 hash of the transaction currently being executed.

### Gas Cost

The gas cost for `TXHASH` is a fixed fee of `2`.

## Rationale

### Gas Price

The opcode is priced to match similar opcodes in the `W_base` set.

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

N/A

## Security Considerations

None.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
