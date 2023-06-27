---
title: Encumber
eip: XXXX
description: Extending token standards to allow pledging tokens without transferring ownership.
author: Coburn Berry (@coburncoburn) Mykel Pereira (@mykelp)
discussions-to: https://ethereum-magicians.org/t/encumber-extending-the-erc-20-token-standard-to-allow-pledging-tokens-without-giving-up-ownership/14849
status: Draft
type: Standards Track
category: ERC
created: 2023-06-27
---

## Abstract
This ERC proposes an extension to the ERC-20 token standard by adding Encumber — the ability for an account to grant another account exclusive right to move some portion of their balance. Encumber is a stronger version of ERC-20 allowances. While ERC-20 approve grants another account the permission to transfer a specified token amount, encumber grants the same permission while ensuring that the tokens will be available when needed.

## Motivation
Token holders commonly transfer their tokens to smart contracts which will return the tokens under specific conditions. In some cases, smart contracts do not actually need to hold the tokens, but need to guarantee they will be available if necessary. Since allowances do not provide a strong enough guarantee, the only way to do guarantee token availability presently is to transfer the token to the smart contract. Locking tokens without moving them gives more clear indication of the rights and ownership of the tokens. This allows for airdrops and other ancillary benefits of ownership to reach the true owner. It also adds another layer of safety, where draining a pool of ERC-20 tokens can be done in a single transfer, iterating accounts to transfer encumbered tokens would be significantly more prohibitive in gas usage.

## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

A compliant token MUST implement the following interface

```solidity
/**
 * @dev Interface of the ERCXXXX standard.
 */
interface IERCXXXX {
    /**
     * @dev Emitted when `amount` tokens are encumbered from `owner` to `taker`.
     */
    event Encumber(address indexed owner, address indexed taker, uint amount);

    /**
     * @dev Emitted when the encumbrance of a `taker` to an `owner` is reduced by `amount`.
     */
    event Release(address indexed owner, address indexed taker, uint amount);

    /**
     * @dev Returns the total amount of tokens owned by `owner` that are currently encumbered.
     * MUST never exceed `balanceOf(owner)`
     *
     * Any function which would reduce balanceOf(owner) below encumberedBalanceOf(owner) MUST revert
     */
    function encumberedBalanceOf(address owner) external returns (uint);

    /**
     * @dev Returns the number of tokens that `owner` has encumbered to `taker`.
     *
     * This value increases when {encumber} or {encumberFrom} are called by the `owner` or by another permitted account.
     * This value decreases when {release} and {transferFrom} are called by `taker`.
     */
    function encumbrances(address owner, address taker) external returns (uint);

    /**
     * @dev Increases the amount of tokens that the caller has encumbered to `taker` by `amount`.
     * Grants to `taker` a guaranteed right to transfer `amount` from the caller's balance by using `transferFrom`.
     *
     * MUST revert if caller does not have `amount` tokens available 
     * (e.g. if `balanceOf(caller) - encumbrances(caller) < amount`).
     *
     * Emits an {Encumber} event.
     */
    function encumber(address taker, uint amount) external;

    /**
     * @dev Increases the amount of tokens that `owner` has encumbered to `taker` by `amount`.
     * Grants to `taker` a guaranteed right to transfer `amount` from `owner` using transferFrom
     *
     * The function SHOULD revert unless the owner account has deliberately authorized the sender of the message via some mechanism.
     * 
     * MUST revert if `owner` does not have `amount` tokens available 
     * (e.g. if `balanceOf(owner) - encumbrances(owner) < amount`).
     *
     * Emits an {Encumber} event.
     */
    function encumberFrom(address owner, address taker, uint amount) external;

    /**
     * @dev Reduces amount of tokens encumbered from `owner` to caller by `amount`
     *
     * Emits a {Release} event.
     */
    function release(address owner, uint amount);


    /**
     * @dev Convenience function for reading the unencumbered balance of an address.
     * Trivially implemented as `balanceOf(owner) - encumberedBalanceOf(owner)`
     */
    function availableBalanceOf(address owner) external returns (uint);
}
```

## Rationale
This extension adds flexibility to the ERC-20 token standard and caters to use cases where token locking is required, but it is preferential to maintain actual ownership of tokens. This interface can also be adapted to other token standards, such as ERC-721, in a straightforward manner.


## Backwards Compatibility
This EIP is backwards compatible with the existing ERC-20 standard. Implementations must add the functionality to block transfer of tokens that are encumbered to another account.


## Reference Implementation

This can be implemented as an extension of any base ERC-20 contract by modifying the transfer function to block the transfer of encumbered tokens and to release encumbrances when spent via transferFrom.

https://github.com/compound-finance/encumber_samples/blob/create-samples/src/encumberableERC20.sol

``` solidity

// An erc-20 token that implements the encumber interface by blocking transfers.

pragma solidity ^0.8.0;
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract EncumberableERC20 is ERC20 {
    // Owner -> Taker -> Amount that can be taken
    mapping (address => mapping (address => uint)) public encumbrances;

    // The encumbered balance of the token owner. encumberedBalance must not exceed balanceOf for a user
    // Note this means rebasing tokens pose a risk of diminishing and violating this prototocol
    mapping (address => uint) public encumberedBalance;
    
    address public minter;

    event Encumber(address indexed owner, address indexed taker, uint encumberedAmount);
    event Release(address indexed owner, address indexed taker, uint releasedAmount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        minter = msg.sender;
    }

    function mint(address recipient, uint amount) public virtual returns (bool) {
        require(msg.sender == minter, "only minter");
        _mint(recipient, amount);
        return true;
    }

    function encumber(address taker, uint amount) public virtual returns (bool) {
        _encumber(msg.sender, taker, amount);
        return true;
    }

    function encumberFrom(address owner, address taker, uint amount) public virtual returns (bool) {
        require(allowance(owner, msg.sender) >= amount);
       _encumber(owner, taker, amount);
       return true;
    }

    function release(address owner, uint amount) public virtual returns (bool) {
        _release(owner, msg.sender, amount);
        return true;
    }

    // If bringing balance and encumbrances closer to equal, must check
    function availableBalanceOf(address a) public view returns (uint) {
        return (balanceOf(a) - encumberedBalance[a]);
    }

    function _encumber(address owner, address taker, uint amount) private {
        require(availableBalanceOf(owner) >= amount, "insufficient balance");
        encumbrances[owner][taker] += amount;
        encumberedBalance[owner] += amount;
        emit Encumber(owner, taker, amount);
    }

    function _release(address owner, address taker, uint amount) private {
        if (encumbrances[owner][taker] < amount) {
          amount = encumbrances[owner][taker];
        }
        encumbrances[owner][taker] -= amount;
        encumberedBalance[owner] -= amount;
        emit Release(owner, taker, amount);
    }

    function transfer(address dst, uint amount) public override returns (bool) {
        // check but dont spend encumbrance
        require(availableBalanceOf(msg.sender) >= amount, "insufficient balance");
        _transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) public override returns (bool) {
        uint encumberedToTaker = encumbrances[src][msg.sender];
        bool exceedsEncumbrance = amount > encumberedToTaker;
        if (exceedsEncumbrance)  {
            uint excessAmount = amount - encumberedToTaker;
            // Exceeds Encumbrance , so spend all of it
            _spendEncumbrance(src, msg.sender, encumberedToTaker);

            // Having spent all the tokens encumbered to the mover,
            // We are now moving only "free" tokens and must check
            // to not unfairly move tokens encumbered to others

           require(availableBalanceOf(src) >= excessAmount, "insufficient balance");

            _spendAllowance(src, dst, excessAmount);
        } else {
            _spendEncumbrance(src, msg.sender, amount);
        }

        _transfer(src, dst, amount);
        return true;
    }

    function _spendEncumbrance(address owner, address taker, uint256 amount) internal virtual {
        uint256 currentEncumbrance = encumbrances[owner][taker];
        require(currentEncumbrance >= amount, "insufficient encumbrance");
        uint newEncumbrance = currentEncumbrance - amount;
        encumbrances[owner][taker] = newEncumbrance;
        encumberedBalance[owner] -= amount;
    }
}
```


## Security Considerations
Parties relying on `balanceOf` to determine the amount of tokens available for transfer should instead rely on `balanceOf(account) - encumberedBalance(account)`, or, if implemented, `availableBalanceOf(account)`.

The property that encumbered balances are always backed by a token balance can be accomplished in a straightforward manner by altering `transfer` and `transferFrom` to block . If there are other functions that can alter user balances, such as a rebasing token or an admin burn function, additional guards must be added by the implementer to likewise ensure those functions prevent reducing `balanceOf(account)` below `encumberedBalanceOf(account)` for any given account.
Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
