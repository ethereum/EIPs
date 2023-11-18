---
title: Time Capsule Encryption via VDF
description: Introduces on-chain content encryption with a time-locked decryption mechanism using Verifiable Delay Functions.
author: Hojay (@hojayxyz), Igor (@igorperic17), Branko (@saicoder), Ivan (@IvanLudvig)
discussions-to: https://ethereum-magicians.org/t/eip-for-time-capsule-encryption-via-verifiable-delay-functions-vdfs/16682
status: Draft
type: Standards Track
category: Core
created: 2023-11-18
requires: N/A
---

## Abstract

This Ethereum Improvement Proposal introduces a 'Time Capsule' mechanism to securely encrypt content on the Ethereum blockchain with a pre-defined time delay for decryption, using Verifiable Delay Functions (VDFs). It allows users to upload encrypted content (text or files) and ensures that decryption occurs only after the specified delay, irrespective of computing power advancements, thereby enhancing Ethereum's data handling capabilities for time-sensitive applications.

## Motivation

The current Ethereum ecosystem lacks a mechanism for time-bound data confidentiality. This EIP proposes a solution to securely encrypt and store content on-chain, which remains inaccessible until a predetermined future time. This functionality is crucial for various applications like sealed bidding, time-locked messages, and secure digital inheritance, enhancing Ethereum's utility in handling time-sensitive information.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

The 'Time Capsule' encryption mechanism operates as follows:

1. **Encryption and Time Delay Setting:**
   - Users MUST encrypt their content using a specified encryption algorithm (e.g., AES-256).
   - During encryption, users MUST set a time delay for decryption, specified in blocks or time units (e.g., days, hours).
   - The encrypted content and time delay information MUST be encapsulated in a smart contract deployed on the Ethereum blockchain.

2. **Verifiable Delay Function Integration:**
   - A Verifiable Delay Function (VDF) MUST be employed to ensure that the decryption process adheres to the specified time delay.
   - The VDF MUST be designed so that its execution time is predictable and linearly dependent on the number of operations, and it MUST NOT be susceptible to acceleration through parallel processing.
   - Upon completion of the VDF execution, a decryption key or mechanism SHALL be made available.

3. **Decryption Process:**
   - Once the set time delay has elapsed, as determined by the VDF, nodes on the Ethereum network MAY begin the decryption process.
   - The decryption process MUST ensure that only after the specified time delay has elapsed, the content becomes accessible.
   - A self-validation mechanism MUST be included to verify the integrity and authenticity of the decrypted content.

4. **On-Chain Verification and Interaction:**
   - Smart contracts involved in the 'Time Capsule' mechanism MUST include functions to verify the status of the time delay and to initiate the decryption process post delay.
   - Users and recipients MUST be able to interact with the smart contract to retrieve the status of the encrypted content and access it post the time delay.

5. **Gas and Transaction Fee Management:**
   - The smart contract MUST handle the transaction and gas fees required for deploying the contract, performing the VDF, and executing the decryption process.
   - It MUST specify the fee structure and rewards for nodes participating in the decryption process.

## Rationale

The use of VDFs ensures a guaranteed time delay for decryption, immune to acceleration by computational power increases. This approach ensures that encrypted content remains secure until the predefined time, addressing the need for reliable time-locked encryption on the blockchain.

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

The following test cases are designed to validate the core functionalities of the 'Time Capsule' encryption mechanism using Verifiable Delay Functions (VDFs). Implementations of this EIP MUST pass all the following tests:

1. **Encryption and Time Delay Setting Test:**
   - Verify that content can be encrypted and a time delay for decryption can be set correctly.
   - Encrypt a sample text or file using the specified encryption algorithm.
   - Set a specific time delay for decryption.
   - Store the encrypted content and time delay information in a smart contract.
   - The smart contract accurately reflects the encrypted content and the set time delay.

2. **Verifiable Delay Function Execution Test:**
   - Ensure that the VDF adheres to the specified time delay and cannot be expedited.
   - Initiate the VDF with a predefined number of operations correlating to the set time delay.
   - Attempt to process the VDF using varying computational resources.
   - The VDF takes the same amount of time to complete regardless of computational resources, adhering strictly to the set time delay.

3. **Decryption Post Time Delay Test:**
   - Validate that decryption occurs only after the specified time delay.
   - After the time delay set in the VDF has elapsed, initiate the decryption process.
   - Verify the integrity and authenticity of the decrypted content.
   - Decryption is successful and accurate only after the VDF has completed, and the content matches the original pre-encryption data.

4. **Smart Contract Interaction Test:**
   - Confirm that users and recipients can interact with the smart contract as intended.
   - Query the smart contract for the status of the encrypted content and time delay.
   - After the time delay, access the decrypted content via the smart contract.
   - The smart contract responds correctly to queries and allows access to decrypted content post time delay.

## Reference Implementation

https://github.com/igorperic17/memento/

## Security Considerations

When implementing the 'Time Capsule' encryption mechanism using Verifiable Delay Functions (VDFs), several security considerations must be taken into account to ensure the integrity, confidentiality, and availability of the encrypted content:

1. **Encryption Strength:**
   - The encryption algorithm chosen MUST be strong enough to withstand modern cryptographic attacks. It is RECOMMENDED to use well-established encryption standards like AES-256.
   - Regular security audits and updates are REQUIRED to ensure the encryption method remains secure against emerging threats.

2. **VDF Implementation:**
   - The VDF MUST be implemented in a manner that prevents acceleration through parallel processing or other optimization techniques.
   - The security of the VDF implementation MUST be evaluated to ensure it behaves predictably and consistently across different platforms and environments.

3. **Smart Contract Security:**
   - Smart contracts used in the 'Time Capsule' mechanism MUST undergo thorough security audits to identify and rectify vulnerabilities such as reentrancy attacks, overflow/underflow bugs, and improper access control.
   - It is RECOMMENDED to follow established best practices for smart contract development, including the use of well-reviewed code patterns and libraries.

4. **Time Manipulation Resistance:**
   - The mechanism MUST be resistant to time manipulation attacks where an adversary might attempt to alter the system clock or block timestamp to prematurely decrypt the content.
   - Robustness against such attacks can be ensured by relying on block numbers or VDF completion, rather than timestamps, for determining decryption eligibility.

5. **Access Control:**
   - Proper access control mechanisms MUST be implemented to ensure that only authorized entities can initiate the encryption and decryption processes.
   - Careful consideration is REQUIRED to prevent unauthorized access to the encrypted content, especially during the decryption phase.

6. **Denial of Service (DoS) Risks:**
   - The system SHOULD be designed to resist DoS attacks, particularly those targeting the decryption process or the smart contract’s functionality.
   - Considerations include limiting the rate of decryption requests and ensuring the system can handle a high volume of concurrent encryption/decryption operations.

7. **Key Management:**
   - Secure handling and storage of encryption and decryption keys are CRITICAL. Exposure of these keys poses a significant risk to the confidentiality of the encrypted content.
   - Implementations SHOULD include mechanisms for secure key generation, storage, and destruction, following industry best practices.

By addressing these security considerations, the 'Time Capsule' mechanism can provide a robust and secure method for time-delayed encryption and decryption of content on the Ethereum blockchain.

## Copyright
Copyright and related rights waived via CC0.
