---
eip: TODO
title: Asynchronous Tokenized Vaults
description: Extension of ERC-4626 with asynchronous deposit and redemption support
author: Jeroen Offerijns (@hieronx), Alina Sinelnikova (@ilinzweilin), Vikram Arun (@vikramarun), Joey Santoro (@joeysantoro)
discussions-to: TODO
status: Draft
type: Standards Track
category: ERC
created: TODO
requires: 20, 4626
---

## Abstract

The following standard extends [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) by adding support for asynchronous deposit and redemption flows. New methods are added to submit, cancel, and view requests. The existing deposit, mint, withdraw and redeem methods are re-used for claiming executed requests. Implementations can choose to make either deposit or redemption flows asynchronous, or both.

## Motivation

The Tokenized Vaults standard has helped to make yield bearing tokens more composable across decentralized finance. The standard has a key assumption built in: that any deposit or redemption can be executed atomically up to a limit. If the limit is reached, no new deposits or redemptions can be submitted.

This limitation does not work well for undercollateralized lending protocols, real world asset protocols, or cross-chain lending protocols. An extension is required which enables users to lock deposit or redemption requests, to be executed asynchronously, and later collected by the existing deposit, mint, withdraw and redeem methods.

## Specification
EIP-X asynchronous tokenized vaults MAY implement asynchronous deposit and redemption flows, or make only one of either asynchronous and use the EIP-4626 standard synchronous flow for the other. Therefore, all methods below are optional. If `requestDeposit` is included,  `pendingDepositRequest` is also required. If `requestRedeem` is included, `pendingRedeemRequest` is also required.

All EIP-X asynchronous tokenized vaults MUST implement EIP-4626, with two exceptions:
1. The `deposit` and`mint` methods in asynchronous tokenized vaults differ from the the EIP-4626 defined standard in that there is no transfer of `asset` to the vault, because this already happened on `requestDeposit`.
2. The `redeem` and `withdraw` methods in asynchronous tokenized vaults differ from the the EIP-4626 defined standard in that there is no transfer of `shares` to the vault, because this already happened on `requestRedeem`. Also, `owner` must be `msg.sender` for the same reason.

### Definitions:
The existing definitions from [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626) apply.

### Methods
#### requestDeposit
Locks `assets` into the Vault and submits a request to receive `shares` Vault shares. When the request is fulfilled, `maxDeposit` and `maxMint` will be increased and `deposit` or `mint` from EIP-4626 can be used to receive `shares`.

MUST support EIP-20 `approve` / `transferFrom` on `asset` as a deposit flow.

The `shares` that will be received on `deposit` or `mint` MAY NOT be equivalent to the current value of `convertToShares(assets)`, as the price can change between request and execution.

Note that most implementations will require pre-approval of the Vault with the Vault's underlying `asset` token.

MUST emit the `RequestDeposit` event.

```yaml
- name: requestDeposit
  type: function
  stateMutability: nonpayable

  inputs:
    - name: assets
      type: uint256
```

#### requestRedeem
Locks `shares` into the Vault and submits a request to receive `assets` of underlying tokens. When the request is fulfilled, `maxRedeem` and `maxWithdraw` will be increased and `redeem` or `withdraw` from EIP-4626 can be used to receive `assets`.

The `assets` that will be received on `redeem` or `withdraw` MAY NOT be equivalent to the current value of `convertToAssets(shares)`, as the price can change between request and execution.

MUST support a redeem request flow where the shares are transferred from `owner` directly where `owner` is `msg.sender`.

MUST support a redeem request flow where the shares are transferred from `owner` directly where `msg.sender` has EIP-20 approval over the shares of `owner`.

SHOULD check `msg.sender` can spend owner funds using allowance.

MUST emit the `RequestRedeem` event.

```yaml
- name: requestRedeem
  type: function
  stateMutability: nonpayable

  inputs:
    - name: shares
      type: uint256
    - name: owner
      type: address
```

#### cancelDepositRequest
Submits an order to cancel the outstanding deposit request. When the cancel deposit request is fulfilled, `maxRedeem` and `maxWithdraw` will be increased and `redeem` or `withdraw` from EIP-4626 can be used to receive `assets` that were previously locked for deposit.

MUST emit the `CancelDepositRequest` event.

```yaml
- name: cancelDepositRequest
  type: function
  stateMutability: nonpayable
```

#### cancelRedeemRequest
Submits an order to cancel the outstanding redeem request. When the cancel redemption request is fulfilled, `maxDeposit` and `maxMint` will be increased and `deposit` or `mint` from EIP-4626 can be used to receive `shares` that were previously locked for redemption.

MUST emit the `CancelRedeemRequest` event.

```yaml
- name: cancelRedeemRequest
  type: function
  stateMutability: nonpayable
```

#### pendingDepositRequest
The amount of assets that the owner has requested to deposit but is not ready to be claimed using `deposit` or `mint`.

MUST NOT show any variations depending on the caller.

MUST NOT revert unless due to integer overflow caused by an unreasonably large input.

```yaml
- name: pendingDepositRequest
  type: function
  stateMutability: view

  inputs:
    - name: owner
      type: address

  outputs:
    - name: assets
      type: uint256
```

#### pendingRedeemRequest
The amount of shares that the owner has requested to redeem but is not ready to be claimed using `redeem` or `withdraw`.

MUST NOT show any variations depending on the caller.

MUST NOT revert unless due to integer overflow caused by an unreasonably large input.

```yaml
- name: pendingRedeemRequest
  type: function
  stateMutability: view

  inputs:
    - name: owner
      type: address

  outputs:
    - name: assets
      type: uint256
```

### Interface
:::info
:bulb: To be removed before publication
:::

```solidity=
interface IERC4626Async is IERC4626 {
    event DepositRequest(address indexed sender, address indexed owner, uint256 assets);
    event RedeemRequest(address indexed sender, address indexed owner, uint256 shares);
    event CancelDepositRequest(address indexed owner);
    event CancelRedeemRequest(address indexed owner);

    // 1. Increases the deposit/redeem request

    /// @dev user requests to deposit assets and mint shares to owner
    /// @notice same as deposit, but emits DepositRequest
    function requestDeposit(uint256 assets) external; 

    /// @dev user requests to burn shares from owner send underlying tokens to owner
    /// @notice same as redeem, but emits WithdrawRequest
    function requestRedeem(uint256 shares, address owner) external;

    // 2. Cancels the outstanding deposit/redeem request

    /// @dev user reduces outstanding request to deposit assets and mint shares to owner to 0
    /// @notice emits CancelDepositRequest
    function cancelDepositRequest() external;

    /// @dev user reduces outstanding request to burn shares from owner send underlying tokens to owner to 0
    /// @notice emits CancelWithdrawRequest
    function cancelRedeemRequest() external;

    // 3. Retrieve the outstanding deposit/redeem request

    /// @dev view the total amount the user has requested to deposit but hasn't been yet
    function pendingDepositRequest(address owner) external view returns (uint256 assets);

    /// @dev view the total amount the user has requested to redeem but hasn't been yet
    function pendingRedeemRequest(address owner) external view returns (uint256 shares);
}
```

## Rationale

TODO

## Backwards Compatibility

The interface is fully backwards compatible with [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626). The specification of the `deposit`, `mint`, `redeem`, and `withdraw` method is different as described in [Specification](##Specification).

## Reference Implementation

Centrifuge has been developing [an implementation](https://github.com/centrifuge/liquidity-pools/blob/72f1ddddf3493db5e166f6c3317a6a5c27675eeb/src/LiquidityPool.sol) that can provide a reference.

## Security Considerations

The methods `userDepositRequest` and `userRedeemRequest` are estimates useful for display purposes, and can be outdated due to the asynchronicity.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).