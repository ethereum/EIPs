---
title: Upgradable ERC20
description: A simple standard for upgrading/downgrading ERC20 token contracts
author: Jeff Huang <jeffishjeff@gmail.com>
discussions-to: TODO
status: Draft
type: Standards Track
category: ERC
created: 2023-04-05
requires: 20
---

<!--
  READ EIP-1 (https://eips.ethereum.org/EIPS/eip-1) BEFORE USING THIS TEMPLATE!

  This is the suggested template for new EIPs. After you have filled in the requisite fields, please delete these comments.

  Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

  The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category.

  TODO: Remove this comment before submitting
-->

## Abstract

This standard outlines a smart contract interface for upgrading/downgrading existing ERC-20 smart contracts while maintaining user balances. The interface itself is an extension of the ERC-20 standard so that other contracts can continue to interact with the upgraded token without any change other than updating contract address.

## Motivation

By design, smart contracts are immutable and token standards like ERC-20 are minimalistic. While these design principles are fundamental in decentalized applications, there are sensible and practical situations where the ability to upgrade an ERC-20 token contract is desirable, such as:

- to address bugs and remove limitations
- to adopt new features and standards
- to comply w/ changing regulations

Proxy pattern using `delegatecall` opcode offers a reasonable, generalized solution to reconcile the immutability and upgradability features but has its own shortcomings:

- contracts must support the pattern from the get go, i.e. it cannot be used on contracts that were not deployed with proxies
- upgrades are silent and irreversible, i.e. users do not have the option to opt-out

In contrast, by reducing the scope to specifically ERC-20 contract, this proposal standardizes an ERC-20 extension that works with any existing or future ERC-20 contracts, is much simpler to implement and to maintain, can be reversed or nested, and offers a double confirmation opportunity for any and all users to explicitly opt-in on the upgrade.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

```solidity
pragma solidity ^0.8.0;

/**
    @title Upgradable ERC-20 Token Standard
    @dev See TODO: link to EIP page
 */
interface IUpgradableERC20 is IERC20 {
    /**
      @dev MUST be emitted when tokens are upgraded
      @param from Previous owner of underlying ERC-20 token
      @param to New owner of the UpgradableERC20 token
      @param amount The amount that is upgraded
    */
    event Upgrade(address indexed from, address indexed to, uint256 amount);

    /**
      @dev MUST be emitted when tokens are downgraded
      @param from Previous owner of UpgradableERC20 token
      @param to New owner of underlying ERC-20 token
      @param amount The amount that is downgraded
    */
    event Downgrade(address indexed from, address indexed to, uint256 amount);

    /**
      @notice Upgrade `amount` of underlying ERC-20 token owned by `msg.sender` to UpgradableERC20 token under `to`
      @dev `msg.sender` must directly own underlyting ERC-20 token
      MUST revert if `to` is the zero address
      MUST revert if `msg.sender` does not directly own `amount` or more of underlying ERC-20 token
      @param to The address to receive UpgradableERC20 token
      @param amount The amount of underlying ERC-20 token to upgrade
    */
    function upgrade(address to, uint256 amount) external;

    /**
      @notice Downgrade `amount` of UpgradableERC20 token owned by `from` to underlying ERC-20 token under `to`
      @dev `msg.sender` must either directly own or be approved to spend sufficient tokens for `from`
      MUST revert if `to` is the zero address
      MUST revert if `from` does not directly own `amount` or more of UpgradableERC20 token
      MUST revret if `msg.sender` is not `from` and not approved to spend sufficient tokens for `from`
      @param from The address to release UpgradableERC20 token
      @param to The address to receive underlying ERC-20 token
      @param amount The amount of UpgradableERC20 token to downgrade
    */
    function downgrade(address from, address to, uint256 amount) external;

    /**
      @notice Get the underlying ERC-20 token address
      @return The address of underlying ERC-20 token
    */
    function baseToken() external view returns (address);
}
```

### Pass-through Extension

The **pass-through extension** is OPTIONAL for IUpgradableERC20 smart contracts. It allows for easy viewing of combined states between UpgradableERC20 token and underlying ERC-20 token.

```solidity
pragma solidity ^0.8.0;

interface IUpgradableERC20PassThrough is IUpgradableERC20 {
  /**
    @notice Get the combined total token supply between UpgradableERC20 token and underlying ERC-20 token
    @return The combined total token supply
  */
  function combinedTotalSupply() external view returns (uint256);

  /**
    @notice Get the combined balance of `account` between UpgradableERC20 token and underlying ERC-20 token
    @param account The address that owns the tokens
    @return The combined token balance
  */
  function combinedBalanceOf(address account) external view returns (uint256);

  /**
    @notice Get the combined allowance of `spender` is allowed to spend for `owner` between UpgradableERC20 token and underlying ERC-20 token
    @param owner The address that owns the tokens
    @param spender The address that is approve to spend the tokens
    @return The combined spending allowance
  */
  function combinedAllowance(address owner, address spender) external view returns (uint256);
}

```

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

### Extending ERC-20 standard

The goal of this standard is to upgrade rather than to replace, therefore leveraging existing data structure and methods is the route of the least engineering efforts as well as the most interoperability.

### Supporting downgrade

The ability to downgrade offers a way to escape any bug or limitation in the UpgradableERC20 contract, as well as an escape route should user change his or her mind about opting in. It also makes moving between multiple IUpgradableERC20 implementations possible.

### Optional pass-through extension

While these functions are useful in many situations, they are trivial to implement and results can be calculated via other public functions, hence to include them in an optional extension rather than the core interface.

## Backwards Compatibility

UpgradableERC20 is generally compatible with ERC-20 standard. The only caveat is that some smart contracts may opt to implement `transfer` to work with the entire combined balance (this reduces user friction, see reference implementation) rather than the standard `balanceOf` amount. In this case it is RECOMMENDED that such contract to implement `balanceOf` the same as `combinedBalanceOf` (which is demonstrated in the reference implementation).

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

TODO

## Security Considerations

Needs discussion.

- User who opts to upgrade underlying ERC-20 tokens must first approve UpgradableERC20 contract to send them. Therefore it's the user's responsibility to verify that UpgradableERC20 contract implementation is sound and secure, and the amount that he or she is approving is approperiate. This represents the same security considerations as with any `approve` operation.
- The UpgradableERC20 may implement any conversion function for upgrade/downgrade purpose: 1-to-1, linear, non-linear. In the case of a non-linear conversion function, `upgrade` and `downgrade` may be vulnerable for front running or sandwich attacks (whether or not to the attacker's benefit). This represents the same security considerations as with any automated market maker (AMM) that uses a similar non-linear curve.
- UpgradableERC20 contracts may ask user to approve unlimited allowance and/or attempt to automatically upgrade during `transfer` (see reference implementation). This reduces the chance for user to triple confirm his or her upgrade intension (`approve` being the double confirmation).
- Multiple UpgradableERC20 can be applied to the same underlying ERC-20 token, and UpgradableERC20s can be nested. This may increase token complexity and cause existing dashboards to report incorrect or inconsistent results.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
