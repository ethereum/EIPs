T 
---
eip: <to be assigned>
title: peerPermit - Token Creation and Transfer with Dual Signatures
author: [xunorus] <[xunorus@gmail.com]>, [Maga] <[magali.theryvela@gmail.com]>
discussions-to: [URL for discussion thread]
status: Draft
type: Standards Track
category: ERC
created: 2024-07-17
---

## Simple Summary
Introduces a mechanism for the creation (mint) and transfer of ERC-20 tokens requiring dual signatures: one from the recipient and one from the value creator.

## Abstract
This EIP proposes a new method called `peerPermit`, which allows the creation and transfer of ERC-20 tokens through the use of two cryptographic signatures. The recipient and the value creator must both sign the transaction, ensuring mutual consent before any tokens are created or transferred.

## Motivation
The `peerPermit` method is designed to enhance security and consent in token transactions by requiring both parties involved to provide cryptographic signatures. This can be particularly useful in scenarios where mutual agreement is critical, such as in escrow services, collaborative funding, and other peer-to-peer transactions.

## Specification
### Data Structures
```solidity
struct PeerPermit {
    address recipient;
    address valueCreator;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}
```

### Methods
#### peerPermit
Allows the creation and transfer of tokens with dual signatures.

```solidity
function peerPermit(
    address recipient,
    address valueCreator,
    uint256 value,
    uint256 nonce,
    uint256 deadline,
    uint8 vRecipient,
    bytes32 rRecipient,
    bytes32 sRecipient,
    uint8 vValueCreator,
    bytes32 rValueCreator,
    bytes32 sValueCreator
) external;
```

**Parameters:**
- `recipient`: The address of the token recipient.
- `valueCreator`: The address of the value creator.
- `value`: The amount of tokens to be created/transferred.
- `nonce`: A unique value to prevent replay attacks.
- `deadline`: The timestamp after which the permit is no longer valid.
- `vRecipient`, `rRecipient`, `sRecipient`: The components of the recipient's signature.
- `vValueCreator`, `rValueCreator`, `sValueCreator`: The components of the value creator's signature.

### Signature Generation
The message to be signed by both parties must include the following data:
- `recipient`
- `valueCreator`
- `value`
- `nonce`
- `deadline`

## Security Considerations
- The nonce and deadline are used to prevent replay attacks.
- Signatures must be generated using the `eth_sign` method.
- The method checks that the signatures match the respective addresses of the `recipient` and `valueCreator`.

## Rationale
Requiring dual signatures ensures that both the recipient and the value creator agree to the transaction, providing a higher level of security and trust.

## Backwards Compatibility
This EIP does not introduce any backwards incompatibilities. It is an optional method that can be implemented alongside existing ERC-20 methods.

## Test Cases
- Test token creation and transfer with valid signatures.
- Test rejection of token creation and transfer with invalid signatures.
- Test rejection of token creation and transfer after the deadline.
- Test rejection of token creation and transfer with reused nonce.

## Implementation
[To be provided]

## References and Inspirations
- EIP-20: ERC-20 Token Standard
- EIP-2612: permit
- Monnaie libre experiments such as Ğ1, Le jardin des échanges universels, S.E.L., and others have inspired aspects of this proposal.

## Acknowledgments
This proposal draws inspiration from the collaborative and mutual consent principles observed in various monnaie libre experiments. Special thanks to the communities behind G1, JEU, and S.E.L. for their pioneering work in decentralized and peer-to-peer economic systems.
 