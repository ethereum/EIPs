---
title: Stateless Block Witnesses with Verkle Proofs
description: Standardises block-carried state witnesses using Verkle proofs to enable stateless block verification.
author: Charles Cohen (@CharlesStratusnet)
discussions-to: https://ethereum-magicians.org
status: Draft
type: Standards Track
category: Core
created: 2025-12-19
---


## Abstract

This proposal standardises the inclusion of state witnesses within execution blocks, consisting of the minimal state data required for transaction execution together with corresponding Verkle proofs. These witnesses allow validators to verify and execute blocks without maintaining the full Ethereum state locally, while preserving correctness through cryptographic commitments to the canonical state root. The specification enables stateless block verification as an opt-in execution model and establishes a foundation for reducing long-term state storage requirements without altering transaction semantics or execution results.

## Motivation

Ethereum validators are currently required to store and maintain the full execution state in order to verify and execute blocks. As the network grows, this state continues to expand monotonically, increasing storage requirements, prolonging initial synchronisation, and raising the operational cost of running a validating node. Over time, this trend places increasing pressure on decentralisation by favouring operators with greater hardware and bandwidth resources.

At the same time, the execution of a block only depends on a small subset of the global state. For any given block, only the accounts, contract code, and storage slots touched by its transactions are required to deterministically reproduce execution results. The remainder of the state is irrelevant for block level verification, yet must still be retained by all validators under the current model.

Previous approaches to mitigating state growth have focused on pruning, snapshot based synchronisation, or external state providers. While valuable, these approaches do not address the fundamental coupling between block verification and persistent full state storage. As long as validators are required to locally possess the entire state, the long term growth trajectory remains unchanged.

This proposal addresses that coupling by standardising the inclusion of state witnesses within blocks. By providing the exact state data required for execution together with cryptographic proofs of correctness, validators can verify blocks against the canonical state root without maintaining the full state locally. This preserves Ethereum’s security model while decoupling block verification from mandatory state storage.

Importantly, this specification does not mandate stateless nodes, alter transaction semantics, or change execution outcomes. It instead defines a common, verifiable format that enables stateless verification as an execution option, allowing clients and future protocol upgrades to progressively reduce state storage requirements without disrupting existing assumptions.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “NOT RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Overview

This specification defines an optional mechanism for including execution state witnesses within Ethereum execution blocks. A state witness consists of the minimal set of state data required to execute all transactions in a block, together with cryptographic proofs demonstrating that the provided data is consistent with the canonical execution state committed to by the block’s `state_root`.

The mechanism enables validators to verify and execute blocks without requiring local access to the full execution state. This specification does not mandate stateless validators, alter transaction semantics, or change execution results. It defines a standard, interoperable format and validation rules for block-carried state witnesses.

---

### Definitions

- **State Element**: Any component of the Ethereum execution state accessed during block execution, including account data, contract bytecode, and storage slots.
- **State Witness**: A collection of state elements together with cryptographic proofs sufficient to verify their inclusion in the canonical execution state.
- **Witness Payload**: The encoded representation of the state witness included with a block.
- **Witness Commitment**: A cryptographic commitment to the witness payload included in the block header.
- **Verkle Proof**: A cryptographic proof demonstrating membership of one or more state elements in a Verkle tree rooted at a given `state_root`.

---

### Witness Inclusion

An execution block MAY include a witness payload.

If a witness payload is included, it MUST contain all state elements accessed during the execution of every transaction in the block, including but not limited to:

- Sender and recipient account state
- Contract bytecode
- All storage slots read or written
- Any additional state required to deterministically reproduce execution

A witness payload MUST be complete. Omission of any required state element SHALL render the block invalid.

Blocks MAY omit a witness payload entirely.

---

### Witness Commitment

If a block includes a witness payload, the block header MUST include an additional field:
state_witness_commitment: Bytes32


The `state_witness_commitment` MUST be a deterministic cryptographic commitment to the entire witness payload. The commitment construction MUST be identical across implementations.

If a block does not include a witness payload, the `state_witness_commitment` field MUST be set to the zero value.

---

### Witness Payload Structure

The witness payload MUST consist of the following components:

1. **State Elements**
   - Canonically encoded representations of all required state elements.
   - Encoding rules MUST be deterministic and unambiguous.

2. **Verkle Proofs**
   - Cryptographic proofs demonstrating that each state element is included in the Verkle tree committed to by the block’s `state_root`.
   - Proofs MAY be aggregated where supported by the proof system.

The ordering of state elements and proofs within the witness payload MUST be deterministic.

---

### Validation Rules

For blocks that include a witness payload, validators MUST perform the following additional validation steps:

1. **Commitment Verification**
   - The witness payload MUST match the `state_witness_commitment` in the block header.

2. **Proof Verification**
   - All Verkle proofs MUST successfully verify against the block’s `state_root`.

3. **Execution Verification**
   - Executing the block using only the provided witness data MUST produce identical execution results, receipts, and state transitions as execution using a locally stored full state.

4. **Completeness Verification**
   - All state accesses performed during execution MUST be satisfied by the witness payload.

Failure of any of the above checks MUST cause the block to be considered invalid.

---

### Client Behaviour

Clients MAY support one or more of the following modes:

- Stateful block verification using locally stored execution state
- Stateless block verification using witness payloads
- Hybrid verification supporting both approaches

Clients MUST NOT assume that blocks include witness payloads.

Clients supporting stateless verification SHOULD reject malformed, unverifiable, or incomplete witness payloads.

---

### Resource Management

This specification does not define protocol-level limits on witness payload size or proof complexity.

Clients MAY impose local policy limits on witness size, bandwidth usage, or verification cost, provided such limits do not affect consensus validity.

Future protocol upgrades MAY introduce explicit limits, pricing mechanisms, or incentive structures for witness inclusion.

---

### Chain Specifics

- Genesis blocks MUST NOT include witness payloads.
- Blocks prior to activation MUST be interpreted as not including witness payloads.
- This specification applies uniformly across mainnet, testnets, and devnets once activated.

---

### Explicit Non-Goals

This specification does not:

- Require validators to operate statelessly
- Modify gas accounting or fee mechanisms
- Alter transaction formats or execution semantics
- Mandate global adoption of Verkle trees outside witness verification
- Replace existing state storage models

---



### Chain Specifics

This specification introduces no chain-specific behaviour differences between mainnet, testnets, or devnets.

Genesis blocks MUST NOT include state witness payloads or witness commitments.

Blocks produced prior to activation of this specification MUST be interpreted as not including state witnesses, and their headers MUST be treated as having a zero `state_witness_commitment`.

Testnets and devnets MAY enable this specification independently for testing and experimentation purposes without requiring additional configuration or network-specific parameters.

No special handling is required for network upgrades beyond standard fork activation procedures.

## Rationale

### Block-carried witnesses

The primary design choice of this specification is to place state witnesses at the block level rather than requiring validators to independently reconstruct or retrieve state from external sources. Block-level inclusion ensures that all data required for execution and verification is available at the point of validation, preserving determinism and avoiding reliance on off-chain infrastructure or trusted state providers.

This approach aligns with Ethereum’s existing block-centric verification model, where all information required to validate a block is either directly present in the block or cryptographically committed to by the block header. By extending this model to include execution state witnesses, the specification preserves existing validation assumptions while reducing mandatory state storage requirements.

---

### Use of Verkle proofs

Verkle proofs are selected as the witness proof mechanism due to their favorable proof size characteristics when proving large numbers of key-value pairs. Compared to Merkle proofs, Verkle proofs allow a wide branching factor and proof aggregation, resulting in significantly smaller witness sizes for equivalent state access patterns.

This choice aligns with Ethereum’s ongoing work toward Verkle tree–based state commitments and provides a forward-compatible foundation for stateless verification. The specification does not mandate global adoption of Verkle trees outside the context of witness verification, allowing incremental deployment and coexistence with existing state representations.

---

### Optional witness inclusion

Witness inclusion is explicitly defined as optional. This design avoids imposing immediate requirements on block producers, validators, or client implementations, and allows gradual adoption based on network readiness and client support.

By not mandating stateless operation, the specification preserves compatibility with existing stateful clients while enabling stateless verification as an execution option. This mirrors previous Ethereum upgrades that introduced new capabilities without forcing uniform adoption at activation.

---

### Separation of verification and storage

A central motivation of this design is the separation of block verification from long-term state storage. While current mitigations such as pruning and snapshot synchronization reduce operational burden, they do not fundamentally decouple verification from possession of the full state.

Block-carried witnesses address this structural coupling directly by ensuring that validators can verify execution correctness without persisting state beyond what is required for block processing. This separation enables future protocol work to reduce or reconfigure state storage requirements without altering execution semantics.

---

### Alternative approaches considered

Several alternative approaches were considered:

- **Mandatory stateless validators** were rejected due to their disruptive impact on existing clients and operational assumptions.
- **External state providers** were rejected as they introduce trust assumptions and availability risks incompatible with Ethereum’s security model.
- **On-demand state retrieval** was rejected due to latency, complexity, and denial-of-service considerations.

The chosen design avoids these issues by preserving Ethereum’s self-contained block verification model.

---

### Relationship to prior and future work

This specification complements existing research and development efforts focused on Verkle trees, stateless clients, and execution-layer scalability. It is intentionally limited in scope and does not attempt to subsume or replace other state-related proposals.

Future EIPs may build upon this specification to introduce protocol-level incentives, resource pricing, or tighter integration with Verkle-based state commitments. By defining a minimal, verifiable witness format, this proposal establishes a stable foundation for such extensions.

---

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

This section describes illustrative test cases intended to validate correct implementation of the state witness mechanism defined in this specification. These cases are non-exhaustive and introduce no additional requirements beyond those defined in the Specification.

### Valid Block With Witness Payload

**Input**
- A block containing one or more transactions.
- A witness payload including all state elements accessed during execution.
- Verkle proofs for each state element proving inclusion in the state committed to by the block’s `state_root`.
- A block header containing a `state_witness_commitment` matching the witness payload.

**Expected Outcome**
- The witness payload commitment matches the header.
- All Verkle proofs verify successfully against the `state_root`.
- Executing the block using only the witness payload produces identical execution results, receipts, and state transitions as execution using locally stored state.
- The block is considered valid.

---

### Block With Missing State Element

**Input**
- A block containing a witness payload.
- The witness payload omits a state element that is accessed during execution.

**Expected Outcome**
- Execution cannot be completed using the witness payload.
- Completeness verification fails.
- The block is considered invalid.

---

### Block With Invalid Verkle Proof

**Input**
- A block containing a witness payload.
- At least one Verkle proof fails to verify against the block’s `state_root`.

**Expected Outcome**
- Proof verification fails.
- The block is considered invalid.

---

### Block Without Witness Payload

**Input**
- A block that does not include a witness payload.
- No `state_witness_commitment` present or set to zero.

**Expected Outcome**
- The block is processed using the client’s locally stored state.
- No witness-related validation is performed.
- The block is considered valid provided all existing consensus rules are satisfied.

---

### Mismatched Witness Commitment

**Input**
- A block containing a witness payload.
- The `state_witness_commitment` in the block header does not match the witness payload.

**Expected Outcome**
- Commitment verification fails.
- The block is considered invalid.

---

### Mixed Client Verification Modes

**Input**
- A block containing a valid witness payload.
- One client verifies the block using locally stored state.
- Another client verifies the block using the witness payload.

**Expected Outcome**
- Both clients accept the block.
- Both clients derive identical execution results and state transitions.

---

Future test vectors and executable test suites MAY be added under `../assets/eip-XXXX/` as client implementations mature.

## Reference Implementation

This section provides a minimal, non-normative reference implementation to illustrate how state witnesses and their verification may be integrated into an Ethereum client. It is intended solely to aid understanding and does not replace the Specification. An implementation conforming to the Specification MUST be correct independently of this section.

The following pseudocode outlines a high-level validation and execution flow for blocks that include state witness payloads.

```python
def verify_witness_commitment(block_header, witness_payload):
    """
    Verify that the witness payload matches the commitment declared
    in the block header.
    """
    commitment = hash(witness_payload)
    return commitment == block_header.state_witness_commitment


def verify_witness_proofs(state_root, witness):
    """
    Verify that all state elements in the witness are members of the
    canonical state committed to by the block's state_root.
    """
    for element, proof in witness.elements:
        if not verify_verkle_proof(
            state_root,
            element.key,
            element.value,
            proof
        ):
            return False
    return True


def execute_block_with_witness(block, witness):
    """
    Execute block transactions using only the provided witness data.
    """
    ephemeral_state = build_ephemeral_state(witness)
    receipts, new_state = execute_transactions(
        block.transactions,
        ephemeral_state
    )
    return receipts, new_state


def validate_block(block):
    """
    High-level block validation logic incorporating optional
    witness verification.
    """
    if block.state_witness_commitment != ZERO_HASH:
        witness = block.witness_payload

        assert verify_witness_commitment(block.header, witness)
        assert verify_witness_proofs(block.header.state_root, witness)

        receipts, new_state = execute_block_with_witness(block, witness)
    else:
        receipts, new_state = execute_block_with_local_state(block)

    assert receipts_root(receipts) == block.header.receipts_root


## Security Considerations

This specification introduces an optional mechanism for block-carried state witnesses and therefore affects block validation pathways, execution inputs, and resource usage. While the proposal does not alter execution semantics or consensus rules when witnesses are absent, careful consideration is required to ensure that witness-enabled validation does not introduce new attack surfaces or weaken existing security assumptions.

### Witness Correctness and Completeness

The primary security requirement of this specification is that witness payloads MUST be both correct and complete. An incomplete witness that omits a required state element, or a malformed witness that provides incorrect data, could lead to divergent execution results if not properly detected.

This risk is mitigated by mandatory completeness checks and cryptographic verification of all provided state elements against the block’s `state_root`. Any failure to satisfy these checks MUST cause the block to be considered invalid, ensuring that incorrect witnesses cannot be exploited to introduce invalid state transitions.

### Cryptographic Soundness of Verkle Proofs

The security of stateless verification relies on the soundness of Verkle proofs and the collision resistance of the witness commitment scheme. Invalid or forged proofs MUST be detected during block validation.

Implementations MUST ensure that Verkle proof verification is performed using constant-time, well-audited cryptographic primitives. Any weakness in proof verification could allow an attacker to provide false state data while still satisfying commitment checks, undermining execution correctness.

This specification does not mandate a specific Verkle construction beyond proof verification requirements, allowing future cryptographic improvements without invalidating the design.

### Denial-of-Service Considerations

Witness payloads increase the amount of data processed during block validation and may introduce new denial-of-service vectors if extremely large or computationally expensive witnesses are accepted indiscriminately.

While this specification does not impose protocol-level limits on witness size or complexity, client implementations SHOULD apply reasonable local resource limits to mitigate bandwidth exhaustion, excessive memory usage, or disproportionate verification cost. Such limits MUST NOT affect consensus validity.

Future protocol upgrades may introduce explicit limits or pricing mechanisms if witness inclusion becomes widespread.

### Interaction With Stateful and Stateless Clients

The specification explicitly allows both stateful and stateless validation paths. Divergence between these paths could represent a security risk if implementations fail to enforce identical execution semantics.

Clients MUST ensure that execution using witness-provided state produces results identical to execution using locally stored state. Any discrepancy MUST result in block rejection. Testing across both execution paths is strongly RECOMMENDED to avoid consensus splits arising from inconsistent handling.

### No Introduction of New Trust Assumptions

This specification avoids introducing external trust dependencies, off-chain state providers, or interactive state retrieval mechanisms. All data required for execution verification is either present in the block or cryptographically committed to by the block header.

By preserving Ethereum’s self-contained verification model, the proposal avoids availability and trust risks associated with external data sources.

### Forward Compatibility and Incremental Deployment

Witness inclusion is optional and does not require immediate adoption by block producers or validators. This reduces systemic risk during early deployment and allows clients to mature implementations before relying on witness-based verification.

The absence of mandatory stateless operation ensures that any unforeseen security issues can be mitigated by reverting to stateful validation without protocol-level intervention.

### Summary

This specification preserves Ethereum’s existing security model while introducing an optional mechanism for stateless verification. The primary risks relate to witness correctness, proof verification, and resource usage, all of which are mitigated through mandatory validation rules, cryptographic verification, and conservative client behavior. No new trust assumptions are introduced, and existing execution semantics remain unchanged.

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
