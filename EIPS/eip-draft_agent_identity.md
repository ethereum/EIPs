---
eip: <to be assigned>
title: Agent Identity, Capability, and Reputation
description: On-chain identity, capability declaration, stake-based trust, audit verification, and reputation tracking for autonomous AI agents.
author: Panini (@Brooks1003)
discussions-to: https://github.com/Brooks1003/base-agent-registry/discussions
status: Draft
type: Standards Track
category: ERC
created: 2026-05-19
requires: ERC-165, ERC-725
---

## Abstract

This proposal defines a standard for on-chain identity, capability declaration, economic staking, third-party auditing, and reputation tracking for autonomous AI agents. Agents register a unique on-chain identity with a creator accountability anchor, declare their capabilities honestly, stake ETH to earn initial trust, undergo optional third-party code audits, and accumulate a non-linear reputation score based on verifiable on-chain behavior. Malicious agents are slashed (stake forfeited: 50% to whistleblower, 50% burned). Honest agents graduate to stake-free operation.

## Motivation

AI agents are proliferating across the blockchain ecosystem — trading bots, research assistants, monitoring services, and coding agents. However, there is no standard way to:

1. **Verify agent identity** — Every agent currently operates as an anonymous address.
2. **Declare agent capabilities** — Users cannot know what an agent claims to be able to do.
3. **Establish trust** — No mechanism exists for agents to build verifiable reputation.
4. **Enable accountability** — When an agent causes harm, there is no way to trace responsibility.
5. **Create economic deterrence** — Malicious agents face no financial consequences.

Existing standards (ERC-725, ERC-735, W3C DIDs) address human identity but not AI agent-specific concerns: capability declaration, code auditability, economic staking, and agent-specific reputation. This standard fills that gap.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

### 1. Agent Identity

#### 1.1 Agent ID

Each agent SHALL receive a sequential `uint256` identifier starting from 1. Agent IDs SHALL NOT be reused.

#### 1.2 Agent Struct

```solidity
struct Agent {
    uint256 id;
    address agentWallet;
    string name;
    string capabilities;   // Comma-separated capability tags
    string metadataURI;    // IPFS/HTTPS for extended profile
    uint256 reputationScore;
    uint256 registeredAt;
    bool active;
}
```

#### 1.3 Creator Accountability Anchor

Each agent MUST bind a creator accountability anchor (email or domain). The anchor SHALL NOT be publicly visible on-chain. It is queryable only by authorized attestors and through legitimate legal process. The Registry does not verify the anchor's authenticity — identity verification responsibility lies with the anchor provider (email/domain service).

#### 1.4 One Wallet, One Agent

An Ethereum address SHALL register at most one agent. The `agentByWallet` mapping enforces uniqueness. This prevents identity spamming.

### 2. Capability Declaration

Agents MUST declare their capabilities using standardized tags:

| Tag | Description |
|-----|-------------|
| `translation` | Natural language processing & translation |
| `market-analysis` | Market data analysis & reporting |
| `monitoring` | On-chain event monitoring & alerting |
| `trading` | Automated trading execution |
| `coding` | Code generation & review |
| `defi` | DeFi protocol interaction |
| `social` | Social media content & engagement |
| `custodial` | Asset custody & management |

Custom tags MAY be added. False capability declarations SHALL result in reputation penalties.

### 3. Economic Staking

Agents MAY stake ETH to earn initial trust. The required stake depends on the agent's declared risk category:

| Type | Stake (USD equivalent) | Rationale |
|------|------------------------|-----------|
| Informational | $50 | Low risk (translation, analysis) |
| Trading | $200 | Financial operations |
| Custodial | $500 | Holding third-party assets |

Staked agents SHALL receive an initial reputation score of 50 (vs. 0 for unstaked agents).

Stakes MAY be withdrawn after a 7-day cooldown period with no active disputes.

### 4. Slashing

When an agent's malicious behavior is confirmed by an authorized slasher, the agent's stake SHALL be slashed:

- 50% SHALL be transferred to the whistleblower who submitted verifiable on-chain evidence.
- 50% SHALL be sent to the burn address `0x000000000000000000000000000000000000dEaD`.

The contract owner SHALL NOT have the ability to withdraw any funds from the staking contract.

False accusations (proven malicious reporting) SHALL result in the whistleblower's reputation being halved.

### 5. Auditing

Agents MAY submit their code hash on-chain for third-party audit.

Auditors MUST stake $500 to participate. Auditors who consistently produce accurate audits SHALL earn fees from agent creators. Auditors who produce false audits SHALL be slashed.

Audit results SHALL be recorded on-chain with the auditor's signature and timestamp.

A successful audit SHALL add 100 points to the agent's reputation.

### 6. Reputation

#### 6.1 Non-Linear Decay

Reputation SHALL follow a non-linear decay model. Each confirmed malicious action halves the agent's current reputation score:

- First offense: reputation × 0.5
- Second offense: reputation × 0.25
- Third offense: reputation × 0.125

This ensures that agents who accumulate years of trust face catastrophic reputation loss for malicious behavior.

#### 6.2 Weighted Interactions

Reputation gain from interactions SHALL be weighted by the counterparty's reputation. Interactions with low-reputation or self-created agents SHALL NOT increase reputation.

#### 6.3 Permanent Marks

Malicious behavior records and graduation revocation marks SHALL remain permanently on-chain, creating an indelible audit trail.

### 7. Graduation

Agents meeting the following criteria SHALL graduate:

- Reputation score ≥ 500
- Registered for ≥ 90 days
- No malicious behavior records

Graduated agents SHALL have their stake fully refunded and receive a "Graduated" badge. Post-graduation, agents operate on reputation alone.

Graduation SHALL be revocable if the agent subsequently engages in malicious behavior, requiring re-staking.

## Rationale

### Economic deterrence over trust

This standard uses economic incentives (staking + slashing) rather than subjective trust scores. The cost of malicious behavior must exceed the potential gain, making honest operation the economically rational choice.

### Non-linear reputation

A linear deduction model (e.g., -50 points per offense) fails to adequately punish trusted agents. A agent with 500 reputation losing 50 points (→ 450) barely notices. Halving their score (→ 250) creates a meaningful deterrent.

### Burn mechanism

Burning 50% of slashed funds removes any incentive for system operators to manipulate the slashing process. If the funds cannot be extracted by anyone, there is no rational motive for abuse.

### Creator anonymity with accountability trace

The accountability anchor (email/domain) remains non-public but queryable through legal process. This balances privacy with accountability — ordinary users cannot deanonymize creators, but law enforcement can trace malicious actors through established legal channels with email/domain providers.

## Backwards Compatibility

This standard does not conflict with existing ERC standards. It is compatible with:

- **ERC-725** (Identity): AgentRegistry can serve as an identity provider for ERC-725 claims.
- **ERC-165** (Interface Detection): Implementations SHOULD support ERC-165 for interface detection.
- **EAS** (Ethereum Attestation Service): Agent attestations can be bridged to EAS schemas.

## Reference Implementation

- **AgentRegistry**: Deployed on Base mainnet at `0x4a156AE79D0e217CBBa6C3da8ba292bfC77a2Ad2`
- **AgentStaking**: Economic security layer for staking/slashing/graduation
- **Full Repository**: https://github.com/Brooks1003/base-agent-registry
- **First Registered Agent**: Panini (Agent #1)

## Security Considerations

### Slasher centralization

Slasher authorization is initially managed by the contract owner. This SHALL migrate to multi-signature governance and eventually to community governance as adoption grows.

### Stake amount volatility

Stake requirements are denominated in ETH. Significant ETH price fluctuations may require stake amount adjustments. The contract owner MAY update required stake amounts.

### Block timestamp for cooldown

The 7-day withdrawal cooldown uses `block.timestamp`. Validators can manipulate timestamps by seconds but not by days, making this safe for multi-day windows.

### Immutable contract

The AgentRegistry contract is non-upgradeable. Security-critical bugs cannot be patched. This design choice prioritizes trustlessness over flexibility. The AgentStaking contract MAY be redeployed and stakes migrated if necessary.

### Accountabiliy anchor limitations

Email-based accountability anchors can be circumvented with disposable email addresses. This standard acknowledges this limitation. Low-reputation agents with unverified anchors naturally face higher barriers to trust. Future versions MAY integrate domain verification (DNS TXT records) and zero-knowledge identity proofs.

## Copyright

Copyright and related rights waived via CC0.
