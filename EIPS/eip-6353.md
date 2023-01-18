---
eip: 6353
title: Charity token
description: Extension of EIP-20 Token that can be partially donated to a charity project
author: Aubay <blockchain-team@aubay.com>, BOCA Jeabby (@bjeabby1507), EL MERSHATI Laith (@lth-elm), KEMP Elia (@eliakemp)
discussions-to: https://ethereum-magicians.org/t/erc20-charity-token/12617
status: Draft
type: Standards Track
category: ERC
created: 2022-05-13
requires: 20
---

## Abstract

An extension to the [EIP-20](./eip-20.md) standard token that allows Token owners to donate to some charity organization. The following standard allows for the implementation of the standard token to enforce charity donation by default. This standard is an extension of the [EIP-20](./eip-20.md) token to provide transfers to a third-party charity during transactions. This standard also allows token that support [EIP-20](./eip-20.md) interface, to have a standardized way of signalling charity information, registered by the token contract.

## Motivation

The initial idea is to allow Token owners to easily donate passively, in order to facilitate contributions to non-profit organizations and facilitate integration by giving a generalized implementation. Users can make an impact with their token and can contribute to achieving sustainable blockchain development. It is the possibility to donate simply with micro-donation during transactions. Projects can easily retrieve charity donations addresses and rate for a given [EIP-20](./eip-20.md) token, token holders can compare minimum rate donation offers allowed by token contract owners.

## Specification

**EIP-20 compliant contract MAY implement this ERC for automatizing Mirco payment during transactions.**

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

Owner of the contract **MAY**, after review, register charity address in `whitelistedRate` and set globally a default rate of donation. To register the address, the rate **MUST** not be null.

Token holders **MAY** choose and specify a default charity address from `_defaultAddress`, this address **SHOULD** be different from the null address for the donation to be activated.

Token holders **MAY** choose a donation rate different from the default one, individually for a specific charity address, by modifying the rate in `_donation`.

Donations are calculated as a percentage of the amount of token transfered, this percentage is added to the initial amount of token transferred. `_feeDenominator()` is overridable but defaults to 10000, meaning the rate is specified in basis points by default but **MAY** be customizable just as the `_defaultRate()` that default to 10.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "./IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

///
/// @dev Required interface of an ERC20 Charity compliant contract.
///
interface IERC20charity is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    ///type(IERC20charity).interfaceId.interfaceId == 0x557512b6
    /// bytes4 private constant _INTERFACE_ID_ERCcharity = 0x557512b6;
    /// _registerInterface(_INTERFACE_ID_ERCcharity);

    
    /**
     * @dev Emitted when `toAdd` charity address is added to `whitelistedRate`.
     */
    event AddedToWhitelist (address toAdd);

    /**
     * @dev Emitted when `toRemove` charity address is deleted from `whitelistedRate`.
     */
    event RemovedFromWhitelist (address toRemove);

    /**
     * @dev Emitted when `_defaultAddress` charity address is modified and set to `whitelistedAddr`.
     */
    event DonnationAddressChanged (address whitelistedAddr);

    /**
     * @dev Emitted when `_defaultAddress` charity address is modified and set to `whitelistedAddr` 
    * and _donation is set to `rate`.
     */
    event DonnationAddressAndRateChanged (address whitelistedAddr,uint256 rate);

    /**
     * @dev Emitted when `whitelistedRate` for `whitelistedAddr` is modified and set to `rate`.
     */
    event ModifiedCharityRate(address whitelistedAddr,uint256 rate);
    
    /**
    *@notice Called with the charity address to determine if the contract whitelisted the address
    *and if it is the rate assigned.
    *@param addr - the Charity address queried for donnation information.
    *@return whitelisted - true if the contract whitelisted the address to receive donnation
    *@return defaultRate - the rate defined by the contract owner by default , the minimum rate allowed different from 0
    */
    function charityInfo(
        address addr
    ) external view returns (
        bool whitelisted,
        uint256 defaultRate
    );

    /**
    *@notice Add address to whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toAdd` cannot be the zero address.
     *
     * @param toAdd The address to whitelist.
     */
    function addToWhitelist(address toAdd) external;

    /**
    *@notice Remove the address from the whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toRemove` cannot be the zero address.
     *
     * @param toRemove The address to remove from whitelist.
     */
    function deleteFromWhitelist(address toRemove) external;

    /**
    *@notice Get all registered charity addresses.
     */
    function getAllWhitelistedAddresses() external ;

    /**
    *@notice Display for a user the rate of the default charity address that will receive donation.
     */
    function getRate() external view returns (uint256);

    /**
    *@notice Set personlised rate for charity address in {whitelistedRate}.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificRate(address whitelistedAddr , uint256 rate) external;

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     *
     * @param whitelistedAddr The address to set as default.
     */
    function setSpecificDefaultAddress(address whitelistedAddr) external;

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The rate is specified by the user.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate 
     * or to the rate specified by the owner of this contract in {whitelistedRate}.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificDefaultAddressAndRate(address whitelistedAddr , uint256 rate) external;

    /**
    *@notice Display for a user the default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
     */
    function specificDefaultAddress() external view returns (
        address defaultAddress
    );

    /**
    *@notice Delete The Default Address and so deactivate donnations .
     */
    function deleteDefaultAddress() external;
}

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

```

To create and deploy an `ERC20Charity` contract one MAY only inherit directly from this [EIP-20](./eip-20.md) extension that would directly signal support for `ERC20Charity` :

```solidity
pragma solidity ^0.8.4;
import "./ERC20Charity.sol";

contract CharityToken is ERC20Charity {
    // ...
    constructor() ERC20("TestToken", "TST") { }
    // ...
}
```

checking if a contract implement this specification can be done with :

```solidity
//import "./IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

bytes4 private constant _INTERFACE_ID_ERCcharity = type(IERC20charity).interfaceId; // 0x557512b6

function checkInterface(address testContract) external returns (bool) {
    (bool success) = IERC165(testContract).supportsInterface(_INTERFACE_ID_ERCcharity);
    return success;
}
```

```solidity
    mapping(address => uint256) public whitelistedRate; 
    mapping(address =>  mapping(address => uint256)) private _donation; 
    mapping (address =>address) private _defaultAddress; 

    address[] whitelistedAddresses; //Addresses whitelisted

    event AddedToWhitelist (address toAdd);
    event RemovedFromWhitelist (address toRemove);
    event DonnationAddressChanged (address whitelistedAddr);
    event DonnationAddressAndRateChanged (address whitelistedAddr,uint256 rate);
    event ModifiedCharityRate(address whitelistedAddr,uint256 rate)

```

### Functions

#### **addToWhitelist**

Add address to whitelist and set the rate to the default rate.

| Parameter | Description |
| ---------|-------------|
| toAdd | The address to the whitelist.

#### **deleteFromWhitelist**

Remove the address from the whitelist and set rate to the default rate.

| Parameter | Description |
| ---------|-------------|
| toRemove | The address to remove from whitelist.

#### **getAllWhitelistedAddresses**

Get all registered charity addresses.

#### **getRate**

Display for a user the rate of the default charity address that will receive donation.

#### **setSpecificRate**

Set personalized rate for charity address in {whitelistedRate}.

| Parameter | Description |
| ---------|-------------|
| whitelistedAddr | The address to set as default. |
| rate  | The personalised rate for donation. |

#### **_returnRate**

Return the rate to donate.

| Parameter | Description |
| ---------|-------------|
| from | The address to get the rate of donation.

#### **setSpecificDefaultAddress**

Set for a user a default charity address that will receive donations. The default rate specified in {whitelistedRate} will be applied.

| Parameter | Description |
| ---------|-------------|
| whitelistedAddr | The address to set as default.

#### **setSpecificDefaultAddressAndRate**

Set for a user a default charity address that will receive donations. The rate is specified by the user.

| Parameter | Description |
| ---------|-------------|
| whitelistedAddr | The address to set as default. |
| rate  | The personalized rate for donation.

#### **specificDefaultAddress**

Display for a user the default charity address that will receive donations. The default rate specified in {whitelistedRate} will be applied.

#### **deleteDefaultAddress**

Delete The Default Address and so deactivate donations.

#### **charityInfo**

Called with the charity address to determine if the contract whitelisted the address and if it is, the rate assigned.

| Parameter | Description |
| ---------|-------------|
| addr | The Charity address queried for donnation information.

## Rationale

This standard provides functionality that allows token holders to donate easily. The donation when activated is done directly in the overridden `transfer`, `transferFrom`, and `approve` functions.

The donation is a percentage-based rate model, but the calculation can be done differently. Also, donations could be in other functions than the `transfer` function.

 To manage the whitelist the owner of the contract can choose to whitelist charity addresses by using an array and keeping track of the "active" status with a mapping. The donation address can also be a single address chosen by the owner of the contract and modified by period.

 They can also choose to store the donation in the contract or in another and add a withdrawal or claimable function so the charity can claim the allocated amount of token themselves, so the transfer function will be triggered by the charity and not the token holder.

## Backwards Compatibility

There are no backward compatibility issues, this implementation is an extension of the functionality of [EIP-20](./eip-20.md). This EIP is fully backward compatible and introduces new functionality retaining the core interfaces and functionality of the [EIP-20](./eip-20.md) standard.

## Test Cases

Tests can be found under [test/](../assets/eip-6353/test/) folder.

## Reference Implementation

The reference implementation of the standard can be found under [contracts/](../assets/eip-6353/contracts/) folder.

## Security Considerations

There are no security considerations related directly to the implementation of this standard. It is to the discretion of the owner of the contract to review charity addresses before whitelisting them and to the token holders to determine whether setting this address as the `_defaultAddress` that will receive donations or not. Discussion with reviewers can still be found at `https://ethereum-magicians.org/t/erc20-charity-token/12617`.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
