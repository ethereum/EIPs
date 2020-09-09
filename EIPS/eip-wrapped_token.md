---
eip: <to be assigned>
title: Wrapped token inspection
author: David Mihal (@dmihal)
discussions-to: <URL>
status: Draft
type: Standards Track
category (*only required for Standard Track): ERC
created: 2020-08-05
---

## Simple Summary
Defines a standard interface for viewing the addresses and balances of wrapped tokens.

## Abstract
Many projects have emerged that create new assets by wrapping existing tokens. However, it can be difficult for applications to easily query which tokens are wrapped, and how much of each token is associated with the holder of the wrapper token.

This EIP introduces a simple interface for exposing the addresses of all wrapped tokens, as well as querying wrapped token balances.

## Motivation
Many projects, particularly in decentralized finance, have created new assets by wrapping existing tokens. This includes, but is not limited to:

* Liquidity pool tokens for automated market makers (Uniswap, Balancer)
* Interest-bearing lending tokens (Compound cTokens, Aave aTokens)
* Managed investment tokens (Set Protocol, yEarn vaults)
* Utility wrapper tokens (DeFi777)

While these tokens enable many new applications and financial primitives, they present a number of challenges for wallets and other applications. 

### Example

For example, if a user deposits tokens in a Uniswap pool, they will receive liquidity provider (LP) tokens. The user’s balance of these LP tokens does not provide information about the pooled tokens, so the user can not know how many funds are held in the pool without visiting the Uniswap dapp.

If Uniswap implemented this EIP, then wallets could look up the wrapped tokens and display them as part of their UI. They could also query the market price data for the wrapped tokens, allowing them to calculate the market value of the LP token.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

```solidity
 
pragma solidity ^0.5.0;

contract WrapperToken {
  /**
   * @dev Should return a list of addresses for tokens that may be wrapped by this contract
   *
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST allow external calls
   */ 
  function wrappedTokens() external view returns (address[] memory);

  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param wrappedToken The address of a token
   * @param holder The address of the account holding a wrapper token
   *
   * MUST return the bytes4 magic value 0x1626ba7e when function passes.
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST return 0 if the user holds 0 wrapper tokens
   * MUST return 0 if the queried token is not wrapped by this contract
   * MUST allow external calls
   */ 
  function wrappedBalanceOf(
    address wrappedToken, 
    address holder)
    public
    view 
    returns (uint256 balance);
}

```

## Rationale
The specification first defines a simple view function that returns an array of addresses that can be queried. This function alone is useful for any application that wants to easily identify and display wrapper tokens (such as block explorers like Etherscan).

The wrappedBalanceOf function allows querying the amount of each wrapped token that is currently allocated to a user. This function is useful for wallets and portfolio trackers to query and display underlying token balances.

These two functions will typically be used together: an application will first query the list of wrapped tokens, then query the wrapped balance of each token for a given token holder.

### Introspection

Contracts implementing this standard should make their interface available, either using ERC165 or ERC1820 (to be determined by community feedback).

## Backwards Compatibility

This EIP is backwards compatible with all existing contracts, as it only provides new view functions. It does not alter the contract state, behavior or any existing methods.

## Implementation
The following is an example of how this EIP could be implemented in the Uniswap V2 UniswapV2Pair contract:

```solidity
contract UniswapV2Pair is UniswapV2ERC20, IWrappedToken {
  address public token0;
  address public token1;

  function wrappedTokens() public view returns (address[] memory) {
    address[] tokens = new address[](2);
    tokens[0] = token0;
    tokens[1] = token1;
    return tokens;
  }

  function wrappedBalanceOf(address wrappedToken, address holder) 
      public view returns (uint256 balance) {
    if (wrappedToken != token0 && wrappedToken != token1) {
      return 0;
    }

    uint256 balance = IERC20(wrappedToken).balanceOf(address(this));
    uint liquidity = balanceOf[holder];

    return liquidity.mul(balance).div(_totalSupply);
  }
}
```

## Security Considerations

This EIP does not introduce any significant security concerns, as it simply standardizes the access to information that is already available in many contracts.

It should be noted that this EIP does not enforce any guarantees about the validity of the information provided. A token could easily report inaccurate balance data, potentially misleading or scamming users.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
