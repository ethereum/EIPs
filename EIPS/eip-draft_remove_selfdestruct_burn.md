---
title: Remove SELFDESTRUCT Burn
description: Eliminate the remaining cases where SELFDESTRUCT burns ETH.
author: Paweł Bylica (@chfast)
discussions-to: https://ethereum-magicians.org/t/eip-proposal-remove-selfdestruct-burn/28416
status: Draft
type: Standards Track
category: Core
created: 2026-05-01
requires: 161, 6780
---

## Abstract

This EIP removes the remaining cases where `SELFDESTRUCT` burns ETH. Accounts marked for deletion still have their code, storage, and nonce cleared at transaction finalization, but any remaining balance is preserved.

## Motivation

The remaining burn behavior of `SELFDESTRUCT` is almost completely unused, but it still forces special-case handling in EVM implementations, specifications, and tests.

After [EIP-6780](./eip-6780.md), ETH can still be burned only when a contract created in the same transaction executes `SELFDESTRUCT`, either with itself as beneficiary or in a case where the contract receives additional ETH (via `CALL` or via `SELFDESTRUCT`, potentially multiple times) later in the same transaction.
A full replay of Ethereum mainnet from genesis to approximately block 24.95M found only 2 post-Cancun burns through this path and 0 cases of balance being burned during transaction finalization. By comparison, pre-Cancun history contained 54 self-burns in total. This indicates that the remaining burn behavior is rarer than the burn behavior already removed by EIP-6780, so the complete removal proposed here should affect fewer transactions than the partial removal already introduced there.

Removing the final burn cases simplifies `SELFDESTRUCT` semantics and avoids preserving an exotic special case that is barely used in practice.

As a consequence, this also removes the last EVM mechanism by which ETH can leave total supply.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

`SELFDESTRUCT (0xff)` MUST NOT burn ETH.

When `SELFDESTRUCT` is executed in the same transaction in which the executing contract was created:

1. the current execution frame halts (unchanged),
2. if the beneficiary differs from the executing contract, the entire account balance is transferred to the beneficiary (unchanged),
3. if the beneficiary is the executing contract, there is no balance transfer and no ETH is burned,
4. the account is marked for deletion (unchanged).

For an account marked for deletion in this way, transaction finalization is modified as follows.

Instead of deleting the account, finalization MUST:

1. clear the account code,
2. clear all account storage,
3. reset the account nonce to `0`,
4. preserve the account balance.

### Clarifications

- If the resulting balance is `0`, the account MUST be removed from the state according to the empty account clearing rule of [EIP-161](./eip-161.md). Otherwise, the account MUST remain in the state with empty code, empty storage, nonce `0`, and its preserved balance.
- For contracts not created in the same transaction in which `SELFDESTRUCT` is executed, the behavior is unchanged from [EIP-6780](./eip-6780.md).

## Rationale

TODO: May contain AI slop.

This change removes burn behavior at its source instead of adding dedicated handling for it elsewhere.

The chosen design preserves the state-clearing effect of `SELFDESTRUCT` for contracts created in the same transaction. The account may still survive in the state, but only as a balance-only account. This removes the special case where ETH disappears from the state while keeping the account non-executable after transaction finalization.

Resetting the nonce to `0` ensures that a future `CREATE2` at the same address is not blocked by a preserved balance-only account.

An alternative would be to preserve the whole account, including nonce, code, and storage. That would remove the burn as well, but it would be a larger semantic change than necessary. This EIP removes only the burn behavior.

## Backwards Compatibility

TODO: May contain AI slop.
TODO: Make sure CREATE2-SELFDESTRUCT sandwitch works.


This EIP requires a hard fork, since it modifies consensus rules.

Previously it was possible to burn ETH by executing `SELFDESTRUCT` in a contract created in the same transaction, either by targeting the executing contract as beneficiary or by sending ETH to the contract after `SELFDESTRUCT` and before transaction finalization. After this EIP, ETH will not be burned in either case.

Previously such contracts were always deleted at transaction finalization. After this EIP, a contract with zero final balance is still deleted, but a contract with nonzero final balance remains in the state as a balance-only account with empty code, empty storage, and nonce `0`.

For contracts not created in the same transaction in which `SELFDESTRUCT` is executed, the behavior is unchanged from [EIP-6780](./eip-6780.md).

## Test Cases

TBD

## Security Considerations

TODO: May contain AI slop.
TODO: Figure out if this is about EVM security or contracts recurity.
TODO: Check if the just_created works off accounts with balance.

Contracts that intentionally rely on ETH being destroyed by `SELFDESTRUCT` change behavior. After this EIP, such ETH remains owned by an account with no code and no storage.

This can leave balance-only accounts in the state in rare cases where ETH is sent to a self-destructed account later in the same transaction. This is not a new kind of account state, but implementations must handle it correctly.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
