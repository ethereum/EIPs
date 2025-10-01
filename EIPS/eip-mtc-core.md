---
eip: TBD
title: MultiTrust Credential (MTC) — Verifiable Reputation Interface (Core)
description: Minimal ERC interface for non-transferable reputation credentials with typed metrics, lifecycle events, and policy masks, without on-chain PII.
author: Yuta Hoshino (@YutaHoshino) <y_hoshino@indiesquare.me>
discussions-to: https://ethereum-magicians.org/t/discussion-erc-multitrust-credential-mtc-core-zk-proof-optional
status: Draft
type: Standards Track
category: ERC
created: 2025-09-19
---

## Abstract
This proposal specifies a minimal, implementation-agnostic ERC interface matching the MultiTrustCredential reference. It standardizes schema registration, role-gated mint/update/revoke, slashing, and validity reads for VC-aligned reputation metrics, while keeping personally identifiable information (PII) off-chain.

## Motivation
Applications need portable, privacy-preserving ways to check eligibility, reputation, or compliance across dApps and chains. Current solutions rely on bespoke contracts or token-based SBTs, which limit interoperability and indexing. MTC defines canonical events, read APIs, and policy masks so wallets, SDKs, and indexers can integrate reputation data with stable semantics.

## Specification
The key words “MUST”, “MUST NOT”, “SHOULD”, and “MAY” are to be interpreted as described in RFC 2119 and RFC 8174.

### ERC-165 Compliance (normative)
Implementations of this standard **MUST** implement ERC-165 and report the interface id for `IMultiTrustCredentialCore`.
The interface id is the XOR of all function selectors defined in the normative interface.
Implementations **MUST NOT** change function signatures in a way that alters the interface id.

### Terms
- **Subject**: Address whose reputation is recorded (one credential token per subject).
- **Metric Schema**: Typed identifier (bytes32) describing a reputation dimension.
- **Mask**: Bitmask policy that constrains allowed comparison operators (GTE/LTE/EQ).
- **Leaf Commitment**: On-chain commitment (e.g., Merkle/poseidon/keccak) to off-chain VC payloads.

### Events (normative)
```solidity
event MetricRegistered(bytes32 indexed id, string label, bytes32 role, uint8 mask);
event MetricUpdated(uint256 indexed tokenId, bytes32 indexed metricId, uint32 newValue, uint256 leafFull);
event MetricRevoked(uint256 indexed tokenId, bytes32 indexed metricId, uint32 prevValue, uint256 prevLeaf);
event Slash(uint256 indexed tokenId, bytes32 indexed metricId, uint32 penalty);
event CompareMaskChanged(bytes32 indexed id, uint8 oldMask, uint8 newMask, address indexed editor);
/// @dev OPTIONAL: Implementations that integrate a ZK verifier MAY emit this.
event VerifierSet(address verifier);
event MaskFrozenSet(bytes32 id, bool frozen);
```

> Note: The event parameter name `role` corresponds to the `roleName` argument in `registerMetric`.

### Data Structures (normative ABI)
```solidity
/**
* @dev Stored metric (per tokenId, metricId).
* - `value`     : current numeric value (or placeholder if commitment-only)
* - `leafFull`  : commitment/hash (circuit-dependent)
* - `timestamp` : last update time (seconds)
* - `expiresAt` : deadline of this metric. 0 indicates no expiration date.
*/
struct Metric { uint32 value; uint256 leafFull; uint32 timestamp; uint32 expiresAt; }

/**
* @dev Input for single mint.
* - `uri` is set as tokenURI on first mint for the address.
*/
struct MetricInput  { bytes32 metricId; uint32 value; uint256 leafFull; string uri; uint32 expiresAt; }

/**
* @dev Input for an update.
*/
struct MetricUpdate { bytes32 metricId; uint32 newValue; uint256 leafFull; uint32 expiresAt; }

/**
* @dev Batch mint item; creates token if absent and sets tokenURI on first write.
*/
struct MintItem { address to; bytes32 metricId; uint32 value; uint256 leafFull; string uri; uint32 expiresAt; }

/**
* @dev Batch update item for an existing token.
*/
struct UpdateItem { uint256 tokenId; bytes32 metricId; uint32 newValue; uint256 leafFull; uint32 expiresAt; }
```

### Compare Mask Domain (normative)
Valid mask values are limited to the bitwise subset of `{ GT = 1, LT = 2, EQ = 4 }`.
Implementations **MUST** revert if a mask contains undefined bits.
After `setMaskFrozen(id, true)` for a given `id`, subsequent `setCompareMask(id, …)` **MUST** revert.

### Interface (normative)
```solidity
pragma solidity ^0.8.22;

interface IMultiTrustCredentialCore {
    /* Schema & Policy */
    function registerMetric(
        bytes32 id,
        string  calldata label,
        bytes32 roleName,
        bool    commitment,
        uint8   mask
    ) external;

    function setCompareMask(bytes32 id, uint8 mask) external;
    function setMaskFrozen(bytes32 id, bool frozen) external;

    /* Mint & Update */
    function mint(address to, MetricInput calldata data) external;
    function mintBatch(MintItem[] calldata arr) external;
    function updateMetric(uint256 tokenId, MetricUpdate calldata upd) external;
    function updateMetricBatch(UpdateItem[] calldata arr) external;
    function revokeMetric(uint256 tokenId, bytes32 metricId) external;
    function slash(address offender, bytes32 metricId, uint32 penalty) external;

    /* Read API */
    function getMetric(uint256 tokenId, bytes32 metricId)
        external view returns (uint32 value, uint256 leafFull, uint32 timestamp);

    function tokenIdOf(address subject) external pure returns (uint256);
}
```

### Revocation Semantics (normative)
After a metric is revoked for `(tokenId, metricId)`, `getMetric(tokenId, metricId)` **MUST** revert.

### Non-Transferability & One-Token-Per-Subject (normative)
Implementations **MUST** enforce non-transferability of the credential token.
There **MUST NOT** exist more than one credential token per subject.
If a deterministic mapping is used, `tokenId` **SHOULD** equal `uint256(uint160(subject))`, and `tokenIdOf(subject)` **MUST** return that value.

### State-Change Authorization (normative)
All state-changing functions (`registerMetric`, `setCompareMask`, `setMaskFrozen`, `mint`, `mintBatch`, `updateMetric`, `updateMetricBatch`, `revokeMetric`, `slash`) **MUST** be restricted by implementation-defined roles/policies.

### Function Behavior & Failure Conditions (normative, minimum set)
- `registerMetric` **MUST** revert if `id` is already registered (unless the implementation explicitly supports updates) and **MUST** revert if `mask` contains undefined bits.
- `setCompareMask` **MUST** revert if `id` is unknown or if `mask` contains undefined bits.
- `setMaskFrozen(id, true)` freezes the policy for `id`; subsequent `setCompareMask(id, …)` **MUST** revert.
- `mint` **MUST** revert if a credential token already exists for `to`, or if `data.metricId` is not registered, or if the caller lacks the required role.
- `updateMetric` / `updateMetricBatch` **MUST** revert if the metric schema is not registered, or if the caller lacks the required role. `updateMetric` **MUST** enforce the `deadline` rule above.
- `revokeMetric` **MUST** revert if the metric is not present or if the caller lacks the required role.
- `slash(offender, …)` **MUST** target the existing credential holder; implementations **SHOULD** derive `tokenId` via `tokenIdOf(offender)` and **MUST** revert if no token exists for `offender`.

### Policy Mask (informative)
```solidity
/**
 * @dev Bit mask for allowed comparison operators in zk checks.
 * GT=1, LT=2, EQ=4 .. combinations allowed (e.g., 1|4).
 */
library CompareMask {
    // Bit flags (base)
    uint16 internal constant GT  = 1 << 0; // 0b0001
    uint16 internal constant LT  = 1 << 1; // 0b0010
    uint16 internal constant EQ  = 1 << 2; // 0b0100
    uint16 internal constant IN  = 1 << 3; // 0b1000 (allowlist membership)
    // Aliases / composites
    uint16 internal constant NONE = 0;           // KYC-only (no compare)
    uint16 internal constant NE   = GT | LT;     // not equal
    uint16 internal constant GTE  = GT | EQ;
    uint16 internal constant LTE  = LT | EQ;
    uint16 internal constant ALL  = GT | LT | EQ;
}
```

### Rationale
- **Event stability**: Canonical events enable uniform indexing across chains.
- **Struct-based ABI**: Minimizes app/SDK glue and preserves upgrade flexibility.
- **Mask governance**: Freezing masks allows ossifying comparison policies post-audit.

## Backwards Compatibility
MTC does not conflict with ERC-721/1155 and can co-exist with ERC-4973/5192 when tokens represent badges. This specification does not define transfer or approval events and SHOULD NOT be confused with token transfer standards.

## Reference Implementation
A non-normative reference will be published (Solidity ≥0.8.22) mirroring the interfaces and events above:  
- Core contract: `MultiTrustCredential.sol` (https://github.com/hazbase/contracts/blob/main/multi-trust-credential/contracts/MultiTrustCredential.sol)

## Security Considerations
- **Role-Gated Writes**: Implementations MUST restrict writers per metric (`roleName`) and protect administrative operations.
- **Non-Transferability**: Implementations MUST prevent transfer of credential tokens.
- **Privacy**: PII MUST NOT be stored on-chain; `leafFull` SHOULD commit to normalized VC payloads; hash functions SHOULD be collision-resistant.
- **Replay/Substitution**: Writers SHOULD prevent duplicate digests and bind updates to `(tokenId, metricId)`; clients SHOULD verify event consistency.
- **Governance**: `CompareMask` freezes SHOULD be used after audits; `VerifierSet` (if any) SHOULD be governed (roles/timelocks).

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
