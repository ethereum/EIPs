---
eip: 7610
title: Revert creation in case of non-empty storage
description: Revert contract creation if address already has the non-empty storage
author: Gary Rong (@rjl493456442), Martin Holst Swende (@holiman)
discussions-to: https://ethereum-magicians.org/t/eip-revert-creation-in-case-of-non-empty-storage/18452
status: Last Call
last-call-deadline: 2024-11-20
type: Standards Track
category: Core
created: 2024-02-02
---

## Abstract

This EIP causes contract creation to throw an error when attempted at an address with pre-existing storage.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

If a contract creation is attempted due to a creation transaction, the `CREATE` opcode, the `CREATE2` opcode, or any other reason, and the destination address already has either a nonzero nonce, a nonzero code length, or non-empty storage, then the creation MUST throw as if the first byte in the init code were an invalid opcode. This change MUST apply retroactively for all existing blocks.

This EIP amends [EIP-684](./eip-684.md) with one extra condition, requiring empty storage for contract deployment.

## Rationale

EIP-684 defines two conditions for contract deployment: the destination address must have zero nonce and zero code length. Unfortunately, this is not sufficient. Before [EIP-161](./eip-161.md) was applied, the nonce of a newly deployed contract remained set to zero. Therefore, it was entirely possible to create a contract with a zero nonce and zero code length but with non-empty storage, if slots were set in the constructor. There exists 28 such contracts on Ethereum mainnet at this time.

As one of the core tenets of smart contracts is that its code will not change, even if the code is zero length. The contract creation must be rejected in such instanace.

## Backwards Compatibility

This is an execution layer upgrade, and so it requires a hard fork.

## Test Cases

There exists quite a number of tests in the ethereum tests repo as well as in the execution spec tests, which test the scenario of deployment to targets with non-empty storage. These tests have been considered problematic in the past; Reth and EELS both intentionally implement a version of the account reset solely to pass the tests. Py-evm declared the situation impossible and never implemented account reset.

Refilling the existing tests will provide sufficient coverage for this EIP.

## Security Considerations

This EIP is a security upgrade: it enforces the imutability of deployed code.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
