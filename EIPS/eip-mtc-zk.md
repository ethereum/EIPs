---
eip: TBD
title: MTC-ZK — Zero-Knowledge Presentation Interface for MultiTrust Credential
description: Optional ERC interface to verify ZK proofs against MTC commitments via a fixed Groth16-style ABI, bound to the current anchor and the active comparison policy.
author: Yuta Hoshino (@YutaHoshino) <y_hoshino@indiesquare.me>
discussions-to: https://ethereum-magicians.org/t/discussion-erc-multitrust-credential-mtc-core-zk-proof-optional
status: Draft
type: Standards Track
category: ERC
created: 2025-09-19
requires: <EIP number of MTC Core>  # set once Core is numbered
---

## Abstract
This proposal defines an optional zero-knowledge presentation interface for MTC deployments. It standardizes how contracts verify proofs that a subject’s metric satisfies a predicate without revealing the underlying value, by binding the proof to the current MTC anchor and comparison policy.

## Motivation
Applications and circuits need a shared, minimal way to verify that a subject’s metric satisfies a policy (e.g., “score ≥ threshold”) without exposing raw values. A common ABI enables wallets, circuits, verifiers, and indexers to interoperate across ecosystems while keeping PII off-chain.

## Specification
The key words “MUST”, “MUST NOT”, “SHOULD”, and “MAY” are to be interpreted as described in RFC 2119 and RFC 8174.

### ERC-165 Compliance (normative)
Implementations of this standard **MUST** implement ERC-165 and report the interface id for `IMultiTrustCredentialZK`.  
The interface id is the XOR of all function selectors defined in this interface.  
Implementations **MUST NOT** change function signatures in a way that alters the interface id.

### External Verifier (normative)
```solidity
pragma solidity ^0.8.22;

/// @notice External circuit verifier (e.g., Groth16 via snarkJS).
interface IVerifier {
    /// @dev Circuit-specific verification with fixed-length proof/public inputs.
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[6] calldata publicSignals
    ) external view returns (bool);
}
```

### ZK Presentation Interface (normative)
```solidity
pragma solidity ^0.8.22;

/// @title IMultiTrustCredentialZK
/// @notice Verify a ZK proof against the current MTC Core anchor and the active comparison policy.
/// @dev This interface is optional and extends the functionality of MTC Core without changing it.
interface IMultiTrustCredentialZK {
    /// @return ok True if proof is valid AND bound to the current anchor/policy for (tokenId, metricId).
    function proveMetric(
        uint256 tokenId,
        bytes32 metricId,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[6] calldata publicSignals
    ) external view returns (bool ok);
}
```

### Public Signals Mapping (normative)
This EIP fixes the order of `publicSignals` to match the reference circuit and verifier:

```
publicSignals[0] = mode        // operator code: 1: > (GT), 2: < (LT), 3: = (EQ); 0 is disallowed
publicSignals[1] = root        // Merkle root (must equal the Core anchor for the metric)
publicSignals[2] = nullifier   // circuit-defined nullifier
publicSignals[3] = addr        // holder address as field element
publicSignals[4] = threshold   // comparator parameter (e.g., threshold or expected value)
publicSignals[5] = leaf        // committed value (private); used inside the circuit
```

### Binding Requirements (normative)
Implementations of `proveMetric` **MUST** guarantee that a successful proof is **bound to the current MTC anchor and policy** for `(tokenId, metricId)`:

- Implementations **MUST** obtain the **current** `leafFull` by calling the MTC Core contract (e.g., `getMetric(tokenId, metricId)`) and **MUST** verify `publicSignals[1] == leafFull`.
  If the metric is revoked, per Core specification, `getMetric` **MUST** revert; ZK verification **MUST NOT** succeed for revoked metrics.
- Implementations **MUST** enforce the **active comparison mask** from Core for the metric schema (CompareMask domain: `GT=1, LT=2, EQ=4`).  
  The operator encoded by `publicSignals[0]` (**mode**) **MUST** be permitted by the mask; otherwise `proveMetric` **MUST** revert. `mode == 0` **MUST** revert.
- Implementations **MUST** verify `tokenId == tokenIdOf(address(uint160(publicSignals[3])))`, interpreting `publicSignals[3]` as a **big-endian field element whose lower 160 bits map to the EVM address**. If no token exists for that address, the call **MUST** revert.

### Comparison Semantics (normative)
Let `value` denote the committed metric value proven inside the circuit. Implementations **MUST** interpret operators as:

- GT (`mode==1`): `value > threshold` (greater than)  
- LT (`mode==2`): `value < threshold` (lower than)  
- EQ (`mode==3`): `value == threshold` (exact match)

`value` and `threshold` are treated as **unsigned 256-bit integers**; units/scaling are defined by the metric schema.

### Leaf Construction with Domain Separation (normative)
To prevent cross-contract / cross-chain replay without changing the public signals arity, this profile **MUST** include a domain separator in the tree leaf construction:

```
domain := keccak256(abi.encode(chainid(), address(this)))  (reduced mod field)
treeLeaf := Poseidon(leaf, addr, domain)
```

- The circuit **MUST** compute `treeLeaf` as above and prove membership in the Merkle tree with `root == publicSignals[1]`.
- On-chain contracts **MUST** rely on the proof (and current root equality) and **MUST NOT** attempt to reconstruct `leaf` beyond verifying the proof and anchor binding.

### Optional Events
```solidity
/// @notice Emitted when the verifier address is configured (e.g., during initialize()).
event VerifierSet(address verifier);

/// @notice MAY be emitted when a proof is successfully verified.
event ProofVerified(uint256 tokenId, bytes32 metricId, uint8 mode, uint256 threshold);
```

### Rationale
- **Fixed ABI**: A Groth16 tuple is widely supported and keeps calldata minimal; other proving systems MAY adapt behind `IVerifier`.
- **Separation of Concerns**: ZK remains optional, keeping Core minimal for non-ZK deployments.
- **Binding over leakage**: By binding proofs to Core’s current anchor and the policy mask, implementations avoid value disclosure while ensuring policy is enforced. Domain separation in the leaf construction prevents cross-contract replay while preserving the 6-signal layout.

## Backwards Compatibility
MTC-ZK is optional and compatible with any MTC Core implementation that stores a commitment (`leafFull`) and a comparison mask policy.  
For the reference profile implied by this mapping, **Core SHOULD store the Merkle `root` in `leafFull`**.  
Gas costs for pairing precompiles vary by platform; implementations SHOULD document expected ranges.

## Reference Implementation
A non-normative reference will be published with example circuits and an adapter verifier contract demonstrating:
- Reading Core’s `getMetric` to retrieve the current `leafFull` (root)
- Enforcing the Core comparison mask against `mode`
- Mapping `publicSignals` per the order above
- Domain-separated leaf construction: `treeLeaf = Poseidon(leaf, addr, keccak256(abi.encode(chainid(), address(this))))`
- Emitting `ProofVerified` on success (optional)

## Security Considerations
- **Substitution & Replay**: Proofs **MUST** be bound to `(tokenId, metricId, root)` and the **active policy mask**.  
  The circuit **MUST** include domain separation in the leaf construction as specified above. Sharing identical roots across unrelated contracts **MUST NOT** occur.
- **Revocation**: Since Core `getMetric` reverts after revocation, ZK verification **MUST NOT** succeed once revoked.
- **Upgrades/Governance**: Verifier addresses SHOULD be governed (roles/timelocks), and changes SHOULD be auditable.
- **Malleability**: Implementations SHOULD reject malformed proofs and unexpected `publicSignals` layouts that would bypass policy checks.

## Editorial Notes
After the MTC Core proposal receives an EIP number, update `requires:` in the preamble to reference it.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
