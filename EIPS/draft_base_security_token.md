---
title: Base Security Token
eip: <to be assigned>
author: Maxim Kupriianov <mk@atlant.io>, Julian Svirsky <js@atlant.io>
status: Draft
type: Standards Track
category: ERC
created: 2018-09-28
require: ERC-20 (#20), ERC-1066 (#1066)
---

## Simple Summary

An extension to ERC-20 standard token that provides compliance with securities regulations and legal enforceability.

## Abstract

This EIP defines a minimal set of additions to the default token standard such as [ERC-20](https://eips.ethereum.org/EIPS/eip-20), that allows to comply with domestic and international legal requirements. Such requirements include KYC and AML regulatory work, ability to lock tokens on account due to a legal dispute or a fraud case. Also the ability to attach additional legal documentation, in order to set up a dual-binding between the token and off-chain legal entities.

The scope of this standard is kept as narrow as possible to avoid limiting potential use-cases of this base security token, any additional functionality and limitations not defined in this standard may be enforced on per-project basis.

## Motivation

There are several Security Token standards being proposed in the recent time. Examples include [ERC-1400/ERC-1411](https://github.com/ethereum/EIPs/issues/1411), also [ERC-1450](https://github.com/ethereum/EIPs/issues/1450). We have concerns about each of them, mostly because the scope of these EIP contains many project-specific or market-specific details. Since many EIPs are coming from the respective backing companies, they capure a lot of niche requirements that are excessive for a general case.

For instance, ERC-1411 uses dependency on [ERC-1410](https://github.com/ethereum/eips/issues/1410) but it falls out of the "security tokens" scope, also its dependency on [ERC-777](https://github.com/ethereum/eips/issues/777]) will block the adoption for a quite period of time before ERC-777 is finalized, but the integration guidelines for existing ERC-20 workflows are not described in the EIP yet. Another attempt to make a much simplier base standard [ERC-1404](https://github.com/ethereum/EIPs/issues/1404) is missing a few important points, specifically it doesn't provide enough granularity to distingush between different ERC-20 transfer functions such as`transfer` and `transferFrom`, it also doesn't provide a way to bind a legal paperwork to the issued tokens.

What we propose in this EIP should be a simple and very modular solution for creating a base security token for the most wide scope of applications, so it can be used by other issuers to build upon. The issuers should be able to add more restrictions and policies to the token, using the functions and implementation proposed below, but they must not be limited in any way while using this ERC.

## Specification

The ERC-20 token provides the following basic features:

```solidity
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
```

This will be extended as follows:

```solidity
interface BaseSecurityToken /* is ERC20 */ {
    // Checking functions
    function checkTransferAllowed (address from, address to, uint256 value) public view returns (byte);
    function checkTransferFromAllowed (address from, address to, uint256 value) public view returns (byte);
    function checkMintAllowed (address to, uint256 value) public view returns (byte);
    function checkBurnAllowed (address from, uint256 value) public view returns (byte);

    // Documentation functions
    function attachDocument(bytes32 _name, string _uri, bytes32 _contentHash) external;
    function lookupDocument(bytes32 _name) external view returns (string, bytes32);
}
```

### Transfer Checking Functions

We introduce four new functions that should be used to check that the actions are allowed for the provided inputs. The implementation details of each function are left for the token issuer, it is his responsibility to add all necessary checks that will validate an operation in accordance with KYC/AML policies and legal rules set for a specific token asset.

Each function must return a status code from the common set of Ethereum status codes (ESC), according to [ERC-1066](https://eips.ethereum.org/EIPS/eip-1066). Localization of these codes is out of scope of this proposal and may be optionally solved by adopting [ERC-1444](https://github.com/ethereum/EIPs/pull/1444) on the application level. If the operation is allowed by a checking function, the return status code must be `hex"11"` (Allowed) or an issuer-specific code with equivalent but more precise meaning. If the opeartion is not allowed by a checking function, the status must be `hex"10"` (Disallowed) or an issuer-specific code with equivalent but more precise meaning. Upon an internal error, the function must return the most relevant code from the general code table or an issuer-specific equivalent, example: `hex"F0"` (Off-Chain Failure).

**For [ERC-20](https://eips.ethereum.org/EIPS/eip-20) based tokens,**
* It is required that `transfer` function must be overridden with logic that checks the corresponding `checkTransferAllowed` return status code.
* It is required that `transferFrom` function must be overridden with logic that checks the corresponding `checkTransferFromAllowed` return status code.
* It is required that `approve` function must be overridden with logic that checks the corresponding `checkTransferFromAllowed` return status code.
* Other functions such as `mint` and `burn` must be overridden, if they exist in the token implementation, they should check `checkMintAllowed` and `checkBurnAllowed` status codes accordingly.

**For [ERC-777](https://eips.ethereum.org/EIPS/eip-777) based tokens,**
* It is required that `send` function must be overridden with logic that checks the corresponding return status codes:
    - `checkTransferAllowed` return status code, if transfer happens on behalf of the tokens owner;
    - `checkTransferFromAllowed` return status code, if transfer happens on behalf of an operator (i.e. delegated transfer).
* It is required that `burn` function must be overridden with logic that checks the corresponding `checkBurnAllowed` return status code.
* Other functions, such as `mint` must be overridden, if they exist in the token implementation, e.g. if the security token is mintable. `mint` function must call `checkMintAllowed` ad check it return status code.

For both cases,

* It is required for guaranteed compatibility with ERC-20 and ERC-777 wallets that each checking function returns `hex"11"` (Allowed) if not overridden with the issuer's custom logic.
* It is required that all overriden checking functions must revert if the action is not allowed or an error occured, according to the returned status code.

Inside checker functions the logic is allowed to use any feature available on-chain: perform calls to registry contracts with whitelists/blacklists, use built-in checking logic that is defined on the same contract or even run off-chain queries through oracle.

### Documentation Functions

We also introduce two new functions that should be used for document management purposes. Function `attachDocument` adds a reference pointing to an off-chain document, with specified name, URI and the contents hash. The hashing algorithm is not specified within this standard, but the resulting hash must be not longer than 32 bytes. Function `lookupDocument` gets the referenced document by its name.

* It is not required to use documentation functions, they are optional and provided as a part of a legal framework.
* It is required that if `attachDocument` function has been used, the document reference must have an unique name, overwriting the references under same name is not allowed. All implementations must check if the reference under the given name is already existing.

## Rationale

This EIP targets both ERC-20 and ERC-777 based tokens, although the most favor is given to ERC-20 due to its adoption, however we keep in mind the forthcoming ERC-777 and the extension is designed to be compatible.

All checking functions are named with prefixes `check` since they return check status code, not booleans, because that is important to facilitate the debugging and tracing process. It is responisibility of the issuer to implement the logic that will handle the return codes appropriately, some handlers will simply throw, other handlers would log things for the future process mining. More rationale for status codes can be seen in [ERC-1066](https://eips.ethereum.org/EIPS/eip-1066).

We require two different transfer validation functions: `checkTransferAllowed` and `checkTransferFromAllowed` since the corresponding `transfer` and `transferFrom` are ususally called in different contexts. Some token standards such as [ERC-1450](https://github.com/ethereum/EIPs/issues/1450) are explicitly disallowing use of `transfer`, while allow only `transferFrom`, there might be also different complex scenarios, where `transfer` and `transferFrom` should be treated differently. ERC-777 is relying on its own `send` for transferring tokens, so its reasonable to switch between checker functions based on its call context. We decided to omit `checkApprove` function since it would be used excactly in the same context as `checkTransferFromAllowed`. In many cases it is required not only regulate securities transfers, but also restrict `burn` and `mint` operations, and we added additional checker functions for that.

The documentation functions that we propose here are a must-have tool to create dual-bindings with off-chain legal documents, a great example of this can be seen in [Neufund's Employee Incentive Options Plan](https://medium.com/@ZoeAdamovicz/37376fd0384a) legal framework that implements full legal enforceability: the smart contract refers to printed ESOP Terms & Conditions Document, which itself refers back to smart contract. It becomes widely adopted practice and even if there is no legal requirements to reference the documents within the security token, however they're almost always required, it's a good way to attach some useful documentation for potential investors.

## Backwards Compatibility

This EIP is fully backwards compatible as its implementation extends the functionality of ERC-20 and ERC-777 tokens.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
