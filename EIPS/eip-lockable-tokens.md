---
eip: <to be assigned>
title: Lockable tokens
description: The extension for the ERC-20 and ERC-777 tokens to be locked for the lending purposes
author: Zionodes Team (@Zionodes), Ilya Shlyakhovoy (@bgrusnak)
discussions-to: https://ethereum-magicians.org/t/eip-draft-lockable-tokens/12488
status: Draft
type: Standards Track
category (*only required for Standards Track): ERC
created: 2023-01-08
---

## Abstract

This is standard to gave to the fungible tokens ability to be locked from the other users. It is needed in some cases, for example in a lending purposes.

## Motivation

There are a number of fungible tokens, which in addition to their value give additional benefits of various kinds when owning them. If such tokens must be pledged to obtain a loan, they are transferred to the lender's account, and the owner of the pledged tokens loses the ability to obtain the specified benefits. This extension of the ERC-20 and ERC-777 contracts allows a certain amount of tokens to be locked into the owner's account as collateral, preserving the lender's ability to collect the collateral if necessary.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Contract Interface

```solidity
interface ILockable {

    /// @notice     Trigger when tokens are locked, including zero value locks.
    event Lock(address indexed from_, address indexed to_, uint256 _value);

    /// @notice     Trigger when tokens are unlocked, including zero value unlocks.
    event Unlock(address indexed from_, address indexed to_, uint256 _value);

    /// @notice     Trigger on any successful approving call.
    event LockApproval(address indexed owner_, address indexed locker_, uint256 _value);

    /// @notice     Trigger on any successful collateral.
    event Collate(address indexed owner_, address indexed locker_, uint256 _value);

    /// @notice     Query of the amount of the all locked tokens for the address.
    /// @param      owner_ The tokens owner
    /// @return     The amount of the owned but locked tokens
    function lockedOf(address owner_) public view returns (uint256 balance);

    /// @notice     Query of the amount of the tokens, owned by the one address and locked by the second one.
    /// @param      owner_ The tokens owner
    /// @param      locker_ The address locked the tokens
    /// @return     The amount of the owned tokens, locked only in favor of the selected address
    function lockedFor(address owner_, address locker_) public view returns (uint256 balance);

    /// @notice     Lock the choosen amount of the tokens in favor of the caller
    /// @param      owner_ The tokens owner
    /// @param      amount_ The tokens summ
    /// @return     `true` if the lock was successful
    function lock(addres owner_, uint256 amount_) public view returns (bool success);

    /// @notice     Unlock the choosen amount of the tokens, locked previously by caller.
    /// @param      owner_ The tokens owner
    /// @param      amount_ The tokens summ
    /// @return     `true` if the unlock was successful
    function unlock(addres owner_, uint256 amount_) public view returns (bool success);

    /// @notice     Lock the choosen amount of the tokens owned by the caller in favor of the desired address
    /// @param      locker_ Who will lock the tokens
    /// @param      amount_ The tokens summ
    /// @return     `true` if the lock was successful
    function lockFor(addres locker_, uint256 amount_) public view returns (bool success);

    /// @notice     Unlock the choosen amount of the tokens owned by the caller and are locked by the selected address
    /// @param      locker_ Who are lock the tokens
    /// @param      amount_ The tokens summ
    /// @return     `true` if the unlock was successful
    function unlockFrom(address locker_, uint256 amount_) public returns (bool success);

    /// @notice     Allows `locker_` to lock the amount of the tokens multiple times, up to the `value_` amount. 
    /// @notice     If this function is called again it overwrites the current allowance with `value_`
    /// @param      locker_ Who are lock the tokens
    /// @param      value_ The possible locked tokens amount
    /// @return     `true` if the approve was successful
    function approveLock(address locker_, uint256 value_) public returns (bool success);

    /// @notice     Allows `owner_` to unlock it's tokens multiple times, up to the `value_` amount.
    /// @notice     If this function is called again it overwrites the current allowance with `value_`
    /// @param      owner_ Who are lock the tokens
    /// @param      value_ The possible locked tokens amount
    /// @return     `true` if the approve was successful
    function approveUnlock(address owner_, uint256 value_) public returns (bool success);

    /// @notice     Returns the amount which `owner_` is still allowed to unlock from `locker_`
    /// @param      owner_ The tokens owner
    /// @param      locker_ The address locked the tokens
    /// @return     The amount of the tokens, allowed to unlock in favor of the selected address
    function lockedAllowance(address owner_, address locker_) public view returns (uint256 remaining);

    /// @notice     Returns the amount which `locker_` is still allowed to lock from `owner_`.
    /// @param      owner_ The tokens owner
    /// @param      locker_ The address locked the tokens
    /// @return     The amount of the tokens, allowed to lock in favor of the selected address
    function unlockedAllowance(address owner_, address locker_) public view returns (uint256 remaining);

    /// @notice     Collect, i.e. transfer tokens from the `owner_` account to the `locker_` in case
    /// @param      owner_ The tokens owner
    /// @param      locker_ The address locked the tokens
    /// @param      amount_ The tokens summ
    /// @return     `true` if the transfer was successful
    function collect(address owner_, address locker_, uint256 amount_) public view (bool success);
}
```

## Rationale

This EIP's goal, as mentioned in the abstract, is to have a simple interface for serving token lock. Here are a few design decisions and why they were made:

- Simple lock/unlock mechanism
  - Unlike standard `transfer` / `transferTo` it allow to leave pledged tokens on the owner's account.
  - Possibility to change the locked amount in selected limit.
- Forced collateral
  - Possibility to collect the pledged tokens and to clear the loan.

## Backwards Compatibility

This standard is an a extension for the any fungible token standards.

## Security Considerations

### Double allowance

To prevent attack vectors contract authors SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender. THOUGH The contract itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed before

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
