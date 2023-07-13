---
eip: 7322
title: Soulbounds with recoverability
description: Soulbounds token with the possibility of recovering the token in case of loss of the private key.
author: Omar Garcia (@ogarciarevett) <oumar.eth@gmail.com>
discussions-to: https://ethereum-magicians.org/t/token-soulbound-with-recoverability/15033
status: Draft
type: Standards Track
category: ERC
created: 20230-07-12
requires: 165, 721, 1155
---

## Abstract

The recoverability of soulbound tokens feature aims to enhance security and ownership control for Web3 companies. This EIP will add a layer of protection to non-transferable tokens by allowing designated recovery agents (trusted entities) to help token holders recover their soulbound tokens in cases of wallet loss, theft, or other unforeseen circumstances.

## Motivation

Soulbound tokens are a new category of tokens that represent non-transferable digital assets. These tokens are meant to stay with their original owner indefinitely. However, this poses a significant risk in the event of a wallet loss, theft, or other security breaches. To mitigate this risk, we need to establish a reliable and secure recovery mechanism.
The primary motivation for this EIP is to enable Web3 companies or web3 games to recover soulbound tokens on behalf of their users, ensuring that users don't lose access to their valuable digital assets.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions
Soulbound Tokens: Non-transferable tokens that are locked to their original owner.
Recovery Agent: A trusted entity assigned by the Web3 company to perform recovery operations for soulbound tokens.

### Interface
The ISoulboundRecovery interface is to be implemented by token contracts to support the recoverability of soulbound tokens.
solidityCopy code
pragma solidity ^0.8.0;

```solidity
interface ISoulboundRecovery {
    function setRecoveryAgent(address _recoveryAgent) external;
    function recoverSoulboundTokens(address _originalOwner, address _newOwner) external;
    event RecoveryAgentSet(address indexed recoveryAgent);
    event SoulboundTokensRecovered(address indexed originalOwner, address indexed newOwner, uint256 amount);
}
```

### Implementation
To implement the **ISoulboundRecovery** interface, token contracts must include the following functions:

### setRecoveryAgent
This function is used to set the recovery agent's address. The recovery agent is the trusted entity responsible for performing recovery operations for soulbound tokens. Only the contract owner should be able to call this function.

```solidity
address public recoveryAgent;

function setRecoveryAgent(address _recoveryAgent) external onlyOwner {
    recoveryAgent = _recoveryAgent;
    emit RecoveryAgentSet(_recoveryAgent);
}
```

### recoverSoulboundTokens
This function is used to recover soulbound tokens for the original owner. Only the recovery agent should be able to call this function.

```solidity
function recoverSoulboundTokens(address _originalOwner, address _newOwner) external onlyRecoveryAgent {
    uint256 amount = balanceOf(_originalOwner);
    _transfer(_originalOwner, _newOwner, amount);
    emit SoulboundTokensRecovered(_originalOwner, _newOwner, amount);
}
```

## Rationale

This EIP provides a solution for the recovery of soulbound tokens, ensuring that users can regain access to their valuable digital assets. By implementing the ISoulboundRecovery interface, token contracts can support recoverability for soulbound tokens, allowing Web3 companies to recover tokens on behalf of their users in case of wallet loss, theft, or other unforeseen circumstances.

## Backwards Compatibility

The proposed EIP is designed to be compatible with existing ERC-721, and ERC-1155 token standards. It introduces an additional interface to be implemented by token contracts to support recoverability for soulbound tokens. Existing tokens can adopt the ISoulboundRecovery interface without affecting their current functionality.

## Test Cases

Test cases should be implemented to verify the correct functionality of the ISoulboundRecovery interface and its implementation. Tests should cover:

1. Setting the recovery agent.

2. Recovering soulbound tokens.

3. Ensuring only the contract owner can set the recovery agent.

4. Ensuring only the recovery agent can recover soulbound tokens.

5. Ensuring proper event emission.

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
