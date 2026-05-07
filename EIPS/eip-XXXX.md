---
eip: XXXX
title: AI Agent Identity and Threat Registry Standard (AITIRS)
author: Sigui Protocol (@sigui-protocol), African Blockchain Initiative
status: Draft
type: Standards Track
category: ERC
created: 2024-05-07
requires: 165, 721, 1155
---

## Abstract

This EIP proposes a standardized framework for decentralized identity (DID) management, reputation scoring, and threat intelligence sharing for AI agents operating across Ethereum-based DeFi protocols. The standard defines interfaces for AI agent registration, multi-tier verification systems, cross-protocol reputation tracking, and collaborative threat detection. It enables AI agents to build portable reputations while allowing protocols to share security intelligence in a decentralized manner.

## Motivation

The rapid proliferation of AI agents in DeFi creates critical security challenges:

1. **Identity Fragmentation**: AI agents lack standardized identity systems across protocols
2. **Reputation Silos**: Agent behavior history is trapped within individual protocols  
3. **Threat Intelligence Gaps**: Security incidents are not shared between protocols
4. **Verification Inconsistencies**: No standard for agent verification tiers
5. **Cross-Protocol Risk**: Malicious agents can attack multiple protocols with fresh identities

Current solutions are protocol-specific and don't enable collaborative security. This standard addresses these challenges by creating:

- **Portable AI Agent Identities**: DID-based identities that work across all protocols
- **Shared Reputation System**: Cross-protocol reputation tracking with standardized tiers
- **Collaborative Threat Detection**: Real-time threat intelligence sharing
- **Standardized Risk Assessment**: Consistent risk evaluation frameworks
- **African Accessibility**: Low-barrier entry for African developers and protocols

## Specification

### Core Concepts

**AI Agent**: Autonomous software entity that interacts with DeFi protocols
**DID**: Decentralized Identifier following W3C DID specification  
**Verification Tier**: Standardized trust levels (None, Bronze, Silver, Gold, Platinum)
**Reputation Score**: Numerical representation of agent trustworthiness (0-1000)
**Threat Pattern**: Cryptographic hash of suspicious behavior patterns
**Risk Assessment**: Multi-dimensional security evaluation

### Interface Definitions

#### IAgentIdentityRegistry

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IAgentIdentityRegistry
 * @notice Interface for AI agent decentralized identity management
 */
interface IAgentIdentityRegistry {
    
    // Agent identity data structure
    struct AgentIdentity {
        string did;                    // did:sigui:chain:address
        bytes32 publicKey;            // Ed25519 public key
        uint8 verificationTier;        // 0=None, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum
        uint16 reputationScore;      // 0-1000 (basis points)
        uint256 registrationTime;     // Block timestamp
        uint256 lastUpdate;          // Last reputation update
        string metadataURI;          // IPFS hash of identity metadata
        bool isActive;               // Whether identity is active
        uint256 totalTransactions;    // Total evaluated transactions
        uint256 successfulTransactions; // Non-blocked transactions
    }
    
    // Verification tier structure
    struct VerificationTier {
        string name;                  // Tier name
        string requirements;          // Requirements description
        uint16 trustMultiplier;      // Multiplier for reputation (100 = 1.0x)
        uint256 verificationFee;     // Fee in wei for verification
        uint256 validityPeriod;      // Validity in seconds
    }
    
    // Events
    event AgentRegistered(
        string indexed did,
        address indexed agentAddress,
        uint8 verificationTier,
        uint16 reputationScore,
        uint256 registrationTime
    );
    
    event AgentUpdated(
        string indexed did,
        uint16 reputationScore,
        uint8 verificationTier,
        uint256 lastUpdate
    );
    
    event ReputationScoreUpdated(
        string indexed did,
        uint16 oldScore,
        uint16 newScore,
        string updateReason
    );
    
    /**
     * @notice Register a new AI agent identity
     * @param did Decentralized identifier
     * @param publicKey Agent's public key
     * @param verificationTier Initial verification tier
     * @param metadataURI URI to identity metadata
     * @return agentId Unique identifier for the agent
     */
    function registerAgent(
        string calldata did,
        bytes32 publicKey,
        uint8 verificationTier,
        string calldata metadataURI
    ) external payable returns (uint256 agentId);
    
    /**
     * @notice Update agent reputation score
     * @param agentAddress Address of the agent
     * @param newScore New reputation score (0-1000)
     * @param updateReason Reason for score update
     */
    function updateReputationScore(
        address agentAddress,
        uint16 newScore,
        string calldata updateReason
    ) external;
    
    /**
     * @notice Update agent verification tier
     * @param agentAddress Address of the agent
     * @param newTier New verification tier (0-4)
     */
    function updateVerificationTier(
        address agentAddress,
        uint8 newTier
    ) external payable;
    
    /**
     * @notice Get agent identity by address
     * @param agentAddress Address of the agent
     * @return Agent identity data
     */
    function getAgentIdentity(address agentAddress) 
        external 
        view 
        returns (AgentIdentity memory);
    
    /**
     * @notice Get agent address by DID
     * @param did Decentralized identifier
     * @return Agent address
     */
    function getAgentByDID(string calldata did) 
        external 
        view 
        returns (address);
    
    /**
     * @notice Check if agent is verified (tier > 0)
     * @param agentAddress Address of the agent
     * @return True if agent is verified
     */
    function isVerified(address agentAddress) 
        external 
        view 
        returns (bool);
    
    /**
     * @notice Calculate agent trust score combining tier and reputation
     * @param agentAddress Address of the agent
     * @return Trust score (0-1000)
     */
    function calculateTrustScore(address agentAddress) 
        external 
        view 
        returns (uint16);
}
```

#### IThreatRegistry

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IThreatRegistry
 * @notice Interface for cross-protocol threat intelligence sharing
 */
interface IThreatRegistry {
    
    // Attack record structure
    struct AttackRecord {
        address agentAddress;     // Agent's wallet address
        bytes32 patternHash;     // keccak256 of behavior pattern
        uint256 amountUSDC6;     // Amount in 6-decimal USDC
        uint256 riskMilli;       // Risk score × 1000
        uint8 layer;            // 1=behavior, 2=splitting, 3=service, 4=contract
        uint256 blockedAt;      // Block timestamp
    }
    
    // Events
    event AttackBlocked(
        uint256 indexed idx,
        address indexed agent,
        bytes32 indexed pattern,
        uint256 amountUSDC6,
        uint256 riskMilli,
        uint8 layer
    );
    
    event ThreatPatternShared(
        bytes32 indexed pattern,
        address indexed reporter,
        uint256 riskScore,
        string description
    );
    
    /**
     * @notice Record a blocked attack
     * @param agent Agent's address
     * @param pattern Behavior pattern hash
     * @param amountUSDC6 Transaction amount (6 decimals)
     * @param riskMilli Risk score × 1000
     * @param layer Attack layer (1-4)
     */
    function recordAttack(
        address agent,
        bytes32 pattern,
        uint256 amountUSDC6,
        uint256 riskMilli,
        uint8 layer
    ) external;
    
    /**
     * @notice Share a new threat pattern
     * @param pattern Pattern hash
     * @param riskScore Associated risk score
     * @param description Pattern description
     */
    function shareThreatPattern(
        bytes32 pattern,
        uint256 riskScore,
        string calldata description
    ) external;
    
    /**
     * @notice Check if agent is known attacker
     * @param agent Agent's address
     * @return True if agent is known attacker
     */
    function isKnownAttacker(address agent) 
        external 
        view 
        returns (bool);
    
    /**
     * @notice Get attack history for an agent
     * @param agent Agent's address
     * @return Attack count and total blocked amount
     */
    function getAgentAttackHistory(address agent) 
        external 
        view 
        returns (uint256 attackCount, uint256 totalBlocked);
    
    /**
     * @notice Calculate threat score for transaction
     * @param agent Agent's address
     * @param amount Transaction amount
     * @param action Action type hash
     * @return Risk score (0-1000)
     */
    function assessTransactionRisk(
        address agent,
        uint256 amount,
        bytes32 action
    ) external view returns (uint256);
}
```

#### IRiskAssessment

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IRiskAssessment
 * @notice Interface for standardized risk assessment
 */
interface IRiskAssessment {
    
    // Risk assessment result
    struct RiskAssessment {
        bool allowed;              // Whether transaction is allowed
        uint256 riskScore;         // Risk score (0-1000)
        string reason;            // Human-readable reason
        uint256 confidence;        // Confidence level (0-100)
        bytes32[] threatPatterns; // Associated threat patterns
    }
    
    // Assessment request
    struct AssessmentRequest {
        address agent;            // Agent address
        uint256 amount;          // Transaction amount
        bytes32 action;          // Action type hash
        address destination;     // Transaction destination
        bytes metadata;          // Additional metadata
    }
    
    /**
     * @notice Assess risk for a transaction
     * @param request Assessment request
     * @return Risk assessment result
     */
    function assessRisk(AssessmentRequest calldata request) 
        external 
        view 
        returns (RiskAssessment memory);
    
    /**
     * @notice Batch assess multiple transactions
     * @param requests Array of assessment requests
     * @return Array of risk assessments
     */
    function batchAssessRisk(AssessmentRequest[] calldata requests) 
        external 
        view 
        returns (RiskAssessment[] memory);
    
    /**
     * @notice Update risk assessment parameters
     * @param parameterHash Hash of parameter changes
     * @param newValues New parameter values
     */
    function updateRiskParameters(
        bytes32 parameterHash,
        uint256[] calldata newValues
    ) external;
}
```

### Verification Tiers

Standardized verification levels with specific requirements:

| Tier | Requirements | Trust Multiplier | Validity Period |
|------|-------------|------------------|-----------------|
| None | Basic DID registration | 0.5x | N/A |
| Bronze | Email + Social verification | 1.0x | 90 days |
| Silver | KYC + Staking 1000 tokens | 1.5x | 180 days |
| Gold | Enhanced KYC + Staking 10000 tokens | 2.0x | 365 days |
| Platinum | Full audit + Staking 50000 tokens | 3.0x | 730 days |

### Reputation Scoring Algorithm

```solidity
function calculateReputationScore(
    uint256 successfulTransactions,
    uint256 totalTransactions,
    uint256 threatContributions,
    uint256 verificationTier,
    uint256 timeSinceRegistration
) pure returns (uint16) {
    // Base score from transaction success rate
    uint256 baseScore = (successfulTransactions * 1000) / totalTransactions;
    
    // Verification tier multiplier
    uint256 tierMultiplier = getTierMultiplier(verificationTier);
    
    // Time-based decay factor
    uint256 timeFactor = min(timeSinceRegistration / 30 days, 2);
    
    // Threat contribution bonus
    uint256 threatBonus = min(threatContributions * 10, 100);
    
    // Final calculation
    uint256 finalScore = (baseScore * tierMultiplier * timeFactor) + threatBonus;
    
    return uint16(min(finalScore, 1000));
}
```

### Threat Pattern Standards

Threat patterns are standardized cryptographic hashes representing suspicious behaviors:

```solidity
// Pattern generation standard
function generateThreatPattern(
    string memory actionType,    // "flash_loan", "sandwich", "oracle_manipulation"
    address destination,        // Target contract
    uint256 amountBucket        // Amount range identifier
) pure returns (bytes32) {
    return keccak256(abi.encodePacked(actionType, destination, amountBucket));
}
```

### Cross-Protocol Integration

Protocols integrate through standardized adapters:

```solidity
contract ProtocolAdapter {
    IAgentIdentityRegistry public identityRegistry;
    IThreatRegistry public threatRegistry;
    
    modifier onlyVerifiedAgent() {
        require(identityRegistry.isVerified(msg.sender), "Agent not verified");
        _;
    }
    
    function protectedFunction() external onlyVerifiedAgent {
        // Protocol logic with agent protection
    }
}
```

## Rationale

### Why This Standard?

1. **Security Through Collaboration**: Enables protocols to share threat intelligence
2. **Reputation Portability**: Agents maintain reputation across protocol boundaries  
3. **African Accessibility**: Designed for low-barrier entry in emerging markets
4. **Graduated Trust**: Multi-tier system allows flexible security requirements
5. **Economic Incentives**: Staking and rewards encourage good behavior

### Design Decisions

**Vyper Implementation**: Chosen for security and African developer accessibility
**DID Standard**: W3C compliance ensures interoperability
**Multi-Tier System**: Balances security with accessibility
**Cross-Chain Design**: Works across all EVM-compatible chains
**Staking Mechanism**: Economic incentives for honest behavior

### African Context

This standard specifically addresses African blockchain challenges:

- **Limited Infrastructure**: Works on low-bandwidth networks
- **Regulatory Uncertainty**: Self-sovereign identity reduces compliance burden  
- **Financial Inclusion**: Enables AI agents for financial services
- **Local Development**: Vyper syntax accessible to African developers
- **Cross-Border**: Facilitates intra-African DeFi collaboration

## Backwards Compatibility

This standard is fully backwards compatible with existing systems:

- **ERC-165**: Implements standard interface detection
- **ERC-721**: Compatible with NFT-based identities  
- **ERC-1155**: Supports multi-token identity systems
- **Existing Protocols**: Can integrate via adapter pattern
- **Legacy Systems**: Gradual migration path available

## Test Cases

```solidity
// Test agent registration
function testAgentRegistration() public {
    string memory did = "did:sigui:eth:0x123...";
    bytes32 publicKey = keccak256("public_key");
    
    uint256 agentId = registry.registerAgent(did, publicKey, 1, "ipfs://metadata");
    
    assertEq(agentId, 1);
    assertTrue(registry.isVerified(address(this)));
}

// Test reputation update
function testReputationUpdate() public {
    address agent = address(0x123);
    
    registry.updateReputationScore(agent, 750, "Good behavior");
    
    IAgentIdentityRegistry.AgentIdentity memory identity = 
        registry.getAgentIdentity(agent);
    
    assertEq(identity.reputationScore, 750);
}

// Test threat detection
function testThreatDetection() public {
    address maliciousAgent = address(0xBAD);
    bytes32 pattern = keccak256("flash_loan_attack");
    
    threatRegistry.recordAttack(maliciousAgent, pattern, 1000000, 950, 1);
    
    assertTrue(threatRegistry.isKnownAttacker(maliciousAgent));
}
```

## Reference Implementation

Complete reference implementation available at:
- [AgentIdentityRegistry.vy](contracts/AgentIdentityRegistry.vy)
- [ThreatRegistry.vy](contracts/ThreatRegistry.vy)  
- [Hogonat.vy](contracts/Hogonat.vy)
- [CompoundSiguiAdapter.vy](partnerships/compound/CompoundSiguiAdapter.vy)

## Security Considerations

### Agent Identity Security

- **Cryptographic Verification**: All identities cryptographically verified
- **DID Document Validation**: W3C DID specification compliance
- **Key Rotation**: Support for secure key rotation
- **Revocation Mechanism**: Standardized identity revocation

### Threat Registry Security

- **Oracle Consensus**: Multi-oracle validation for threat reports
- **Rate Limiting**: Prevents spam and manipulation
- **Appeal Process**: Mechanism for false positive correction
- **Audit Trail**: Complete transparency of all decisions

### Economic Security

- **Staking Slashing**: Malicious behavior results in stake loss
- **Insurance Fund**: Protection against false positives
- **Incentive Alignment**: Rewards for honest participation
- **Cost of Attack**: Economic barriers to system gaming

### Privacy Considerations

- **Selective Disclosure**: Agents control information revelation
- **Zero-Knowledge Proofs**: Privacy-preserving verification
- **Pseudonymous Operation**: Agents operate without real-world identity
- **Data Minimization**: Only essential data stored on-chain

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).