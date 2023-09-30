---
title: Token Bound Function Oracle AMM Contract
description: A Standard Interface System which wrap/unwrap betweem fungible tokens and non-fungible token based on an inbeded Function Oracle AMM to achieve decentralized credit endorsement.

author: Lanyin Zhang(lz8aj@virginia.edu), Jerry(jerrymindflow@gmail.com), FirstName (@GitHubUsername) and GitHubUsername (@GitHubUsername)>
discussions-to: <https://ethereum-magicians.org/t/eip-7797-token-bound-function-oracle-amm-contract/15950>
status: Draft
type: Standards Track
category: ERC
created: 2023-09-03
requires: <EIP number(s)> # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---


## Abstract

This proposal defines a system which embeds a Function Oracle that can wrap fungible tokens to non-fungible token and unwrap the non-fungible back to fungible tokens. The preset Function Oracle provides its own Automated Market Maker(AMM) so that it standardize the process of a creating pool for the issuer of vouchers.

## Motivation

The motivation behind a wrapping system with embedded Function Oracle AMM is to provide decentralized credit endorsement and thus quantifiable decentralized credit assets with liquidity. This creates an applicable infrastructure for credit creation, transmission, and oracle in payment, social, and financial context. Decentralized credit voucher can be implemented in the form of Non-fungible tokens, compatible with current Ethereum environment, which also expands its application scenarios. The concept of decentralized credit is highly integrated with dApps development. It aims to foster a more trustless environment.

Under current framework of pool, it is hard for user to define how to manage the pool without coding. However, we believe it should be more accessible for users to define and create their own pools to energize the market. Through employing FTs as premium for NFTs under a customizable framework, such an approach standardize the process of creating a pool and allows users to gain the ability to "do it yourself."

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Contract Interfaces: 
There are two interfaces SHALL be implemented as they are mutually bounded. One is an agency which wrap and unwrap the token with a function oracle, and another one is the wrapper, or the issuer of the vouchers.

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct Asset {
    address currency;
    uint256 amount;
    address payable feeRecipient;
    uint16 mintFeePercent;
    uint16 burnFeePercent;
}
interface IERC7Agency{
    /**
     * @dev Emitted when `tokenId` token is wrapped.
     * @param to The address of the recipient of the newly created non-fungible token.
     * @param tokenId The identifier of the newly created non-fungible token.
     * @param price The price of wrapping.
     * @param fee The fee of wrapping.
     */
    event Wrap(
        address indexed to,
        uint256 indexed tokenId,
        uint256 price,
        uint256 fee
    );

    /**
     * @dev Emitted when `tokenId` token is unwrapped.
     * @param to The address of the recipient of the currency.
     * @param tokenId The identifier of the non-fungible token to unwrap.
     * @param price The price of unwrapping.
     * @param fee The fee of unwrapping.
     */
    event Unwrap(
        address indexed to,
        uint256 indexed tokenId,
        uint256 price,
        uint256 fee
    );

    /**
     * @dev Allows the account to receive Ether
     *
     * Accounts MUST implement a `receive` function.
     *
     * Accounts MAY perform arbitrary logic to restrict conditions
     * under which Ether can be received.
     */
    receive() external payable;

    /**
     * @dev Wrap some amount of currency into a non-fungible token.
     * @param to The address of the recipient of the newly created non-fungible token.
     * @param data The data to encode into ifself and the newly created non-fungible token.
     * @return The identifier of the newly created non-fungible token.
     */
    function wrap(address to, bytes calldata data) external payable returns (uint256);

    /**
     * @dev Unwrap a non-fungible token into some amount of currency.
     *
     * Todo: event
     *
     * @param to The address of the recipient of the currency.
     * @param tokenId The identifier of the non-fungible token to unwrap.
     * @param data The data to encode into ifself and the non-fungible token with identifier `tokenId`.
     */
    function unwrap(address to, uint256 tokenId, bytes calldata data) external payable;

    /**
     * @dev Returns the strategy of the agency.
     * @return app The address of the app.
     * @return asset The asset of the agency.
     * @return attributeData The attributeData of the agency.
     */
    function getStrategy() external view returns(address app, Asset memory asset, bytes memory attributeData);

    /**
     * @dev Returns the price and fee of unwrapping.
     * @param data The data to encode to calculate the price and fee of unwrapping.
     * @return price The price of wrapping.
     * @return fee The fee of wrapping.
     */
    function getUnwrapOracle(bytes memory data) external view returns(uint256 price, uint256 fee);

    /**
     * @dev Returns the price and fee of wrapping.
     * @param data The data to encode to calculate the price and fee of wrapping.
     * @return price The price of wrapping.
     * @return fee The fee of wrapping.
     */
    function getWrapOracle(bytes memory data) external view returns(uint256 price, uint256 fee);
 }
 ```


``` 
 interface IERC7App{
    /**
     * @dev Returns the maximum supply of the non-fungible token.
     */
    function getMaxSupply() external view returns (uint256);

    /*
     * @dev Sets the maximum supply of the non-fungible token.
     * @param maxSupply The maximum supply of the non-fungible token.
     */
    function setMaxSupply(uint256 maxSupply) external;

    /**
     * @dev Returns the name of the non-fungible token with identifier `id`.
     * @param id The identifier of the non-fungible token.
     */
    function getName(uint256 id) external view returns (string memory);

    /**
     * @dev Returns the agency of the non-fungible token.
     */
    function getAgency() external view returns (address payable);

    /**
     * @dev Sets the agency of the non-fungible token.
     * @param agency The agency of the non-fungible token.
     */
    function setAgency(address payable agency) external;

    /**
     * @dev Mints a non-fungible token to `to`.
     * @param to The address of the recipient of the newly created non-fungible token.
     * @param data The data to encode into the newly created non-fungible token.
     */
    function mint(address to, bytes calldata data) external returns (uint256);

    /**
     * @dev Burns a non-fungible token with identifier `tokenId`.
     * @param tokenId The identifier of the non-fungible token to burn.
     * @param data The data to encode into the non-fungible token with identifier `tokenId`.
     */
    function burn(uint256 tokenId, bytes calldata data) external;
 }
```

## Rationale

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.



## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
