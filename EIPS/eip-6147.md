---
eip: 6147
title: Guard of NFT/SBT, an Extension of EIP-721
description: A new management role of NFT/SBT is defined, which realizes the separation of transfer right and holding right of NFT/SBT.
author: 5660-eth (@5660-eth), Wizard Wang
discussions-to: https://ethereum-magicians.org/t/guard-of-nft-sbt-an-extension-of-eip-721/12052
status: Draft
type: Standards Track
category: ERC
created: 2022-12-07
requires: 165, 721
---

## Abstract

This standard is an extension of [EIP-721](./eip-721.md). It separates the holding right and transfer right of non-fungible tokens (NFTs) and Soulbound Tokens (SBTs) and defines a new role, `guard`. The flexibility of the `guard` setting enables the design of NFT anti-theft, NFT lending, NFT leasing, SBT, etc.

## Motivation

NFTs are assets that have both use and financial value.

Many cases of NFT theft currently exist, and current NFT anti-theft schemes, such as transferring NFT to cold wallets, make NFT inconvenient to be used.

In current NFT lending, the NFT owner needs to transfer the NFT to the NFT lending contract, and the NFT owner no longer has the right to use the NFT while he or she has obtained the loan. In the real world, for example, if a person takes out a mortgage on his own house, he still has the right to use that house.

For SBT, the current mainstream view is that an SBT is not transferable, which makes an SBT bound to an Ether address. However, when the private key of the user address is leaked or lost, retrieving SBT will become a complicated task and there is no corresponding specification. The SBTs essentially realizes the separation of NFT holding rights and transfer rights. When the wallet where SBT is located is stolen or unavailable, SBT should be able to be recoverable. 

In addition, SBTs still need to be managed in use. For example, if a university issues a diploma SBT to its graduates, and if the university later finds that a graduate has committed academic misconduct or jeopardized the reputation of the university, it should have the ability to retrieve the diploma SBT. 


## Specification

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY" and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

### Contract Interface
  
```solidity
 interface IERC6147 {

    /// Logged when the guard of an NFT is changed 
    /// @notice Emitted when  the `guard` is changed
    /// The zero address for guard indicates that there is no guard address
    event UpdateGuardLog(uint256 indexed tokenId,address indexed newGuard,address oldGuard);
    
    /// @notice  Owner can set guard of the NFT and guard can modifiy guard of the NFT
    /// If the NFT has a guard role, the owner of the NFT cannot modify guard
    /// @dev The newGuard can not be zero address
    /// Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to get the guard address for
    /// @param newGuard The new guard address of the NFT
    function changeGuard(uint256 tokenId, address newGuard) external;

  
    /// @notice Remove the guard of the NFT
    /// Only guard can remove its own guard role
    /// @dev The guard address is set to 0 address
    /// Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to remove the guard address for
    function removeGuard(uint256 tokenId) external;
    
    /// @notice Transfer the NFT and remove its guard role
    /// @dev The NFT is transferred to `to`and the guard address is set to 0 address
    /// Throws if `tokenId` is not valid NFT
    /// @param from The address of the previous owner of the NFT
    /// @param to The address of NFT recipient 
    /// @param tokenId The NFT to get transferred for
    function transferAndRemove(address from,address to,uint256 tokenId) external;

    /// @notice Get the guard address of the NFT
    /// @dev The zero address indicates that there is no guard
    /// Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to get the guard address for
    /// @return The guard address for the NFT
   function guardOf(uint256 tokenId) external view returns (address);   
}
  
  ```
The standard defines a new role `guard` and regulates the permissions of `owner` and `guard` as follows

`owner`（Including authorised operators or approved addresses, which will not be described in detail below）: when the guard of the NFT is empty, `owner` can transfer the NFT, and also set `guard`. However, when `guard` already exists for the NFT, `owner` cannot modify `guard`, and cannot transfer the NFT.

`guard`: The `guard` can remove its own `guard` identity or transfer the NFT to a specified address. For example, the `guard` can be set as the cold wallet address of the NFT holder, or an address trusted by the NFT holder. After the `owner` address of the NFT is abnormal, the `guard` can call the contract to transfer the NFT to the specified address.

The `supportsInterface` method MUST return `true` when called with `0xc0655ef1`.

## Rationale 

### The design idea of the standard is as follows

#### Universality

There are many application scenarios for NFT/SBT, and there is no need to propose a dedicated EIP for each one, which would make the overall number of EIPS inevitably increase and add to the burden of developers. The standard is based on the analysis of the right attached to assets in the real world, and abstracts the right attached to NFT/SBT into holding right and transfer right making the standard more universal.

For example, the standard has and has more than the following use cases.

SBTs. The SBTs issuer can assign a uniform role of `guard` to the SBTs before they are minted, so that the SBTs cannot be transferred by the corresponding holder and can be managed by the SBTs issuer through the `guard`.

NFT anti-theft. NFT holders set the `guard` address of the NFT as their own cold wallet address, the NFT can still be used by the NFT holder, but the risk of theft is greatly reduced.

NFT lending. The borrower sets the `guard` of his own NFT as the lender's address, the borrower still has the right to use the NFT while obtaining the loan, but at the same time cannot transfer or sell the NFT. if the borrower defaults on the loan, the lender can transfer and sell the NFT.

#### Simplicity

Improvements to the ETH protocol should be as simple as possible. Entities should not be multiplied beyond necessity.

#### Extensibility
  
This standard only defines a `guard`, for the complex functions required by NFT and SBT, such as social recovery, multi-signature, expires management, according to the specific application scenarios, the `guard` can be set as a third-party protocol address, through the third-party protocol to achieve more flexible and diverse functions.

### Choice of name

The alternative names are `guardian` and `guard`, both of which basically match the permissions corresponding to the role: protection of NFT or necessary management according to its application scenarios. The `guard` has fewer characters than the `guardian` and is more concise.

## Backwards Compatibility

This standard can be fully EIP-721 compatible by adding an extension function set.

If the NFT issued based on the above standard does not have a `guard` role, then it is no different from the current NFT issued based on the EIP-721 standard.


## Reference Implementation
  
```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC6147.sol";

abstract contract ERC721QS is ERC721, IERC6147 {
    
    mapping(uint256 => address) internal token_guard_map;

    /// @notice Update the guard of the NFT
    /// @dev Delete function: set guard  to 0 address,update function: set guard to new address
    /// Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to update the guard address for
    /// @param newGuard The newGuard address
    /// @param allowNull Allow 0 address
    function updateGuard(uint256 tokenId,address newGuard,bool allowNull) internal {
        address guard = guardOf(tokenId);
        if (!allowNull) {
            require(newGuard != address(0), "New guard can not be null");
        }
        if (guard != address(0)) { 
            require(guard == _msgSender(), "only guard can change it self"); 
        } else { 
            require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721QS: caller is not owner nor approved");
        } 

        if (guard != address(0) || newGuard != address(0)) {
            token_guard_map[tokenId] = newGuard;
            emit UpdateGuardLog(tokenId, newGuard, guard);
        }
    }

    /// @notice Owner sets guard or guard modifies guard
    /// @dev The newGuard can not be zero address
    /// Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to get the guard address for
    /// @param newGuard The new guard address of the NFT
    function changeGuard(uint256 tokenId, address newGuard) public virtual{
        updateGuard(tokenId, newGuard, false);
    }

    /// @notice Remove the guard of the NFT
    /// @dev The guard address is set to 0 address
    ///      Only guard can remove its own guard role
    /// Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to remove the guard address for
    function removeGuard(uint256 tokenId) public virtual  {
        updateGuard(tokenId, address(0), true);
    }
    
    /// @notice Transfer the NFT and remove its guard role
    /// Throws  if `tokenId` is not valid NFT
    /// @param  from The address of the previous owner of the NFT
    /// @param  to The address of NFT recipient 
    /// @param  tokenId The NFT to get transferred for
    function transferAndRemove(address from,address to,uint256 tokenId) public virtual {
        transferFrom(from,to,tokenId);
        removeGuard(tokenId);
    }
    
    /// @notice Get the guard address of the NFT
    /// @dev The zero address indicates that there is no guard
    /// Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to get the guard address for
    /// @return The guard address for the NFT
    function guardOf(uint256 tokenId) public view virtual returns (address) {
        return token_guard_map[tokenId];
    }
    
    /// @notice Check the guard address
    /// @dev The zero address indicates there is no guard
    /// Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to check the guard address for
    /// @return The guard address
    function checkGuard(uint256 tokenId) internal view returns (address) {
        address guard = guardOf(tokenId);
        address sender = _msgSender();
        if (guard != address(0)) {
            require(guard == sender, "sender is not guard of token");
            return guard;
        }else{
            return address(0);
        }
    }

    ///@dev When burning, delete `token_guard_map[tokenId]`
    function _burn(uint256 tokenId) internal virtual override {
        address guard=guardOf(tokenId);
        super._burn(tokenId);
        delete token_guard_map[tokenId];
        emit UpdateGuardLog(tokenId, address(0), guard);
    }
 
    /// @dev Before transferring the NFT, need to check the gurard address
    function transferFrom(address from,address to,uint256 tokenId) public virtual override {
        address guard;
        address new_from = from;
        if (from != address(0)) {
            guard = checkGuard(tokenId);
            new_from = ownerOf(tokenId);
        }
        if (guard == address(0)) {
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        }
        _transfer(new_from, to, tokenId);
    }

    /// @dev Before safe transferring the NFT, need to check the gurard address
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) public virtual override {
        address guard;
        address new_from = from;
        if (from != address(0)) {
            guard = checkGuard(tokenId);
            new_from = ownerOf(tokenId);
        }
        if (guard == address(0)) {
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721QS).interfaceId || super.supportsInterface(interfaceId);
    }
}

```


## Security Considerations

When an NFT has a `guard`, even if an address is authorized as an operator through `approve` or `setApprovalForAll`, the operator still has no right to transfer the NFT.

For NFT trading platforms that trade through `setApprovalForAll` + holder's signature, when NFT has `guard`, it cannot be traded. It is recommended to prevent such pending orders by checking the interface beforehand.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
