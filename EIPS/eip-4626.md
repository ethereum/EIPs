---
eip: 4626
title: Tokenized Vault Standard
description: A standard for tokenized Vaults with a single underlying ERC-20 token.
author: Joey Santoro (@joeysantoro), t11s (@transmissions11), Jet Jadeja (@JetJadeja), Alberto Cuesta Cañada (@alcueca), Señor Doggo (@fubuloubu)
discussions-to: https://ethereum-magicians.org/t/eip-4626-yield-bearing-vault-standard/7900
status: Review
type: Standards Track
category: ERC
created: 2021-12-22
requires: 20, 2612
---

## Abstract

The following standard allows for the implementation of a standard API for tokenized Vaults
representing shares of a single underlying [ERC-20](./eip-20.md) token.
This standard is an extension on the ERC-20 token that provides basic functionality for depositing
and withdrawing tokens and reading balances.

## Motivation

Tokenized Vaults have a lack of standardization leading to diverse implementation details.
Some various examples include lending markets (Compound, Aave, Fuse),
aggregators (Yearn, Rari Vaults, Idle), and intrinsically interest bearing tokens (xSushi).

This makes integration difficult at the aggregator or plugin layer for protocols which need to conform to many standards and
forces each protocol to implement their own adapters which are error prone and waste development resources.

A standard for tokenized Vaults will allow for a similar cambrian explosion to ERC-20,
unlocking access to yield and other strategies in a variety of applications
with little specialized effort from developers.

## Specification

All ERC-4626 tokenized Vaults MUST implement ERC-20 to represent shares.
If a Vault is to be non-transferrable, it MAY revert on calls to transfer or transferFrom.
The ERC-20 operations balanceOf, transfer, totalSupply, etc. operate on the Vault "shares"
which represent a claim to ownership on a fraction of the Vault's underlying holdings.

All ERC-4626 MUST implement ERC-20's optional metadata extensions.
The `name` and `symbol` functions should reflect the underlying token's `name` and `symbol` in some way.
The value of `decimals` can mirror the underlying's value of `decimals`,
which may affect precision for computing the value of Vault shares

ERC-4626 MAY implement [EIP-2612](./eip-2612.md) to improve the UX of approving shares on various integrations.

### Definitions:

- asset: The underlying token managed by the Vault.
  Has units defined by the corresponding ERC20 contract.

- share: The token of the Vault. Has a ratio of underlying assets
  exchanged on mint/deposit/withdraw/redeem (defined by the Vault).

- slippage: Any difference between advertised share price and economic realities of
  deposit to or withdrawal from the Vault, which is not accounted by fees.

- fee: An amount of assets or shares charged to the Vault. Can be a fee on deposits,
  yield, AUM, withdrawal, or any other kind of fee.

### Methods

#### asset

The address of the underlying token used for the Vault uses for accounting, depositing, and withdrawing.

MUST be an ERC-20 token contract.

MUST _NOT_ revert.

```yaml
- name: asset
  type: function
  stateMutability: view

  inputs: []

  outputs:
    - name: assetTokenAddress
      type: address
```

#### totalAssets

Total amount of the underlying asset that is "managed" by Vault.

SHOULD include any compounding that occurs from yield.

MUST be inclusive of any fees that are charged against assets in the Vault.

MUST _NOT_ revert.

```yaml
- name: totalAssets
  type: function
  stateMutability: view

  inputs: []

  outputs:
    - name: totalAssets
      type: uint256
```

#### assetsPerShare

The current exchange rate of shares to assets, quoted per share unit (a share unit is `10 ** Vault.decimals()`).

MUST be equal to `(Vault.totalAssets() * (10 ** Vault.decimals())) / Vault.totalSupply()` unless `Vault.totalSupply()` is 0.

MUST be inclusive of any fees that are charged against assets in the Vault.

MAY _NOT_ be completely accurate according to slippage or other on-chain conditions, when performing the actual exchange.

MUST _NOT_ return 0 to indicate the Vault is empty.

MUST _NOT_ revert.

In certain types of fee calculations, this calculation MAY _NOT_ reflect the "per-user" price-per-share,
and instead should reflect the "average-user's" price-per-share, meaning what the average user should expect
to see when exchanging to and from.

The `assetsOf` method SHOULD be used for more accurate calculations of a user's underlying balance.

```yaml
- name: assetsPerShare
  type: function
  stateMutability: view

  inputs: []

  outputs:
    - name: assetsPerShareUnit
      type: uint256
```

#### assetsOf

Total number of underlying assets that `depositor`'s shares represent.

MAY be more accurate than using `assetsPerShare` or `totalAssets / Vault.totalSupply` for certain types of fee calculations.

MAY _NOT_ be completely accurate according to slippage or other on-chain conditions.

MUST _NOT_ revert.

```yaml
- name: assetsOf
  type: function
  stateMutability: view

  inputs:
    - name: depositor
      type: address

  outputs:
    - name: assets
      type: uint256
```

#### maxDeposit

Total number of underlying assets that `caller` can be deposit.

MUST return a limited value if `caller` is subject to some deposit limit.

MUST return `2 ** 256 - 1` if there is no limit on the maximum amount of assets that may be deposited.

MAY be used in the `previewDeposit` or `deposit` methods for `assets` input parameter.

MUST _NOT_ revert.

```yaml
- name: maxDeposit
  type: function
  stateMutability: view

  inputs:
    - name: caller
      type: address

  outputs:
    - name: maxAssets
      type: uint256
```

#### previewDeposit

Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block,
given current on-chain conditions.

MUST return as close to the _exact_ amount of Vault shares that would be minted if the caller were
to deposit a given _exact_ amount of underlying assets using the `deposit` method as technically possible.

MUST _NOT_ account for deposit limits like those returned from `maxDeposit` and should always act
as though the deposit would be accepted, regardless if the user has enough tokens approved, etc.

MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.

MUST _NOT_ revert.

Note that any unfavorable discrepancy between `assetsPerShare` and the ratio of `assets` to `shares` SHOULD
be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by depositing.

```yaml
- name: previewDeposit
  type: function
  stateMutability: view

  inputs:
    - name: assets
      type: uint256

  outputs:
    - name: shares
      type: uint256
```

#### deposit

Mints `shares` Vault shares to `receiver` by depositing exactly `amount` of underlying tokens.

MUST match the quote given by `previewDeposit` as close as technically possible.

MUST emit the `Deposit` event.

MAY support an additional flow in which the underlying tokens are owned by the Vault contract
before the `deposit` execution, and are accounted for during `deposit`.

MUST revert if all of `assets` cannot be deposited (due to deposit limit being reached, slippage, the user not
approving enough underlying tokens to the Vault contract, etc).

Note that most implementations will require pre-approval of the Vault with the Vault's underlying `asset` token.

```yaml
- name: deposit
  type: function
  stateMutability: nonpayable

  inputs:
    - name: assets
      type: uint256
    - name: receiver
      type: address

  outputs:
    - name: shares
      type: uint256
```

#### maxMint

Total number of underlying shares that `caller` can mint.

MUST return a limited value if `caller` is subject to some deposit limit.

MUST return `2 ** 256 - 1` if there is no limit on the maximum amount of shares that may be minted.

MAY be used in the `previewMint` or `mint` methods for `shares` input parameter.

MUST _NOT_ revert.

```yaml
- name: maxMint
  type: function
  stateMutability: view

  inputs:
    - name: caller
      type: address

  outputs:
    - name: maxShares
      type: uint256
```

#### previewMint

Allows an on-chain or off-chain user to simulate the effects of their mint at the current block,
given current on-chain conditions.

MUST return as close to the _exact_ amount of Vault shares that would be minted if the caller were
to deposit a given _exact_ amount of underlying assets using the `mint` method as technically possible.

MUST _NOT_ account for mint limits like those returned from `maxMint` and should always act
as though the mint would be accepted, regardless if the user has enough tokens approved, etc.

MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.

MUST _NOT_ revert.

Note that any unfavorable discrepancy between `assetsPerShare` and the ratio of `assets` to `shares` SHOULD
be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by minting.

```yaml
- name: previewMint
  type: function
  stateMutability: view

  inputs:
    - name: shares
      type: uint256

  outputs:
    - name: assets
      type: uint256
```

#### mint

Mints exactly `shares` Vault shares to `receiver` by depositing `amount` of underlying tokens.

MUST match the quote given by `previewMint` as close as technically possible.

Any discrepancy could cause a revert due to tight slippage bounds by caller.

MUST emit the `Deposit` event.

MAY support an additional flow in which the underlying tokens are owned by the Vault contract
before the `mint` execution, and are accounted for during `mint`.

MUST revert if all of `shares` cannot be minted (due to deposit limit being reached, slippage, the user not approving
enough underlying tokens to the Vault contract, etc).

Note that most implementations will require pre-approval of the Vault with the Vault's underlying `asset` token.

```yaml
- name: mint
  type: function
  stateMutability: nonpayable

  inputs:
    - name: shares
      type: uint256
    - name: receiver
      type: address

  outputs:
    - name: assets
      type: uint256
```

#### maxWithdraw

Total number of underlying assets that `caller` can withdraw.

MUST return a limited value if `caller` is subject to some withdrawal limit or timelock.

MUST return `assetsOf(caller)` if `caller` is not subject to any withdrawal limit or timelock.

MAY be used in the `previewWithdraw` or `withdraw` methods for `assets` input parameter.

MUST _NOT_ revert.

```yaml
- name: maxWithdraw
  type: function
  stateMutability: view

  inputs:
    - name: caller
      type: address

  outputs:
    - name: maxAssets
      type: uint256
```

#### previewWithdraw

Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
given current on-chain conditions.

MUST return as close to the _exact_ amount of Vault shares that would be redeemed by the caller if withdrawing
a given _exact_ amount of underlying assets using the `withdraw` method as technically possible.

MUST _NOT_ account for withdrawal limits like those returned from `maxWithdraw` and should always act
as though the withdrawal would be accepted, regardless if the user has enough shares, etc.

MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.

MUST _NOT_ revert.

Note that any unfavorable discrepancy between `assetsPerShare` and the ratio of `assets` to `shares` SHOULD
be considered slippage in share price or some other type of condition, meaning the withdrawer will lose assets by withdrawing.

```yaml
- name: previewWithdraw
  type: function
  stateMutability: view

  inputs:
    - name: assets
      type: uint256

  outputs:
    - name: shares
      type: uint256
```

#### withdraw

Redeems `shares` from `owner` and sends `assets` of underlying tokens to `receiver`.

MUST match the quote given by `previewWithdraw` as close as technically possible.

MUST emit the `Withdraw` event.

MAY support an additional flow in which the underlying tokens are owned by the Vault contract
before the `withdraw` execution, and are accounted for during `withdraw`.
MUST revert if all of `assets` cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).

Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
Those methods should be performed separately.

```yaml
- name: withdraw
  type: function
  stateMutability: nonpayable

  inputs:
    - name: assets
      type: uint256
    - name: receiver
      type: address
    - name: owner
      type: address

  outputs:
    - name: shares
      type: uint256
```

#### maxRedeem

Total number of underlying shares that `caller` can redeem.

MUST return a limited value if `caller` is subject to some withdrawal limit or timelock.

MUST return `balanceOf(caller)` if `caller` is not subject to any withdrawal limit or timelock.

MAY be used in the `previewRedeem` or `redeem` methods for `shares` input parameter.

MUST _NOT_ revert.

```yaml
- name: maxRedeem
  type: function
  stateMutability: view

  inputs:
    - name: caller
      type: address

  outputs:
    - name: maxShares
      type: uint256
```

#### previewRedeem

Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
given current on-chain conditions.

MUST return as close to the _exact_ amount of underlying assets that would be withdrawn by the caller if redeeming
a given _exact_ amount of Vault shares using the `redeem` method as technically possible.

MUST _NOT_ account for redemption limits like those returned from `maxRedeem` and should always act
as though the redemption would be accepted, regardless if the user has enough shares, etc.

MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.

MUST _NOT_ revert.

Note that any unfavorable discrepancy between `assetsPerShare` and the ratio of `assets` to `shares` SHOULD
be considered slippage in share price or some other type of condition, meaning the withdrawer will lose assets by redeeming.

```yaml
- name: previewRedeem
  type: function
  stateMutability: view

  inputs:
    - name: shares
      type: uint256

  outputs:
    - name: assets
      type: uint256
```

#### redeem

Redeems `shares` from `owner` and sends `assets` of underlying tokens to `receiver`.

MUST match the quote given by `previewRedeem` as close as technically possible.

MUST emit the `Withdraw` event.

MAY support an additional flow in which the underlying tokens are owned by the Vault contract
before the `redeem` execution, and are accounted for during `redeem`.

MUST revert if all of `shares` cannot be redeemed (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).

Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.

Those methods should be performed separately.

```yaml
- name: redeem
  type: function
  stateMutability: nonpayable

  inputs:
    - name: shares
      type: uint256
    - name: receiver
      type: address
    - name: owner
      type: address

  outputs:
    - name: assets
      type: uint256
```

### Events

#### Deposit

`sender` has exchanged `assets` for `shares`, and transferred those `shares` to `receiver`.

MUST be emitted when tokens are deposited into the Vault via the `mint` and `deposit` methods.

```yaml
- name: Deposit
  type: event

  inputs:
    - name: sender
      indexed: true
      type: address
    - name: receiver
      indexed: true
      type: address
    - name: assets
      indexed: false
      type: uint256
    - name: shares
      indexed: false
      type: uint256
```

#### Withdraw

`sender` has exchanged `shares` for `assets`, and transferred those `assets` to `receiver`.

MUST be emitted when shares are withdrawn from the Vault in `redeem` or `withdraw` methods.

```yaml
- name: Withdraw
  type: event

  inputs:
    - name: sender
      indexed: true
      type: address
    - name: receiver
      indexed: true
      type: address
    - name: assets
      indexed: false
      type: uint256
    - name: shares
      indexed: false
      type: uint256
```

## Rationale

The Vault interface is designed to be optimized for integrators with a feature complete yet minimal interface.
Details such as accounting and allocation of deposited tokens are intentionally not specified,
as Vaults are expected to be treated as black boxes on-chain and inspected off-chain before use.

ERC-20 is enforced because implementation details like token approval
and balance calculation directly carry over to the shares accounting.
This standardization makes the Vaults immediately compatible with all ERC-20 use cases in addition to ERC-4626.

The mint method was included for symmetry and feature completeness.
Most current use cases of share-based Vaults do not ascribe special meaning to the shares such that
a user would optimize for a specific number of shares (`mint`) rather than specific amount of underlying (`deposit`).
However, it is easy to imagine future Vault strategies which would have unique and independently useful share representations.

A single `assetsPerShare` method can only be guaranteed to be exact with one of the four mutable methods,
unless significant conditions are placed on the use cases that can comply with this standard.
Use cases that require to know the value of a Vault position need to know the result of a `redeem` call, without executing it.
On the other hand, integrators that intend to call `withdraw` on Vaults with the user approving only the exact amount of
underlying need the result of a `withdraw` call. Similar use cases can be found for `deposit` and `mint`.

As such, the `assetsPerShare` method has been kept for ease of integration on part of the simpler use cases,
but `preview*` methods have been included for each one of the four mutable methods.
In each case, the value of a preview method is only guaranteed to equal the return value of the related mutable method
if called immediately before in the same transaction.

The `max*` methods are used to check for deposit/withdraw limits on vault capacity. These can be consumed off-chain for more user focused applications or on-chain for more on-chain aggregation/integration use cases.

If implementors intend to support EOA account access directly, they should consider adding an additional function with the means to accommodate slippage loss or deposit/withdrawal limits,
since their transaction will revert if the exact amount is not achieved.

## Backwards Compatibility

ERC-4626 is fully backward compatible with the ERC-20 standard and has no known compatibility issues with other standards.
For production implementations of Vaults which do not use ERC-4626, wrapper adapters can be developed and used.

## Reference Implementations

See [Solmate ERC4626](https://github.com/Rari-Capital/solmate/pull/88):
a minimal and opinionated implementation of the standard with hooks for developers to easily insert custom logic into deposits and withdrawals.

See [Vyper ERC4626](https://github.com/fubuloubu/ERC4626):
a demo implementation of the standard in Vyper, with hooks for share price manipulation and other testing needs.

## Security Considerations

This specification has similar security considerations to the ERC-20 interface.

Fully permissionless use cases could fall prey to malicious implementations which only conform to the interface but not the specification.
It is recommended that all integrators review the implementation for potential ways of losing user deposits before integrating.

The methods `totalAssets`, `assetsPerShare` and `assetsOf` are estimates useful for display purposes,
but do _not_ have to confer the _exact_ amount of underlying assets their context suggests.
Integrators of ERC-4626 Vaults should be aware of the difference between these view methods when integrating with this standard.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
