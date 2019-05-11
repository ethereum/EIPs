---
eip: <to be assigned>
title: Fundable Token
author: Fernando Paris <fer@io.builders>
status: Draft
type: Standards Track
category:  ERC
created: 2019-05-10
requires: 20

---

## Simple Summary
An extension to the ERC-20 standard token that allows Token wallet owners to request a wallet to be funded, by calling the smart contract and attaching a funding instruction string. 

## Actors

#### Token Wallet Owners
The person or company who owns the wallet, and will order a token funding request into the wallet.

#### Token contract operator
The entity, company responsible/ owner  of the token contract, and token issuing/minting. This actor is in charge of trying to fullfill all funding request, reading the funding instruction, and corelate the private payment details.


## Abstract 
Token wallet owners (or approved addresses) can order tokenization requests through  blockchain. This is done by calling the orderFunding or orderFundingFrom methods, which initiate the workflow for the token contract operator to either honor or reject the funding request. In this case, funding instructions are provided when submitting the request, which are used by the operator to determine the source of the funds to be debited in order to do fund the token wallet (through minting). 

In general, it is not advisable to place explicit routing instructions for debiting funds on a verbatim basis on the blockchain, and it is advised to use a private communication alternatives. such as private channels, encrypted storage or similar,  to do so (external to the blockchain ledger). Another (less desirable) possibility is to place these instructions on the instructions field on encrypted form.


## Motivation
Nowadays most of the token issuing/funding request, based on any fiat based payment method  need a previous centralized transaction, to be able to get the desired tokens issued on requester's wallet.
In the aim of trying step by step to bring all the needed steps into decentralization, exposing all the needed steps of token lifecycle and payment transactions, a funding request can allow wallet owner to initiate the funding request via  blockchain.
Key benefits:

* Funding and payment traceability is enhanced bringing the initation into the ledger. All payment status con be stored on chain.
* Almost all money/token lifecycle is covered via an decentralized approach, complemented with private communications which is common used in the ecosystem.


## Specification

```solidity
interface IFundable /* is ERC-20 */ {
    enum FundStatusCode {
        Nonexistent,
        Ordered,
        Executed,
        ReleasedByNotary,
        ReleasedByPayee,
        ReleasedOnExpiration
    }
    function approveToOrderFund(address orderer) external returns (bool);
    function revokeApprovalToOrderFund(address orderer) external returns (bool) ;
    function orderFund(string calldata operationId, uint256 value, string calldata instructions) external returns (bool);
    function orderFundFrom(string calldata operationId, address walletToFund, uint256 value, string calldata instructions) external returns (bool);
    function cancelFund(string calldata operationId) external returns (bool);
    function processFund(address orderer, string calldata operationId) external returns (bool);
    function executeFund(address orderer, string calldata operationId) external returns (bool);
    function rejectFund(address orderer, string calldata operationId, string calldata reason) external returns (bool);
    function isApprovedToOrderFunding(address walletToFund, address orderer) external view returns (bool);
    function retrieveFundingData(address orderer, string calldata operationId) external view returns (address walletToFund,       uint256 value, string memory instructions, FundingStatusCode status);
    event FundingOrdered(address indexed orderer, string indexed operationId, address indexed walletToFund, uint256 value,         string instructions);
    event FundingInProcess(address indexed orderer, string indexed operationId);
    event FundingExecuted(address indexed orderer, string indexed operationId);
    event FundingRejected(address indexed orderer, string indexed operationId, string reason);
    event FundingCancelled(address indexed orderer, string indexed operationId);
    event ApprovalToOrderFunding(address indexed walletToFund, address indexed orderer);
    event RevokeApprovalToOrderFunding(address indexed walletToFund, address indexed orderer);
}

```

## Rationale
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Backwards Compatibility
This EIP is fully backwards compatible as its implementation extends the functionality of ERC-20.

## Implementation
The GitHub repository [IoBuilders/fundable-token](https://github.com/IoBuilders/fundable-token) contains the work in progress implementation.

## Contributors
This proposal has been collaboratively implemented  by adhara.io and io.builders.

Copyright
Copyright and related rights waived via CC0.
