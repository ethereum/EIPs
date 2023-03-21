---
eip: <to be assigned>
title: Redeemable Tokens
description: A proposition for redeemable tokens
author: Lucaz Lindgren (@LucazFFz)
discussions-to: https://ethereum-magicians.org/t/eip-4365-redeemable-tokens/13441
status: Draft
type: Standards Track
category: ERC
created: 2023-03-20
requires: 165
---

## Abstract

This ERC outlines a smart contract interface that can represent any number of fungible and non-fungible redeemable token types. The standard builds upon the [ERC-1155](./eip-1155.md) standard borrowing many of the ideas introduced by it including support for multiple tokens within the same contract and batch operations.

Contrary to the ERC-1155 standard, this ERC does not enforce transferability as it recognizes situations where implementers might not want to allow it. Additionally, it introduces several extensions used to expand the functionality like the **Expirable extension** which provides a simple way to add an expiry date to tokens.

## Motivation

The core idea of this ERC is to standardize and simplify the development of redeemable tokens (tickets) on the Ethereum blockchain. The tokens can be redeemed in exchange for currency or access (the reward for redeeming is left to implementers). The tokens can be exchanged for real-world or digital rewards.

Example of use-cases for redeemable tokens:

- **General admission tickets** - Tickets allowing attendees entry to the event together with access to the regular event activities. This type of ticket could be fungible meaning they are interchangeable. The event can be held either physically or digitally.
- **VIP tickets** - All-access tickets that include everything the event offers with activities excluded from the general admission tickets to give the attendees a premium experience. These tickets can be non-fungible making every ticket unique and allowing each ticket to be connected to an individual artwork or likewise to incentivize purchasing VIP tickets instead.

Additionally, these tokens can be used to create, among others, vouchers, gift cards, and scratchcards.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

**Every smart contract implementing this ERC MUST implement the all of the functions in the `ERC4365` interface. Additionally, they MUST implement the ERC-165 `supportsInterface` function and MUST return the constant value `true` if the constant value `0x9d1da9d1` is passed through the `interfaceId` argument.**

```solidity
interface IERC4365 is IERC165 {
    /**
     * @dev Emitted when `amount` tokens of token type `id` are minted to `to` by `minter`.
     */
    event MintSingle(address indexed minter, address indexed to, uint256 indexed id, uint256 amount);

    /**
     * @dev Equivalent to multiple {MintSingle} events, where `minter` and `to` is the same for all token types.
     */
    event MintBatch(address indexed minter, address indexed to, uint256[] ids, uint256[] amounts);

    /**
     * @dev Emitted when `amount` tokens of token type `id` owned by `owner` are burned by `burner`.
     */
    event BurnSingle(address indexed burner, address indexed owner, uint256 indexed id, uint256 amount);

    /**
     * @dev Equivalent to multiple {BurnSingle} events, where `owner` and `burner` is the same for all token types.
     */
    event BurnBatch(address indexed burner, address indexed owner, uint256[] ids, uint256[] amounts);

    /**
     * @dev Emitted when `amount` of tokens of token type `id` are redeemed by `account`.
     */
    event Redeem(address indexed account, uint256 indexed id, uint256 amount);

    /**
     * @dev Returns the balance of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Returns the balance of `account` for a batch of token `ids`.
     */
    function balanceOfBatch(address account, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Returns the balance of multiple `accounts` for a batch of token `ids`.
     * This is equivalent to calling {balanceOfBatch} for several accounts in just one call.
     *
     * Requirements:
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBundle(address[] calldata accounts, uint256[][] calldata ids)
        external
        view
        returns (uint256[][] memory);

    /**
     * @dev Returns the balance of tokens of token type `id` redeemed by `account`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function balanceOfRedeemed(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Returns the balance of `account` for a batch of redeemed token `ids`.
     */
    function balanceOfRedeemedBatch(address account, uint256[] calldata ids) external view returns (uint256[] memory);

     /**
     * @dev Returns the balance of multiple `accounts` for a batch of redeemed token `ids`.
     * This is equivalent to calling {balanceOfRedeemedBatch} for several accounts in just one call.
     *
     * Requirements:
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfRedeemedBundle(address[] calldata accounts, uint256[][] calldata ids)
        external
        view
        returns (uint256[][] memory);

    /**
     * Redeem `amount` of token type `id` owned by `account`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * - `amount` together with `account` balance of redeemed token of token type `id`
     * cannot exceed `account` balance of token type `id`.
     */
    function redeem (address account, uint256 id, uint256 amount, bytes memory data) external;
}
```

In addition, in order for a contract to be compliant with this ERC, it MUST abide by the following:

- Implementers MAY enable token transfers to support functionality such as ticket reselling.
- Implementers MUST NOT allow tokens to be transferred between addresses after they have been redeemed.
- Implementers MUST allow token holders to redeem their tokens.
- Implementers MUST NOT allow token issuers to redeem the tokens they have issued.
- Implementers SHOULD allow token recipients to burn any token they receive.
- Implementers MAY enable token issuers to burn the tokens they issued.

**Smart contracts MUST implement all of the functions in the `ERC4365Receiver` interface to accept tokens being minted to them.**

The **URI Storage extension** is OPTIONAL for compliant smart contracts. This allows contracts to associate a unique URI for each token ID.

```solidity
interface IERC4365URIStorage is IERC4365 {
    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     */
    event URI(uint256 indexed id, string value);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `id` token.
     */
    function tokenURI(uint256 id) external view returns (string memory);
}
```

The **Expirable extension** is OPTIONAL for compliant smart contracts. This allows contracts to associate a unique expiry date for each token ID. Smart contracts implementing the `ERC4365Expirable` extension MUST abide by the following:

- Implementers MUST NOT allow tokens to be minted or redeemed if expired.

```solidity
interface IERC4365Expirable is IERC4365 {
    /**
     * @dev Sets the expiry date for the token of token type `id`.
     */
    function setExpiryDate(uint256 id, uint256 date) external;

    /**
     * @dev [Batched] version of {setExpiryDate}.
     */
    function setBatchExpiryDates(uint256[] memory ids, uint256[] memory dates) external;

    /**
     * @dev Returns the expiry date for the token of token type `id`.
     */
    function expiryDate(uint256 id) external view returns (uint256);

    /**
     * @dev Returns `true` or `false` depending on if the token of token type `id` has expired
     * by comparing the expiry date with `block.timestamp`.
     */
    function isExpired(uint256 id) external view returns (bool);
}
```

The **Supply extension** is OPTIONAL for compliant smart contracts. This allows contracts to associate a unique max supply for each token ID. Smart contracts implementing the `ERC4365Supply` extension MUST abide by the following:

- Implementers SHOULD NOT allow tokens to be minted if total supply exceeds max supply.
- Implementers SHOULD increment total supply upon minting and decrement upon burning.
- Implementers are RECOMMENDED to override the `_beforeMint` hook to increment total supply upon minting and decrement upon burning.

```solidity
interface IERC4365Payable is IERC4365 {
    /**
     * @dev Sets the price `amount` for the token of token type `id`.
     */
    function setPrice(uint256 id, uint256 amount) external;

    /**
     * @dev [Batched] version of {setPrice}.
     */
    function setBatchPrices(uint256[] memory ids, uint256[] memory amounts) external;

    /**
     * @dev Returns the price for the token type `id`.
     */
    function price(uint256 id) external view returns (uint256);
}
```

The **Payable extension** is OPTIONAL for compliant smart contracts. This allows contracts to associate a unique price for each token ID. Smart contracts implementing the `ERC4365Payable` extension MUST abide by the following:

- Implementers SHOULD require recipients to provide funding equal to the token price.

```solidity
interface IERC4365Supply is IERC4365 {
    /**
     * @dev Sets the max supply for the token of token type `id`.
     */
    function setMaxSupply(uint256 id, uint256 amount) external;

    /**
     * @dev [Batched] version of {setMaxSupply}.
     */
    function setBatchMaxSupplies(uint256[] memory ids, uint256[] memory amounts) external;

    /**
     * @dev Returns the total supply for token of token type `id`.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Returns the max supply for token of token type `id`.
     */
    function maxSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token of token type `id` exists, or not.
     */
    function exists(uint256 id) external view returns (bool);
}
```

## Rationale

### Overview

The proposed interface and implementation draw heavy inspiration from ERC-1155 which paved the way for managing multiple token types in the same smart contract reducing gas costs. It draws from the lessons and prior discussions which emerged from the standard and therefore inherits from its design and structure.

ERC-1155 presents multiple interesting features also applicable to redeemable tokens:

- Because one contract is able to hold multiple different token types, there is no need to deploy multiple contracts for each collection as with previous standards. This saves on deployment gas costs as well as reduces redundant bytecode on the Ethereum blockchain.
- ERC-1155 is fungibility-agnostic which means the same contract can manage both fungible and non-fungible token types.
- Batch operations are supported making it possible to mint or query the balance for multiple token ids within the same call.
- Eliminates the possibility to lock tokens in smart contracts due to the requirement for smart contracts to implement the `ERC1155TokenReceiver` interface.
- Smart contracts implementing the `ERC1155TokenReceiver` interface may reject an increase in balance.

This standard does not assume who has the power to mint/burn tokens nor under what condition the actions can occur. However, it requires that the token holders have the ability to redeem their tokens.

### Fungibility

This ERC, likewise ERC-1155, chooses to stay agnostic regarding the fungibility of redeemable Tokens. It recognizes that it may be useful in some cases to have both fungible and non-fungible redeemable tokens managed in the same contract.

One way to achieve non-fungible tokens is to utilize split ID bits reserving the top 128 bits of the 256 bits `id` parameter to represent the base token ID while using the bottom 128 bits to represent the index of the non-fungible to make it unique.

Alternatively, a more intuitive approach to represent non-fungible tokens is to allow a maximum value of 1 for each. This would reflect the real world, where unique items have a quantity of 1 and fungible items have a quantity greater than 1.

### Batch Operations

ERC-1155, likewise this ERC, conveniently supports batch operations, where a batch is represented by an array of token IDs and an amount for each token ID making it possible to for example mint multiple token IDs in one call.

However, a batch often time only concerns one address. While minting a batch of tokens to an address in one transaction is convenient, supporting the ability to mint to multiple addresses in one transaction is even more convenient. Therefore, this ERC support bundle operations. A bundle is simply a collection of batches where each batch have a seperate address.

### Transfer

This ERC does not enforce transferability between addresses except for minting and burning. However, it recognizes the possible need for it when for example implementing resell functionality and, therefore, does not prevent it.

### Redeem

The core addition to redeemable tokens is the possibility to redeem tokens in exchange for currency, access, etc. As tokens only can be redeemed by their holders a possible `redeemBatch` function has been excluded as it is not expected that a holder would want to redeem multiple token types simultaneously.

### Safe Mint Only

This ERC takes inspiration from the ERC-1155 standard and only supports safe-style transfers when minting tokens. This enables receiver contracts to depend on `ERC4365Mint` or `ERC4365MintBatch` functions to be called at the end of minting. This allows receivers to reject an increase in balance.

## Backwards Compatibility

Because of the heavy inspiration from the ERC-1155 standard many concepts and methods remain identical, namely the concept of a batch, the `balanceOf` and `balanceOfBatch` functions, and to some extent the URI Storage and Supply extensions.

## Reference Implementation

- [Reference implementation](../assets/eip-4365/)

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
