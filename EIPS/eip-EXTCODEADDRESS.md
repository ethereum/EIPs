---
eip: TBD
title: EOF - EXTCODEADDRESS instruction
description: Add EXTCODEADDRESS instruction to EOF to address code delegation use cases
author: Danno Ferrin (@shemnon)
discussions-to: <tbd>
status: Draft
type: Standards Track
category: Core
created: 2024-09-01
requires: 7692, 7702, 7761
---

## Abstract

Add an instruction to EOF that reads code delegation designations from the account without requiring code introspection.

## Motivation

EOFv1 as scoped in [EIP-7692] removes code introspection capabilities from the EVM, preventing EOF from reading raw code values such as code delegation designations set by [EIP-7702]. There are a number of use cases where reading the delegation designation of [EIP-7702] would allow contracts to be more proactive about user experience issues.

One example would be a managed proxy contract. Such a contract may want to ensure security by not allowing the proxy to be updated to a delegated address. There are also safety concerns with pointing to a delegation, as the contract may be updated to non EOF code and `EXTDELEGATECALL` will no longer be able to call the contract, due to changes outside the control of the managed proxy contract.

To address this the essential task of the designation parsing is moved into a new opcode `EXTCODEADDRESS`, where the task of calculating the delegated address will be performed.  For non-delegated accounts or empty accounts the address will be the same as the queried address.

## Specification

### Parameters

| Constant                  | Value                                                              |
|---------------------------|--------------------------------------------------------------------|
| `FORK_BLKNUM`             | tbd                                                                |
| `GAS_COLD_ACCOUNT_ACCESS` | Defined as `2600` in the [Ethereum Execution Layer Spec Constants] |
| `GAS_WARM_ACCESS`         | Defined as `100` in the [Ethereum Execution Layer Spec Constants]  |

We introduce a new EOFv1 instruction on the block number `FORK_BLKNUM`: `EXTCODEADDRESS` (`0xTBD`)

EOF code which contains this instruction before `FORK_BLKNUM` is considered invalid. Beginning with block `FORK_BLKNUM` `0xTBD` is added to the set of valid EOFv1 instructions.

### Execution Semantics

#### `EXTCODEADDRESS`

- deduct `GAS_WARM_ACCESS` gas
- pop 1 argument `target_address` from the stack
- if `target_address` has any of the high 12 bytes set to a non-zero value (i.e. it does not contain a 20-byte address), then halt with an exceptional failure
  - Notice: Future expansion of the EVM address space may enlarge the number of valid addresses. Do not rely on this step always halting with the current restrictions.
- deduct `GAS_COLD_ACCOUNT_ACCESS - GAS_WARM_ACCESS` if `target_address` is not in `accessed_addresses` and add `target_address` to `accessed_addresses`
- Load the code from `target_address` and refer to it as `loaded_code`
- If `loaded_code` indicates a delegation designator (for example, `0xef0100` as defined in [EIP-7702]) push the address of the designation onto the stack.
  - Notice: if [EIP-7702] delegation designations are updated in a future fork (such as allowing chained delegations), then this section is expected to comply with any such hypothetical changes. 
- Otherwise, push `target_adress` onto the stack.

Note: If `target_address` or the delegation designator points to an account with a contract mid-creation then the code is empty and returns `0` (`TYPE_NONE`). This is aligned with similar behavior of instructions like `EXTCODESIZE`.

Note: Only `target_address` is warmed. If a delegation is found the address that it is delegated to is not added to the `accessed_addresses`. Also, whether the delegated address is in `accessed_addresses` has no impact on the gas charged for the operation.

## Rationale

This EIP is very similar to [EIP-7761], which introduces account type introspection. Its rationale is included by reference as they all apply to this situation.

### Alternative: Return the whole designation, have contract parse

One alternative is to have a specially limited `EXTCODECOPY` that would return just delegation designations. Apart from the general objections to code introspection this would then lock in and limit delegation designation formats and capabilities that must be preserved in future forks. By allowing access to the effect of the delegation rather than the mechanism EOF preserves space for the mechanism to be changed without breaking existing code. 

## Backwards Compatibility

`EXTCODEADDRESS` at `0xTBD` can be introduced in a backwards compatible manner into EOFv1 (no bump to version), because `0xTBD` has been rejected by EOF validation before `FORK_BLKNUM` and there are no EOF contracts on-chain with a `0xTBD` which would have their behavior altered.

## Security Considerations

[EIP-7702] code delegation is a new feature that has not been made accessible to mainnet yet. EIP authors will keep abreast of any developments and reflect on their impact to this proposed instruction. 

## Copyright

Copyright and related rights waived via [CC0]

[CC0]: ../LICENSE.md
[EIP-7702]: ./eip-7702.md
[EIP-7692]: ./eip-7692.md
[EIP-7761]: ./eip-7761.md
[Ethereum Execution Layer Spec Constants] :https://github.com/ethereum/execution-specs/blob/1adcc1bfe774798bcacc685aebc17bd9935078c3/src/ethereum/cancun/vm/gas.py#L65-L66
