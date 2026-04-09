---
eip: 7819
title: SETDELEGATE instruction
description: Introduce a new instruction allowing contracts to create clones using EIP-7702 delegation designations
author: Hadrien Croubois (@amxx)
discussions-to: https://ethereum-magicians.org/t/eip-7819-create-delegate/21763
status: Draft
type: Standards Track
category: Core
created: 2024-11-18
requires: 7702
---

## Abstract

Introduce a new instruction that allows smart contracts to create (and update) delegation accounts that match [EIP-7702](./eip-7702.md)'s design. These accounts can be used similarly to [ERC-1167](./eip-1167.md) clones, with significant advantages.

## Motivation

Many on-chain applications involve creating multiple instances of the same code at different locations. Account abstraction solutions depend heavily on this pattern to deploy smart account instances.

These applications often rely on clones, or proxies, to reduce deployment costs. Clones, such as those described in ERC-1167, are minimal pieces of code that contain the target address directly in the bytecode. That makes them extremely lightweight but prevents any form of reconfiguration (upgradability). Upgradeable proxies differ from clones in that they read the implementation's address from storage. This makes them more versatile but also more expensive to use.

In both cases, delegating the received calls to an implementation using EVM code comes with some downsides:

- Calldata must be copied to memory before performing the delegate call.
- If EOF is ever enabled, clones and proxies written in EOF do not support delegation to an implementation written in legacy EVM code, and are thus limited or possibly dangerous. This encourages the continued use of legacy EVM code.

EIP-7702 introduces a new type of object with the expected behavior: the delegation indicator. These objects are designed to be instantiated at EOA addresses, but the same behavior can be reused to implement clones at the protocol level. Using delegation indicators for this use case provides upgradeability without the need for storage lookups, provided the contract calling `SETDELEGATE` allows it.

Studies by the Geth team (see "Not all state is equal" from EthCC[9]) have shown that 97.1% of the ~50 million contracts deployed correspond to code that has been deployed more than once, and that 28.6% of the unique bytecodes are tiny (under 1 KiB). Clones and proxies probably account for a large fraction of these contracts. Having a technical solution to use delegation indicators for these contracts would positively impact both the users (through reduced interaction cost) and the network's sustainability (through reduced state growth).

The use cases for this new deployment method include the "traditional" family of smart contract accounts used by wallets such as Safe, [ERC-4337](./eip-4337.md)-compliant smart accounts (that need upgradeability to stay up to date with new versions of the entrypoint), and all the new deployments implicitly required by proposals such as [EIP-8141](./eip-8141.md) in our path toward quantum-resistant accounts.

### Account Abstraction

Smart accounts (contracts that are "owned" by one or multiple keys and are intended to replace EOAs) are often deployed using clones or proxies that point to a singleton implementation. This forces a choice between an upgradeable or a non-upgradeable design. Both designs come with downsides. Non-upgradeable designs can leave you stranded with buggy (or limited) account code. Upgradeable designs incur costs associated with fetching the implementation address from storage.

The `SETDELEGATE` instruction would enable new factories to implement an upgradeable design without the added cost of the lookup. Factories could also deploy non-upgradeable variants, or even selectively disable the upgradeability of some accounts. Both the upgrade mechanism and the selective locking would be handled at the factory level, which removes the burden of implementing the upgrade logic in the account itself.

Additionally, using EIP-7702 delegations instead of clones/proxies moves the call redirection logic from userspace to the protocol. This means fewer EVM operations and thus reduced gas consumption for every operation that calls these contracts. This includes the verification of signatures and the execution of user operations, but also transfers of assets that include a callback, such as [ERC-721](./eip-721.md) and [ERC-1155](./eip-1155.md) tokens.

### Scalability

Clone and proxy contracts are present in large numbers in the blockchain state. OpenZeppelin's [ERC-1967](./eip-1967.md) proxies are ~708 bytes. Using EIP-7702 delegations that are only 23 bytes would significantly reduce blockchain state usage.

Additionally, clone and proxy contracts handle call redirection in userspace, which incurs execution cost. Using EIP-7702 delegations moves the redirection to the protocol level, reducing the gas cost of all operations targeting these accounts. This means more gas/blockspace is available for the actual execution of the contracts.

## Specification

A new instruction (`SETDELEGATE`) is added at `0xf6`.

### Behavior

Executing this instruction does the following:

1. Deduct `EMPTY_ACCOUNT_COST` gas.
2. Halt if the current frame is in `static-mode`.
3. Pop `salt` and `target` from the operand stack.
4. Calculate `location` as `keccak256(DESIGNATOR ++ address ++ salt)[12:]`.
5. Add `location` to `accessed_addresses`, as defined in [EIP-2929](./eip-2929.md).
6. Halt if the code at `location` is not empty and does not start with `0xEF0100` (i.e., it is neither empty nor a delegation indicator).
7. Add `EMPTY_ACCOUNT_COST - BASE_COST` gas to the global refund counter if `location` already exists in the trie.
8. Set the code of `location` to `DESIGNATOR ++ target`, matching the delegation process defined in EIP-7702.
    - Similarly to EIP-7702, if `target` is `0x0`, do not write the designation. Instead, clear the code at `location` and reset `location`'s code hash to the empty hash `0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470`.
9. If the nonce of the account at `location` is 0, increment it to 1.
10. Push `location` onto the stack.

In step 8, `target` MUST be exactly 20 bytes. If the value retrieved from the stack is smaller than 20 bytes, it MUST be left-padded (big-endian notation) with zeros. If it is larger than 20 bytes, the highest-order bytes MUST be trimmed. The code placed at `location` MUST be exactly 23 bytes long, following EIP-7702.

The delegation indicator created at `location` behaves identically to those created by EIP-7702.

Note: The delegation is effective immediately upon completion of the operation. Calls to the address starting from the very next operation will execute the newly delegated code.

The delegation indicators created by the `SETDELEGATE` opcode are the same objects as those created using EIP-7702. Therefore, all behavioral specifics documented in EIP-7702 (`CODESIZE`, `CODECOPY`, targeting precompiles, and chaining delegation indicators) also apply here. Any future EIP that modifies the behavior of EIP-7702 delegation indicators should also apply to those created using `SETDELEGATE`. They are not contracts and cannot be deleted using `SELFDESTRUCT`, even if `SELFDESTRUCT` occurs in the same transaction that created the account at `location`. Destruction of delegations SHOULD only be possible by the same caller (that created them) performing a new `SETDELEGATE` call with the same salt and a zero target.

Step 9 ensures that an account created using `SETDELEGATE` never returns to an empty state (as forbidden by [EIP-7523](./eip-7523.md)). Even if the balance is zero, no state was ever set, and the code is removed by a `SETDELEGATE` operation with a zero target, the nonce being at least one guarantees the account is not considered empty.

### Parameters

These parameters are the same as those used in EIP-7702.

| Constant             | Value    |
| -------------------- | -------- |
| `DESIGNATOR`         | 0xef0100 |
| `EMPTY_ACCOUNT_COST` | 25000    |
| `BASE_COST`          | 12500    |

## Rationale

### Gas Cost

The execution of the `SETDELEGATE` instruction involves fewer moving pieces than what EIP-7702 gas costs account for:

- There is no signature recovery.
- There is no dedicated calldata that must be accounted for beyond what is already paid at the transaction level.
- There is no nonce update (aside from the initial set to 1 in step 9).

Therefore, the cost of executing this instruction could be lower than that of EIP-7702. The values from EIP-7702 are reused here for simplicity. They are lower than the costs of `CREATE` or `CREATE2` operations, making this instruction competitive for the intended use cases.

### Address Derivation

The `location` is derived from `keccak256(DESIGNATOR ++ address ++ salt)`, using the caller's address and a caller-chosen salt. This mirrors the deterministic addressing of `CREATE2` while using a distinct pre-image length (55 bytes) to avoid collisions with existing address derivation schemes (see Backwards Compatibility).

## Backwards Compatibility

### Address Collision

The derivation of `location` is designed not to conflict with contracts created using the `CREATE` or `CREATE2` opcodes. In particular, the pre-images used to hash the produced address have different lengths, preventing any collision.

Contracts deployed using `CREATE2` have an address derived from an 85-byte pre-image, as opposed to 55 bytes for `SETDELEGATE`. This difference alone eliminates the risk of pre-image collision.

Contracts deployed using `CREATE` have an address derived from `RLP([address, nonce])`. For this pre-image to have a length of 55 bytes (matching `SETDELEGATE`), the `nonce` would need to be 32 bytes long. In that case, the RLP encoding would be `0xf694<address>a0<nonce>`, which does not start with the `0xef0100` designator used by `SETDELEGATE`. A smaller nonce could lead to a pre-image starting with `0xef`, but then the pre-image would be shorter than 55 bytes. Even in that case, the pre-image would start with `0xef94` (where `0x94` encodes the 20-byte `address` object), which still differs from the `SETDELEGATE` pre-image prefix.

## Security Considerations

### Delegator Upgrades and Deletion

Reusing EIP-7702 behavior, including clearing the code when the target is `0x0`, enables the ability to upgrade or even remove the created delegation indicator. This process is controlled (and can be restricted) by the factory contract that calls `SETDELEGATE`. Some factories will add checks that prevent re-executing `SETDELEGATE` with a salt that was already used, making the created delegation indicator immutable. Others may allow access-restricted upgrades but prevent deletion. In any case, guarantees about the lifecycle of delegation indicators created using `SETDELEGATE` are provided by the contracts that call it, not by the protocol itself.

### Delegator Chaining

As documented in EIP-7702, designation chains or loops are not resolved. This means that, unlike clones, chaining is an issue. However, this is something developers are accustomed to, as chaining proxies can result in unexpected behaviors, including infinite delegation loops.

Factories may want to protect against this risk by verifying that the `target` does not itself contain a delegation indicator.

### Front-Running Initialization

Unlike EIP-7702 signatures, which can be included in any transaction and can thus lead to initialization front-running if the implementation doesn't verify the authenticity of the initialization parameters, `SETDELEGATE` is executed by a smart contract that can perform the initialization logic atomically, immediately after the delegation is created. This process is well understood by developers who already initialize clones and proxies just after creation.

### Multiple Delegation Changes Within a Single Transaction

If a contract performs multiple `SETDELEGATE` operations with the same salt but different targets within the same transaction, while also making calls to the corresponding address, this would result in—within a single transaction without reverts—an address that has multiple different code values associated with it, two or more of which are executed. This includes the delegation being removed or reset any number of times during the transaction.

This behavior is already possible with more traditional upgradeable contracts, where the implementation target changes as a result of modifying a specific storage slot.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
