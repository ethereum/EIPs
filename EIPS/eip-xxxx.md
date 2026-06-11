---
title: SETCODEFROM Code Reuse Instruction
description: Adds an instruction that sets an account's code hash from an existing deployed contract.
author: TBD
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2026-06-11
---

## Abstract

This EIP introduces `SETCODEFROM`, an EVM instruction that sets the current account's code hash to the code hash of a source account with existing deployed code. During contract creation, `SETCODEFROM` defines the created account's deployed code. During deployed-code execution, `SETCODEFROM` changes only the executing account's code hash, and the new code is visible to later code execution.

## Motivation

This EIP has two primary use cases.

First, it improves code reuse and deployment economics. Deploying many contracts with identical runtime code is expensive, especially when contract deployment is repriced more closely to state growth, for example under [EIP-8037](./eip-8037.md). Contract creation can initialize per-instance storage, then adopt shared deployed code without paying code-deposit gas for identical runtime code. Existing contracts can also adopt a new shared implementation through their own upgrade logic.

Second, it provides an account migration path for disabling ECDSA-based EOA transaction authority. Migration code can store account-specific wallet state, including PQ wallet state, then adopt regular wallet code. After that update, account control is through the installed wallet code rather than ECDSA transaction origination. This is because the account now has regular deployed code, not an EIP-7702 delegation indicator, so ECDSA-authenticated transactions remain invalid under EIP-3607. EIP-7702 authorization processing can no longer redelegate the account because the authority code check only accepts empty code or an existing delegation indicator. The account can still upgrade through upgrade logic in the installed code, for example by calling `SETCODEFROM` again or by using other methods. Protocol-level ECDSA transaction origination remains permanently disabled.

`SETCODEFROM` provides the code-adoption step for both cases after any per-instance state has been initialized.

## Specification

### Parameters

The opcode and gas parameters are defined as follows:

| Parameter                     | Value                                                   |
| ----------------------------- | ------------------------------------------------------- |
| `SETCODEFROM_OPCODE`          | `TBD`                                                   |
| `SETCODEFROM_BASE_GAS`        | `3000`                                                  |
| `SOURCE_ACCOUNT_ACCESS_COST`  | warm/cold account access cost                           |
| `SETCODEFROM_GAS`             | `SETCODEFROM_BASE_GAS + SOURCE_ACCOUNT_ACCESS_COST`     |

### `SETCODEFROM`

`SETCODEFROM(source)` takes one stack item. The low 160 bits of the stack item are interpreted as `source`.

Before execution:

```text
[..., source]
```

After execution:

```text
[..., success]
```

`success` is `1` if the code update succeeds, and `0` if no code update is made.

The instruction is address-based: its input is `source` address, not a raw code hash. It reads `source.codeHash` from a live account in consensus state.

For this instruction, the current account is the current execution-environment address, meaning the account returned by `ADDRESS` and whose storage is affected by `SSTORE`. If the executing code was loaded from another account, including through [EIP-7702](./eip-7702.md) delegated execution, `SETCODEFROM` updates the execution-environment account, not the code source account.

A source account is valid for `SETCODEFROM` if all of the following are true:

- The source account is not a precompile.
- `source.codeHash != EMPTYCODEHASH`.
- `source.code` is valid regular deployed code under the active fork, e.g. it does not start with `0xEF`, which is reserved by [EIP-3541](./eip-3541.md) and used by [EIP-7702](./eip-7702.md) delegation indicators.

If executed in a static context, `SETCODEFROM` causes an exceptional halt.

If `source` is not a valid source account, `SETCODEFROM` pushes `0` and makes no state change.

If `source` is a valid source account, `SETCODEFROM` sets the current account's `codeHash` to `source.codeHash` and pushes `1`.

State changes made by `SETCODEFROM` follow normal EVM revert semantics. If the frame or transaction reverts, the code update reverts.

### Contract Creation

During contract creation, the creation frame tracks whether an unreverted successful `SETCODEFROM` adoption has occurred.

When `SETCODEFROM` succeeds in initcode for a contract creation transaction or for `CREATE`/`CREATE2`, the creation frame records the source account's deployed code as the adopted code for the account being created.

If multiple `SETCODEFROM` executions succeed in the same unreverted creation frame, the last successful execution determines the adopted code. An unsuccessful `SETCODEFROM` does not clear or change a previous successful adoption.

The adoption state follows normal creation-frame revert semantics. If the frame or a nested scope containing the adoption reverts, that adoption is discarded.

At initcode completion:

- If no unreverted successful adoption exists, the created account's deployed code is the initcode's final output data.
- If an unreverted successful adoption exists and the initcode's final output data is empty, the created account's deployed code is the last adopted source code.
- If an unreverted successful adoption exists and the initcode's final output data is nonempty, contract creation fails.

### Deployed Code Execution

When `SETCODEFROM` succeeds while executing deployed code, it updates the code hash of the current execution-context account.

The current execution frame continues running the code that was already loaded for that frame. The updated code hash is used by later code executing operations, including later calls to the same account in the same transaction, subject to normal revert semantics.

### ECDSA Transaction Origination

After `SETCODEFROM` installs regular deployed code on an account, the account is controlled through that code. The account has nonempty regular code, so an ECDSA-authenticated transaction whose recovered sender is that account is invalid under [EIP-3607](./eip-3607.md). It also disables [EIP-7702](./eip-7702.md) redelegation, because EIP-7702 authorization processing accepts only empty code or an existing valid delegation indicator for the authority account.

### Gas Costs

`SETCODEFROM` charges `SETCODEFROM_GAS` for each execution attempt, where `SETCODEFROM_GAS = SETCODEFROM_BASE_GAS + SOURCE_ACCOUNT_ACCESS_COST`.

`SETCODEFROM_BASE_GAS` is the fixed cost to update the current execution-context account's code hash. To compute a fair cost for this operation, the authors review its impact on the system:

- carrying the `source` address = `0`, charged by ordinary calldata, initcode, or deployed-code costs
- reading `source` = included in `SOURCE_ACCOUNT_ACCESS_COST`
- source-validity checks after `source` account access = `100`, matching `WARM_STORAGE_READ_COST`
- updating the current account's code hash = `2900`, matching a warm nonzero-to-nonzero `SSTORE` update under [EIP-2200](./eip-2200.md) and [EIP-2929](./eip-2929.md)
- storing source bytecode = `0`, because the code already exists

Although the code hash is an account field rather than a storage slot, a warm nonzero-to-nonzero `SSTORE` update is the closest current-schedule proxy for updating one already-loaded 32-byte value with revert semantics. These fixed components sum to `3000`, so `SETCODEFROM_BASE_GAS` is set to `3000`. This fixed charge is not affected by source code size because no new bytecode is stored.

The source account access follows the active warm/cold account access rules. Under [EIP-2929](./eip-2929.md), if `source` is cold, charge `COLD_ACCOUNT_ACCESS_COST`. Otherwise, charge `WARM_STORAGE_READ_COST`.

Under the current EIP-2929 source-access constants, `SETCODEFROM_GAS` is `5600` gas for a cold source and `3100` gas for a warm source.

## Rationale

Using an address rather than a raw code hash avoids depending on client-local code database contents, which may differ across nodes. A newly synced node may have a smaller local code database than a long-running node because it may not keep historical or unreferenced bytecode entries. For this reason, this EIP makes `SETCODEFROM` copy the code hash from a live source account, so the adopted code hash is confirmed by current consensus state.

The instruction is self-only during deployed-code execution to keep authority local to the account whose code is executing. It does not allow the executing code to update any other account's code hash.

Contract-creation support allows initcode to write per-instance storage before adopting shared runtime code. This covers patterns such as token clones, liquidity pools, and account migration where parameters are instance-specific but executable code is shared.

For example, the instruction can be used in the following patterns.

An account migration can initialize account specific wallet state, then adopt a shared wallet implementation:

```
SSTORE(pq_pubkey_slot, userPubkey)
SSTORE(recovery_slot, recoveryConfig)
SETCODEFROM(PQ_WALLET_TEMPLATE)
```

An ERC-20 clone factory can initialize token metadata and ownership in `CREATE2` initcode, then adopt a shared token implementation:

```
SSTORE(name_slot, "MyToken")
SSTORE(symbol_slot, "MYT")
SSTORE(owner_slot, msg.sender)
SETCODEFROM(ERC20_TEMPLATE)
RETURN("")
```

## Backwards Compatibility

This EIP requires a hard fork to implement because it introduces a new instruction which did not exist previously. As a result, already deployed contracts using this instruction could change their behavior after this EIP.

## Security Considerations

`SETCODEFROM` can change the code used by later executions of an account. Contracts that expose this instruction must restrict access to trusted control paths, because a successful call can permanently change account behavior if the transaction does not revert.

The source restriction requires valid regular deployed code under the active fork, e.g. code that does not use the `0xEF` prefix reserved by [EIP-3541](./eip-3541.md) and used by [EIP-7702](./eip-7702.md) delegation indicators. It also excludes empty code and precompiles. This prevents `SETCODEFROM` from bypassing deployed-code validity rules or treating precompile behavior as deployed code.

Protocol-level ECDSA transaction origination is disabled once the account has regular deployed code, meaning code that is not an EIP-7702 delegation indicator. Contracts that verify ECDSA signatures directly through `ecRecover` may still recover that address. This affects signature-based authorization such as `permit`. A companion `ecRecover` change, such as [EIP-8151](./eip-8151.md), can reject recovered addresses whose account code is regular deployed code rather than an EIP-7702 delegation indicator, and return 32 zero bytes.

Because the current frame keeps executing already-loaded code, implementations must clearly separate the executing code for the current frame from the account code visible to later calls. Re-entrant calls after a successful `SETCODEFROM` observe the updated code.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
