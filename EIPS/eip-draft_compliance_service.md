---
eip: <to be assigned>
title: Compliance Service 
author: Daniel Lehrner <daniel@io.builders>
discussions-to: https://github.com/IoBuilders/EIPs/issues/4
status: Draft
type: Standards Track
category: ERC
created: 2019-05-09
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

This EIP proposes a service for decentralized compliance checks for regulated tokens. 

## Actors

#### Operator
An account which has been approved by a token to update the tokens accumulated.

#### Token
An account, normally a smart contract, which uses the `Compliance Service` to check if the an action can be executed or not.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

A regulated token needs to comply with several legal requirements, especially [KYC][KYC-Wikipedia] and [AML][AML-Wikipedia]. If the necessary checks have to be made off-chain the token transfer becomes centralized. Further the transfer in this case takes longer to complete as it can not be done in one transaction, but requires a second confirmation step. The goal of this proposal is to make this second step unnecessary by providing a service for compliance checks.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

Currently there is no proposal on how to accomplish decentralized compliance checks. [ERC-1462][ERC-1462] proposes a basic set of functions to check if `transfer`, `mint` and `burn` are allowed for a user, but not how those checks should be implemented. This EIP proposes a way to implement them fully on-chain while being generic enough to leave the actual implementation of the checks up to the implementers, as these may vary a lot between different tokens.  

The proposed `Compliance Service` supports more than one token. Therefore it could be used by law-makers to maintain the compliance rules of regulated tokens in one smart contract. This smart contract could be used by all of the tokens that fall under this jurisdiction and ensure compliance with the current laws.

By having a standard for compliance checks third-party developers can use them to verify if token movements for a specific account are allowed and act accordingly.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

```solidity
interface CompliantService {
    function checkTransferAllowed(bytes32 tokenId, address from, address to, uint256 value) external view returns (byte);
    function checkTransferFromAllowed(bytes32 tokenId, address sender, address from, address to, uint256 value) external view returns (byte);
    function checkMintAllowed(bytes32 tokenId, address to, uint256 value) external view returns (byte);
    function checkBurnAllowed(bytes32 tokenId, address from, uint256 value) external view returns (byte);
    
    function updateTransferAccumulated(bytes32 tokenId, address from, address to, uint256 value) external;
    function updateMintAccumulated(bytes32 tokenId, address to, uint256 value) external;
    function updateBurnAccumulated(bytes32 tokenId, address from, uint256 value) external;
    
    function addToken(bytes32 tokenId, address token) external;
    function replaceToken(bytes32 tokenId, address token) external;
    function removeToken(bytes32 tokenId) external;
    function isToken(address token) external view returns (bool);
    function getTokenId(address token) external view returns (bytes32);
    
    function authorizeAccumulatedOperator(address operator) external returns (bool);
    function revokeAccumulatedOperator(address operator) external returns (bool);
    function isAccumulatedOperatorFor(address operator, bytes32 tokenId) external view returns (bool);
    
    event TokenAdded(bytes32 indexed tokenId, address indexed token);
    event TokenReplaced(bytes32 indexed tokenId, address indexed previousAddress, address indexed newAddress);
    event TokenRemoved(bytes32 indexed tokenId);
    event AuthorizedAccumulatedOperator(address indexed operator, bytes32 indexed tokenId);
    event RevokedAccumulatedOperator(address indexed operator, bytes32 indexed tokenId);
}
```

### Mandatory checks

The checks must be verified in their corresponding actions. The action must only be successful if the check return an `Allowed` status code. In any other case the functions must revert.

### Status codes

If an action is allowed `0x11` (Allowed) or an issuer-specific code with equivalent but more precise meaning must be returned. If the action is not allowed the status must be `0x10` (Disallowed) or an issuer-specific code with equivalent but more precise meaning. 

### Functions

#### checkTransferAllowed

Checks if the `transfer` function is allowed to be executed with the given parameters.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| from | The address of the payer, from whom the tokens are to be taken if executed |
| to | The address of the payee, to whom the tokens are to be transferred if executed |
| value | The amount to be transferred |

#### checkTransferFromAllowed

Checks if the `transferFrom` function is allowed to be executed with the given parameters.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| sender | The address of the sender, who initiated the transaction |
| from | The address of the payer, from whom the tokens are to be taken if executed |
| to | The address of the payee, to whom the tokens are to be transferred if executed |
| value | The amount to be transferred |

#### checkMintAllowed

Checks if the `mint` function is allowed to be executed with the given parameters.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| to | The address of the payee, to whom the tokens are to be given if executed |
| value | The amount to be minted |

#### checkBurnAllowed

Checks if the `burn` function is allowed to be executed with the given parameters.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| from | The address of the payer, from whom the tokens are to be taken if executed |
| value | The amount to be burned |

#### updateTransferAccumulated

Must be called in the same transaction as `transfer` or `transferFrom`. It must revert if the update violates any of the compliance rules. It is up to the implementer which specific logic is executed in the function.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| from | The address of the payer, from whom the tokens are to be taken if executed |
| to | The address of the payee, to whom the tokens are to be transferred if executed |
| value | The amount to be transferred |

#### updateMintAccumulated

Must be called in the same transaction as `mint`. It must revert if the update violates any of the compliance rules. It is up to the implementer which specific logic is executed in the function.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| to | The address of the payee, to whom the tokens are to be given if executed |
| value | The amount to be minted |

#### updateBurnAccumulated

Must be called in the same transaction as `burn`. It must revert if the update violates any of the compliance rules. It is up to the implementer which specific logic is executed in the function.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| from | The address of the payer, from whom the tokens are to be taken if executed |
| value | The amount to be minted |

#### addToken

Adds a token to the service, which allows the token to call the functions to update the accumulated. If an existing token id is used the function must revert. It is up to the implementer if adding a token should be restricted or not.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| token | The address from which the update functions will be called |

#### replaceToken

Replaces the address of a added token with another one. It is up to the implementer if replacing a token should be restricted or not, but a token should be able to replace its own address.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| token | The address from which the update functions will be called |

#### removeToken

Removes a token from the service, which disallows the token to call the functions to update the accumulated. It is up to the implementer if removing a token should be restricted or not.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |

#### isToken

Returns `true` if the address has been added to the service, `false` if not.

| Parameter | Description |
| ---------|-------------|
| token | The address which should be checked |

#### getTokenId

Returns the token id of a token. If the token has not been added to the service, '0' must be returned.

| Parameter | Description |
| ---------|-------------|
| token | The address which token id should be returned |

#### authorizeAccumulatedOperator

Approves an operator to update accumulated on behalf of the token id of msg.sender.

| Parameter | Description |
| ---------|-------------|
| operator | The address to be approved as operator of accumulated updates |

#### revokeAccumulatedOperator

Revokes the approval to update accumulated on behalf the token id the token id ofof msg.sender.

| Parameter | Description |
| ---------|-------------|
| operator | The address to be revoked as operator of accumulated updates |

#### isAccumulatedOperatorFor

Retrieves if an operator is approved to create holds on behalf of `tokenId`.

| Parameter | Description |
| ---------|-------------|
| operator | The address which is operator of updating the accumulated |
| tokenId | The unique ID which identifies a token |

### Events

#### TokenAdded

Must be emitted after a token has been added.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| token | The address from which the update functions will be called |

#### TokenReplaced

Must be emitted after the address of a token has been replaced.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |
| previousAddress | The previous address which was used before |
| newAddress | The address which will be used from now on |

#### TokenRemoved

Must be emitted after the a token has been removed.

| Parameter | Description |
| ---------|-------------|
| tokenId | The unique ID which identifies a token |

#### AuthorizedAccumulatedOperator

Emitted when an operator has been approved to update the accumulated on behalf of a token.

| Parameter | Description |
| ---------|-------------|
| operator | The address which is operator of updating the accumulated |
| tokenId | Token id on which behalf updates of the accumulated will potentially be made |

#### RevokedHoldOperator

Emitted when an operator has been revoked from updating the accumulated on behalf of a token.

| Parameter | Description |
| ---------|-------------|
| operator | The address which was operator of updating the accumulated |
| tokenId | Token id on which behalf updates of the accumulated could be made |

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The usage of a token id instead of the address has been chosen to give tokens the possibility to update their smart contracts and keeping all their associated accumulated. If the address would be used, a migration process would needed to be done after a smart contract update.

No event is emitted after updating the accumulated as those are always associated with a `transfer`, `mint` or `burn` of a token which already emits an event of itself.

While not requiring it, the naming of the functions `checkTransferAllowed`, `checkTransferFromAllowed`, `checkMintAllowed` and `checkBurnAllowed` was adopted from [ERC-1462][ERC-1462].

While not requiring it, the naming of the functions `authorizeAccumulatedOperator`, `revokeAccumulatedOperator` and `isAccumulatedOperatorFor` follows the naming convention of [ERC-777](https://eips.ethereum.org/EIPS/eip-777).

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

AS the EIP is not using any existing EIP there are no backwards compatibilities to take into consideration.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

The GitHub repository [IoBuilders/compliance-service](https://github.com/IoBuilders/compliance-service) contains the work in progress implementation.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

[KYC-Wikipedia]: https://en.wikipedia.org/wiki/Know_your_customer
[AML-Wikipedia]: https://en.wikipedia.org/wiki/Money_laundering#Anti-money_laundering
[ERC-1462]: http://eips.ethereum.org/EIPS/eip-1462
