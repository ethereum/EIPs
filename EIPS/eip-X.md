---
eip: <to be assigned>
title: Cross-Chain Execution
description: This specification defines an interface that supports execution across EVM networks.
author: Brendan Asselstine (@asselstine), Anna Carroll (@anna-carroll), Hadrien Croubois (@Amxx), Theo Gonella (@mintcloud), Rafael Solari (@rsolari), Auryn Macmillan (@auryn-macmillan), Nathan Ginnever (@nginnever)
discussions-to: <URL>
status: Draft
type: Standards Track
category (*only required for Standards Track): ERC
created: 2022-06-14
---

# EIP-?: Cross-Chain Execution

# Abstract

This specification defines a cross-chain execution interface for EVM-based blockchains. Users of this spec will be able to have contracts on one chain call contracts on another chain. The specification is agnostic of the transport layer, so that implementations can choose how they relay the execution.

# Motivation

Many Ethereum protocols need to coordinate state changes across multiple EVM-based blockchains. These chains often have native or third-party bridges that allow Ethereum contracts to execute code. However, bridges have different APIs so bridge integrations are bespoke.

Bridge technology is improving rapidly, and there are multiple bridges to choose from. Each one affords different properties; with varying degrees of security, speed, and control.

By standardizing a cross-chain execution interface, we can cleanly separate the transport layer from the application layer. Cross-chain execution becomes another composable piece with which the Ethereum ecosystem can build shared infrastructure.

# Specification

This specification allows contracts on one chain to send messages to contracts on another chain. There are two key contracts:

- CrossChainRelayer
- CrossChainReceiver

The `CrossChainRelayer` lives on the origin chain. Messages sent to this contract are relayed to CrossChainReceivers on other chains.

The `CrossChainReceiver` lives on the destination chain. The receiver is bound to a CrossChainRelayer and executes any messages sent by the relayer.

When a user wishes to send cross-chain messages, they will create a CrossChainRelayer and a CrossChainReceiver.

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## CrossChainRelayer

The `CrossChainRelayer` lives on the chain from which messages are sent. The Relayer's job is to broadcast the messages through a transport layer.

### Methods

**relayCalls**

MUST emit the `Relayed` event when successfully called. 

MUST increment a `nonce` so that messages can be uniquely identified.

```solidity
struct Call {
  address target;
  bytes data;
  uint value;
}

interface CrossChainRelayer {
    function relayCalls(Call[] calldata calls) external;
}
```

```yaml
- name: relayCalls
  type: function
  stateMutability: nonpayable
  inputs: 
    - name: calls
      type: Call[]
```

### Events

**Relayed**

MUST be emitted when a CrossChainRelayer relays calls.

```solidity
interface CrossChainRelayer {
  event Relayed(
      uint256 indexed nonce,
      Call[] calls
  );
}
```

```yaml
- name: Relayed
  type: event
  inputs:
    - name: nonce
      indexed: true
      type: uint256
    - name: calls
      type: Call[]
```

## CrossChainReceiver

The `CrossChainReceiver` contract executes messages sent by a `CrossChainRelayer`.

### Methods

**relayer**

Returns the address of the relayer that this receiver is bound to.

```solidity
interface CrossChainReceiver {
  function relayer() external view returns (address);
}
```

```yaml
- name: relayer
  type: function
  stateMutability: constant
  outputs: 
    - name: relayerAddress
      type: address
```

**relayerChainId**

Returns the id of the chain that the relayer lives on.

```solidity
interface CrossChainReceiver {
  function relayerChainId() external view returns (uint256);
}
```

```yaml
- name: relayerChainId
  type: function
  stateMutability: constant
  outputs: 
    - name: relayerChainId
      type: uint256
```

### Events

**Executed**

MUST be emitted when a relayed message is executed.

```solidity
interface CrossChainReceiver {
  event Executed(
      uint256 indexed nonce,
      Call[] calls
  );
}
```

```yaml
- name: Executed
  type: event
  inputs:
    - name: nonce
      indexed: true
      type: uint256
    - name: calls
      type: Call[]
```

**RelayerSet**

MUST be emitted when the relayer is initialized or updated.

```solidity
interface CrossChainReceiver {
  event RelayerSet(
      address indexed relayer,
      uint256 indexed chainId
  );
}
```

```yaml
- name: RelayerSet
  type: event
  inputs:
    - name: relayer
      indexed: true
      type: address
    - name: relayerChainId
      indexed: true
      type: uint256
```

# Rationale

There are some notable design decisions worth talking about:

- Relayers and receivers have a one-to-many relationship
- Calls are relayed in batches
- Receivers include both events and accessors to access the relayer

The message receiver always authenticates the sender. This is the case whether contracts live on the same chain or across chains. That's why the relayer is unaware of the receiver, but the receiver is aware of the relayer. This approach is the most compatible with transport layers (namely Nomad!) and affords the ability to broadcast messages to multiple receivers.

Calls are relayed in batches because it is such a common action. Rather than have implementors take different approaches to encoding multiple calls into the `data` portion, this spec includes call batching to take away any guess work.

The receiver makes the relayer address and chainId available on-chain, and emits events when the Relayer is initialized or set. This makes it easy to trace cross-chain execution. Thanks to the events and nonce, an indexer can know exactly who the relayer and receiver were in the past and trace the execution of a call batch. With the on-chain accessor, external contracts can check to see who the current relayer is.

# Backwards Compatibility

This specification is compatible with existing governance systems as it offers simple cross-chain execution.

# Implementation

A basic implementation of the interfaces is available on [Github](https://github.com/pooltogether/cross-chain-relay-implementation).

# References

This specification was born out of the conversation in [Ethereum Magicians](https://ethereum-magicians.org/t/eip-draft-multi-chain-governance/9284) and informed by prior work, including the Nomad [GovernanceRouter](https://github.com/nomad-xyz/monorepo/blob/14e99f292e20e08148b4b1b950d05c7fcb0f6cb9/packages/contracts-core/contracts/governance/GovernanceRouter.sol#L227) and the OpenZeppelin Labs [bridge](https://github.com/Amxx/openzeppelin-labs/tree/devel/crosschain-contracts/contracts/global/polygon-callbridge).
