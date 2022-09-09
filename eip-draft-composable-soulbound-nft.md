---
eip: <to be assigned>
title: Composable Soulbound NFT, EIP-1155 Extension
description: Add composable soulbound property to EIP-1155 tokens
author: HonorLabs (@honorworldio)
discussions-to: TBD
status: Draft
type: Standards Track
category: ERC
created: 2022-09-09
requires: 165, 1155
---

## Abstract

This standard is an extension of EIP-1155. It proposes a smart contract interface that can represent any number of soulbound and non-soulbound NFT types. Soulbound is the property of a token that prevents it from being transferred between accounts. This standard allows for each token ID to have its own soulbound property. 


## Motivation

The soulbound NFTs similar to World of Warcraft’s soulbound items are attracting more and more attention in the Ethereum community. In a real world game like World of Warcraft, there are thousands of items, and each item has its own soulbound property. For example, the amulate Necklace of Calisea is of soulbound property, but another low level amulate is not. This proposal provides a standard way to represent soulbound NFTs that can coexist with non-soulbound ones. It is easy to design a composable NFTs for an entire collection in a single contract. 

This standard outline a interface to EIP-1155 that allows wallet implementers and developers to check for soulbound property of token ID using EIP-165. the soulbound property can be checked in advance, and the transfer function can be called only when the token is not soulbound.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

A token type with a `uint256 id`  is soulbound if function `isSoulbound(uint256 id)` returning true. In this case, all EIP-1155 functions of the contract that transfer the token from one account to another MUST throw, except for mint and burn. 

```
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IComposableSoulboundNFT {
  /**
   * @dev Emitted when a token type `id` is set or cancel to soulbound, according to `bounded`.
   */
  event Soulbound(uint256 indexed id, bool bounded);

  /**
   * @dev Returns true if a token type `id` is soulbound.
   */
  function isSoulbound(uint256 id) external view returns (bool);
}
```
Smart contracts implementing this standard MUST implement the ERC-165 supportsInterface function and MUST return the constant value true if 0x911ec470 is passed through the interfaceID argument.

## Rationale

If all tokens in a contract are soulbound by default, `isSoulbound(uint256 id)` should return true by default during implementation.

## Backwards Compatibility

This standard is fully EIP-1155 compatible.

## Test Cases

Run in terminal:

```
npx hardhat test
```

### Test code
```
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ComposableSoulboundNFTDemo contract", function () {

  it("InterfaceId should equals 0x911ec470", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const ComposableSoulboundNFTDemo = await ethers.getContractFactory("ComposableSoulboundNFTDemo");

    const demo = await ComposableSoulboundNFTDemo.deploy();
    await demo.deployed();

    expect(await demo.getInterfaceId()).equals("0x911ec470");
  });

  it("Test soulbound", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const ComposableSoulboundNFTDemo = await ethers.getContractFactory("ComposableSoulboundNFTDemo");

    const demo = await ComposableSoulboundNFTDemo.deploy();
    await demo.deployed();

    await demo.setSoulbound(1, true);
    expect(await demo.isSoulbound(1)).to.equal(true);
    expect(await demo.isSoulbound(2)).to.equal(false);

    await demo.mint(addr1.address, 1, 2, "0x");
    await demo.mint(addr1.address, 2, 2, "0x");

    await expect(demo.connect(addr1).safeTransferFrom(addr1.address, addr2.address, 1, 1, "0x")).to.be.revertedWith(
        "ComposableSoulboundNFT: Soulbound, Non-Transferable"
    );
    await expect(demo.connect(addr1).safeBatchTransferFrom(addr1.address, addr2.address, [1], [1], "0x")).to.be.revertedWith(
        "ComposableSoulboundNFT: Soulbound, Non-Transferable"
    );
    await expect(demo.connect(addr1).safeBatchTransferFrom(addr1.address, addr2.address, [1,2], [1,1], "0x")).to.be.revertedWith(
        "ComposableSoulboundNFT: Soulbound, Non-Transferable"
    );

    await demo.mint(addr1.address, 2, 1, "0x");
    demo.connect(addr1).safeTransferFrom(addr1.address, addr2.address, 2, 1, "0x");
    demo.connect(addr1).safeBatchTransferFrom(addr1.address, addr2.address, [2], [1], "0x");

    await demo.connect(addr1).burn(addr1.address, 1, 1);
    await demo.connect(addr1).burnBatch(addr1.address, [1], [1]);
    await demo.connect(addr2).burn(addr2.address, 2, 1);
    await demo.connect(addr2).burnBatch(addr2.address, [2], [1]);
  });
});
```

test contract:
```
// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ComposableSoulboundNFT.sol";

contract ComposableSoulboundNFTDemo is ERC1155, ERC1155Burnable, Ownable, ComposableSoulboundNFT {
    constructor() ERC1155("") ComposableSoulboundNFT() {}

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function setSoulbound(uint256 id, bool soulbound) 
        public
        onlyOwner 
    {
        _setSoulbound(id, soulbound);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ComposableSoulboundNFT)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ComposableSoulboundNFT)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function getInterfaceId() public view returns (bytes4) {
        return type(IComposableSoulboundNFT).interfaceId;
    }
}
```

## Reference Implementation

```
// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IComposableSoulboundNFT.sol";

/**
 * @dev Extension of ERC1155 that adds soulbound property per token id.
 *
 */
abstract contract ComposableSoulboundNFT is ERC1155, IComposableSoulboundNFT {
    mapping(uint256 => bool) private _soulbounds;
    
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return interfaceId == type(IComposableSoulboundNFT).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns true if a token type `id` is soulbound.
     */
    function isSoulbound(uint256 id) public view virtual returns (bool) {
        return _soulbounds[id];
    }

    function _setSoulbound(uint256 id, bool soulbound) internal {
        _soulbounds[id] = soulbound;
        emit Soulbound(id, soulbound);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            if (isSoulbound(ids[i])) {
                require(
                    from == address(0) || to == address(0),
                    "ComposableSoulboundNFT: Soulbound, Non-Transferable"
                );
            }
        }
    }
}
```

## Security Considerations
There are no security considerations related directly to the implementation of this standard.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
