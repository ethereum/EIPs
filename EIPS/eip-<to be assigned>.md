---
eip: <to be assigned>
title: Cross Chain Messaging Interface
description: A common smart contract interface for interacting with messaging protocols.
author: Sujith Somraaj (@sujithsomraaj)
discussions-to: https://ethereum-magicians.org/t/cross-chain-messaging-standard/12197, https://ethresear.ch/t/standardisation-of-cross-chain-messaging-interface/13770
status: Draft
type: Standards Track
category: ERC
created: 2022-12-19
---

## Simple Summary
A Standard Interface For Cross-Chain Messengers.

## Abstract
The following standard allows for implementing a standard API for cross-chain messaging within smart contracts. This standard provides basic functionalities to send and receive a cross-chain message (state).

## Motivation
Cross-chain messaging protocols lack standardization leading to diverse implementation detail. Some examples include Layerzero, Hyperlane & Wormhole, having their own sets of implementations. This makes integration difficult at the aggregator or plugin layer for protocols that must conform to any standards and forces each protocol to implement its adapter.

Even chain native arbitrary messaging protocols like Matic State Tunnel has its own way of implementation.

The lack of standardization not only makes integration difficult but also is error prone as developers need to understand the operation of the messaging protocol at its core.

A standard for cross-chain messaging will lower integration efforts for cross-chain messaging while creating more robust & secure cross-chain application development.

To the worst, each messaging protocol has its chain ids (or) chain identification mechanism. However, this mechanism is used as they support non-EVM chains, which makes integration a nightmare.

## Specification
The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

### Methods

sendMessage
Dispatch message/state to `receiver` on a predetermined `chain id`.
MUST emit `MessageSent` event.
MUST support global chain-ids. Propreitory chain ids should be mapped internally to global chain ids.
MUST revert if `chain id` is invalid.
MUST return `true` on successful response from underlying messaging protocol.

**NOTE:** I'm proposing chain-ids be the bytes encoding of their native token name string. For eg., abi.encode("ETH"), abi.encode("SOL") imagining they cannot override.
       
       function sendMessage(bytes chainId, bytes receiver, bytes message) public returns(bool)

receiveMessage
Receive message/state from `sender` on a predetermined `chain id`
MUST emit `MessageReceived` event.
MUST support global based chain-ids.
MUST revert if `sender` or `chain-id` is invalid.
MUST return `true` on successful processing.

**NOTE:** Sender validation (or) message validation, gas overrides are handled at relayer level.

       function receiveMessage(bytes chainId, bytes sender, bytes message) public returns(bool)

### Events
MessageSent
MUST trigger when message is sent, include zero bytes transfers.
       
       event MessageSent(bytes _sender, bytes _fromChainId, bytes _receiver, bytes _toChainId, bytes message)

MessageReceived
MUST trigger on any successful call to `receiveMessage(bytes chainId, bytes sender, bytes message)` function. 
       
       event MessageReceived(bytes _sender, bytes _fromChainId, bytes _receiver, bytes _toChainId, bytes message)

## Rationale
The Cross-Chain interface is designed to be optimized for messaging layer integrators with a feature complete yet minimal interface. Validations such as sender authentication, receiver whitelisting, relayer mechanisms and cross-chain execution overrides are intentionally not specified, as Messaging protocols are expected to be treated as black boxes on-chain and inspected off-chain before use.

## Security Considerations
Fully permissionless messaging could be a security threat to the protocol. It is recommended that all the integrators review the implementation of messaging tunnels before integrating.

## Copyright
Copyright and related rights waived via [CC0]("https://eips.ethereum.org/LICENSE")
