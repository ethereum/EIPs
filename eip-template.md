---
title: About Contract Metadata
description: This standard enhances transparency and informed decision-making by allowing the inclusion of relevant information, such as company details and audits, in Ethereum contracts.
author: David Beatove (@Beatove)
discussions-to:
status: Draft
type: Standards Track
category: ERC
created: 2023-06-21
---

## Abstract

This standard introduces the 'about()' function in Ethereum contracts. This function serves as a means to retrieve a URI pointing to a JSON file that contains additional information about the contract. By implementing the 'about()' function, contract creators can provide users with comprehensive contract details in a structured format, promoting transparency and enabling easy access to supplementary contract information through the linked JSON file.

## Motivation

By establishing the 'about()' function as a standard feature, it becomes easier for users to access and evaluate contract information uniformly across the Ethereum network. The 'about()' function ensures that contracts provide clear and concise descriptions, making it simpler for users to understand the purpose and key features of a contract. Additionally, the inclusion of company information, contact details, and auditing firm data within the 'about()' function enhances transparency, facilitating better assessment of a contract's credibility and compliance. 

Standardizing contract information through the 'about()' function also contributes to improved contract discoverability. Users can search, filter, or browse contracts based on the provided descriptions returned by the 'about()' function, enabling them to find contracts that align with their specific needs or interests more efficiently. This promotes a more accessible and user-friendly Ethereum ecosystem, fostering greater participation and collaboration among users.

In summary, the relevance of implementing the 'about()' function lies in establishing a consistent and standardized approach to contract information within Ethereum. By providing a standardized way to retrieve clear and concise contract details, promoting transparency, enhancing contract discoverability, and enabling informed decision-making, the 'about()' function contributes to a more trustworthy and efficient ecosystem for Ethereum users.


## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

The 'about()' function is a read-only function that allows contract users and external applications to retrieve the URI representing the location of the JSON file containing the contract metadata. 
The 'about()' function MUST return a string value representing the URI pointing to the JSON file. 
The JSON file contains structured information about the contract, such as company details, contact information, auditing firm data, or any other relevant metadata.
The URI can follow any standard format, such as HTTP/HTTPS or IPFS, allowing for flexibility in storing and accessing the metadata.
It is RECOMMENDED to have a 'setAboutURI()' function in addition to the 'about()' function. This function would allow for updating the value of the URI returned by the 'about()' function in case any relevant data needs to be changed. 
By providing a way to update the URI, contract creators can ensure that users have access to the most up-to-date and accurate contract metadata. 
If the 'setAboutURI()' function is implemented, the contract MUST implement the 'event AboutURIUpdated(string newAboutURI)'. 
This event should be emitted whenever the URI value is updated using the 'setAboutURI()' function. This ensures transparency and provides a way for interested parties to track changes in the contract metadata.
The 'setAboutURI()' function SHOULD have a control access modifier to restrict who can execute it. By implementing a control access modifier such as 'onlyOwner', contract creators can ensure that only authorized entities are allowed to update the contract metadata URI. This helps maintain the integrity and security of the contract information.

Syntax: function about() external view returns (string) 
Function selector: 0x5e1d5482

## Rationale

The rationale behind the design of this standard is driven by the fragmented nature of including metadata about the contract itself and the difficulty in accessing such information.
This consolidation of metadata provides a more cohesive and accessible way for users and external applications to access contract information. 

Alternate designs were considered, such as relying on external documentation or separate contract variables for each piece of metadata. However, these approaches were deemed less practical and less user-friendly. By incorporating metadata directly within the contract through the 'about()' function, users can easily access comprehensive information without the need to search through fragmented sources. 

The implementation of the ERC standard can be extended in various ways, depending on the type of contract. One significant extension involves incorporating additional metadata specifically tailored for marketplaces. This expanded metadata can include various elements such as the logo of the collection, banners, descriptions, links to social media, website URLs, and documentation links. These enhancements allow marketplaces to provide a more enriched user experience and facilitate the discovery and presentation of contract collections in a standardized manner.


## Backwards Compatibility

No backward compatibility issues found.

## Reference Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";

contract ContractMetadata is Ownable {

    string _about;
    event AboutURIUpdated(string newAboutURI);

    constructor(string memory about){
        _about = about;
    }

    function setAboutURI(string calldata newAboutURI) public onlyOwner{
        _about = newAboutURI;
        emit AboutURIUpdated(newAboutURI);
    }

    function about() external view returns(string memory){
        return _about;
    }
}

```

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
