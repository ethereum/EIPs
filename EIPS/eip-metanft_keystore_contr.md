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
requires: 721, 1155
---

## Abstract

- This EIP proposes a standard interface for NFTs (MetaNFTs) that allows for the storage and retrieval of additional on-chain data, referred to as Properties and Restrictions. This enhances the capabilities of NFTs, enabling them to hold mutable states and reflect changes over time.

- MetaNFTs aim to address the limitations of traditional NFTs by enabling on-chain data aggregation, providing an interface for standardized, interoperable, and composable data management solutions within NFTs.

- MetaNFTs store data as Properties, an agnostic data structure. Properties can have Restrictions (i.e. in the case of an identity-based Property or SoulBound Tokens, a Transfer Restriction; in the case of staking, a Lock Restriction).

- MetaNFTs address some of the existing limitations with traditional keystore contracts that aim to separate the logic from the storage.

- This EIP proposes a standard interface for interacting with Properties and Restrictions within a MetaNFT (Meta Non-Fungible Token) on the Ethereum blockchain. This enables greater flexibility, interoperability, and utility for NFTs

## Motivation

This proposal is motivated by the need to extend the capabilities of NFTs beyond their static nature, enabling them to hold mutable states and reflect changes over time. This is particularly relevant for use cases where the state of the NFT needs to change in response to certain events or conditions, as well as when the storage and the logic must be separated. For instance, NFTs representing Keystore contracts, Smart Wallets, or the digital representation of dynamic assets.

The Ethereum ecosystem hosts a rich diversity of token standards, each designed to cater to specific use cases. While such diversity spurs innovation, it also results in a highly fragmented landscape, especially for Non-Fungible Tokens (NFTs). NFTs conforming to standards such as ERC-721 and ERC-1155 have often faced limitations when representing complex digital assets. While each standard serves its purpose, they often lack the flexibility needed to manage additional on-chain data associated with the utility of these tokens.

Furthermore, there is a need for a standardized interface to manage these mutable states for tokenization. Without a standard, different projects might implement their own ways of managing mutable states, incurring in further fragmentation and interoperability issues. A standard interface would provide all NFTs, regardless of their specific use case, with a mechanism for interacting with each other in a consistent and predictable way.

We propose the standardization of an interface for storing and accessing data on-chain, codifying information as Properties and Restrictions associated with NFTs use cases. This enhancement is designed to work by extending existing token standards, providing a flexible, efficient, and coherent way to manage the data associated with:

- **Standard Neutrality**: The standard aims to separate the data logic from the token standard. This neutral approach would allow NFTs to transition seamlessly between different token standards, promoting interactions with platforms or marketplaces designed for those standards. This could significantly improve interoperability among different standards, reducing fragmentation in the NFT landscape.

- **Consistent Interface**: A uniform interface abstracts the data storage from the use case, irrespective of the underlying NFT standard. This consistent interface simplifies interoperability, enabling platforms and marketplaces to interact with a uniform data interface, regardless of individual token standards. This common ground for all NFTs could reduce fragmentation in the ecosystem.

- **Simplified Upgrades**: A standard interface for representing the utility of an NFT would simplify the process of upgrading NFTs to new token standards. This could help to reduce fragmentation caused by outdated standards, facilitating easier transition to new, more efficient, or feature-rich standards.

- **Minimized Redundancy**: Currently, developers often need to write similar code for different token standards, leading to unnecessary redundancy. A standardized interface would allow developers to separate the data storage code from the underlying token utility logic, reducing redundancy and promoting greater unity in the ecosystem.

- **Actionable data**: Current practices often store metadata off-chain, rendering it inaccessible for smart contracts without the use of oracles. Moreover, metadata is often used to store information that could otherwise be considered data relevant to the NFT's inherent identity. This EIP seeks to rectify this issue by introducing a standardized interface for reading and storing additional on-chain data related to NFTs.

A case-by-case analysis was performed and summarized [here](../assets/eip-7210/eip-7210-compat.md).


## Specification

### Terms

**MetaNFT**: A uniquely identifiable non-fungible token. A MetaNFT MAY store Properties and Restrictions.

**Property**: A modifiable information unit stored within a MetaNFT. It SHOULD be capable of undergoing modifications.

**Restriction**: A configuration data structure associated with a Property within the MetaNFT. Restrictions are REQUIRED to define conditions under which a Property can be modified.

### Interface

```solidity
interface IERC7210 {
  /**
   * @notice Gets a property of the MetaNFT.
   * @dev This function allows anyone to get a property of the MetaNFT.
   * @param _tokenId The ID of the MetaNFT.
   * @param _propertyKey The key of the property to be retrieved.
   * @return _propertyValue The value of the property.
   */
  function getProperty(
      uint256 tokenId,
      string calldata propertyKey
    ) external view returns (bytes memory);

  /**
   * @notice Gets a restriction of the MetaNFT.
   * @dev This function allows anyone to get a restriction of the MetaNFT.
   * @param _tokenId The ID of the MetaNFT.
   * @param _restrictionKey The key of the restriction to be retrieved.
   * @return _restrictionValue The value of the restriction.
  */
  function getRestriction(
      uint256 tokenId,
      string calldata restrictionKey
    ) external view returns (bytes memory);

  /**
   * @notice Sets a property of the MetaNFT.
   * @dev This function allows the owner or an authorized operator to set a property of the MetaNFT.
   * @param _tokenId The ID of the MetaNFT.
   * @param _propertyKey The key of the property to be set.
   * @param _propertyValue The value of the property to be set.
  */
  function setProperty(
      uint256 tokenId,
      string calldata propertyKey,
      bytes calldata propertyValue
    ) external;

  /**
   * @notice Sets a restriction of the MetaNFT.
   * @dev This function allows the owner or an authorized operator to set a restriction of the MetaNFT.
   * @param _tokenId The ID of the MetaNFT.
   * @param _restrictionKey The key of the restriction to be set.
   * @param _restrictionValue The value of the restriction to be set.
   */
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

### MetaNFT Functionality
A MetaNFT MUST extend the functionality of traditional NFTs through the incorporation of Properties and Restrictions in its internal storage. The Properties and Restrictions of a MetaNFT SHALL be stored on-chain and be made accessible to smart contracts. The interface defining this interaction is as follows:

**Examples of Properties**:

**Metadata**: This could include the name, description, image URL, and other metadata associated with the NFT. For example, in the case of an art NFT, the setProperty function could be used to set the artist's name, the creation date, the medium, and other relevant information.

**Ownership History**: The setProperty function could be used to record the ownership history of the NFT. Each time the NFT is transferred, a new entry could be added to the ownership history property.

**Royalties**: The setProperty function could be used to set a royalties property for the NFT. This could specify a percentage of future sales that should be paid to the original creator.

**Zero-Knowledge Proofs**: The setProperty function could be used to store Identity information related to the NFTs owner and signed by KYC provider.

**Oracle Subscription**: An oracle system can stream data periodically into the Property.



**Examples of restrictions**:

**Transfer Restrictions**: The setRestriction function could be used to limit who the NFT can be transferred to. For example, it could be used to prevent the NFT from being transferred to certain addresses in the case of Soulbound tokens.

**Usage Restrictions**: The setRestriction function could be used to limit how the NFT can be used. For example, in the case of a digital asset in a game, the setRestriction function could be used to specify that the asset can only be used in certain ways or at certain times.

**Geographical Restrictions**: The setRestriction function could be used to limit where the NFT can be used. For example, in the case of a ticket to a physical event, the setRestriction function could be used to specify that the ticket can only be used in a certain location.



## Rationale

The decision to encode Properties and Restrictions as bytes in the MetaNFT Interface is primarily driven by flexibility and future-proofing. Encoding as bytes allows for a wide range of data types to be stored, including but not limited to strings, integers, addresses, and more complex data structures, providing the developer with flexibility to accommodate diverse use cases. Furthermore, as Ethereum and its standards continue to evolve, encoding as bytes ensures that the MetaNFT standard can support future data types or structures without requiring significant changes to the standard itself.

A case-by-case example on potential Properties and Restrictions encodings was performed and summarized [here](../assets/eip-7210/eip-7210-encoding.md).

The inclusion of Properties and Restrictions within a MetaNFT provides the capability to associate a richer set of on-chain accessible information with an NFT. This enables a wide array of complex, dynamic, and interactive use cases to be implemented with NFTs.

Properties in a MetaNFT offer flexibility in storing mutable on-chain data that can be modified as per the requirements of the token's use case. This allows the NFT to hold mutable states and reflect changes over time, providing a dynamic layer to the otherwise static nature of NFTs through a standardized interface.

Restrictions, on the other hand, provide a structured way to control the modification conditions of these properties, ensuring the integrity and security of the data. By stipulating conditions under which a Property can be modified, Restrictions bring a level of control and compliance to the dynamic capabilities of MetaNFTs.

By leveraging Properties and Restrictions together within the MetaNFT, this standard delivers a powerful framework that amplifies the potential of NFTs. In particular, MetaNFTs can be leveraged to represent [KeyStore contracts](https://vitalik.eth.limo/general/2023/06/09/three_transitions.html), abstracting the data-storage from the logic that consumes it.

![MetaNFT example](../assets/eip-7210/CoreAndPMs.jpg)


## Backwards Compatibility

This EIP is intended to augment the functionality of existing token standards without introducing breaking changes. As such, it does not present any backwards compatibility issues. Already deployed NFTs can be wrapped as Properties, with the application of Restrictions relevant to each use-case.

It offers an extension that allows for the storage and retrieval of Properties and Restrictions within a MetaNFT while maintaining compatibility with existing EIPs related to NFTs and tokenization.


## Reference Implementation

[Nexera Protocol](https://nexeraprotocol.com/)

## Security Considerations

1. The management of Properties and Restrictions should be handled securely, with appropriate access control mechanisms in place to prevent unauthorized modifications.
2. Storing enriched metadata on-chain could potentially lead to higher gas costs. This should be considered during the design and implementation of MetaNFTs.
3. Increased on-chain data storage could also lead to potential privacy concerns. It's important to ensure that no sensitive or personally identifiable information is stored within MetaNFT metadata.
4. Ensuring decentralized control over the selection of Property Managers is critical to maintain the decentralization ethos of Ethereum.
5. Developers must also be cautious of potential interoperability and compatibility issues with systems that have not yet adapted to this new standard.

The presence of mutable Properties and Restrictions can be used to implement security measures. In the context of preventing unauthorized access and modifications, a MetaNFT keystore contracts could implement the following strategies, adapted to each use-case:

**Role-Based Access Control (RBAC)**: Only accounts assigned to specific roles at a Restriction level can perform certain actions on a Property. For instance, only an 'owner' might be able to call setProperty or setRestriction functions.

**Time Locks**: Time locks can be used to delay certain actions, giving the community or a governance mechanism time to react if something malicious is happening. For instance, changes to Properties or Restrictions could be delayed depending on the use-case.

**Multi-Signature (Multisig) Properties**: Multisig Properties could be implemented with Restrictions that require more than one account to approve an action performed on the Property. This could be used as an additional layer of security for critical functions. For instance, changing certain properties or restrictions might require approval from multiple trusted signers.



This EIP requires further discussions

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).