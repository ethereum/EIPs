---
eip: 3386
title: ERC-721 and ERC-1155 to ERC-20 Wrapper
author: Calvin Koder (@ashrowz)
discussions-to: https://github.com/ethereum/EIPs/issues/3384
status: Draft
type: Standards Track
category: ERC
created: 2021-03-12
requires: 165
---

## Simple Summary
A standard interface for contracts that create generic ERC-20 tokens which derive from a pool of unique ERC-721/ERC-1155 tokens.

## Abstract

This standard outlines a smart contract interface to wrap identifiable tokens with fungible tokens. This allows for derivative [ERC-20](./eip-20.md) tokens to be minted by locking the base [ERC-721](./eip-721.md) non-fungible tokens and [ERC-1155](./eip-1155.md) multi tokens into a pool. The derivative tokens can be burned to redeem base tokens out of the pool. These derivatives have no reference to the unique id of these base tokens, and should have a proportional rate of exchange with the base tokens. As representatives of the base tokens, these generic derivative tokens can be traded and otherwise utilized according to ERC-20, such that the unique identifier of each base token is irrelevant.

ERC-721 and ERC-1155 tokens are considered valid base, tokens because they have unique identifiers and are transferred according to similar rules. This allows for both ERC-721 NFTs and ERC-1155 Multi-Tokens to be wrapped under a single common interface.

## Motivation

The ERC-20 token standard is the most widespread and liquid token standard on Ethereum. ERC-721 and ERC-1155 tokens on the other hand can only be transferred by their individual ids, in whole amounts. Derivative tokens allow for exposure to the base asset while benefiting from contracts which utilize ERC-20 tokens. This allows for the base tokens to be fractionalized, traded and pooled generically on AMMs, collateralized, and be used for any other ERC-20 type contract. Several implementations of this proposal already exist without a common standard.

Given a fixed exchange rate between base and derivative tokens, the value of the derivative token is proportional to the floor price of the pooled tokens. With the derivative tokens being used in AMMs, there is opportunity for arbitrage between derived token markets and the base NFT markets. By specifying a subset of base tokens which may be pooled, the difference between the lowest and highest value token in the pool may be minimized. This allows for higher value tokens within a larger set to be poolable. Additionally, price calculations using methods such as Dutch auctions, as implemented by NFT20, allow for price discovery of subclasses of base tokens. This allows the provider of a higher value base token to receive a proportionally larger number of derivative tokens than a token worth the floor price would receive.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

**Every IWrapper compliant contract must implement the `IWrapper` and `ERC165` interfaces** :


```solidity
pragma solidity ^0.8.0;

/**
    @title IWrapper Identifiable Token Wrapper Standard
    @dev {Wrapper} refers to any contract implementing this interface.
    @dev {Base} refers to any ERC-721 or ERC-1155 contract. It MAY be the {Wrapper}.
    @dev {Pool} refers to the contract which holds the {Base} tokens. It MAY be the {Wrapper}.
    @dev {Derivative} refers to the ERC-20 contract which is minted/burned by the {Wrapper}. It MAY be the {Wrapper}.
    @dev All uses of "single", "batch" refer to the number of token ids. This includes individual ERC-721 tokens by id, and multiple ERC-1155 by id. An ERC-1155 `TransferSingle` event may emit with a `value` greater than `1`, but it is still considered a single token.
    @dev All parameters named `_amount`, `_amounts` refer to the `value` parameters in ERC-1155. When using this interface with ERC-721, `_amount` MUST be 1, and `_amounts` MUST be either an empty list or a list of 1 with the same length as `_ids`.
*/
interface IWrapper /* is ERC165 */ {
    /**
     * @dev MUST emit when a mint occurs where a single {Base} token is received by the {Pool}.
     * The `_from` argument MUST be the address of the account that sent the {Base} token.
     * The `_to` argument MUST be the address of the account that received the {Derivative} token(s).
     * The `_id` argument MUST be the id of the {Base} token transferred.
     * The `_amount` argument MUST be the number of {Base} tokens transferred.
     * The `_value` argument MUST be the number of {Derivative} tokens minted.
     */
    event MintSingle (address indexed _from, address indexed _to, uint256 _id, uint256 _amount, uint256 _value);

    /**
     * @dev MUST emit when a mint occurs where multiple {Base} tokens are received by the {Wrapper}.
     * The `_from` argument MUST be the address of the account that sent the {Base} tokens.
     * The `_to` argument MUST be the address of the account that received the {Derivative} token(s).
     * The `_ids` argument MUST be the list ids of the {Base} tokens transferred.
     * The `_amounts` argument MUST be the list of the numbers of {Base} tokens transferred.
     * The `_value` argument MUST be the number of {Derivative} tokens minted.
     */
    event MintBatch (address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts, uint256 _value);

    /**
     * @dev MUST emit when a burn occurs where a single {Base} token is sent by the {Wrapper}.
     * The `_from` argument MUST be the address of the account that sent the {Derivative} token(s).
     * The `_to` argument MUST be the address of the account that received the {Base} token.
     * The `_id` argument MUST be the id of the {Base} token transferred.
     * The `_amount` argument MUST be the number of {Base} tokens transferred.
     * The `_value` argument MUST be the number of {Derivative} tokens burned.
     */
    event BurnSingle (address indexed _from, address indexed _to, uint256 _id, uint256 _amount, uint256 _value);

    /**
     * @dev MUST emit when a mint occurs where multiple {Base} tokens are sent by the {Wrapper}.
     * The `_from` argument MUST be the address of the account that sent the {Derivative} token(s).
     * The `_to` argument MUST be the address of the account that received the {Base} tokens.
     * The `_ids` argument MUST be the list of ids of the {Base} tokens transferred.
     * The `_amounts` argument MUST be the list of the numbers of {Base} tokens transferred.
     * The `_value` argument MUST be the number of {Derivative} tokens burned.
     */
    event BurnBatch (address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts, uint256 _value);

    /**
     * @notice Transfers the {Base} token with `_id` from `msg.sender` to the {Pool} and mints {Derivative} token(s) to `_to`.
     * @param _to       Target address.
     * @param _id       Id of the {Base} token.
     * @param _amount   Amount of the {Base} token.
     *
     * Emits a {MintSingle} event.
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    /**
     * @notice Transfers `_amounts[i]` of the {Base} tokens with `_ids[i]` from `msg.sender` to the {Pool} and mints {Derivative} token(s) to `_to`.
     * @param _to       Target address.
     * @param _ids      Ids of the {Base} tokens.
     * @param _amounts  Amounts of the {Base} tokens.
     *
     * Emits a {MintBatch} event.
     */
    function batchMint(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Burns {Derivative} token(s) from `_from` and transfers `_amounts` of some {Base} token from the {Pool} to `_to`. No guarantees are made as to what token is withdrawn.
     * @param _from     Source address.
     * @param _to       Target address.
     * @param _amount   Amount of the {Base} tokens.
     *
     * Emits either a {BurnSingle} or {BurnBatch} event.
     */
    function burn(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     * @notice Burns {Derivative} token(s) from `_from` and transfers `_amounts` of some {Base} tokens from the {Pool} to `_to`. No guarantees are made as to what tokens are withdrawn.
     * @param _from     Source address.
     * @param _to       Target address.
     * @param _amounts  Amounts of the {Base} tokens.
     *
     * Emits either a {BurnSingle} or {BurnBatch} event.
     */
    function batchBurn(
        address _from,
        address _to,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Burns {Derivative} token(s) from `_from` and transfers `_amounts[i]` of the {Base} tokens with `_ids[i]` from the {Pool} to `_to`.
     * @param _from     Source address.
     * @param _to       Target address.
     * @param _id       Id of the {Base} token.
     * @param _amount   Amount of the {Base} token.
     *
     * Emits either a {BurnSingle} or {BurnBatch} event.
     */
    function idBurn(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    /**
     * @notice Burns {Derivative} tokens from `_from` and transfers `_amounts[i]` of the {Base} tokens with `_ids[i]` from the {Pool} to `_to`.
     * @param _from     Source address.
     * @param _to       Target address.
     * @param _ids      Ids of the {Base} tokens.
     * @param _amounts   Amounts of the {Base} tokens.
     *
     * Emits either a {BurnSingle} or {BurnBatch} event.
     */
    function batchIdBurn(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;
}
```

## Rationale

### Naming

The ERC-721/ERC-1155 tokens which are pooled are called {Base} tokens. Alternative names include:
- Underlying.
- NFT. However, ERC-1155 tokens may be considered "semi-fungible".

The ERC-20 tokens which are minted/burned are called {Derivative} tokens. Alternative names include:
- Wrapped.
- Generic.

The function names `mint` and `burn` are borrowed from the minting and burning extensions to ERC-20. Alternative names include:
- `mint`/`redeem` ([NFTX](https://nftx.org))
- `deposit`/`withdraw` ([WrappedKitties](https://wrappedkitties.com/))
- `wrap`/`unwrap` ([MoonCatsWrapped](https://etherscan.io/address/0x7c40c393dc0f283f318791d746d894ddd3693572))

The function names `*idBurn` are chosen to reduce confusion on what is being burned. That is, the {Derivative} tokens are burned in order to redeem the id(s).

The wrapper/pool itself can be called an "Index fund" according to NFTX, or a "DEX" according to [NFT20](https://nft20.io). However, the {NFT20Pair} contract allows for direct NFT-NFT swaps which are out of the scope of this standard.

### Minting
Minting requires the transfer of the {Base} tokens into the {Pool} in exchange for {Derivative} tokens. The {Base} tokens deposited in this way MUST NOT be transferred again except through the burning functions. This ensures the value of the {Derivative} tokens is representative of the value of the {Base} tokens.

Alternatively to transferring the {Base} tokens into the {Pool}, the tokens may be locked as collateral in exchange for {Derivative} loans, as proposed in NFTX litepaper, similarly to Maker vaults. This still follows the general minting pattern of removing transferability of the {Base} tokens in exchange for {Derivative} tokens.

### Burning
Burning requires the transfer of {Base} tokens out of the {Pool} in exchange for burning {Derivative} tokens. The burn functions are distinguished by the quantity and quality of {Base} tokens redeemed. 
- For burning without specifying the `id`: `burn`, `batchBurn`.
- For burning with specifying the `id`(s): `idBurn`, `batchIdBurn`.

By allowing for specific ids to be targeted, higher value {Base} tokens may be selected out of the pool. NFTX proposes an additional fee to be applied for such targeted withdrawals, to offset the desire to drain the {Pool} of {Base} tokens worth more than the floor price.

### Pricing
Prices should not be necessarily fixed. therefore, Mint/Burn events MUST include the ERC-20 `_value` minted/burned.

Existing pricing implementations are as follows (measured in base:derivative):
- Equal: Every {Base} costs 1 {Derivative}
    - NFTX
    - Wrapped Kitties
- Proportional
    - NFT20 sets a fixed rate of 100 {Base} tokens per {Derivative} token.
- Variable
    - NFT20 also allows for Dutch auctions when minting.
    - NFTX proposes an additional fee to be paid when targeting the id of the {Base} token.

Due to the variety of pricing implementations, the Mint\* and Burn\* events MUST include the number {Derivative} tokens minted/burned.

### Inheritance
#### ERC-20
The {Wrapper} MAY inherit from {ERC20}, in order to directly call `super.mint` and `super.burn`.
If the {Wrapper} does not inherit from {ERC20}, the {Derivative} contract MUST be limited such that the {Wrapper} has the sole power to `mint`, `burn`, and otherwise change the supply of tokens.

#### ERC721Receiver, ERC1155Receiver
If not inheriting from {ERC721Receiver} and/or {ERC1155Receiver}, the pool MUST be limited such that the base tokens can only be transferred via the Wrapper's `mint`, `burn`.

There exists only one of each ERC-721 token of with a given (address, id) pair. However, ERC-1155 tokens of a given (address, id) may have quantities greater than 1. Accordingly, the meaning of "Single" and "Batch" in each standard varies. In both standards, "single" refers to a single id, and "batch" refers to multiple ids. In ERC-1155, a single id event/function may involve multiple tokens, according to the `value` field.

In building a common set of events and functions, we must be aware of these differences in implementation. The current implementation treats ERC-721 tokens as a special case where, in reference to the quantity of each {Base} token:
- All parameters named `_amount`, MUST be `1`.
- All parameters named `_amounts` MUST be either an empty list or a list of `1` with the same length as `_ids`.

This keeps a consistent enumeration of tokens along with ERC-1155. Alternative implementations include:
- A common interface with specialized functions. EX: `mintFromERC721`.
- Separate interfaces for each type. EX: `ERC721Wrapper`, `ERC1155Wrapper`.

#### ERC721, ERC1155
The {Wrapper} MAY inherit from {ERC721} and/or {ERC1155} in order to call `super.mint`, directly. This is optional as minting {Base} tokens is not required in this standard. An "Initial NFT Offering" could use this to create a set of {Base} tokens within the contract, and directly distribute {Derivative} tokens.

If the {Wrapper} does not inherit from {ERC721} or {ERC1155}, it MUST include calls to {IERC721} and {IERC1155} in order to transfer {Base} tokens.

### Approval
All of the underlying transfer methods are not tied to the {Wrapper}, but rather call the ERC-20/721/1155 transfer methods. Implementations of this standard MUST:
- Either implement {Derivative} transfer approval for burning, and {Base} transfer approval for minting.
- Or check for Approval outside of the {Wrapper} through {IERC721} / {IERC1155} before attempting to execute.

## Backwards Compatibility
Most existing implementations inherit from ERC-20, using functions `mint` and `burn`.
Events:
- Mint
    - WK: DepositKittyAndMintToken
    - NFTX: Mint

- Burn
    - WK: BurnTokenAndWithdrawKity
    - NFTX: Redeem

## Reference Implementation
[ERC-3386 Reference Implementation](https://github.com/ashrowz/erc-3386)

## Security Considerations
Wrapper contracts are RECOMMENDED to inherit from burnable ERC-20 tokens. If they are not, the supply of the {Derivative} tokens MUST be controlled by the Wrapper. Similarly, price implementations MUST ensure that the supply of {Base} tokens is reflected by the {Derivative} tokens.

With the functions `idBurn`, `idBurns`, users may target the most valuable NFT within the generic lot.  If there is a significant difference between tokens values of different ids, the contract SHOULD consider creating specialized pools (NFTX) or pricing (NFT20) to account for this.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
