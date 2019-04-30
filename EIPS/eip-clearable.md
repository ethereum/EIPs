---
eip: <to be assigned>
title: Clearable Token
author: Daniel Lehrner <daniel@io.builders>
discussions-to: https://github.com/IoBuilders/EIPs/pull/3
status: Draft
type: Standards Track
category: ERC
created: 2019-04-30
requires: 20
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

In banking and finance, clearing denotes all activities from the time a commitment is made for a transaction until it is settled. [[1]][Wikipedia] 

## Actors

#### Clearing Agent

An account which processes, executes or rejects a clearable transfer.

#### Operator
An account which has been approved by an account to order clearable transfers on its behalf.

#### Orderer
The account which orders a clearable transfer. This can be the account owner itself, or any account, which has been approved as an operator for the account.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

The clearing process turns the promise of transfer into the actual movement of money from one account to another. 

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

```solidity
interface ClearableToken /* is ERC-20 */ {
    enum ClearableTransferStatusCode { Nonexistent, Ordered, InProcess, Executed, Rejected, Cancelled }


    function orderTransfer(string calldata operationId, address to, uint256 value) external returns (bool);
    function orderTransferFrom(string calldata operationId, address from, address to, uint256 value) external returns (bool);
    function cancelTransfer(string calldata operationId) external returns (bool);
    function processClearableTransfer(address orderer, string calldata operationId) external returns (bool);
    function executeClearableTransfer(address orderer, string calldata operationId) external returns (bool);
    
    event ClearableTransferInProcess(address indexed orderer, string operationId);
    event ClearableTransferExecuted(address indexed orderer, string operationId);
    event ClearableTransferRejected(address indexed orderer, string operationId, string reason);
    event ClearableTransferCancelled(address indexed orderer, string operationId);
    event ApprovalToorderTransfer(address indexed wallet, address indexed orderer);
    event RevokeApprovalToorderTransfer(address indexed wallet, address indexed orderer);
}
```

### Functions

#### orderTransfer

Orders a clearable transfer on behalf of the msg.sender in favor of the payee. It specifies a notary who is responsable to either execute or release the hold.

| Parameter | Description |
| ---------|-------------|
| operationId | The unique ID per issuer to identify the clearable transfer |
| to | The address of the payee, to whom the tokens are to be paid if executed |
| value | The amount to be transferred. Must be less or equal than the balance of the payer. |

#### orderTransferFrom

Orders a clearable transfer on behalf of the payer in favor of the payee. It specifies a notary who is responsable to either execute or release the hold.

| Parameter | Description |
| ---------|-------------|
| operationId | The unique ID per issuer to identify the clearable transfer |
| to | The address of the payee, to whom the tokens are to be paid if executed |
| value | The amount to be transferred. Must be less or equal than the balance of the payer. |

#### cancelTransfer

Cancels the order of a clearable transfer. Only the orderer can cancel their own orders. Must not be successful as soon as it is in status `InProcess`.

| Parameter | Description |
| ---------|-------------|
| operationId | The unique ID per issuer to identify the clearable transfer |

#### processClearableTransfer

Sets a clearable transfer to status `InProcess`. Only an clearing agent can successfully execute this action.

| Parameter | Description |
| ---------|-------------|
| orderer | The address which ordered the clearable transfer |
| operationId | The unique ID per issuer to identify the clearable transfer |

#### executeClearableTransfer

Executes a clearable transfer, . Only an clearing agent can successfully execute this action.

| Parameter | Description |
| ---------|-------------|
| orderer | The address which ordered the clearable transfer |
| operationId | The unique ID per issuer to identify the clearable transfer |

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

This EIP is fully backwards compatible as its implementation extends the functionality of ERC-20.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

The GitHub repository [IoBuilders/clearable-token](https://github.com/IoBuilders/clearable-token) contains the work in progress implementation.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

[1] https://en.wikipedia.org/wiki/Clearing_(finance)

[Wikipedia]: https://en.wikipedia.org/wiki/Clearing_(finance)
