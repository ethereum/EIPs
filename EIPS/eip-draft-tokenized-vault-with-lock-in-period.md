---
eip: <to be assigned>
title: Tokenized Vaults with Lock-in Period
description: EIP-4626 Tokenized Vaults with Lock-in Period.
author: Anderson Chen (@Ankarrr), Martinet Lee <martinetlee@gmail.com>, Anton Cheng <antonassocareer@gmail.com>
discussions-to: https://ethereum-magicians.org/t/eip-tokenized-vaults-with-lock-in-period/12298
status: Draft
type: Standards Track
category: ERC
created: 2022-12-21
requires: 4626
---

## Abstract

This standard is an extension of the [EIP-4626](./eip-4626.md) Tokenized Vaults that provides functions to support the lock-in period.

## Motivation

The [EIP-4626](./eip-4626.md) standard defines a tokenized vault standard that fits the use cases for users (contracts or EOAs) to deposit and withdraw underlying tokens at any time. However, in many cases, the vault needs to lock the underlying tokens to execute certain strategies, and during the lock-in period, withdrawal or deposit of underlying tokens should not be allowed. This standard extends the EIP-4626 to support the lock-in period and handle scheduled deposits and withdrawals during the lock-in period.

## Specification

All vaults that follow this EIP MUST implement [EIP-4626](./eip-4626.md) to provide basic vault functions and [EIP-20](./eip-20.md) to represent shares.

### Definitions

- asset: The underlying [EIP-20](./eip-20.md) token that the vault accepts and manages.
- share: The EIP-20 token that the vault issued.
- locked: A status of the vault. When the vault is locked, user can’t withdraw or deposit assets from the vault.
- unlocked: A status of the vault. When the vault is unlocked, user can withdraw or deposit assets from the vault.
- round: The period that the vault is locked.

### States

#### VaultStates

The `enum` of VaultState. There will be two types `LOCKED` and `UNLOCKED`.

```
- name: VaultState
  type: enum
  stateMutability: view

  inputs: []

  outputs:
    - name: VaultState
    - type: enum
```

#### state

The current state of the vault.

It MUST be either `LOCKED` or `UNLOCKED`.

```
- name: state
  type: VaultStates
  stateMutability: view

  inputs: []

  outputs:
    - name: state
      type: VaultStates

```

#### round

The current round of the vault.

MUST start with `0`

MUST add `1` when a new round is started and that mean the state become `LOCKED`. MUST NOT be modified in any other circumstances.

```
- name: round
  type: uint256
  stateMutability: view

  inputs: []

  outputs:
    - name: round
      type: uint256
```

### Methods

#### scheduleDeposit

Schedule the intent to deposit `assets` when the vault is in a `LOCKED` state.

MUST only be callable when the vault is at `LOCKED` state.

MUST transfer the `assets` from the caller to the vault. MUST not issue new shares.

MUST revert if `assets` cannot be deposited.

MUST revert if vault is at `UNLOCKED` state.

```
- name: scheduleDeposit
  type: function
  stateMutability: nonpayable

  inputs:
    - name: assets
      type: uint256
```

#### scheduleRedeem

Schedule the intent to redeem `shares` from the vault when the vault is in a `LOCKED` state.

MUST only be callable when the vault is at `LOCKED` state.

MUST transfer the `shares` from the caller to the vault. MUST not transfer assets to caller.

MUST revert if `shares` cannot be redeemed.

MUST revert if vault is at `UNLOCKED` state.

```
- name: scheduleRedeem
  type: function
  stateMutability: nonpayable

  inputs:
    - name: shares
      type: uint256
```

#### settleDeposits

Process all scheduled deposits for `depositor` and minting `newShares`.

MUST only be callable when the vault is at `UNLOCKED` state.

MUST issue `newShares` according to the current share price for the scheduled `depositor`.

MUST revert if there is no scheduled deposit for `depositor`.

```
- name: settleDeposits
  type: function
  stateMutability: nonpayable

  inputs:
    - name: depositor
    - type: address

  outputs:
    - name: newShares
    - type: uint256
```

#### settleRedemptions

Process all scheduled redemptions for `redeemer` by burning `burnShares` and transferring `redeemAssets` to the `redeemer`.

MUST only be callable when the vault is at `UNLOCKED` state.

MUST burn the `burnShares` and transfer `redeemAssets` back to the `redeemer` according to the current share price. 

MUST revert if no scheduled redemption for `redeemer`.

```
- name: settleRedemptions
  type: function
  stateMutability: nonpayable

  inputs:
    - name: redeemer
    - type: address

  outputs:
    - name: burnShares
    - type: uint256
    - name: redeemAssets
    - type: uint256
```

#### getScheduledDeposits

Get the `totalAssets` of scheduled deposits for `depositor`.

MUST *NOT* revert.

```
- name: getScheduledDeposits
  type: function
  stateMutability: view

  inputs:
    - name: depositor
    - type: address

  outputs:
    - name: totalAssets
    - type: uint256
```

#### getScheduledRedemptions

Get the `totalShares` of scheduled redemptions for `redeemer`.

MUST *NOT* revert.

```
- name: getScheduledRedemptions
  type: function
  stateMutability: view

  inputs:
    - name: redeemer
    - type: address

  outputs:
    - name: totalShares
    - type: uint256
```

### Events

#### ScheduleDeposit

`sender` schedules a deposit with `assets` in this `round`.

MUST be emitted via `scheduleDeposit` method.

```
- name: ScheduleDeposit
  type: event

  inputs:
    - name: sender
      indexed: true
      type: address
    - name: assets
      indexed: false
      type: uint256
    - name: round
      indexed: false
      type: uint256
```

#### ScheduleRedeem

`sender` schedules a redemption with `shares` in this `round`.

MUST be emitted via `scheduleRedeem` method.

```
- name: ScheduleRedeem
  type: event

  inputs:
    - name: sender
      indexed: true
      type: address
    - name: shares
      indexed: false
      type: uint256
    - name: round
      indexed: false
      type: uint2
```

#### SettleDeposits

Settle scheduled deposits for `depositor` in this `round`. Issue `newShares` and transfer them to the `depositor`.

MUST be emitted via `settleDeposits` method.

```jsx
- name: SettleDeposits
  type: event

  inputs:
    - name: depositor
      indexed: true
      type: address
    - name: newShares
      type: uint256
    - name: round
      type: uint256
```

#### SettleRedemptions

Settle scheduled redemptions for `redeemer` in this `round`. Burn `burnShares` and transfer `redeemAssets` back to the `redeemer`.

MUST be emitted via `settleRedemptions` method.

```
- name: SettleRedemptions
  type: event

  inputs:
    - name: redeemer
      indexed: true
      type: address
    - name: burnShares
      type: uint256
    - name: redeemAssets
      type: uint256
    - name: round
      type: uint256
```

## Rationale

The standard is designed to be a minimal interface. Details such as the start and end of a lock-in period, and how the underlying tokens are being used during the lock-in period are not specified.

There is no function for scheduling a withdrawal, since during the lock-in period, the share price is undetermined, so it’s not able to decide how many underlying tokens can be withdrawn.

## Backwards Compatibility

The `deposit`, `mint`, `withdraw`, `redeem` methods for [EIP-4626](./eip-4626.md) should be reverted when vault is in `LOCKED` state to prevent issuing or burning shares with an undefined share price.

## Security Considerations

Implementors need to be aware of unsettled scheduled deposits and redemptions. If a user has scheduled a deposit or withdrawal but does not settle when the vault becomes `UNLOCKED`, and then settles it after several rounds, the vault will process it with an incorrect share price. We didn’t specify the solution in the standard since there are many possible ways to solve this issue and we think implementors should decide the solution according to their use cases. For example:

- Not allow the vault to become `LOCKED` if there is any unsettled scheduled deposit or redemption
- Force settling the scheduled deposits or redemptions when the vault becomes `LOCKED`
- Memorize the ending share price for each round and let the users settle according to the share prices

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
