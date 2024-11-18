---
eip: XXXX
title: Create delegate
description: Add a new EVM instruction allowing contracts to create clones using ERC-7702 delegation designations
author: Hadrien Croubois (@amxx), Danno Ferrin (@shemnon)
discussions-to: todo
status: draft
type: Standards Track
category: Core
created: 2024-05-07
requires: 7692, 7702
---

## Abstract

Introduce a new EVM instruction to [EOF1](./eip-7692.md) that allows smart contracts to create (and update) delegation accounts that match [EIP-7702](./eip-7702.md)'s design. These accounts can be used similarly to [ERC-1167](./erc-1167.md) clones, with significant advantages.

## Motivation

Many onchain applications involve creating multiple instances of the same code at different location. These applications ofter rely on clones, or proxies, to reduce the deployment costs.

Clones, such as the one described in ERC-1167 are minimal pieces of code that contain the target address directly in the code. That makes them extremelly light, but prevents any form of reconfiguration (upgradability).

Upgradeable proxies differ from clones in that they read the implementation' address from storage. This makes them more versatile but also more expensive to use.

In both cases delegating the received calls to an implementation using evm code comes with some downsides:
- the calldata must be copied to memory defore performing the delegate call
- clones and proxy written in EOF do not support delegation to an implementation written in legacy evm code, and are thus limited or possibly dangerous. This encourages the continued use of legacy evm code.

EIP-7702 introduces a new type of object that has the expected behavior: designator. These object are designed to be instanciated at the address of EOA's, but the same behavior could be re-used to implement clones at the protocol level. Using designator for this usecase provides upgradeability without the need for storage lookups if the contract calling the `CREATE_DELEGATE` allows it. It also removes any issue related to code version incompatibilities.

## Specification

A new instruction (`CREATE_DELEGATE`) is added to EOF1 at `0xf6`.

### Behavior

Executing this instruction does the following:

1. deduct `EMPTY_ACCOUNT_COST` gas
2. halt if the current frame is in `static-mode`
3. pop `salt`, `target` from the operand stack
4. calculate `location` as `keccak256(0xfe10000 ++ address ++ salt)[12:]`
5. halt if the code at `location` is not empty and does not start with `0xEF0100` (no empty and not a designator)
6. add `EMPTY_ACCOUNT_COST - BASE_COST` gas to the global refund counter if `location` exists in the trie.
7. set the code of `authority` to be `0xef0100 || target`, matching the delegation process defined in [EIP-7702](./eip-7702.md).
    * Similarly to EIP-7702, if `target` is `0x0000000000000000000000000000000000000000` do not write the designation. Clear the code at `location` and reset the `location`'s code hash to the empty hash `0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470`.
8. push `location` onto the stack

The designator created at `location` behaves identically to the those created by EIP-7702

### Parameters

| Constant                     | Value            |
| ---------------------------- | ---------------- |
| `EMPTY_ACCOUNT_COST`         | 25000            |
| `BASE_COST`                  | 12500            |

## Rationale

### Gas cost

The execution of the `CREATE_DELEGATE` instruction involves less moving pieces than what EIP-7702 gas costs account for:

- there is no signature recovery
- there is no dedicated calldata that must be accounted for that is not already paid for at the transaction level
- there is no nonce update

Therefore, the cost of executing this instruction could possibly be way lower than EIP-7702. Number of EIP-7702 are reused for simplicity. They are lower than `CREATE` or `CREATE2` operations, making the use of this instruction competitive for the intended usecases.

## Backwards Compatibility

TODO

## Security Considerations

### Delegators upgrades & deletion

Reusing EIP-7702 behavior, including clearing the code if location is 0, result in the ability to upgrade or even "remove" the created designator. This process is controled (and can be restricted) by the factory (the contract that calls `CREATE_DELEGATE`). Some factory will add checks that prevent re-executing `CREATE_DELEGATE` with a salt that was already used, making the create designator immutable. Other may allow access-restricted upgrades, but prevent deletion. In any case, guarantees about the lifecycle of the designator created using `CREATE_DELEGATE` are provided by the contracts that call it and not by the protocol.

### Delegators chaining

As documented in EIP-7702, designator chains or loop is are not resolved. This means that unlike clones, chaining is an issue. This is something developper are used to, as chaining proxy can often results in trange behaviors, including infinite delegation loops.

Factories may want to protect against this risk by veryfing that the `target` doesn't contain a designator. This can be achieved using a legacy contract helper that has access to `EXTCODEHASH`. It could also be done using other forms of introspection such as an `ACCOUNT_TYPE` instruction.

### Front running initialization

Unlike EIP-7702 signature, which can be included in any transaction, and can thus lead to initialization front-running if the implementation doesn't check the authenticity of the initialization parameters, `CREATE_DELEGATION` is executed by a smart contract that can execute the initialization logic atomically, just after the delegation is created. This process is well known of developpers that initilize clones and proxyes just after creation.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
