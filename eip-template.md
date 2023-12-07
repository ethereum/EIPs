---
title: Authentication SBT using Credential
description: verifying a User's DID/credential and issuing SBT
author: Geunyoung Kim (@c1ick), JaeCheol Ryou <jcryou@home.cnu.ac.kr
discussions-to: TBA
status: Draft
type: Standards Track
category: ERC
created: 2023-11-01
requires: 165, 721
---

## Abstract


This document outlines the step-by-step process for verifying a user's Decentralized Identity(DID) credential and issuing a Soul Bound Token (SBT) upon successful verification.

We have considered granting user identity based on DID Credentials. Instead of providing the DID Credential itself within the wallet, we will use Soul Bound token(SBT) to indicate that the person has been authenticated through the Credential.

When validating the Credential within the smart contract, there is a risk of exposing personal information. To address this concern, we propose a process that protects user privacy using Zero-Knowledge Proofs (Zokrates) while authenticating the user.


## Motivation

The anonymous nature of wallets has led to numerous issues in DeFi, Metaverse Avatars, and similar platforms. Therefore, a new interface is needed where only individuals authenticated through Credentials can receive SBTs. Moreover, only those with issued SBTs should be permitted to access specific services.


## Specification


The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.


### MetaData Interface


NFT metadata structured by the official ERC721 metadata standard or the Enjin Metadata suggestions are as follows referring to OpenSea docs.

```jsx
{
   "description": "University bachelor KYC",
   "external_url":"https://api.kor.credential/metadata/1/1",
   "home_url": "https://app.kor.credential/token/1",
   "image_url": "https://www.poap.xyz/events/badges/ethdenver-19.png",
   "name":" KOREA KYC",
   "attributes": { ... },
}
```

In addition to the existing NFT metadata standards, a new standard for identity verification supplements the metadata with the "Issuer" and "credentialNumber" sections. When issuing SBTs, the Issuer and the credential number from the Credential are specified. This approach ensures that the user's personal information remains private. In case of any issues, the identity verification process can be traced back by requesting the credential number used for verification from the Issuer without revealing the user's information. This standard represents an extension of ERC721 metadata.

```jsx
{
   "description": "University bachelor KYC",
   "external_url": "https://api.kor.credential/metadata/1/1",
   "home_url": "https://app.kor.credential/token/1",
   "image_url": "https://www.poap.xyz/events/badges/ethdenver-19.png",
   "name":" KOREA KYC",
   "attributes": { ... },
   "Iusser": { ...},
   "credentialNumber": { ... },
 }
```

We have defined a structure to represent VerifiedPresentation. It includes the user's wallet address, issuer, user name, and Credential Number

```jsx
struct VerifiedPresentation {
address userAddr;
string issuer;
string user;
uint CredentialNumber;
}
```

Following that, here is the contract that verifies a user's Credential proof and issues SBTs:


### Contract Interface


In this scenario, a **`verify`** function is created using Zokrates. Upon successful verification, the generated **`verify`** function calls the SBT issuance contract, enabling the entire process.

```
/ SPDX-License-Identifier: CC0-1.0
pragma solidity^0.8.0;interface IERC5192 {

/// @ Function to verify the user's proof.
/// @ Generated through Zokrates, required parameters upon completion of generation are proof, input, and numofCred.
/// @ Other information such as issuer/holder is optional.
function verify(Proof memory proof, uint[2] memory input, uint numOfCred) returns ();

/// @ Only those who have completed verifyProof can obtain the opportunity to issue SBT.
/// @ Only the service provider can call the createSBT function.
/// @ Issues SBT to authenticated users, with the verified credential Number and Issuer being input for tokenURI.
function createSBT(address user, String memory tokenURI) public onlyOwner returns(uint256) public onlyWoner returns(uint256))

/// @ Only the service provider can call the createSBT function.
/// @ Issuing an SBT allows cancellation effects by severing the user's tokenURI, such as when the credential is revoked.
function updateTokenURI(address user, string memory tokenURI) public onlyOwner

/// @ Added cannotTransfer functionality to prevent the transfer of SBT to others.
function safeTransferFrom(adress _from, address _to, uint256 _tokenId) public virtual oveerid

}
```

Through this process, obtaining SBT is the only means of authentication, and the possession of SBT subsequently serves as a method for identity verification.


## Rationale


This is a system that verifies the basic DID signature by integrating the Ethereum extension program Zokrates. Following the verification of the DID signature, it proceeds with issuing SBT, allowing the validation of a user's identity information.


## Backwards Compatibility

No backward compatibility issues found.


## Security Considerations

There are no security considerations related directly to the implementation of this standard.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
