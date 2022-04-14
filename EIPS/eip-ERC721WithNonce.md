---
eip: 
title: ERC-721 Nonce Extension
description: Add a nonce property to ERC-721 tokens.
author: Anders (@0xanders), Lance (@LanceSnow), Shrug <shrug@emojidao.org>
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2022-04-10
requires: 165, 721
---

## Abstract

This standard is an extension of [ERC-721](./eip-721.md). It proposes adding an `nonce` property to ERC-721 tokens.

## Motivation

Some orders of NFT marketplace has been attacked and the NFTs have been sold in a lower price than market floor price. One reason is that users transfer NFT to another wallet and then, after a certain period of time, transfer it back to the original wallet, and the order becomes valid again.

This EIP proposes adding an `nonce` property to ERC-721 tokens, and the `nonce` will be changed when transfer. If `nonce` is added to an order, the order can be checked to avoid attacks. 

## Specification

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY" and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

```solidity
interface IERC721WithNonce  {

    // Logged when the nonce of a NFT is changed 
    /// @notice Emitted when the `nonce` of an NFT is changed
    event UpdateNonce(uint256 tokenId, uint256 newNonce);

    /// @notice Get the nonce of an NFT
    /// Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to get the nonce for
    /// @return The nonce of this NFT
    function nonce(uint256 tokenId) external view returns(uint256);
}
```

The `nonce(uint256 tokenId)` function MAY be implemented as `pure` or `view`.

The `UpdateNonce` event MUST be emitted when the nonce of a NFT is changed.

## Rationale

At first `transferCount` was considered as function name, but there maybe some case to change the `nonce` except transfer, such as important properties are changed, then we changed `transferCount` to `nonce`.

## Backwards Compatibility

This standard is compatible with current ERC-721 standards.

## Test Cases

### Test Contract 

```solidity
pragma solidity 0.8.10;
import "./ERC721WithNonce.sol";

contract ERC721WithNonceDemo is ERC721WithNonce{

    constructor(string memory name_, string memory symbol_)ERC721WithNonce(name_, symbol_){        
    }

    /// @notice mint a new original time NFT  
    /// @param to  The owner of the new token
    /// @param id  The id of the new token   
    function mint(address to, uint256 id) public {
       _mint(to, id);
    }    
}

```
### Test Code

run in Terminal: `npm hardhat test`

test.ts:
```TypeScript
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Test nonce ", function () {

    let [alice, bob] = await ethers.getSigners();

    const ERC721WithNonceDemo = await ethers.getContractFactory("ERC721WithNonceDemo");

    let contract = await ERC721WithNonceDemo.deploy();


    let tokenId = 1;
    await contract.mint(alice.address, tokenId);

    expect(await contract.nonce(tokenId)).equals(1);

    await contract.transferFrom(alice.address, bob.address, tokenId);

    expect(await contract.nonce(tokenId)).equals(2);
    
});
```

## Reference Implementation

```solidity
// SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721WithNonce.sol";

contract ERC721WithNonce is ERC721, IERC721WithNonce {
    mapping(uint256 => uint256) private tokenNonce;

    constructor(string memory name_, string memory symbol_)ERC721(name_, symbol_){        
    }

    function nonce(uint256 tokenId) public virtual override view returns(uint256) {
        require(_exists(tokenId), "Error: query for nonexistent token");

        return  tokenNonce[tokenId];
     }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        super._beforeTokenTransfer(from,to,tokenId);
        tokenNonce[tokenId]++;
        emit UpdateNonce(tokenId, tokenNonce[tokenId]);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721WithNonce).interfaceId || super.supportsInterface(interfaceId);
    }
     
}
```

## Security Considerations
No security issues found.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

