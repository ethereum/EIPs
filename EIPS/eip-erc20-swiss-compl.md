---
eip: <to be assigned>
title: ERC20 for Swiss compliant
author: Gianluca Perletti (@Perlets9), Alan Scarpellini (@alanscarpellini), Roberto Gorini (@robertogorini), Manuel Olivi (@manvel79)
discussions-to: Pull Request
status: Draft
type: Standards Track
category: ERC
created: 2020-09-08
requires: eip-20
---

TODO:
This is the suggested template for new EIPs.

Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

The title should be 44 characters or less.

## Simple Summary
This new standard is an ERC-20 compatible token with restrictions that comply with one or more one the following Swiss laws: Stock Exchange Act, the Banking Act, the Financial Market Infrastructure Act, the Act on Collective Investment Schemes and the Anti-Money Laundering Act. The Financial Services Act and the Financial Institutions Act must also be considered. The solution achieved meet also the European jurisdiction. 

## Abstract
This new standard meets the new era of asset tokens (or security tokens). These new methods manage securities ownership during issuance and trading. The issuer is the only role that can manage a white-listing and the only one that is allowed to execute “freeze” or “revoke” functions.

## Motivation
In its ICO guidance dated February 16, 2018, FINMA (Swiss Financial Market Supervisory Authority) defines asset tokens as tokens representing assets and/or relative rights. It explicitly mentions that asset tokens are analogous to and can economically represent shares, bonds, or derivatives. The long list of relevant financial market laws mentioned above reveal that we need more methods than with Payment and Utility Token. 

## Specification
TODO:The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).

## Rationale
There are currently no token standards that expressly facilitate conformity to securities law and related regulations. EIP-1404 (Simple Restricted Token Standard) it’s not enough to address FINMA requirements around re-issuing securities to Investors.
In Swiss law, an issuer must eventually enforce the restrictions of their token transfer with a “freeze” function. The token must be “revocable”, and we need to apply a white-list method for AML/KYC checks.

## Backwards Compatibility
TODO:All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
TODO:Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Implementation
TODO:The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Security Considerations
TODO:All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright
TODO:Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
