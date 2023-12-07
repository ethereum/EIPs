---
title: Authentication SBT using Credential
description: verifying a User's DID/credential and issuing SBT
author: Geunyoung Kim (@c1ick), JaeCheol Ryou <jcryou@home.cnu.ac.kr
discussions-to: TBD
status: Draft
type: Standards Track
category: ERC
created: 2023-11-01
requires: 165, 721
---

<!--
  READ EIP-1 (https://eips.ethereum.org/EIPS/eip-1) BEFORE USING THIS TEMPLATE!

  This is the suggested template for new EIPs. After you have filled in the requisite fields, please delete these comments.

  Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

  The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category.

  TODO: Remove this comment before submitting
-->

## Abstract

<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->


This document outlines the step-by-step process for verifying a user's Decentralized Identity(DID) credential and issuing a Soul Bound Token (SBT) upon successful verification.

We have considered granting user identity based on DID Credentials. Instead of providing the DID Credential itself within the wallet, we will use Soul Bound token(SBT) to indicate that the person has been authenticated through the Credential.

When validating the Credential within the smart contract, there is a risk of exposing personal information. To address this concern, we propose a process that protects user privacy using Zero-Knowledge Proofs (Zokrates) while authenticating the user.


## Motivation

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

The anonymous nature of wallets has led to numerous issues in DeFi, Metaverse Avatars, and similar platforms. Therefore, a new interface is needed where only individuals authenticated through Credentials can receive SBTs. Moreover, only those with issued SBTs should be permitted to access specific services.


## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->


The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.


### MetaData Interface


NFT metadata structured by the official ERC721 metadata standard or the Enjin Metadata suggestions are as follows referring to OpenSea docs.

```jsx
{
   "description":"University bachelor KYC",
   "external_url":"https://api.kor.credential/metadata/1/1",
   "home_url":"https://app.kor.credential/token/1",
   "image_url":"https://www.poap.xyz/events/badges/ethdenver-19.png",
   "name":" KOREA KYC",
   "attributes" : { ... },
}
```

In addition to the existing NFT metadata standards, a new standard for identity verification supplements the metadata with the "Issuer" and "credentialNumber" sections. When issuing SBTs, the Issuer and the credential number from the Credential are specified. This approach ensures that the user's personal information remains private. In case of any issues, the identity verification process can be traced back by requesting the credential number used for verification from the Issuer without revealing the user's information. This standard represents an extension of ERC721 metadata.

```jsx
{
   "description":"University bachelor KYC",
   "external_url":"https://api.kor.credential/metadata/1/1",
   "home_url":"https://app.kor.credential/token/1",
   "image_url":"https://www.poap.xyz/events/badges/ethdenver-19.png",
   "name":" KOREA KYC",
   "attributes" : { ... },
   "Iusser" : { ...},
   "credentialNumber" : { ... },
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

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

This is a system that verifies the basic DID signature by integrating the Ethereum extension program Zokrates. Following the verification of the DID signature, it proceeds with issuing SBT, allowing the validation of a user's identity information.


## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.


## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

There are no security considerations related directly to the implementation of this standard.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
