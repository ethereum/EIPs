---
eip: <to be assigned>
title: Ethereum Signed Packages
author: Philipp Langhans (@PhilippLgh) <philipp@ethereum.org>
discussions-to: https://github.com/PhilippLgh/ethereum-signed-packages/issues
status: Draft
type: Standards Track (Core, Networking, Interface, ERC)
category (*only required for Standard Track): ERC
created: 2019-02-27
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

# Ethereum Signed Packages (EPK)

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Ethereum Signed Packages are container files such as .zip, .tar or .asar files containing application source code, assets, executables or smart contracts which are digitally signed using Ethereum's signature schemes. 
They can potentially have the extension `.epk` to better distinguish and recognize them.

## Terminology
We will use the term `certificate` to describe a data structure which represents a public key or Ethereum address and binds it for a specified time to an identity. An `identity` in this case can be a `username` of an online service, `email` or just a `person or device name`. Certificates, identities, and key representation formats are outside of the scope of this document and should be defined in separate EIPs.
The terms module, (Web) application and package might be used interchangeable.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
The proposed solution solves the problem of module authentication. We need better ways to determine and verify the author of a (software) package or module and to verify the authenticity and integrity of their provided code. 
Ideally, such verifications can be done in a privacy preserving and decentralized way without the need for certificate authorities (CAs). Additionally, we can recover the Ethereum address from the author's signature and use it in a transaction to financially incentivize authors to sign and maintain their code, which helps to create a healthier balance and relationship between Free & Open-Source (FOSS) developers providing and maintaining packages and paid software that is highly dependant on and consumes these packages.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
`Code Signing` is widely adopted e.g. in the Java Ecosystem. [JAR](https://docs.oracle.com/javase/tutorial/deployment/jar/signing.html) and [Android APK](https://developer.android.com/studio/publish/app-signing) files already have signature standards and are digitally signed to establish additional security mechanisms and prevent e.g. man-in-the-middle attacks.
Decentralization in software ecosystems means that the code for a build is fetched from many different servers, repositories or sources which requires complex trust models.
In Web app (and Dapp) development these important security features are missing from almost all distributed packages, registries and package managers (see for example [Node Package Manager (NPM)](http://www.npmjs.com/)).

 It would be an option to just propose and "enforce" the adoption of existing signing mechanisms and PKI for the security critical applications we are building (e.g. wallets, clients, signers) and to establish trustworthy, (centrally) organized, and vetted package registries for audited packages. 
 However, the potentially better alternative is to propose and leverage the signing capabilities of Ethereum key pairs and tools from the Ethereum ecosystem and their financial capabilities which has significant advantages over traditional code signing:
 - authors can become financially incentivized to develop and maintain(!) secure open source software (zero-config donation buttons, auto revenue splitting) which posed to be one of the biggest security problems of the past
- it helps projects to manage donations and payments through a single software defined and package-contained source which makes project funding transparent, granular and makes it easier for projects to exist independent of parent organizations or donation platforms
- it helps to transition away from centralized PKI and certificate authorities
- it allows to move to privacy preserving trust models instead
- we can issue and accept self-signed certificates with short expiration times and dedicated key usage which makes the certificate issuance, identity verification and signing process much faster and efficient and further limits the power of stolen certificates and keys
- certificates can be defined to match and cover real world usage / identity proofs: e.g. "author has publishing access to git repository X" instead of "author has *common name* Y, works for organization W, and lives at address Z"
- instead of having to pay hundreds of USD per year for a centrally issued and verified certificate, authors could get paid to sign their code and make modules more secure
- leverages existing and emerging hardware such as "hardware wallets" to sign code -> no need to buy proprietary usb tokens and install drivers with lock-in effects
- benefits not just the crypto ecosystem but the wider Web infrastructure
- software licensing and auto-payments are possible which improves the portability of apps and packages and allows for decentralized software marketplaces 
- helps to decouple development from distribution and hosting
- compatible to emerging blockchain based identity provider solutions
- leverages existing and emerging ecosystem tools for key management such as keybase or metamask to manage keys and sign packages in the browser
- certificate revocation lists can be implemented on the blockchain to be tamper proof and "instantly" updated to prevent bad actors from using stolen keys to sign malware

Discussion on the magicians forum: [Package and Dependency Managers](https://ethereum-magicians.org/t/package-and-dependency-managers/2418)

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
A specification draft and reference implementation can be found at:

**Specification Draft**
[https://github.com/PhilippLgh/ethereum-signed-packages/](https://github.com/PhilippLgh/ethereum-signed-packages/blob/master/spec/README.md).

The core idea is to calculate the digests for the files contained within an archive file and then sign these digests with a certificate (x509 currently not supported) or Ethereum key pair.

To represent these signatures, we are using JSON Web Signatures (JWS) as defined per [RFC7515](https://tools.ietf.org/html/rfc7515) and [RFC7519](https://tools.ietf.org/html/rfc7519).

The certificate in this case is just represented by a human-readable JSON structure binding a public secp256k1 key or Ethereum address to a dedicated key usage, valid time stamp, validity period and identity. The spec for this is out of scope and should probably be discussed in a separate EIP (TBD).


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The rationale is mostly contained in above spec draft, but mainly we are using easy to parse and human readable formats like JSON and JSON Web Signatures / JSON Web Tokens instead of historically established binary formats such as ASN.1 with DER used in x509 or URL-safe [Base64URL](https://tools.ietf.org/html/rfc4648) encoded text as it is used by most JSON Web Tokens (JWT).

One problem that emerges is that Ethereum defines two ways of signing arbitrary messages. `ecsign` would provide better compatibility with e.g. hardware but can be abused to trick users into signing transactions. `eth message signing` is more user friendly and secure but would make it much harder to get standardized in e.g. in [RFC7518](https://tools.ietf.org/html/rfc7518). 
Ideally, this issue is solved by having better key metadata and dedicated wallets which auto-move large funds but this should be a topic for future discussions.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
\-

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
Ethereum Signed Packages will be piloted on a bigger scale in Ethereum's [new client manager software](https://github.com/ethereum/mist-shell):

[https://github.com/ethereum/mist-shell/blob/master/ETH_CERTS.md](https://github.com/ethereum/mist-shell/blob/master/ETH_CERTS.md)

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
A reference implementation and signer CLI ttool can be found at:

**Signer CLI Tool (WIP)**
[https://github.com/PhilippLgh/ethereum-signed-packages](https://github.com/PhilippLgh/ethereum-signed-packages)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).