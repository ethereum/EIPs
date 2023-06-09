---
eip: XXXX
title: MetaNFT keystore contracts
description: An interface for reading and storing data within NFTs
author: Rachid Ajaja(rachid@allianceblock.io),Alexandros Athanasopulos(Xaleee),Pavel Rubin (pash7ka),Sebastian Galimberti Romano (@galimba)
discussions-to: https://ethereum-magicians.org/
status: Draft
type: Standards Track
category: ERC
created: 2023-06-09
requires: 721
---

## Abstract

- MetaNFTs aim to address the limitations of traditional NFTs by enabling on-chain data aggregation, providing an interface for standardized, interoperable, and composable data management solutions within NFTs.

- MetaNFTs store data as Properties, an agnostic data structure. Properties can have Restrictions (i.e. in the case of an identity-based Property or SoulBound Tokens, a Transfer Restriction; in the case of staking, a Lock Restriction).

- MetaNFTs address some of the existing limitations with traditional keystore contracts that aim to separate the logic from the storage.

- This EIP proposes a standard interface for interacting with Properties and Restrictions within a MetaNFT (Meta Non-Fungible Token) on the Ethereum blockchain. This enables greater flexibility, interoperability, and utility for NFTs

## Motivation

The Ethereum ecosystem hosts a rich diversity of token standards, each designed to cater to specific use cases. While such diversity spurs innovation, it also results in a highly fragmented landscape, especially for Non-Fungible Tokens (NFTs). NFTs, conforming to standards such as ERC-721 and ERC-1155, have often faced limitations when representing complex digital assets. While each standard serves its purpose, they often lack the flexibility needed to manage additional on-chain data associated with the utility of these tokens.

This EIP is driven by the need to address these limitations. We propose the standardization of an interface for storing and accessing data on-chain, codifying information as Properties and Restrictions associated with NFTs use cases. This enhancement is designed to work by extending existing token standards, providing a flexible, efficient, and coherent way to manage the data associated with NFTs.

The key motivations driving this proposal are:

- **Standard Neutrality**: The standard aims to separate the data logic from the token standard. This neutral approach would allow NFTs to transition seamlessly between different token standards, promoting interactions with platforms or marketplaces designed for those standards. This could significantly improve interoperability among different standards, reducing fragmentation in the NFT landscape.

- **Consistent Interface**: A uniform interface abstracts the data storage from the use case, irrespective of the underlying NFT standard. This consistent interface simplifies interoperability, enabling platforms and marketplaces to interact with a uniform data interface, regardless of individual token standards. This common ground for all NFTs could reduce fragmentation in the ecosystem.

- **Simplified Upgrades**: A standard interface for representing the utility of an NFT would simplify the process of upgrading NFTs to new token standards. This could help to reduce fragmentation caused by outdated standards, facilitating easier transition to new, more efficient, or feature-rich standards.

- **Minimized Redundancy**: Currently, developers often need to write similar code for different token standards, leading to unnecessary redundancy. A standardized interface would allow developers to separate the data storage code from the underlying token utility logic, reducing redundancy and promoting greater unity in the ecosystem.

- **Actionable data**: Current practices often store metadata off-chain, rendering it inaccessible for smart contracts without the use of oracles. Moreover, metadata is often used to store information that could otherwise be considered data relevant to the NFT's inherent identity. This EIP seeks to rectify this issue by introducing a standardized interface for reading and storing additional on-chain data related to NFTs.

The current EIP is not focused on creating a new token standard, but rather offering a flexible, universal, and objective approach that caters to a variety of use cases. The motivation behind this proposal is to provide a more unified, efficient, and flexible framework for managing on-chain data associated with NFTs, in the form of Properties and Restrictions. By doing so, this standard aims to reduce the need for multiple overlapping standards, fostering a more cohesive Ethereum ecosystem.


## Specification

### Terms

**MetaNFT**: A uniquely identifiable non-fungible token. A MetaNFT MAY store Properties and Restrictions.

**Property**: A modifiable information unit stored within a MetaNFT. It SHOULD be capable of undergoing modifications.

**Restriction**: A configuration data structure associated with a Property within the MetaNFT. Restrictions are REQUIRED to define conditions under which a Property can be modified.

### MetaNFT Functionality
A MetaNFT MUST extend the functionality of traditional NFTs through the incorporation of Properties and Restrictions in its internal storage. The Properties and Restrictions of a MetaNFT SHALL be stored on-chain and be made accessible to smart contracts. The interface defining this interaction is as follows:

```solidity
interface IMetaNFT {
  function getProperty(
      uint256 tokenId,
      string calldata propertyKey
    ) external view returns (bytes memory);

  function getRestriction(
      uint256 tokenId,
      string calldata restrictionKey
    ) external view returns (bytes memory);

  function setProperty(
      uint256 tokenId,
      string calldata propertyKey,
      bytes calldata propertyValue
    ) external;

  function setRestriction(
      uint256 tokenId,
      string calldata restrictionKey,
      bytes calldata restrictionValue
    ) external;
}
```

- **getProperty**: This function MUST retrieve a specific property of a MetaNFT, identifiable through the `tokenId` and `propertyKey` parameters.

- **getRestriction**: This function MUST retrieve a specific restriction of a MetaNFT, identifiable through the `tokenId` and `restrictionKey` parameters.

- **setProperty**: This function MUST set or update a specific property of a MetaNFT. This operation is REQUIRED to be executed solely by the owner of the MetaNFT or an approved Smart Contract.

- **setRestriction**: This function MUST set or update a specific restriction of a MetaNFT. Similar to `setProperty`, this operation is REQUIRED to be executed only by the owner of the MetaNFT or an approved Smart Contract.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

The inclusion of Properties and Restrictions within a MetaNFT provides the capability to associate a richer set of on-chain accessible information with an NFT. This enables a wide array of complex, dynamic, and interactive use cases to be implemented with NFTs.

Properties in a MetaNFT offer flexibility in storing mutable on-chain data that can be modified as per the requirements of the token's use case. This allows the NFT to hold mutable states and reflect changes over time, providing a dynamic layer to the otherwise static nature of NFTs through a standardized interface.

Restrictions, on the other hand, provide a structured way to control the modification conditions of these properties, ensuring the integrity and security of the data. By stipulating conditions under which a Property can be modified, Restrictions bring a level of control and compliance to the dynamic capabilities of MetaNFTs.

By leveraging Properties and Restrictions together within the MetaNFT, this standard delivers a powerful framework that amplifies the potential of NFTs. In particular, MetaNFTs can be leveraged to represent [KeyStore contracts](https://vitalik.eth.limo/general/2023/06/09/three_transitions.html), abstracting the data-storage from the logic that consumes it.

![MetaNFT example](../assets/eip-7171/CoreAndPMs.jpg)


## Backwards Compatibility

This EIP is intended to augment the functionality of existing token standards without introducing breaking changes. As such, it does not present any backwards compatibility issues.

It offers an extension that allows for the storage and retrieval of Properties and Restrictions within a MetaNFT while maintaining compatibility with existing EIPs related to NFTs and tokenization.

We evaluate compatibility with popular tokenization standards on the following apendix [here](../assets/eip-7171/eip-7171-compat.md)



## Reference Implementation

[Nexera Protocol](https://nexeraprotocol.com/)

## Security Considerations

1. The management of Properties and Restrictions should be handled securely, with appropriate access control mechanisms in place to prevent unauthorized modifications.
2. Storing enriched metadata on-chain could potentially lead to higher gas costs. This should be considered during the design and implementation of MetaNFTs.
3. Increased on-chain data storage could also lead to potential privacy concerns. It's important to ensure that no sensitive or personally identifiable information is stored within MetaNFT metadata.
4. Ensuring decentralized control over the selection of Property Managers is critical to maintain the decentralization ethos of Ethereum.
5. Developers must also be cautious of potential interoperability and compatibility issues with systems that have not yet adapted to this new standard.

This EIP requires further discussions

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).