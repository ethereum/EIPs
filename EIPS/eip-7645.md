---
eip: 7645
title: Alias ORIGIN to SENDER
description: Eliminate ORIGIN tech debt to lay groundwork for account abstraction and close security holes
author: Cyrus Adkisson (@cyrusadkisson), Eirik Ulversøy (@EirikUlversoy)
discussions-to: https://ethereum-magicians.org/t/eip-7645-alias-origin-to-sender/19047
status: Stagnant
type: Standards Track
category: Core
created: 2024-03-03
---

## Abstract

This EIP proposes aliasing the ORIGIN opcode to the SENDER opcode within the Ethereum Virtual Machine (EVM). The purpose of this change is to move Ethereum closer to enabling account abstraction by harmonizing the treatment of externally owned accounts (EOAs) and smart contracts and to address the security concerns associated with the use of ORIGIN that have and will continue to surface in all or most account abstraction proposals. 

## Motivation

The ORIGIN opcode in Ethereum returns the address of the account that started the transaction chain, differing from the SENDER (or CALLER) opcode, which returns the address of the direct caller. The use of ORIGIN has been discouraged and deemed deprecated since mid-2016 due to the security problems it introduces, such as susceptibility to phishing attacks and other vulnerabilities where the distinction between the original sender and the immediate sender can be exploited.

For instance, if an [ERC-4337](./eip-4337.md) bundler has tokens or other authority in a smart contract determined by ORIGIN, any of the transactions it bundles can hijack this authority since ORIGIN remains the bundler address throughout each child transaction.

More apropos in the current context of EVM evolution, the differentiation between the ORIGIN and SENDER opcodes presents a challenge for all account abstraction efforts, such as those outlined in [EIP-7377](./eip-7377.md) and [EIP-3074](./eip-3074.md), because any move towards account abstraction must address the ORIGIN opcode's role, either by modifying or completely bypassing it. Without addressing this, the ORIGIN opcode stands as a barrier to the evolution of Ethereum's account model towards greater flexibility and functionality.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

This EIP proposes the alteration of the behavior of the ORIGIN opcode within the Ethereum Virtual Machine (EVM). Currently, the ORIGIN opcode returns the address of the original transaction initiator. Under this EIP, the ORIGIN opcode would, instead, return the same value as the SENDER opcode, which is the address of the immediate sender of the message or transaction.

Definition Change: The ORIGIN opcode (0x32) MUST, in all contexts of execution, return the same value as that returned by the SENDER (also known as CALLER) opcode (0x33).

EVM Implementation: All Ethereum clients MUST implement the following change to the EVM: Whenever the ORIGIN opcode is called, the value to be pushed onto the stack is the current call's sender address, as if the SENDER opcode was executed instead.

Transaction Validation: Transactions MUST be validated as before, with no changes to the transaction structure or processing logic beyond the EVM opcode behavior specified above.

Compatibility: Smart contracts relying on the ORIGIN opcode for obtaining the transaction initiator's address MUST be reviewed to ensure they function correctly under the new definition and worked-around or avoided if this EIP introduces breaking changes.

Implementers are encouraged to provide feedback on this specification and report any potential issues encountered during the implementation or testing phases.

## Rationale

The rationale behind aliasing ORIGIN to SENDER is to:

Facilitate Account Abstraction: Elegantly nullify a universal barrier to account abstraction, enabling more flexible and powerful account models in Ethereum.

Enhance Security: Eliminate the security vulnerabilities associated with differentiating between the original transaction initiator and the immediate caller.

Clean up tech debt and simplify the EVM Model: Reduce the complexity of the EVM's transaction and execution model by removing an outdated and deprecated feature, making future changes easier and safer.

## Backwards Compatibility

This change is not fully backwards compatible. Contracts relying on the distinction between ORIGIN and SENDER for logic or security will be affected. However, given the longstanding discouragement of ORIGIN's use, the minimal impact of the change, the widespread desire for a future account abstraction solution in the EVM, and the reality that any AA solution will ultimately have to deal with ORIGIN one way or the other, this incompatibility is considered a necessary step forward for Ethereum's development.

No backward compatibility issues found.

## Test Cases

For each CALL, STATICCALL, DELEGATECALL, CALLCODE:

Direct - Ensure that, at the target smart contract, ORIGIN and SENDER produce the same value. (For simple no-hop EOA-to-EOA/SCA transactions, this is already the case today.)

Multi-hop - Ensure that, at each frame in a multi-hop transaction, ORIGIN and SENDER produce the same value.

## Security Considerations

By aliasing ORIGIN to SENDER, the specific security vulnerabilities associated with the ORIGIN opcode are addressed and eliminated. Outside the scope of this EIP, it may be wise to ban all use of ORIGIN to eliminate further misunderstanding or misuse. This can be done via tooling changes outside the EVM or, inside the EVM, reverting smart contract deployments that use ORIGIN.

For existing misuse of ORIGIN affected negatively by this aliasing to SENDER (of yet a clear example has yet to be identified), it may be necessary to educate users to avoid this problematic legacy code.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
