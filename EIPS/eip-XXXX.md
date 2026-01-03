---
eip: XXXX
title: Agent Authorization Interface
description: A standard interface for secure, time-bound, and usage-limited delegation of on-chain actions to autonomous agents.
author: WORLD3 Team (@world3-ai) <dev@world3.ai>
discussions-to: https://ethereum-magicians.org/t/eip-xxxx-agent-authorization-interface (placeholder - topic to be created)
status: Draft
type: Standards Track
category: ERC
created: 2026-01-02
requires: 165, 712, 1271
license: CC0-1.0
---

## Abstract

This EIP defines a standard interface for authorizing autonomous agents (bots, AI systems, or automated accounts) to perform specific on-chain actions on behalf of users (principals). The standard provides:

- **Time-bound authorizations**: Optional start and end timestamps
- **Usage-limited authorizations**: Maximum call count with automatic revocation
- **Function-level granularity**: Permissions scoped to specific function selectors
- **Cryptographic consent**: Agents must sign consent to being authorized (EIP-712)
- **Single-principal constraint**: Each agent serves only one principal at a time per contract

## Motivation

As autonomous AI agents become more prevalent in blockchain ecosystems, a standardized interface for delegation is needed to:

1. **Enable AI agents to act on-chain**: AI systems need predictable, secure ways to execute transactions on behalf of users
2. **Provide fine-grained control**: Users should be able to limit what actions agents can take, for how long, and how many times
3. **Ensure security**: Agents must consent to authorizations, preventing unauthorized binding
4. **Support composability**: A standard interface enables cross-contract and cross-application agent authorization

Existing delegation mechanisms (like token approvals) are either too broad (unlimited approvals) or too narrow (single-use signatures). This standard provides a balanced approach suitable for autonomous agent scenarios.

### Real-World Use Cases

**Automated Trading Agents**: Users authorize AI trading bots to execute trades within specific parameters (e.g., only swap functions, maximum 100 calls per day, valid for 30 days).

**Gaming NPCs**: Game contracts allow AI-controlled characters to perform in-game actions on behalf of players during offline periods, with automatic expiration.

**DeFi Position Management**: Users authorize agents to rebalance portfolios, compound yields, or manage liquidation protection with usage-limited authorizations.

**DAO Proposal Execution**: Governance agents can be authorized to execute approved proposals within time windows, with automatic revocation after execution.

**Subscription Services**: Service providers authorize payment agents to collect recurring fees with monthly call limits and renewal requirements.

**Cross-Chain Relayers**: Bridge agents receive time-limited authorization to relay messages, with automatic expiration preventing stale authorizations.

### Production Validation

This standard has been validated through extensive production deployment and peer-reviewed academic research. In a fully on-chain gaming application deployed on OpBNB, the protocol:

- Supported **1,067,998 unique wallets** over 222 active days
- Processed **5,704,860 transactions** without custody violations
- Achieved peak usage of **12,791 daily active users**
- Maintained complete audit trails with zero operational interruptions
- Demonstrated immediate revocation effectiveness in practice

This production deployment validates the security properties and practical viability of the delegation model at scale.

The formal capability semantics, security invariants, and production results are documented in a peer-reviewed industrial poster presented at **BRAINS 2025** (7th Conference on Blockchain Research & Applications for Innovative Networks and Services), Zurich, Switzerland.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions

- **Principal**: The account (EOA or contract) delegating authority
- **Agent**: The account receiving authorization to act on behalf of the principal
- **Selector**: A 4-byte function selector identifying the authorized function
- **Authorization**: A tuple of (principal, agent, selector, startTime, endTime, allowedCalls)

### Interface

Contracts implementing this standard MUST implement `IERCXXXXAgentAuthorizationBase`:

```solidity
interface IERCXXXXAgentAuthorizationBase {
    // Events
    event AgentAuthorized(
        address indexed principal,
        address indexed agent,
        bytes4 indexed selector,
        uint256 startTime,
        uint256 endTime,
        uint256 allowedCalls
    );

    event AgentRevoked(
        address indexed principal,
        address indexed agent,
        bytes4 indexed selector
    );

    // Errors
    error InvalidAgentAddress();
    error InvalidSelector();
    error ZeroCallsNotAllowed();
    error ValueExceedsBounds();
    error SignatureExpired();
    error InvalidSignature();
    error AgentAlreadyBound();
    error NoAuthorizationExists();
    error NotAuthorized();

    // Write Functions
    function authorizeAgent(
        address agent,
        bytes4 selector,
        uint256 startTime,
        uint256 endTime,
        uint256 allowedCalls,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function batchAuthorizeAgent(BatchAuthorization[] calldata batch) external;

    function revokeAgent(address agent, bytes4 selector) external;

    function batchRevokeAgent(address agent, bytes4[] calldata selectors) external;

    // View Functions
    function isAuthorizedAgent(
        address principal,
        address agent,
        bytes4 selector
    ) external view returns (bool);

    function getAgentAuthorization(
        address principal,
        address agent,
        bytes4 selector
    ) external view returns (uint256 startTime, uint256 endTime, uint256 remainingCalls);

    function principalOf(address agent) external view returns (address);

    function nonces(address agent) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

struct BatchAuthorization {
    address agent;
    bytes4 selector;
    uint256 startTime;
    uint256 endTime;
    uint256 allowedCalls;
    uint256 deadline;
    bytes signature;
}
```

### Optional Update Extension

Contracts MAY implement `IERCXXXXAgentAuthorizationUpdatable` for in-place authorization updates:

```solidity
interface IERCXXXXAgentAuthorizationUpdatable is IERCXXXXAgentAuthorizationBase {
    event AgentAuthorizationUpdated(
        address indexed principal,
        address indexed agent,
        bytes4 indexed selector,
        uint256 newStartTime,
        uint256 newEndTime,
        uint256 newAllowedCalls
    );

    function updateAgentAuthorization(
        address agent,
        bytes4 selector,
        uint256 newStartTime,
        uint256 newEndTime,
        uint256 newAllowedCalls,
        uint256 deadline,
        bytes calldata signature
    ) external;
}
```

#### Update Extension Behavior

The `updateAgentAuthorization` function allows principals to modify existing authorizations:

1. The function MUST revert with `NoAuthorizationExists` if no authorization exists for the specified principal-agent-selector tuple.

2. Updates are classified as either **restrictions** or **escalations**:
   - **Restriction** (no signature required): reducing `remainingCalls`, narrowing the time window
   - **Escalation** (signature required): increasing `remainingCalls`, extending the time window

   **Sentinel Value Semantics for Comparisons:**

   Since `startTime = 0` means "immediately valid" and `endTime = 0` means "no expiration" (infinite), comparisons MUST treat these sentinel values as follows:

   For `startTime` (where 0 = immediate, lower is more permissive):
   - `0 → non-zero`: RESTRICTION (adding a start delay)
   - `non-zero → 0`: ESCALATION (removing start delay)
   - `non-zero → higher non-zero`: RESTRICTION (increasing delay)
   - `non-zero → lower non-zero`: ESCALATION (decreasing delay)

   For `endTime` (where 0 = infinite/no expiry, higher is more permissive):
   - `0 → non-zero`: RESTRICTION (adding an expiration)
   - `non-zero → 0`: ESCALATION (removing expiration, granting infinite validity)
   - `non-zero → lower non-zero`: RESTRICTION (earlier expiration)
   - `non-zero → higher non-zero`: ESCALATION (later expiration)

   For `remainingCalls`:
   - `current → lower`: RESTRICTION
   - `current → higher`: ESCALATION

3. For escalations, the function MUST:
   - Validate the agent's EIP-712 signature (same `AgentConsent` structure as `authorizeAgent`)
   - Revert with `SignatureExpired` if `block.timestamp > deadline`
   - Revert with `InvalidSignature` if the signature is invalid
   - Increment the agent's nonce after successful update

4. The function MUST:
   - Revert with `ZeroCallsNotAllowed` if `newAllowedCalls` is 0 (use `revokeAgent` instead)
   - Revert with `ValueExceedsBounds` if values exceed storage bounds
   - Emit `AgentAuthorizationUpdated` on success

### Behavior Specification

#### Authorization

The `principal` for all authorization operations MUST be `msg.sender`. The caller of `authorizeAgent` is always the principal granting the authorization.

1. The `authorizeAgent` function MUST:
   - Set the principal to `msg.sender` (the caller is the principal)
   - Revert with `InvalidAgentAddress` if `agent` is the zero address
   - Revert with `InvalidSelector` if `selector` is `0x00000000`
   - Revert with `ZeroCallsNotAllowed` if `allowedCalls` is 0
   - Revert with `ValueExceedsBounds` if `startTime` or `endTime` exceeds `type(uint48).max`, or `allowedCalls` exceeds `type(uint64).max`
   - Revert with `SignatureExpired` if `block.timestamp > deadline`
   - Revert with `InvalidSignature` if the signature is invalid or the `principal` field in the signed message does not match `msg.sender`
   - Revert with `AgentAlreadyBound` if the agent is bound to a different principal
   - Increment the agent's nonce after successful authorization
   - Emit `AgentAuthorized` on success

   If an authorization already exists for the `(msg.sender, agent, selector)` tuple, `authorizeAgent` MUST overwrite the existing authorization with the new parameters. This behavior mirrors ERC-20 `approve` semantics where a new approval replaces the previous one. Principals who wish to extend an existing authorization without replacement SHOULD use the optional `updateAgentAuthorization` function if available.

2. The signature MUST be an EIP-712 typed data signature with the following structure:
   ```
   AgentConsent(
       address principal,
       address agent,
       bytes4 selector,
       uint256 startTime,
       uint256 endTime,
       uint256 allowedCalls,
       uint256 nonce,
       uint256 deadline
   )
   ```

3. For contract agents, the signature MUST be validated using EIP-1271 `isValidSignature`.

4. The EIP-712 domain MUST use the following structure:
   ```
   EIP712Domain(
       string name,
       string version,
       uint256 chainId,
       address verifyingContract
   )
   ```
   Implementations SHOULD use `name = "Agent Authorization"` and `version = "1"` for interoperability, but MAY use contract-specific values. The `chainId` MUST be the current chain ID, and `verifyingContract` MUST be the contract address implementing this interface.

#### Time and Usage Bounds

Time bounds use sentinel values for unbounded conditions:
- A `startTime` of 0 means the authorization is immediately valid (no start restriction)
- An `endTime` of 0 means the authorization has no expiration (no end restriction)

Authorization time validity MUST be evaluated as:
- If `startTime != 0` AND `block.timestamp < startTime`, authorization is NOT valid
- If `endTime != 0` AND `block.timestamp > endTime`, authorization is NOT valid
- Otherwise, the authorization is time-valid

Note: If `startTime > endTime` (where both are non-zero), the authorization will never be time-valid. Implementations MAY reject such authorizations at creation time.

Usage limits:
- Each successful call through a protected function MUST decrement `remainingCalls` (the current remaining count)
- When `remainingCalls` reaches 0, the authorization MUST be automatically revoked
- The `allowedCalls` parameter in `authorizeAgent` sets the initial value of `remainingCalls`

#### Single-Principal Constraint

Each agent can only be bound to one principal at a time within a contract instance. This prevents conflicting instructions from multiple principals.

#### Revocation

- Principals can revoke authorizations at any time using `revokeAgent`
- The `revokeAgent` function MUST revert with `NoAuthorizationExists` if the specified authorization does not exist
- When an agent's last authorization is revoked, the agent becomes unbound (can be authorized by a different principal)

#### View Functions

View functions MUST NOT revert for valid inputs and MUST return predictable values:

1. `isAuthorizedAgent(principal, agent, selector)` MUST return `true` if and only if:
   - An authorization exists for the `(principal, agent, selector)` tuple, AND
   - The authorization is time-valid per the rules in "Time and Usage Bounds", AND
   - `remainingCalls > 0`

   Otherwise, it MUST return `false`. This function MUST NOT revert.

2. `getAgentAuthorization(principal, agent, selector)` MUST:
   - Return `(startTime, endTime, remainingCalls)` from storage if an authorization exists
   - Return `(0, 0, 0)` if no authorization exists for the tuple
   - This function MUST NOT revert for valid addresses and selectors

3. `principalOf(agent)` MUST:
   - Return the address of the principal the agent is currently bound to
   - Return `address(0)` if the agent is not bound to any principal
   - This function MUST NOT revert

4. `nonces(agent)` MUST:
   - Return the current nonce for the agent (used for signature replay protection)
   - Return `0` for agents that have never been authorized
   - This function MUST NOT revert

#### Batch Operations

Batch operations provide gas-efficient multi-authorization management:

1. `batchAuthorizeAgent` MUST:
   - Process each `BatchAuthorization` in array order (index 0 first)
   - Be atomic: if any single authorization fails, the entire batch MUST revert
   - The principal for all authorizations in the batch MUST be `msg.sender`
   - Each element's signature MUST use the same `AgentConsent` EIP-712 typed data structure as `authorizeAgent`

   **Nonce Sequencing for Batch Operations:**

   When the same agent appears multiple times in a batch (with different selectors), signatures MUST use sequential nonces:
   - The first authorization for an agent uses `nonces(agent)` (the current stored nonce)
   - Each subsequent authorization for the same agent in the batch uses `nonces(agent) + N`, where N is the number of prior authorizations for that agent in the batch
   - The agent's stored nonce is incremented once per successful authorization

   Example: If agent A has nonce=5 and appears at batch indices 0, 2, and 4:
   - Index 0: signature uses nonce 5
   - Index 2: signature uses nonce 6
   - Index 4: signature uses nonce 7
   - After batch completes: stored nonce becomes 8

2. `batchRevokeAgent` MUST:
   - Revoke all specified selectors for the given agent
   - Be atomic: if any revocation fails (e.g., authorization doesn't exist), the entire batch MUST revert

### ERC-165 Interface Detection

Contracts MUST implement ERC-165 and return `true` for:
- `IERCXXXXAgentAuthorizationBase` interface ID: `0x9e22ca0f`
- `IERCXXXXAgentAuthorizationUpdatable` interface ID (if implemented): `0x51c6e02e`

The base interface ID is calculated as the XOR of all function selectors:
```
authorizeAgent(address,bytes4,uint256,uint256,uint256,uint256,bytes) = 0xcc14c2e4
batchAuthorizeAgent((address,bytes4,uint256,uint256,uint256,uint256,bytes)[]) = 0xdbfb37e9
revokeAgent(address,bytes4) = 0xe9bbcb43
batchRevokeAgent(address,bytes4[]) = 0x46c0b6de
isAuthorizedAgent(address,address,bytes4) = 0x616c0c47
getAgentAuthorization(address,address,bytes4) = 0x6eb21fd1
principalOf(address) = 0x61e20a1c
nonces(address) = 0x7ecebe00
DOMAIN_SEPARATOR() = 0x3644e515
```

The updatable extension ID is: `0x9e22ca0f XOR updateAgentAuthorization selector (0xcfe42a21) = 0x51c6e02e`

## Rationale

### Agent Consent Requirement

Requiring agents to sign consent prevents principals from binding agents without their knowledge. This is crucial for:
- Preventing DOS attacks where malicious principals could bind agents to unusable contracts
- Ensuring agents are aware of their responsibilities
- Providing a clear audit trail of consent

### Single-Principal Constraint

While limiting, this constraint:
- Prevents conflicting instructions from multiple principals
- Simplifies the security model
- Reduces gas costs (no need to track multiple principals per agent)

### Null Selector Prohibition

The zero selector (`0x00000000`) is prohibited to prevent ambiguity with wildcard authorizations, which are explicitly not supported for security reasons.

### Packed Storage

Authorization data uses packed storage (uint48 for timestamps, uint64 for call count) to:
- Reduce gas costs for storage operations
- Keep authorization data in a single storage slot
- Maintain practical limits (timestamps valid for ~8.9 million years, call counts up to ~18 quintillion)

### Comparison with Existing Standards

This EIP occupies a unique position relative to existing delegation standards:

| Feature | ERC-4337 | EIP-7702 | This EIP |
|---------|----------|----------|----------|
| **Address Type** | Smart wallet | EOA | EOA |
| **Custody** | Smart wallet | EOA | EOA preserved |
| **Granularity** | Session keys | Tx-scoped | Function-level |
| **Limits** | Time-based | Per-tx | Usage- and time-bounded |
| **Revocation** | Wallet-specific | Tx ends | Immediate |
| **Chains** | EVM only | Ethereum | Multi-chain |
| **Migration** | Required | None | None |

**Key Differentiators:**

- Unlike smart account wallets (ERC-4337) that relocate custody to contract accounts, this EIP preserves EOA custody without migration
- Unlike single-use EOA code delegation (EIP-7702), this EIP introduces persistent, function-level capabilities
- This EIP remains compatible with account abstraction features such as bundlers and paymasters, preserving existing wallet infrastructure while enabling fine-grained delegation

**ERC-2612 (Permit)**
- ERC-2612 provides gasless token approvals via signatures
- This EIP generalizes the signature-based authorization pattern beyond token transfers
- Both use EIP-712 typed data and nonces for replay protection
- This EIP adds time bounds, usage limits, and function-level granularity

**ERC-4337 (Account Abstraction)**
- ERC-4337 abstracts account logic for flexible transaction validation
- This EIP focuses on agent-level delegation within existing accounts
- ERC-4337 UserOperations require bundlers; this EIP works with standard transactions
- Complementary: smart accounts can implement this interface for agent delegation

**ERC-6900 (Modular Accounts)**
- ERC-6900 defines plugin architecture for modular smart accounts
- This EIP can be implemented as an ERC-6900 execution plugin
- ERC-6900 focuses on account modularity; this EIP focuses on agent authorization semantics
- Both support ERC-165 interface detection for composability

**ERC-7579 (Minimal Modular Accounts)**
- ERC-7579 provides minimal modular account interface
- Similar complementary relationship as with ERC-6900
- This EIP's authorization module could be added to ERC-7579 accounts

## Backwards Compatibility

This EIP introduces a new interface and does not modify existing standards. Contracts implementing this standard can coexist with other delegation mechanisms.

### Account Abstraction Compatibility

This EIP is designed to complement rather than replace account abstraction infrastructure:

- **Bundler Integration**: Authorized agent transactions can be bundled via ERC-4337 bundlers
- **Paymaster Support**: Gas sponsorship via paymasters is fully compatible with agent-authorized calls
- **No Wallet Migration**: Existing EOA wallets can use this standard without migration to smart contract wallets
- **Minimal Integration Path**: dApps can add capability-based delegation by implementing policy guards on existing contracts

### Integration Strategies

**Existing Contracts**: Contracts without this interface can be wrapped by a proxy implementing `IERCXXXXAgentAuthorizationBase` that delegates authorized calls to the underlying contract.

**Token Approvals**: This standard operates independently of ERC-20/721/1155 approval mechanisms. An agent authorized via this interface still requires appropriate token approvals for transfers.

**Access Control**: This standard complements but does not replace role-based access control (e.g., OpenZeppelin AccessControl). Contract owners should consider whether agent authorizations should be granted in addition to or instead of role assignments.

### Upgrade Considerations

Contracts using the optional update extension (`IERCXXXXAgentAuthorizationUpdatable`) should ensure upgrade mechanisms preserve authorization state. When using proxy patterns (ERC-1967, UUPS), the authorization storage slots must remain consistent across implementations.

## Reference Implementation

A reference implementation is available at [github.com/WORLD3-ai/eips](https://github.com/WORLD3-ai/eips/tree/main/contracts):

- [`AgentAuthorizationBase.sol`](https://github.com/WORLD3-ai/eips/blob/main/contracts/AgentAuthorizationBase.sol): Base implementation
- [`AgentAuthorizationUpdatable.sol`](https://github.com/WORLD3-ai/eips/blob/main/contracts/AgentAuthorizationUpdatable.sol): Implementation with update extension
- [`interfaces/`](https://github.com/WORLD3-ai/eips/tree/main/contracts/interfaces): Interface definitions
- [`libraries/`](https://github.com/WORLD3-ai/eips/tree/main/contracts/libraries): Shared types and errors
- [`test/`](https://github.com/WORLD3-ai/eips/tree/main/test): Comprehensive test suite (98 tests)

## Test Cases

The reference implementation includes a comprehensive test suite with 98 tests covering:

### Authorization Tests
- Valid authorization with proper EIP-712 signature
- Rejection of zero agent address (`InvalidAgentAddress`)
- Rejection of zero selector (`InvalidSelector`)
- Rejection of zero allowed calls (`ZeroCallsNotAllowed`)
- Rejection of expired signatures (`SignatureExpired`)
- Rejection of invalid signatures (`InvalidSignature`)
- Rejection when agent is bound to different principal (`AgentAlreadyBound`)
- Rejection of values exceeding storage bounds (`ValueExceedsBounds`)

### Execution Tests
- Successful execution with valid authorization
- Proper decrementing of `allowedCalls` counter
- Automatic revocation when `allowedCalls` reaches zero
- Time-bound enforcement (before `startTime`, after `endTime`)
- Principal context preservation during callbacks

### Revocation Tests
- Manual revocation by principal
- Agent unbinding after last authorization revoked
- Rejection of non-existent authorization revocation (`NoAuthorizationExists`)

### Batch Operation Tests
- Batch authorization with multiple agent-selector pairs
- Atomic failure on any invalid authorization in batch
- Batch revocation of multiple selectors

### Contract Agent Tests (EIP-1271)
- Authorization of smart contract agents
- Signature validation via `isValidSignature`

### Update Extension Tests
- Restriction without signature (reducing calls, narrowing time window)
- Escalation requiring signature (increasing calls, extending time window)
- Rejection of non-existent authorization update

## Security Considerations

### Formal Security Properties

This standard provides four formal security guarantees, validated through production deployment:

1. **Custody Preservation**: Agents invoke only those methods that a user-signed capability authorizes, scoped to the chain, the contract, and the selector set. The principal's private key is never shared with the agent.

2. **Bounded Authority**: On-chain verification of quota, scope, and expiry occurs before execution. Any successful call consumes exactly one unit of allowance, ensuring agents cannot exceed their authorization.

3. **Cryptographic Attribution**: Every delegated action is linked to its capability identifier and the corresponding user signature, providing complete audit trails.

4. **Effective Revocation**: Once a revocation is finalized on-chain, any subsequent use fails immediately. Production deployment demonstrated immediate revocation effectiveness across millions of transactions.

### Signature Replay Protection

- Nonces prevent replay of the same signature
- Deadlines limit the validity window of signatures
- EIP-712 domain separator prevents cross-contract replay
- Chain ID in domain separator prevents cross-chain replay

### Reentrancy

Protected functions should follow the checks-effects-interactions pattern. The modifier validates and consumes authorization before executing the protected function.

### Front-Running

- Revocation transactions may be front-run by agents attempting to use remaining calls
- Consider using private mempools for sensitive revocations
- Time-based restrictions (endTime) provide additional protection

### Agent Key Security

Compromised agent keys can be mitigated by:
- Setting conservative `allowedCalls` limits
- Using short time windows
- Prompt revocation via `revokeAgent`

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
