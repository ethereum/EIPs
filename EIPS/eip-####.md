---
title: Social SBT
description: Social SBT, A Soul-Bound Token Standard for DAO Governance
author: Ali Bertay SOLAK (<alibertay@gmail.com>)
status: Draft
type: Standards Track
category: ERC
created: 2024-12-27
requires: 721
---

## Simple Summary

SocialSBT is a non-transferable ERC-721-based token standard that integrates a dynamic social point system for DAO governance. It aims to mitigate whale attacks and promote equitable, community-driven decision-making.

## Abstract

SocialSBT introduces a soulbound token standard built on ERC-721 that incorporates a social point system for DAO governance. Tokens are non-transferable, and governance power is tied to contributions rather than token holdings. Members can vote on adjustments to social points based on behavior and contributions, ensuring fair and community-aligned decision-making.

## Motivation

Traditional DAO's economic token based governance models are prone to manipulation by entities with significant financial resources, undermining the collective interests of the community. SocialSBT shifts governance influence to social contributions rather than token holdings, mitigating whale attacks and fostering fair participation.

The system rewards positive contributions and penalizes harmful behaviors. A economic token based voting mechanism ensures equitable participation during social point adjustments, promoting fairness and encouraging active engagement in DAO governance.

## Specification

### Key Functionalities

1. **Minting Tokens**
   - **Function**: `mint() public payable`
   - **Description**: Mints a SocialSBT token for the caller, provided they pay the `_price` and do not already own a token.
   - **Constraints**:
     - The caller must pay the exact `_price`.
     - Each address can own only one token.

2. **Deleting Tokens**
   - **Function**: `deleteToken(uint256 tokenId) public`
   - **Description**: Allows token owners to permanently delete their tokens without refunds.
   - **Constraints**:
     - Caller must own the specified token.

3. **Voting on Proposals**
   - **Function**: `vote(uint256 votingIndex_, bool choice_) public`
   - **Description**: Token holders can vote "yes" (`true`) or "no" (`false`) on proposals to adjust social points.
   - **Constraints**:
     - Caller must own a token.
     - Each caller can vote only once per proposal.

4. **Ending Voting**
   - **Function**: `endVoting(uint256 votingIndex_) public`
   - **Description**: Ends voting and adjusts points if the majority votes "yes."
   - **Constraints**:
     - Voting period must have expired.
     - Proposal must be active.

5. **Querying Token Points**
   - **Function**: `pointOf(uint256 tokenId) public view returns (uint256)`
   - **Description**: Retrieves the social points associated with a specified token.

6. **Event Triggers**
   - **NewVotingCreated**: Triggered when a voting proposal is created.
   - **VoteEvent**: Triggered when a user casts a vote.
   - **VotingEnd**: Triggered when voting ends.
   - **PointUpdated**: Triggered when token points are adjusted.

### Data Structures

```solidity
struct Voting {
    uint256 votingIndex;
    string name;
    string description;
    uint256 tokenIndex;
    uint256 point;
    bool increase;
    uint256 yes;
    uint256 no;
    uint256 startDate;
    uint256 endDate;
    bool isActive;
}
```

## Rationale

SocialSBT decouples governance power from token holdings by implementing a "1 address = 1 vote" system. This ensures fairness and prevents undue influence by high-point token holders. Non-refundable token burning discourages speculative behaviors and maintains the integrity of DAO governance.

## Backwards Compatibility

SocialSBT extends the ERC-721 standard while remaining compatible with its core functionalities. However, it introduces non-transferability and a social point mechanism, which deviate from the standard.

## Test Cases

1. **Minting Tokens**
   - Expected: Successful minting for eligible users.
   - Failures:
     - User already owns a token.
     - Payment amount does not match `_price`.

2. **Voting**
   - Expected: Correct vote recording and prevention of duplicate voting.
   - Failures:
     - Non-token holder participation.
     - Duplicate votes on the same proposal.

3. **Ending Voting**
   - Expected: Accurate point adjustment based on majority votes.
   - Failures:
     - Ending before expiration.
     - Inactive proposals.

4. **Burning Tokens**
   - Expected: Permanent token removal.
   - Failures:
     - Unauthorized burn attempts.

## Security Considerations

SocialSBT ensures secure governance through:
- **Non-transferability**: Prevents token trading and governance manipulation.
- **Fair voting**: Independent of social points.
- **Mitigation of whale attacks**: Restricts tokens to one per wallet.
- **Non-refundable burning**: Discourages exploitative behaviors.
- **Compliance with OpenZeppelin standards**: Reduces risks in implementation.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
