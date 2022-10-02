---
extip: 2
title: Token Certifications & Attestations Standard
description: A standard interface for assigning non-transferable qualification tokens, acting as certificates and attestations for particular capabilities, expertise or skills. Establishing an on-chain registry of capabilities, expertises and skills associated with a token, and the corresponding attribution of who has assigned the token to whom. 
author: Primavera De Filippi <pdefilippi@cyber.harvard.edu>, Isaac Patka <@ipatka>
status: Draft
type: Governance
category: Interface
created: 2022-09-22
---

## Abstract

ExtIP2 tokens provide the following features:

-   A means for anyone to create a "type" of qualification tokens, representing a particular capability, expertise of skill, and describing the minimum standards to be met in order to qualify for such qualification tokens.

-   A means for people to demonstrate that they hold a particular capability, expertise or skill (through the acquisition of "qualification tokens")

-   A means for people to issue qualification tokens to third parties to the extent that they can demonstrate that they are qualified to do so (through the acquisition of "qualified issuer" tokens)

-   On-chain tracking of the lineage who assigned which qualification token to whom.

-   On-chain tracking of how capabilities, expertises or skills have spread over time.

-   Standard format for skill descriptions in the metadata.

-   Function calls for assignment, co-signing, witnessing, flagging and burning a qualification token.

## Motivation

Institutions have developed precise practices and formal procedures to create a standardized system of certifications and qualifications for specific capabilities, expertise and skills, which is intended to be objective. However, despite the alleged objectivity of these systems, they suffer from the lack of granularity that comes from a more personal and subjective system of peer attestation and validation. Today, holding a diploma from a university is not enough of a guarantee that one is actually able to apply the knowledge acquired into the real world. Additional certifications can be collected, yet - because of their attempt at objectivity - these certifications are often impersonal and do not reflect the personalized assessment of individuals who have worked closely with the person holding these certificates.

Our goal with this standard is to help individuals - both those who already possess a set of diplomas and certifications from established institutions and those who did not engage into the process of acquiring these institutional accreditations - to demonstrate their capabilities, expertise and skills through alternative, more extitutional means.

We aim to create a system of token-based badges or qualifications that would enable people to (1) introduce a new typology of qualifications to be distributed to third parties, along with the basic requirements to be met to qualify for such tokens; (2) assign these qualification tokens to third parties who satisfy the minimum set of standards; (3) witnessing or flagging the assignment of these qualification tokens to a particular actor, in order to correspondingly reinforce or diminish their saliency.

An on-chain registry of "qualification tokens" and "qualified issuers tokens" will help in the discovery of the various capabilities, expertises and skills that have been created with this protocol, and how they have spread over time.

## Specification

```
Qualified Issuer

interface IExtituteIssuers {

 event Flag(

     uint256 badgeId,

     uint256 badgeType,

     address owner,

     address flagger,

     string messageUri

 );

 event Revoke(

     uint256 badgeId,

     uint256 badgeType,

     address owner,

     address revoker,

     string messageUri

 );

 function issueBadge(

     address _badgeContract,

     uint256 _badgeType,

     address _recipient

 ) external;

 function unequip(uint256 _badgeId) external;

 function revoke(uint256 _badgeId, string memory _messageUri) external;

 function flagBadge(

     uint256 _badgeId,

     address _owner,

     string memory _messageUri

 ) external;

}

Qualification Badge

interface ExtituteBadges {

 event BeginIssuance(

     uint256 badgeId,

     uint256 badgeType,

     address owner,

     address issuer,

     string messageUri

 );

 event Cosign(

     uint256 badgeId,

     uint256 badgeType,

     address owner,

     address cosigner,

     string messageUri

 );

 event Witness(

     uint256 badgeId,

     uint256 badgeType,

     address owner,

     address witness,

     string messageUri

 );

 event Flag(

     uint256 badgeId,

     uint256 badgeType,

     address owner,

     address flagger,

     string messageUri

 );

 event Revoke(

     uint256 badgeId,

     uint256 badgeType,

     address owner,

     address revoker,

     string messageUri

 );

 event NewBadgeType(

     uint256 badgeType,

     uint256 reqCosigners,

     string name,

     string uri

 );

 function issueBadge(

     uint256 _badgeType,

     address _recipient,

     string memory _messageUri

 ) external;

 function unequip(uint256 _badgeId) external;

 function revoke(uint256 _badgeId, string memory _messageUri) external;

 function cosignBadge(

     uint256 _badgeId,

     address _recipient,

     string memory _messageUri

 ) external;

 function witnessAsIssuer(

     uint256 _badgeId,

     address _owner,

     string memory _messageUri

 ) external;

 function witnessAsPeer(

     uint256 _badgeId,

     address _owner,

     uint256 _witnessBadgeId,

     string memory _messageUri

 ) external;

 function flagBadgeAsIssuer(

     uint256 _badgeId,

     address _owner,

     string memory _messageUri

 ) external;

 function flagBadgeAsPeer(

     uint256 _badgeId,

     address _owner,

     uint256 _flaggerBadgeId,

     string memory _messageUri

 ) external;

}
```

## Reference implementation:

A full reference implementation is available at the Extitute github repo:

<https://github.com/extitute/contracts/tree/main/src>

## New "Qualification" ExtIP

Through this ExtIP, we introduce a new type of ExtIPs, which relates specifically to the addition of a new type of qualification token that mainly requires specifying the type of qualification, and the minimum standards that must be met to acquire the token.

## Rationale

### EIP712 Interface

-   We use the standard EIP712 interface to display the badge metadata and a related image. Using EIP712 makes the ExtIP-002 badges compatible with NFT viewers for wallets

-   We disable transferability using the standard _beforeTokenTransfer hook in default EIP712 implementations

### Administrator Roles

-   In the reference implementation we have distinct roles for type creation, revocation, and creation of issuer badges. These roles can all belong to the same committee/ DAO/ multisig, or can be held by different subcommittees or individuals

### Issuer qualification badges

-   We use an NFT collection to manage the list of individuals able to issue qualification badges. By making issuer badges a distinct collection we can have a central list of authorized individuals, with multiple qualification badge collections

-   It is also useful to have a separate collection for issuer badges so we can easily distinguish between qualified issues and qualified individuals

### Qualification badges

-   We use an NFT collection to manage the list of qualified individuals for a specific skill or expertise. This collection can be used to find lists of individuals with collections of skills

### Revocation

-   We allow the authorized address to revoke badges in case the holder loses control of a wallet, or loses a qualification

### Flagging

-   We allow peers and issuers to flag badges that they think were wrongfully issued

### Burning

-   We make both issuer badges and qualification badges burnable by the holder. This is so people who receive a badge that they did not want can remove it from their wallet

### Non-transferability

-   We disable transferability of badges as they are tied to individuals and should not be able to be bought/ sold/ traded

## Examples

1.  Hug expertise

Alice has spent many years in a variety of communities, exploring the various ways in which people give hugs to each other, and acquiring considerable expertise in the skill of hugging people. Because of her expertise, she also is very good at assessing how good someone is at hugging people, but only after she has received a hug herself. She wants to make sure that this skillset is well recognized and documented, helping people demonstrate their hugging capabilities, without having to spend time running around the world hugging people all the time. 

She submits a request to the Extitute for the introduction of a new qualification token concerning the "hugging skill", and she specifies the minimum standards that have to be met in order to qualify for that skill. The Extitute assesses the proposal and approves it.

Alice subsequently asks to be assigned the first qualified issuer token for that skill. The Extitute identify the proper set of experts to respond to that requests and proceeds to evaluate the hugging skills of Alice to determine whether she does indeed qualify for a qualified issuer token. After having done the necessary due diligence, the Extitute approves her request and assigns her a qualified issuer token for the "hugging skill". 

Alice can now proceed to assigning qualified tokens to the people that she has hugged in the past, provided that they meet the minimum standards stipulated in the token. She also identifies a few individuals who are not only excellent huggers, but also display expertise in assessing the hugging skills of others. She assigns them a "qualified issuer" token for the hugging skill, which needs to be co-signed by another person holding the same token. Because she is the only one qualified to issue these qualification tokens at the moment, she needs to request the Extitute to do so. 

Over time, more and more people acquire the qualification tokens and qualified issuer tokens regarding the 'hugging skill'. In order to increase the granularity and subjective value of the system, people who hold the qualification tokens and/or the qualified issuer tokens can also 'witness' current token holders (in order to demonstrate their approval) or 'flag' them (in order to demonstrate the disapproval). 

The world now has a new means to establish the hugging-qualification of people, without having to hug them, as long as they trust the judgment of the various people who have certified their hugging skills.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/deed.fr).
