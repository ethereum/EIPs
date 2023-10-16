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

The following standard extends [ERC-4626](./eip-4626.md) by adding support for asynchronous deposit and redemption flows. The async flows are called "Requests".

New methods are added to submit, cancel, and view pending Requests. The existing deposit, mint, withdraw, and redeem ERC-4626 methods are used for executing claimable Requests. Implementations can choose to add asynchronous flows for deposit and/or redemption. Cancelling a pending Request is also optionally defined in the spec.

## Motivation

The ERC-4626 Tokenized Vaults standard has helped to make yield-bearing tokens more composable across decentralized finance. The standard is optimized for atomic deposits and redemptions up to a limit. If the limit is reached, no new deposits or redemptions can be submitted.

This limitation does not work well for any smart contract system with asynchronous actions or delays as a prerequisite for interfacing with the Vault (e.g. real-world asset protocols, undercollateralized lending protocols, cross-chain lending protocols, liquid staking tokens, or insurance safety modules). 

This standard expands the utility of 4626 Vaults for asynchronous use cases. The existing Vault interface (deposit/withdraw/mint/redeem) is fully utilized to claim asynchronous Requests.

## Specification

### Definitions:
The existing definitions from [ERC-4626](./eip-4626.mn) apply. In addition, this spec defines:
- request: a function call that initiates an asynchronous deposit/redemption flow
- fulfill: the Vault's step of executing the request and enabling the user to claim the outcome of the request
- claim: the corresponding Vault method to complete a request (e.g. `deposit` claims `shares` from `requestDeposit`)
- pending request: the state where a request has been made but is not yet claimable
- asynchronous deposit Vault: a Vault that implements asynchronous requests for deposit flows
- asynchronous redemption Vault: a Vault that implements asynchronous redemption flows
- fully asynchronous Vault: a vault that implements asynchronous requests for both deposit and redemption

### Request Flows
EIP-X vaults MUST implement one or both of asynchronous deposit and redemption request flows. If either flow is not implemented in a request pattern, it MUST use the ERC-4626 standard synchronous interaction pattern. 

All EIP-X asynchronous tokenized vaults MUST implement ERC-4626, with the following overrides for request flows:
1. In asynchronous deposit Vaults, the `deposit` and `mint` methods do not transfer  `asset` to the vault, because this already happened on `requestDeposit`.
2. In asynchronous redemption Vaults, the `redeem` and `withdraw` methods do not transfer `shares` to the vault, because this already happened on `requestRedeem`. 
3. In asynchronous redemption Vaults, the `owner` field of `redeem` and `withdraw` MUST be `msg.sender` to prevent the theft of requested redemptions by a nonowner.

### Request Lifecycle
After submission, Requests go through Pending, Claimable, and Claimed stages. An example lifecycle for a deposit request is visualized in the table below.

| **State** | **User**                         |                                                                                                                **Vault** |
| ---------:|:-------------------------------- | ------------------------------------------------------------------------------------------------------------------------:|
|   Pending | requestDeposit(assets, operator) |                               asset.transferFrom(msg.sender, vault, assets)<br>pendingDepositRequest[operator] += assets |
| Claimable |                                  | <i>Internal request fulfillment</i><br>pendingDepositRequest[msg.sender] -= assets<br>maxDeposit[operator] += assets<br> |
|   Claimed | deposit(assets, receiver)        |                                                  maxDeposit[msg.sender] -= assets<br>vault.balanceOf[receiver] += shares |

The requested amount is defined by `pendingDepositRequest + maxDeposit`.

Requests MUST NOT skip step 2 and be automatically claimed, due to the ambiguity this creates for integrators. Instead there can be router contracts which atomically check for claimable amounts immediately upon request.

Note that for redemption requests, whether yield still accrues on shares that are pending a redemption request, or only on shares that are pending a redemption request and have not been executed, is up to the Vault implementation.

### Methods
#### requestDeposit
Locks `assets` from `msg.sender` into the Vault and submits a request by `operator` to receive `shares` Vault shares. When the request is fulfilled, `maxDeposit` and `maxMint` will be increased, and `deposit` or `mint` from ERC-4626 can be used to receive `shares`.

MUST support ERC-20 `approve` / `transferFrom` on `asset` as a deposit flow.

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
    - name: operator
      type: address
```

#### requestRedeem
Locks `shares` from `owner` into the Vault and submits a request by `operator` to receive `assets` of underlying tokens. When the request is fulfilled, `maxRedeem` and `maxWithdraw` will be increased, and `redeem` or `withdraw` from ERC-4626 can be used to receive `assets`.

The `assets` that will be received on `redeem` or `withdraw` MAY NOT be equivalent to the current value of `convertToAssets(shares)`, as the price can change between request and execution.

MUST support a redeem request flow where the shares are transferred from `owner` directly where `owner` is `msg.sender`.

MUST support a redeem request flow where the shares are transferred from `owner` directly where `msg.sender` has ERC-20 approval over the shares of `owner`.

SHOULD check `msg.sender` can spend owner funds using allowance.

MUST emit the `RequestRedeem` event.

```yaml
- name: requestRedeem
  type: function
  stateMutability: nonpayable

  inputs:
    - name: shares
      type: uint256
    - name: operator
      type: address
    - name: owner
      type: address
```

#### cancelDepositRequest
Submits an order to cancel the outstanding deposit request. When the cancel deposit request is fulfilled, `maxRedeem` and `maxWithdraw` will be increased, and `redeem` or `withdraw` from ERC-4626 can be used to receive `assets` that were previously locked for deposit.

MUST emit the `CancelDepositRequest` event.

```yaml
- name: cancelDepositRequest
  type: function
  stateMutability: nonpayable
```

#### cancelRedeemRequest
Submits an order to cancel the outstanding redemption request. When the cancel redemption request is fulfilled, `maxDeposit` and `maxMint` will be increased, and `deposit` or `mint` from ERC-4626 can be used to receive `shares` that were previously locked for redemption.

MUST emit the `CancelRedeemRequest` event.

```yaml
- name: cancelRedeemRequest
  type: function
  stateMutability: nonpayable
```

#### pendingDepositRequest
The amount of `assets` that the operator has requested to deposit but is not ready to be claimed using `deposit` or `mint`.

MUST NOT show any variations depending on the caller.

MUST NOT revert unless due to integer overflow caused by an unreasonably large input.

```yaml
- name: pendingDepositRequest
  type: function
  stateMutability: view

  inputs:
    - name: operator
      type: address

  outputs:
    - name: assets
      type: uint256
```

#### pendingRedeemRequest
The amount of `shares` that the operator has requested to redeem but is not ready to be claimed using `redeem` or `withdraw`.

MUST NOT show any variations depending on the caller.

MUST NOT revert unless due to integer overflow caused by an unreasonably large input.

```yaml
- name: pendingRedeemRequest
  type: function
  stateMutability: view

  inputs:
    - name: operator
      type: address

  outputs:
    - name: shares
      type: uint256
```

### Events

#### DepositRequest

`sender` has locked `assets` in the Vault to request a deposit. `operator` controls this request.

MUST be emitted when a deposit request is submitted using the `requestDeposit` method.

```yaml
- name: DepositRequest
  type: event

  inputs:
    - name: sender
      indexed: true
      type: address
    - name: operator
      indexed: true
      type: address
    - name: assets
      indexed: false
      type: uint256
```

#### RedeemRequest

`sender` has locked `shares`, owned by `owner`, in the Vault to request a redemption. `operator` controls this request.

MUST be emitted when a redemption request is submitted using the `requestRedeem` method.

```yaml
- name: RedeemRequest
  type: event

  inputs:
    - name: sender
      indexed: true
      type: address
    - name: operator
      indexed: true
      type: address
    - name: owner
      indexed: true
      type: address
    - name: assets
      indexed: false
      type: uint256
```

#### CancelDepositRequest

`sender` has requested to cancel the pending deposit request.

MUST be emitted when a cancel deposit request is submitted using the `cancelDepositRequest` method.

```yaml
- name: CancelDepositRequest
  type: event

  inputs:
    - name: sender
      indexed: true
      type: address
    - name: assets
      indexed: false
      type: uint256
```

#### CancelRedeemRequest

`sender` has requested to cancel the pending redemption request.

MUST be emitted when a cancel redemption request is submitted using the `cancelRedeemRequest` method.

```yaml
- name: CancelRedeemRequest
  type: event

  inputs:
    - name: sender
      indexed: true
      type: address
    - name: assets
      indexed: false
      type: uint256
```

## Rationale

### Symmetry and Non-inclusion of requestWithdraw and requestMint

In ERC-4626, the spec was written to be fully symmetrical with respect to converting assets and shares by including deposit/withdraw and mint/redeem.

Due to the asynchronous nature of requests, the vault can only operate with certainty on the quantity that is fully known at the time of the request (`assets` for `deposit` and `shares` for `redeem`). The deposit request flow cannot work with a `mint` call, because the amount of `assets` for the requested `shares` amount may fluctuate before the fulfillment of the request. Likewise, the redemption request flow cannot work with a `withdraw` call.

### Parameter Choices for request vs claiming

Keeping track of parameters more complex than a single quantity such as `assets` or `shares` between request and claiming adds significant complexity to implementations for asynchronous vaults. Therefore, there is no `receiver` parameter in `requestDeposit` or `requestRedeem`.

### Optionality of flows and cancels

Certain use cases are only asynchronous on one flow but not the other between request and redeem. A good example of an asynchronous redemption vault is a liquid staking token. The unstaking period necessitates support for asynchronous withdrawals, however, deposits can be fully synchronous.

In many cases, canceling a request may not be straightforward or even technically feasible, therefore cancel operations are optional. Defining the cancel flow is still important for certain classes of use cases for which the fulfillment of a Request can take a considerable amount of time.

### Request Implementation flexibility

The standard is flexible enough to support a wide range of interaction patterns for request flows. Pending requests can be handled via internal accounting, globally or on per-user levels, use ERC-20 or [ERC-721](./eip-721.md), etc.

### Operator function parameter on requestDeposit and requestRedeem

To support flows where a smart contract manages the request lifecycle on behalf of a user, the `operator` parameter is included in the `requestDeposit` and `requestRedeem` functions. This is not called `owner` because the `assets` or `shares` are not transferred from this account on request submission, unlike the behaviour of an `owner` on `redeem`. It is also not called `receiver` because the `shares` or `assets` are not necessarily transferred on claiming the request, this can be chosen by the operator when they call `deposit`, `mint`, `redeem`, or `withdraw`.

## Backwards Compatibility

The interface is fully backwards compatible with [ERC-4626](https://eips.ethereum.org/EIPS/eip-4626). The specification of the `deposit`, `mint`, `redeem`, and `withdraw` methods is different as described in [Specification](##Specification).

## Reference Implementation

Centrifuge has been developing [an implementation](https://github.com/centrifuge/liquidity-pools/blob/72f1ddddf3493db5e166f6c3317a6a5c27675eeb/src/LiquidityPool.sol) that can provide a reference.

## Security Considerations

The methods `pendingDepositRequest` and `pendingRedeemRequest` are estimates useful for display purposes, and can be outdated due to the asynchronicity.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).