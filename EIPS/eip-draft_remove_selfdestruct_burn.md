---
title: Remove SELFDESTRUCT Burn
description: Eliminate the remaining cases where SELFDESTRUCT burns ETH.
author: Paweł Bylica (@chfast)
discussions-to: https://ethereum-magicians.org/t/eip-7708-eth-transfers-emit-a-log/20034/63
status: Draft
type: Standards Track
category: Core
created: 2026-05-01
---

## Abstract

This EIP removes the remaining cases where `SELFDESTRUCT (0xff)` burns ETH. Accounts marked for deletion still have their code, storage, and nonce cleared at transaction finalization, but any remaining balance is preserved.

## Motivation

The remaining burn behavior of `SELFDESTRUCT` is almost completely unused, but it still forces special-case handling in EVM implementations, specifications, and tests.

After [EIP-6780](./eip-6780.md), ETH can only still be burned when a contract created in the same transaction executes `SELFDESTRUCT`, either to itself or before receiving more ETH later in the same transaction. A full replay of Ethereum mainnet from genesis to approximately block 24.95 million found only 2 post-Cancun burns through this path and 0 cases of balance being burned during transaction finalization. By comparison, pre-Cancun history contained 54 self-burns in total. This indicates that the remaining burn behavior is rarer than the burn behavior already removed by EIP-6780, so the complete removal proposed here should affect fewer transactions than the partial removal already introduced there.

Removing the final burn cases simplifies `SELFDESTRUCT` semantics and avoids preserving an exotic feature only to support behavior that is barely used in practice.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

`SELFDESTRUCT (0xff)` MUST NOT burn ETH.

For an account marked for deletion by `SELFDESTRUCT` in the same transaction in which the account was created, transaction finalization is modified as follows.

Instead of deleting the account and its balance, finalization MUST:

1. clear the account code,
2. clear all account storage,
3. reset the account nonce to `0`,
4. preserve the account balance.

If the resulting balance is `0`, the account MUST be removed from the state. Otherwise, the account MUST remain in the state with empty code, empty storage, nonce `0`, and its preserved balance.

When a contract created in the same transaction executes `SELFDESTRUCT` with itself as beneficiary, there is no balance transfer and no balance burn.

All other `SELFDESTRUCT` behavior remains unchanged.

## Rationale

This change removes burn behavior at its source instead of adding dedicated handling for it elsewhere.

The chosen design preserves the state-clearing effect of `SELFDESTRUCT` for contracts created in the same transaction. This keeps the current behavior where the account does not survive as an executable contract, while removing only the special case where ETH disappears from the state.

Resetting the nonce to `0` ensures that a future `CREATE2` at the same address is not blocked by a preserved balance-only account.

An alternative would be to preserve the whole account, including nonce, code, and storage. That would remove the burn as well, but it would be a larger semantic change than necessary. This EIP removes only the burn behavior.

## Backwards Compatibility

This EIP requires a hard fork, since it modifies consensus rules.

Previously it was possible to burn ETH by executing `SELFDESTRUCT` in a contract created in the same transaction, either by targeting the executing contract as beneficiary or by sending ETH to the contract after `SELFDESTRUCT` and before transaction finalization. After this EIP, ETH will not be burned in either case.

All other `SELFDESTRUCT` behavior is unchanged from [EIP-6780](./eip-6780.md).

## Test Cases

Tests should cover at least the following cases:

1. A contract created in the same transaction executes `SELFDESTRUCT` with itself as beneficiary and nonzero balance. After transaction finalization, the account has empty code, empty storage, nonce `0`, and the original balance.
2. A contract created in the same transaction executes `SELFDESTRUCT` with a different beneficiary, then receives additional ETH later in the same transaction. After transaction finalization, the later balance remains in the account instead of being burned.
3. A contract created in the same transaction executes `SELFDESTRUCT` and has zero balance at transaction finalization. The account is removed from the state.

## Security Considerations

Contracts that intentionally rely on ETH being destroyed by `SELFDESTRUCT` change behavior. After this EIP, such ETH remains owned by an account with no code and no storage.

This can leave balance-only accounts in the state in rare cases where ETH is sent to a self-destructed account later in the same transaction. This is not a new kind of account state, but implementations must handle it correctly.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
