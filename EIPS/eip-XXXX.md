---
eip: XXXX
title: Multi-Owner Non-Fungible Tokens (MO-NFT)
author: James Savechives <james.walstonn@gmail.com> (jamesavechives)
discussions-to: https://ethereum-magicians.org/t/multi-owner-nfts-discussion-thread
status: Draft
type: Standards Track
category: ERC
created: 2024-07-13
---

## Simple Summary
A proposal to introduce multi-owner non-fungible tokens (MO-NFTs), allowing for shared ownership and transferability among multiple users.

## Abstract
This EIP proposes a new standard for non-fungible tokens (NFTs) that supports multiple owners. The MO-NFT standard allows a single NFT to have multiple owners, reflecting the shared and distributable nature of digital assets. This model also incorporates a mechanism for value depreciation as the number of owners increases, maintaining the principle that less ownership translates to more value.

## Motivation
Traditional NFTs enforce a single-ownership model, which does not align with the inherent duplicability of digital assets. MO-NFTs allow for shared ownership, promoting wider distribution and collaboration while maintaining secure access control. This model supports the principle that some valued information is more valuable if fewer people know it, hence less ownership means higher value.

## Specification

### Token Creation and Ownership Model
1. **Minting**: When a digital asset is uploaded, a unique MO-NFT is minted, and the uploader becomes the initial owner.
2. **Ownership List**: The MO-NFT maintains a list of owners. Each transfer adds the new owner to the list while retaining the existing owners.
3. **Transfer Mechanism**: Owners can transfer the token to new owners. The transfer does not remove the original owner from the list but adds the new recipient.

### Transfer of Ownership
1. **Additive Ownership**: Transferring ownership adds the new owner to the ownership list without removing the current owners.
2. **Ownership Tracking**: The smart contract tracks the list of owners for each MO-NFT.

### Decryption Rights and Access Control
1. **Encrypted Asset**: The digital asset associated with the MO-NFT is encrypted.
2. **Owner Access**: Only addresses listed as owners in the smart contract can access the decryption key.

### Value Depreciation
1. **Value Model**: As the number of owners increases, the value of the MO-NFT decreases to reflect the reduced exclusivity.
2. **Depreciation Mechanism**: The value depreciation model is defined based on the asset type and distribution strategy. Less ownership equates to more value, following the principle that valued information or assets become less valuable as they become more widely known or accessible.

### Interface Definitions
Define the necessary interfaces for interacting with MO-NFTs. This includes minting, transferring, and accessing ownership data.

#### ERC-721 Compliance
Ensure compatibility with the existing ERC-721 standard for NFTs to maintain interoperability with existing tools and platforms.

## Rationale
The rationale behind MO-NFTs is to align the ownership model of NFTs with the nature of digital assets that can be easily copied and shared. By allowing multiple owners and implementing a value depreciation mechanism, MO-NFTs provide a more flexible and realistic approach to digital asset ownership.

## Backwards Compatibility
This standard is designed to be backwards compatible with the existing ERC-721 standard. Existing tools and platforms that support ERC-721 should be able to interact with MO-NFTs with minimal modifications.

## Test Cases
Include test cases to demonstrate the functionality of MO-NFTs:
1. Minting an MO-NFT and verifying initial ownership.
2. Transferring an MO-NFT and verifying additive ownership.
3. Accessing the encrypted asset as an owner.
4. Ensuring the value depreciation model works as expected.

## Implementation
Provide a reference implementation of the MO-NFT smart contract, ensuring compliance with the specified standard.

## Security Considerations
1. **Access Control**: Ensure only legitimate owners can access the encrypted asset.
2. **Data Integrity**: Protect the integrity of the ownership list and associated metadata.
3. **Smart Contract Security**: Follow best practices for smart contract development to prevent vulnerabilities and exploits.

---

### About the Author
James Savechives is a Blockchain Engineer, with a keen interest in blockchain technology and digital assets. With a background in AizelNetwork, James Savechives aims to explore innovative solutions that bridge the gap between technology and practical applications. You can follow James Savechives on [\Twitter\]](https://x.com/CopyNature) or visit [\[Medium\]](https://medium.com/@james.walstonn) for more insights and articles.

---
