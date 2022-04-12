---
eip: 
title: ERC-1155 User
description: Add a user role with restricted permissions to ERC-1155 tokens.
author: Anders (@0xanders), Lance (@LanceSnow), Shrug <shrug@emojidao.org>
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2022-03-11
requires: 165, 1155
---

## Abstract

This standard is an extension of [ERC-1155](./eip-1155.md). It proposes an additional role (`user`) which can be granted to addresses. The `user` role represents permission to "use" the NFT, but not be able to transfer it or set operators.

## Motivation

Some NFTs have certain utilities. For example: in-game NFTs can be "used" to play, virtual land can be "used" to build scenes, and music NFTs can be "used" while listening. In some cases, the owner and user may not be the same account. Someone may purchase an NFT with utility, but they may not have time or ability to use it, so separating the "use" right from ownership makes a lot of sense.

Nowadays, many NFTs are managed by adding the role of **controller/operator**. Accounts in these roles can perform specific usage actions but can’t approve or transfer the NFT like an owner. 

It is conceivable that with the further expansion of NFT application, the problem of usage rights management will become more common, so it is necessary to establish a unified standard to facilitate collaboration among all applications.

By adding **user**, it enables multiple protocols to integrate and build on top of usage rights.

## Specification

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY" and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

```solidity
// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155WithUserRole is IERC1155 {
    event UpdateUser(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens of token type `id` used by `user`.
     *
     * Requirements:
     *
     * - `user` cannot be the zero address.
     */
    function balanceOfUser(address user, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of frozen tokens of token type `id` by `owner`.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     */
    function frozenOfOwner(address owner, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of tokens of token type `id` used by `user`.
     *
     * Requirements:
     *
     * - `user` cannot be the zero address.
     * - `owner` cannot be the zero address.
     */
    function balanceOfUserFromOwner(
        address user,
        address owner,
        uint256 id
    ) external view returns (uint256);

    /// @notice set the user of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param amount  The new user could use
    function setUser(
        address owner,
        address user,
        uint256 id,
        uint256 amount
    ) external;
}

```


## Rationale

Many developers are trying to develop based on the NFT utility, and some of them have added roles already,  but there are some key problems need to be solved. The advantages of this standard are below.

### Clear Permissions Management

Usage rights are part of ownership, so **owner** can modify **user** at any time, while **user** is only granted some specific permissions, such as **user** usually does not have permission to make permanent changes to NFT's Metadata.

NFTs may be used in multiple applications, and adding the user role to NFTs makes it easier for the application to make special grants of rights.

### Simple On-chain Time Management

Most NFTs do not take into account the expiration time even though the role of the user is added, resulting in the need for the owner to manually submit on-chain transaction to cancel the user rights, which does not allow accurate on-chain management of the use time and will waste gas.

The usage right often corresponds to a specific time, such as deploying scenes on land, renting game props,  etc.

### Easy Third-Party Integration

The standard makes it easier for third-party protocols to manage NFT usage rights without permission from the NFT issuer or the NFT application.

## Backwards Compatibility

As mentioned in the specifications section, this standard can be fully ERC721 compatible by adding an extension function set.

In addition, new functions introduced in this standard have many similarities with the existing functions in ERC721. This allows developers to easily adopt the standard quickly.

## Test Cases
run in Terminal:
```
npm hardhat test
```

### Test Code
```TypeScript
import { expect } from "chai";
import { ethers } from "hardhat";

describe("set_user", function () {
    it("Should set user to bob", async function () {
        /**alice is the Owner */
        const [alice, bob] = await ethers.getSigners();

        const ERC1155WithUserRole = await ethers.getContractFactory("ERC1155WithUserRole");

        const contract = await ERC1155WithUserRole.deploy();

        await contract.mint(alice.address, 1,100);

        await contract.setUser(alice.address,bob.address,1,50);

        await contract.setUser(alice.address,bob.address,1,10);

        expect(await contract.balanceOfUser(bob.address,1)).equals(10);

        expect(await contract.balanceOfUserFromOwner(bob.address,alice.address,1)).equals(10);

        expect(await contract.frozenOfOwner(alice.address,1)).equals(10);
        
    });
});
```

## Reference Implementation

```solidity
// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IERC1155WithUserRole.sol";

contract ERC1155WithUserRole is ERC1155, IERC1155WithUserRole {
    /**mapping(tokenId=>mapping(user=>amount)) */
    mapping(uint256 => mapping(address => uint256)) private _userAllowances;

    /**mapping(tokenId=>mapping(owner=>amount)) */
    mapping(uint256 => mapping(address => uint256)) private _frozen;

    /** mapping(tokenId=>mapping(owner=>mapping(user=>amount))) */
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        private _allowances;

    constructor() ERC1155("") {}

    function balanceOfUser(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return _userAllowances[id][user];
    }

    function balanceOfUserFromOwner(
        address user,
        address owner,
        uint256 id
    ) public view returns (uint256) {
        return _allowances[id][owner][user];
    }

    function frozenOfOwner(address owner, uint256 id)
        external
        view
        returns (uint256)
    {
        return _frozen[id][owner];
    }

    function setUser(
        address owner,
        address user,
        uint256 id,
        uint256 amount
    ) public virtual {
        require(user != address(0), "ERC1155: transfer to the zero address");
        address operator = msg.sender;
        uint256 fromBalance = balanceOf(owner, id);
        _frozen[id][owner] -= _allowances[id][owner][user];
        uint256 frozen = _frozen[id][owner];
        require(
            fromBalance - frozen >= amount,
            "ERC1155: insufficient balance for setUser"
        );
        unchecked {
            _frozen[id][owner] = frozen + amount;
        }
        _userAllowances[id][user] -= _allowances[id][owner][user];
        _userAllowances[id][user] += amount;
        _allowances[id][owner][user] = amount;

        emit UpdateUser(operator, owner, user, id, amount);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        _mint(to, id, amount, "");
    }
}

```

## Security Considerations

This EIP standard can completely protect the rights of the owner, the owner can change the NFT user.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

