---
eip: 11796
title: WYRIWE — What You Read Is What You Execute
description: An input-provenance commitment scheme and attestation profile for verifiable AI agent inference
author: Tiago Merlini (@TMerlini), Vincent Wu (@TruthAnchor-AI), Damon Zwicker (@damonzwicker), Jimmy Shi (@JimmyShi22), babyblueviper1 (@babyblueviper1)
discussions-to: https://ethereum-magicians.org/t/wyriwe-what-you-read-is-what-you-execute-input-provenance-for-verifiable-ai-inference/28655
status: Draft
type: Standards Track
category: ERC
created: 2026-05-28
requires: 712, 8004
---

## Abstract

This ERC defines a triple-hash commitment scheme and EIP-712 attestation profile for proving that the input a model received is the input the user intended. It introduces three linked fields — `raw_input_hash`, `sanitization_pipeline_hash`, and `input_hash` — that together form a verifiable chain of custody for AI inference inputs. A verifier can confirm input integrity using only the committed hashes and the public sanitization specification, without trusting the agent, gateway, or execution environment. This standard occupies the input-provenance layer of the AI inference trust stack, complementing ERC-8004 (agent identity), ERC-8126 (agent verification), ERC-8263 (on-chain proof commitment and anchor layer), and OCP / ERC-8281 (observation commitment protocol).

---

## Motivation

On-chain AI agent systems built on standards such as ERC-8004, ERC-8126, ERC-8263, and ERC-8274 can attest to which agent is registered, which model ran, and what output was produced — but no standard defines how to commit to the *input* before inference. This creates a trust gap: an agent may sanitize, rewrite, or substitute the user's input between request submission and model execution, leaving no on-chain evidence of the transformation.

ERC-8126 (AI Agent Verification, Final) addresses the question "Is this agent trustworthy?" via risk scores and verification registries. It deliberately leaves the execution receipt layer out of scope — what the agent actually processed in a specific invocation. WYRIWE closes that gap.

Without a committed input record:
- A settlement contract cannot verify that the delivered output corresponds to the funded input.
- A proof verifier (e.g. an `IProofVerifier` implementation per ERC-8274) cannot confirm the `inputHash` it receives matches what was originally requested.
- A dispute resolution mechanism (e.g. ERC-8275 `CommitRevealSettler`) has no ground truth for what the model was actually asked to do.

WYRIWE (What You Read Is What You Execute) closes this gap by defining a minimal, hash-based commitment that any compliant gateway MUST produce at execution time and that any verifier can check independently.

---

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

### 1. Triple-Hash Construction

A WYRIWE-compliant execution MUST produce the following three values:

```
raw_input_hash             = keccak256(raw_user_input)
sanitization_pipeline_hash = keccak256(sanitization_spec_cid || raw_input_hash)
input_hash                 = keccak256(sanitized_input)
```

Where:

- `raw_user_input` is the exact bytes of the user's input as received, before any transformation.
- `sanitization_spec_cid` is the full IPFS URI string including the `ipfs://` scheme prefix (e.g., `ipfs://QmccvoM6aRVg...`), serialized as UTF-8 bytes. The `ipfs://` prefix is part of the preimage and MUST be included.
- `sanitized_input` is the exact bytes fed to the model after applying the sanitization pipeline.
- `||` denotes byte concatenation.

**Verification invariant:** Given `raw_input_hash`, `sanitization_pipeline_hash`, and the public sanitization specification at `sanitization_spec_cid`, any verifier MUST be able to confirm that `input_hash` is the correct output of that pipeline applied to that raw input. No party needs to be trusted to assert this.

### 2. IDENTITY_SENTINEL — No-Sanitization Case

When no sanitization is applied (identity transform), the following MUST hold:

```
sanitization_pipeline_hash = keccak256(IDENTITY_SENTINEL_CID || raw_input_hash)
input_hash                 = raw_input_hash
```

`IDENTITY_SENTINEL_CID` is a stable IPFS reference to the identity-transform specification:

```
ipfs://QmccvoM6aRVgZ2dtFWvT6Wm3DmTvoAUHHotK7uQufnStVR
```

The content at this CID is normative and frozen — it defines the identity transform (no modification to the input). Implementations MUST pin this CID to ensure long-term verifiability. The content is reproduced in Appendix C for self-containment in the event of IPFS unavailability.

The `input_hash == raw_input_hash` equality in the no-sanitization case is a provable on-chain claim, not an assumption. Implementations MUST NOT omit `sanitization_pipeline_hash` even when no sanitization is applied.

### 3. WyriweAttestation Struct

A WYRIWE attestation is an EIP-712 typed structured data record with the following fields:

```solidity
struct WyriweAttestation {
    bytes32 agentId;                    // ERC-8004 agent identity anchor
    address registry;                   // ERC-8004 registry address
    bytes32 modelHash;                  // Hash of model weights or manifest
    bytes32 rawInputHash;               // keccak256(raw_user_input)
    bytes32 sanitizationPipelineHash;   // keccak256(sanitization_spec_cid || raw_input_hash)
    bytes32 inputHash;                  // keccak256(sanitized_input)
    bytes32 outputHash;                 // keccak256(model_output)
    uint256 timestamp;                  // Unix timestamp of execution
}
```

All fields are REQUIRED. A conforming attestation MUST populate every field. `agentId` and `registry` MAY be zero-valued if the execution environment does not implement ERC-8004, but MUST NOT be omitted from the struct.

The canonical EIP-712 type string for `WyriweAttestation` is:

```
WyriweAttestation(bytes32 agentId,address registry,bytes32 modelHash,bytes32 rawInputHash,bytes32 sanitizationPipelineHash,bytes32 inputHash,bytes32 outputHash,uint256 timestamp)
```

Field ordering is as declared in the struct above and is normative. EIP-712 encoding is order-sensitive — a type string with fields in any other order produces a different `typeHash` and MUST NOT be used.

**ERC-8274 claim classification:** A `WyriweAttestation` is an `attestation`-class claim. In ERC-8274 terminology, the corresponding `IProofVerifier` SHOULD return `proofSystem() = "attestation/wyriwe"`. When wrapped in an ERC-8274 outer claim container, `claimType` SHOULD be set to `Attestation`. The EIP-712 type string acts as the on-chain schema discriminator; `claimType` serves off-chain consumers (indexers, explorers, dispute interfaces) that read the raw signed struct without calling the verifier contract.

Note: `modelHash` commits to the model weights or manifest — what model ran. This is distinct from a TEE `codeMeasurement`, which commits to the execution environment. WYRIWE operates at the input-provenance layer, not the execution environment layer. For execution environment attestations, see ERC-8274 `tee/*` proof systems.

### 4. EIP-712 Domain

The EIP-712 domain separator for WYRIWE attestations is:

```solidity
EIP712Domain({
    name:    "ERC8004AttestationGateway",
    version: "1",
    chainId: block.chainid
})
```

`chainId` MUST use the chain ID of the network on which the attestation is produced (`block.chainid` in Solidity). A hardcoded value is NOT permitted — doing so prevents the domain separator from distinguishing attestations produced on different chains and breaks replay protection in multi-chain deployments.

The `signature` is produced via `eth_signTypedData_v4` over the EIP-712 digest of the `WyriweAttestation` struct, yielding a 65-byte `(r, s, v)` ECDSA signature recovered against the attestor address. Note: `eth_signTypedData_v4` (EIP-712) is distinct from `eth_sign` — using `eth_sign` applies the `\x19Ethereum Signed Message` prefix, which would break on-chain `ecrecover` verification of the 712 digest and MUST NOT be used.

### 5. Verification Procedure

A verifier MUST execute the following steps to accept a WYRIWE attestation as valid:

1. Recompute the EIP-712 digest from the attestation struct fields and verify `signature` against the known attestor address.
2. Verify `rawInputHash == keccak256(raw_user_input)` if the raw input is available.
3. Fetch the sanitization specification at `sanitization_spec_cid` and apply it to `raw_user_input`; verify the result hashes to `inputHash`.
4. If `sanitization_spec_cid == IDENTITY_SENTINEL_CID`, verify `inputHash == rawInputHash`.
5. Accept the attestation only if all applicable steps pass.

Steps 2–4 are REQUIRED when the corresponding inputs are available. Step 1 is always REQUIRED.

### 6. Gateway Query Interface

A conforming gateway MUST expose the following HTTP endpoint:

```
GET /agent/verify/:inputHash
```

Where `:inputHash` is the lowercase hex-encoded (no `0x` prefix) `inputHash` value. The response MUST be a JSON object containing the `WyriweAttestation` fields and the `signature`. The response MUST use HTTP 200 on success and HTTP 404 when no attestation exists for the given `inputHash`.

---

### 7. ClaimType Discriminator

ERC-8274-compliant claim artifacts MUST carry a `claimType` field identifying the accountability model of the claim. This field is distinct from `proofSystem` and MUST NOT be conflated with it:

- `proofSystem` belongs to the `IProofVerifier` contract path and has contract context. It identifies the cryptographic mechanism that authenticated the artifact.
- `claimType` belongs inside the signed artifact and travels without that context. It identifies the accountability and dispute model.

An off-chain consumer holding only the raw signed struct MUST be able to determine the accountability model without a registry lookup.

```solidity
enum ClaimType {
    ReExecution,  // deterministic computation — objectively disputable
    Attestation,  // authorized signer certifies a result
    Judgment      // subjective assessment — accountable through track record / policy
}
```

The fields answer different questions:

- `proofSystem` answers: what cryptographic mechanism authenticated the artifact?
- `claimType` answers: what kind of accountability model backs the claim?

A `zk/sp1` proof system may back a `ReExecution` claim; `sig/eip712` is used for both `Attestation` and `Judgment` claims. The proof system alone does not determine the accountability model.

| `claimType` | `proofSystem` examples | Accountability | Dispute surface |
|---|---|---|---|
| `ReExecution` | `zk/sp1`, `zk/ezkl`, `op/ora` | Mathematical / economic | Objectively disputable |
| `Attestation` | `sig/eip712`, `attestation/wyriwe`, `attestation/multisig` | Signer authorization / stake / reputation | Signer registry or policy |
| `Judgment` | `sig/eip712`, `attestation/judgment` | Track record / reputation / policy-defined stake | Pre-outcome commitment + later outcome evidence |

A `WyriweAttestation` is an `Attestation`-class claim (`claimType = Attestation`). A `JudgmentExecutionAttestation` is a `Judgment`-class claim (`claimType = Judgment`). See Section 3 and the Composition section respectively.

---

## Rationale

### Why three hashes?

Two hashes (raw and final) are insufficient: they prove the input was transformed but do not commit to *which* transformation was applied. The `sanitization_pipeline_hash` commits to both the specification and the raw input, making the transform auditable and reproducible by any third party.

### Why IPFS CIDs for the sanitization spec?

Content-addressed references ensure the specification retrieved at verification time is identical to the one applied at execution time. A mutable URL reference would allow the spec to be swapped after the fact, defeating the commitment.

### Why EIP-712?

EIP-712 typed structured data signatures are natively verifiable on-chain by Ethereum contracts, wallet UIs, and existing tooling. The structured hash is deterministic and auditable without any off-chain oracle.

### Why include `agentId` and `registry`?

Linking attestations to an ERC-8004 agent identity makes the attestation attributable — not just to a signing key, but to an on-chain registered agent. This is load-bearing for settlement systems (e.g. ERC-8274, ERC-8183) that need to associate an output with a specific funded agent.

### Why `IDENTITY_SENTINEL_CID` instead of a null value?

Using a null or zero value for `sanitization_pipeline_hash` in the no-sanitization case would make it ambiguous whether the field was intentionally omitted or a transform was applied but not committed. The sentinel makes the no-sanitization case explicit, auditable, and verifiable on equal footing with sanitized cases.

### Relationship to ERC-8126

ERC-8126 (AI Agent Verification, Final) defines risk scores and verification registries that answer "Is this agent trustworthy?" WYRIWE is complementary, not overlapping: it answers "What did this agent actually process in this invocation?" The two standards compose naturally — ERC-8126 establishes agent-level trust, WYRIWE establishes execution-level provenance. A settlement contract may require both: the agent must be verified (ERC-8126) AND the input commitment must match the funded request (WYRIWE).

---

## Backwards Compatibility

This ERC introduces a new standard with no dependencies on or conflicts with existing ERCs beyond the voluntary integration points described in the Specification. It does not modify any existing interface.

---

## Test Cases

### Case 1: Identity transform (no sanitization)

```
raw_user_input             = "transfer 1 ETH to 0xABCD..."
raw_input_hash             = keccak256("transfer 1 ETH to 0xABCD...")
sanitization_spec_cid      = "ipfs://QmccvoM6aRVgZ2dtFWvT6Wm3DmTvoAUHHotK7uQufnStVR"
sanitization_pipeline_hash = keccak256(sanitization_spec_cid_bytes || raw_input_hash)
sanitized_input            = raw_user_input
input_hash                 = raw_input_hash
```

Expected: `input_hash == raw_input_hash` — verifier confirms identity case.

### Case 2: Sanitization applied

```
raw_user_input             = "transfer 1 ETH to 0xABCD... <script>alert(1)</script>"
raw_input_hash             = keccak256(raw_user_input)
sanitization_spec_cid      = "ipfs://Qm<strip-html-spec-cid>"
sanitized_input            = "transfer 1 ETH to 0xABCD..."
sanitization_pipeline_hash = keccak256(sanitization_spec_cid_bytes || raw_input_hash)
input_hash                 = keccak256(sanitized_input)
```

Expected: `input_hash != raw_input_hash` — verifier fetches spec, applies strip-HTML transform to raw input, confirms result matches `input_hash`.

### Case 3: Attestation forgery (should fail)

```
input_hash (claimed) = keccak256("transfer 100 ETH to attacker")
```

Verifier fetches attestation for this `input_hash`, recomputes `sanitization_pipeline_hash` from the claimed sanitized input and the committed spec, finds mismatch with the attested `sanitization_pipeline_hash`. Attestation rejected.

---

## Reference Implementation

A live WYRIWE-compliant gateway is deployed at:

```
GET https://gateway.ensub.org/agent/verify/:inputHash
```

Example query:
```
https://gateway.ensub.org/agent/verify/758d61f26a44448384e5c4468a0dcb7a2abe456067b0f7b505bc28b9411fe931
```

Source code: https://github.com/Echo-Merlini/ccip-router

**L2 settlement reference node:** `https://gateway.gen-plasma.com` — live ccip-router node tracking spec revisions. Runs `CommitRevealSettlerV2` (bond/slash, Router+Hybrid gate) and `GenericCommitRevealSettler` (bytes-generic, Appendix A) against Sepolia. Each spec revision is reviewed against the deployed node before commit; drift found in review is fixed before the revision is pushed. Conformance is tracked at the npm package version — `ccip-router` on npmjs.com mirrors the deployed spec layer.

**L4 judgment reference implementation:** `https://api.babyblueviper.com/ledger` — live production judgment validator tracking spec revisions. Each revision reviewed against deployed endpoints; `/commitment` and `/outcome` sub-paths conform to Appendix A. See Acknowledgements.

**External implementations:**
- WyriweVerifier (Jimmy Shi) — `IProofVerifier` wrapper for ERC-8274: https://ethereum-magicians.org/t/erc-8274-ai-inference-proof-verification/28083
- WyriweProofVerifier (mainnet): `0xd8a09d830b27697e1b24e8c9800e562d20318a09`
- WyriweAttestationVerifier (mainnet): referenced in ccip-router npm package

---

## Security Considerations

### Attestor key compromise

The `signature` is only as trustworthy as the attestor's private key. Implementations that use WYRIWE attestations for settlement or dispute resolution SHOULD maintain an on-chain registry of authorised attestor addresses and support key rotation. A compromised attestor key allows forged attestations but does not break the hash commitments — a forged attestation for a hash with no matching input still cannot produce a valid preimage.

### Hash collision resistance

WYRIWE relies on keccak256 collision resistance. No practical collision attacks against keccak256 are known. If keccak256 is broken, all three hashes are affected equally; the triple-hash construction does not introduce additional collision surface.

### Adversarial sanitization specification

WYRIWE proves faithful application of a declared transform, not that the transform is benign. A gateway that publishes a sanitization specification designed to rewrite inputs maliciously (e.g., replacing a transfer amount or destination address) can commit to the application of that spec faithfully while still exploiting the caller. The scheme makes the transform fully auditable and attributable — any observer can fetch the spec at the committed CID and verify it was applied correctly — but semantic safety of the specification is a consumer responsibility, not a WYRIWE guarantee. Implementations that accept arbitrary sanitization spec CIDs SHOULD enforce an allow-list of approved CIDs. End users SHOULD verify the sanitization spec at the committed CID before trusting a result.

### Sanitization spec CID stability

`sanitization_pipeline_hash` commits to a CID, not the spec content. If the IPFS content at the referenced CID becomes unavailable, step 3 of the verification procedure cannot be completed. Implementations SHOULD pin all referenced sanitization spec CIDs to ensure long-term verifiability.

### Replay and cross-domain attacks

The `timestamp` field in `WyriweAttestation` is informational and does not prevent replay. Settlement contracts that consume WYRIWE attestations MUST enforce their own replay protection (e.g. by recording consumed `inputHash` values on-chain). The EIP-712 `chainId` in the domain separator prevents cross-chain signature replay.

### Input availability

WYRIWE commits to the *hash* of the input, not the input itself. The raw input and sanitized input are not published by this standard. Parties who need to reproduce verification MUST retain the original inputs off-chain. WYRIWE does not define an input storage or retrieval mechanism.

---

## Composition

This section documents known application patterns that reuse WYRIWE's triple-hash shape at adjacent stack layers. The shape — `commitment = keccak256(abi.encode(inputCommitment, scopeBinding, attestingParty))` — is layer-agnostic; only the semantic content of each slot changes.

### L2 Snapshot commitment (ERC-8275 / ccip-router)

The ccip-router's contribution settlement layer reuses the triple-hash directly:

```
snapshotRoot    = keccak256(abi.encode(rows))
commitmentHash  = keccak256(abi.encode(snapshotRoot, periodId, nodeAddress))
```

Slot mapping against WYRIWE's L3 scheme:

| WYRIWE (L3 input provenance) | ERC-8275 L2 snapshot settlement |
|---|---|
| `rawInputHash` | `snapshotRoot` — commitment to contribution rows |
| `sanitizationPipelineHash` | `periodId` — temporal scope of the settlement window |
| `inputHash` (submitted on-chain) | `commitmentHash` (submitted to `CommitRevealSettler`) |
| `agentId` | `nodeAddress` — the attesting node |

The `snapshotRoot` is derived from rows of `(address contributor, uint256 score, uint256 timestamp)` sorted by contributor address ascending, ABI-encoded. The `commitmentHash` is what a node submits during the commit phase; the full snapshot rows are revealed and verified against it during the reveal phase. The commit-reveal scheme closes the "committed → executed" gap by construction: a node can only reveal data whose hash matches its commit.

Reference implementation: `POST /contributions/snapshot/freeze` in [ccip-router v0.6.0](https://github.com/Echo-Merlini/ccip-router).

### L4 Judgment validator binding (@babyblueviper1)

The same chain-of-custody question exists one layer up for judgment validators: `inputHash` commits to the exact proposed action reviewed, but nothing yet binds "action reviewed" to "action executed after verdict." The triple-hash shape maps slot-for-slot:

| WYRIWE (L3, input provenance) | Judgment validator (L4, one layer up) |
|---|---|
| `rawInputHash` — what the user submitted | `rawProposalHash` — what the agent proposed |
| `sanitizationPipelineHash` — public spec transforming raw → permitted | `verdictHash` — the judgment, including any conditions ("approve IF size halved") = the public spec transforming proposed → permitted |
| `inputHash` — what the model actually received | `executedActionHash` — what was actually executed |
| `IDENTITY_SENTINEL` — no-sanitization is a provable claim | unconditional approve — executed-as-reviewed is a provable claim, not an assumption |

**Triple-hash construction:**

```
rawProposalHash    = keccak256(canonical_proposed_action)
verdictHash        = keccak256(verdict_artifact_ref || rawProposalHash)
executedActionHash = keccak256(canonical_executed_action_record)
```

`verdict_artifact_ref` is the canonical identifier of the specific signed verdict artifact. The format is storage-backend dependent: an IPFS CID for content-addressed storage, a Nostr event ID for relay-anchored verdicts (`keccak256(verdict_event_id || rawProposalHash)` in the reference implementation). The anti-equivocation property is identical across formats: a validator cannot swap between multiple signed verdicts post-reveal because the specific artifact identifier is bound in the commitment.

`verdictHash` binds to `rawProposalHash` — mirroring the sanitization-pipeline-hash construction — making verdict-shopping impossible: a verdict cannot be replayed against a different proposal than the one it judged.

**EIP-712 struct:**

```solidity
struct JudgmentExecutionAttestation {
    bytes32 agentId;             // ERC-8004 identity of the EXECUTING agent
    address registry;            // ERC-8004 registry address
    bytes32 validatorId;         // ERC-8004 identity of the judgment validator. MUST NOT be omitted.
                                 // Zero value signals an off-registry validator whose identity
                                 // MUST be resolvable from the verdict artifact (e.g. schnorr pubkey in a signed Nostr event).
    bytes32 rawProposalHash;     // keccak256(canonical proposed-action artifact, pre-review)
    bytes32 verdictHash;         // keccak256(verdict_artifact_ref || rawProposalHash)
                                 // verdict_artifact_ref: IPFS CID or Nostr event ID of the signed verdict
    bytes32 executedActionHash;  // keccak256(canonical executed-action record), revealed at settlement
    uint256 verdictTimestamp;    // verdict issuance — the commit, strictly pre-execution
    uint256 executedTimestamp;   // execution — the reveal
    string  recordPointer;       // URI to the ledger entry. Standard sub-paths:
                                 //   {recordPointer}/commitment — pre-settlement evidence
                                 //     (signed verdict, relay anchor, judgment execution commitment)
                                 //   {recordPointer}/outcome    — post-settlement evidence
                                 //     (settlement account, signed outcome digests)
                                 // Empty string if not yet anchored.
}
```

The `recordPointer` URI resolves to a record conforming to the `RecordPointer` schema defined in Appendix B. `commitmentProof` and `outcomeEvidence` MUST remain separately resolvable (see design note 4 and Appendix B).

**Type string:**

```
JudgmentExecutionAttestation(bytes32 agentId,address registry,bytes32 validatorId,bytes32 rawProposalHash,bytes32 verdictHash,bytes32 executedActionHash,uint256 verdictTimestamp,uint256 executedTimestamp,string recordPointer)
```

Domain separator: `ERC8004AttestationGateway` / version `"1"` / `block.chainid` — same as `WyriweAttestation` by design. Struct typehash prevents cross-type confusion; attestor address serves as deployment-level identity. A dedicated judgment gateway SHOULD use the same domain name — splitting it would fork verifier code paths without adding security.

`proofSystem() = "attestation/judgment"` — returned by the `IProofVerifier` implementation; lives in the verifier path (contract context). `claimType = Judgment` — carried inside the signed artifact for off-chain consumers (indexers, dispute interfaces) that read the struct without calling the verifier contract. The two fields serve distinct routing purposes and MUST NOT be conflated.

**Design notes:**

1. **Signature roles.** Only one signature is required — the executing agent's attestor signs the EIP-712 digest at reveal time. The validator's own signature lives inside the verdict artifact that `verdictHash` pins, so validator authenticity is carried without a second signature field. This keeps the ERC-8274 layering clean: `IProofVerifier` authenticates the attestation; the verdict artifact authenticates the judgment.

2. **Commit-reveal invariant.** `verdictTimestamp < executedTimestamp` MUST hold. `executedActionHash` SHOULD be committed at verdict time — when the post-verdict intent hash is knowable — not post-execution. `submitReveal` is then called post-execution with settlement evidence linked separately rather than hashed into the record. The verdict artifact is published at commit time (relay-anchored in the reference implementation). The reviewed→executed gap closes by the same argument as WYRIWE's reviewed→input gap: the executor can only reveal an action whose hash matches what was committed and judged. This two-step pattern maps directly to `CommitRevealSettler.submitCommit` / `submitReveal`.

3. **Canonicalization as verification step 3.** The executed action record never byte-equals the proposal (a fill has a price; a proposal has an intent), so the verdict artifact doubles as the conformance spec the verifier applies — exactly the role the sanitization spec CID plays in WYRIWE verification step 3. The unconditional-approve case degenerates to canonical field equality, which is the sentinel.

4. **`recordPointer`, evidence separability, and `verify()` semantics.** The `recordPointer` target MUST keep commitment evidence and outcome evidence separately addressable via standard sub-paths: `{recordPointer}/commitment` returns pre-settlement evidence (signed verdict, relay anchor, judgment execution commitment); `{recordPointer}/outcome` returns post-settlement evidence (settlement account, signed outcome digests). A verifier MUST be able to check commitment without outcome (pre-settlement) and outcome without re-deriving commitment (post-settlement). A single combined document breaks this invariant: a dispute client cannot prove it did not inspect the outcome before evaluating the commitment.

   For `ClaimType.Judgment`, `verify() = true` means the verdict is authentically the validator's and correctly bound to the task inputs. It does NOT mean the judgment is sound, that the action should proceed, or that the verdict has been independently endorsed. A settlement contract that gates directly on the bool has confirmed authenticity — it has not endorsed the judgment. Verdict weight lives in the accountability record, not in the bool.

   The three-layer accountability boundary:

   ```
   IProofVerifier  — authenticates the verdict (EIP-712 binding is valid)
   IAgentVerifier  — checks validator authorization for the task
   recordPointer   — carries accountability: track record + pre-outcome commitment
   ```

   Reference implementation: `api.babyblueviper.com/ledger/{n}/commitment` and `api.babyblueviper.com/ledger/{n}/outcome`.

**Honesty conventions from the reference implementation** (generalise to any producer):
- Entries predating the wiring carry a partial block with `executed_action_hash: null` and an explicit `"not backfilled by design"` status. A commitment you did not make at the time is not one you get to manufacture later.
- Where a production system records a single timestamp per governance cycle, `executedTimestamp` is `null` with an ordering note rather than a fabricated reveal time. The strict `verdictTimestamp < executedTimestamp` invariant belongs to the on-chain attestation; an off-chain production mapping should record what it actually measured.

Reference implementation: [api.babyblueviper.com/ledger](https://api.babyblueviper.com/ledger) — live production ledger. Entry `/ledger/3` shows a pre-wiring partial block; new entries carry the full `judgment_execution` block. Running against real capital.

5. **`string recordPointer` is the correct type for EIP-712.** The `RecordPointer` struct (Appendix B) is the resolved payload schema — it is NOT inlined into the signed type. The attestation is signed once and frozen at verdict time; the record it points to is alive and grows over time (`outcomeEvidence` does not exist when the verdict attestation is signed). Inlining `RecordPointer` into the EIP-712 struct would require signing a permanently incomplete field. The on-chain anchoring of the verdict artifact (Nostr event ID or IPFS CID in `verdictHash`) already secures commitment integrity independently of the pointer. The 9-field type string is therefore stable and MUST NOT be changed pre-review.

---

## Appendix A — Cross-system settlement: GenericCommitRevealSettler integration

This appendix documents the integration pattern for judgment attestations with `GenericCommitRevealSettler` as a reference for any L4 producer. First demonstrated in the cross-system settlement of ledger entry 19 at [api.babyblueviper.com/ledger/19](https://api.babyblueviper.com/ledger/19) — commit block 11030402, reveal block 11030403.

**Contract:** `GenericCommitRevealSettler` on Sepolia: `0xFe7Ab6d95f7567a311B98D029373d0fc1511aCCe`

Bytes-opaque commit/reveal primitive. No bond, no NodeType gate. Verifies preimage binding only — usable for contribution snapshots (ERC-8275), judgment attestations (WYRIWE L4), OCP observations, or any future schema.

### Hash construction

```solidity
commitmentHash = keccak256(abi.encode(record, periodId, committer))
```

Binding to `periodId + committer` prevents cross-period and cross-sender replay without the contract knowing the record schema.

### Encoding convention for judgment attestations

```solidity
bytes memory record = abi.encode(
    rawProposalHash,     // bytes32 — what was proposed
    verdictHash,         // bytes32 — the judgment, binding to rawProposalHash
    executedActionHash,  // bytes32 — what was actually executed
    verdictTimestamp     // uint256 — verdict issuance, strictly pre-execution
);
```

Minimal set that closes the reviewed→executed gap. Attestation metadata (`agentId`, `registry`, `validatorId`, `recordPointer`) is carried in the full struct at settlement time and does not need to be committed.

### Recommended preflight

Before calling `submitCommit`, verify the hash binding off-chain at zero gas cost:

```solidity
// eth_call — no gas spent
bytes32 expected = computeCommitmentHash(record, periodId, committerAddress);
// verify expected == locally computed hash before submitting
```

Treat this as a required preflight, not an optional check. If the hashes do not match byte-exact, there is an encoding error — fix it before spending gas.

### periodId convention

Use the ledger entry number as `periodId`. Creates a 1:1 binding between ledger entries and settlement periods; makes `getCommit(periodId, committer)` directly queryable from the entry index.

### Workflow

```
1. record           = abi.encode(rawProposalHash, verdictHash, executedActionHash, verdictTimestamp)
2. commitmentHash   = keccak256(abi.encode(record, periodId, committerAddress))
3. Preflight        : eth_call computeCommitmentHash(record, periodId, committerAddress) → verify match
4. submitCommit(periodId, commitmentHash)
5. Execute the governed action
6. submitReveal(periodId, record)
```

`submitReveal` reverts on mismatch. Reveal window: 48 hours from commit. Challenge period: 7 days from reveal.

### Invariant check

```solidity
CommitRecord memory c = getCommit(periodId, committer);
// c.committedAt > 0                          committed
// c.revealedAt  > c.committedAt              temporal ordering holds
// c.recordHash  == keccak256(record)         preimage binding holds
```

The `Revealed` event emits the full `bytes record` — any observer can verify the preimage independently from the event log.

### recordPointer sub-paths

`{recordPointer}/commitment` MUST return pre-settlement evidence: signed verdict, relay anchor, `commitmentHash`, block number of `submitCommit`. `{recordPointer}/outcome` MUST return post-settlement evidence: `recordHash` from `getCommit`, reveal transaction hash, settlement account. These are separately resolvable — a dispute verifier MUST be able to confirm commitment integrity without accessing outcome evidence.

---

## Appendix B — RecordPointer Schema

The `RecordPointer` struct is the resolved payload schema for the `string recordPointer` field in `JudgmentExecutionAttestation`. It is NOT part of the EIP-712 signed type — the attestation is signed once and frozen at verdict time; the record it points to grows over time as `outcomeEvidence` accumulates. See design note 5.

### Struct definition

```solidity
struct RecordPointer {
    bytes32 validatorId;      // ERC-8004 identity of the judgment validator.
                              // Zero value: off-registry validator — identity MUST resolve from the
                              // verdict artifact itself (e.g. schnorr pubkey of a signed Nostr event).
                              // Consumers MUST reject if resolution fails.
    bytes32 registryType;     // keccak256 of registry type string — see table below.
    bytes   registryRef;      // registry-specific locator (contract address, Nostr pubkey, URL, etc.)
    bytes   commitmentProof;  // pre-settlement evidence: signed verdict, relay anchor, commit hash.
                              // SHOULD open with a self-describing mechanism identifier byte prefix
                              // so consumers can select the correct trust model without external context.
    bytes   outcomeEvidence;  // post-settlement evidence: settlement account, outcome digests.
                              // MAY be empty before settlement closes.
                              // SHOULD open with a self-describing mechanism identifier byte prefix.
}
```

### registryType values

| Identifier string | keccak256 | Description |
|---|---|---|
| `"evm/registry"` | — | On-chain ERC-8004 registry. `registryRef` = ABI-encoded `(address registry, bytes32 agentId)`. |
| `"nostr/profile"` | — | Nostr relay profile. `registryRef` = UTF-8 encoded npub or hex pubkey. |
| `"offchain/ledger"` | — | Off-chain ledger URL. `registryRef` = UTF-8 encoded base URL. |

Producers SHOULD use one of the above identifiers. Custom types are permitted; consumers encountering an unknown `registryType` SHOULD surface it as unrecognised rather than failing silently.

### Mechanism identifier convention

`commitmentProof` and `outcomeEvidence` are opaque `bytes`. Each SHOULD open with a UTF-8 encoded self-describing mechanism identifier followed by a null byte (`0x00`) separator, so consumers can select the correct trust model without external context:

| Identifier | Meaning |
|---|---|
| `"nostr-relay-publication"` | Nostr event anchor — Nostr event ID, relay set, `relay_anchor` retention status |
| `"onchain-commitment"` | On-chain commit tx hash and block number (e.g. `GenericCommitRevealSettler`) |
| `"onchain-settlement+digests"` | On-chain reveal tx hash + signed outcome digests |
| `"offchain-ledger+digests"` | Off-chain settlement account URL + signed outcome digests |

### validatorId = 0x0 — off-registry validators

When `validatorId` is zero, the validator is not registered in an ERC-8004 registry. The validator identity MUST resolve from the verdict artifact itself — for example, the schnorr pubkey embedded in a signed Nostr event pinned by `verdictHash`. Consumers MUST reject the record if resolution fails. Zero `validatorId` is a valid state, not an error; it describes validators whose identity is carried in the artifact rather than an on-chain registry.

### Relay retention

For Nostr-anchored verdicts, relay copies are not guaranteed to persist. NIP-33 parameterized-replaceable events can silently overwrite relay copies — naive event-fetching by event ID may fail even when the commitment binding survives intact. Producers SHOULD surface a `relay_anchor` retention status field within `commitmentProof` that declares actual relay availability rather than assuming it. Consumers MUST treat an unavailable relay copy as a retrieval failure, not as evidence of non-commitment.

The `relay_anchor` status SHOULD use one of the following values:

| Status | Meaning |
|---|---|
| `"anchored"` | Original event live on all declared relays. |
| `"replaced_by_newer_same_artifact"` | Original event overwritten by NIP-33 replacement; surviving event commits to identical artifact hash. Recovery path: consumer verifies the surviving event satisfies the same commitment check. |
| `"unverified"` | Relay availability could not be confirmed at record publication time. |

The `replaced_by_newer_same_artifact` state distinguishes a recoverable NIP-33 overwrite (same content, different event ID) from an unrecoverable loss. When a producer identifies a surviving equivalent event, consumers can confirm **publication timing** from the survivor — but the survivor's timestamp is strictly later than the original's. A NIP-33 replacement eliminates the relay-attested timestamp of the original event; the survivor proves the verdict existed by the survivor's timestamp, not by the original publication time. `verdictHash` binding is separate: it ties to the specific original event ID committed on-chain and is not affected by relay churn; the original event ID remains in the on-chain commitment record regardless of relay availability. These are two distinct proof layers — relay anchor confirms publication occurred; on-chain verdictHash confirms what was published. This recovery path is anchor-type-specific — the mechanism identifier tag (`"nostr-relay-publication"`) scopes what "event id" means within that trust model; other anchor types require their own recovery semantics.

**Timestamp hierarchy for pre-outcome commitment evaluation.** Consumers evaluating whether a verdict was committed before execution MUST apply the following precedence:

1. **Original relay copy available** — use the original relay-attested timestamp. Strongest proof; no gap.
2. **On-chain `committedAt` (settled entry)** — use the `committedAt` block timestamp from the settlement contract. Decay-resistant; independent of relay state. Valid even when relay copy is unavailable.
3. **Survivor timestamp (`replaced_by_newer_same_artifact`)** — fallback only. The survivor's timestamp is strictly later than the original publication time. Production-observed gap: 15–45 minutes (illustrative; normative content is the hierarchy, not the specific numbers). Consumers MUST NOT treat survivor timestamp as equivalent to original relay-attested timestamp.

Claiming tier-1 timing strength from a tier-3 source is incorrect. For settled entries, tier 2 is always available and SHOULD be preferred over the survivor timestamp regardless of relay state.

Production finding: in the reference implementation, 9 of 18 relay copies were silently replaced via NIP-33 overwrites before the `relay_anchor` status field was introduced. The commitment bindings survived; naive fetching would have failed. Observed gap between original publication and NIP-33 replacement: 15–45 minutes.

### Production mapping — reference implementation

Ledger entry at `https://api.babyblueviper.com/ledger/19`:

| `RecordPointer` field | Value |
|---|---|
| `validatorId` | `0x0` (off-registry — schnorr pubkey resolves from the signed Nostr event) |
| `registryType` | `keccak256("offchain/ledger")` |
| `registryRef` | `https://api.babyblueviper.com/ledger/19` |
| `commitmentProof` | resolves at `/ledger/19/commitment` — Nostr event ID, relay set, `relay_anchor` retention status |
| `outcomeEvidence` | resolves at `/ledger/19/outcome` — settlement account, signed outcome digests (pending until settlement) |

---

## Appendix C — Identity-Transform Specification (IDENTITY_SENTINEL_CID)

This appendix reproduces the normative content of the identity-transform specification pinned at `ipfs://QmccvoM6aRVgZ2dtFWvT6Wm3DmTvoAUHHotK7uQufnStVR`. It is included here so the standard is self-contained in the event of IPFS unavailability. The content at the CID MUST match this text exactly. Any discrepancy between the pinned CID and this appendix is an error in the pinned content, not in this document.

```json
{
  "name": "identity-transform",
  "version": "1",
  "description": "The identity sanitization pipeline. No modification is applied to the input. The sanitized output is identical to the raw input byte-for-byte.",
  "transform": "none",
  "input": "raw_user_input (bytes, unmodified)",
  "output": "raw_user_input (bytes, identical to input)",
  "invariants": [
    "sanitized_input == raw_user_input",
    "input_hash == raw_input_hash",
    "sanitization_pipeline_hash == keccak256(IDENTITY_SENTINEL_CID_bytes || raw_input_hash)"
  ],
  "notes": "Use this CID when no sanitization is applied. The input_hash == raw_input_hash equality is a provable on-chain claim. Implementations MUST NOT substitute any other CID to represent the no-sanitization case."
}
```

The CID was derived from the above JSON content (UTF-8 encoded, no trailing newline) using the IPFS CIDv0 (SHA2-256 multihash) algorithm. Implementations that re-derive the CID from this content MUST produce `QmccvoM6aRVgZ2dtFWvT6Wm3DmTvoAUHHotK7uQufnStVR`.

---

## References

- [ERC-8004](https://ethereum-magicians.org/t/erc-8004-trustless-agents/25098) — Verified Node Identity (agent identity layer)
- [ERC-8126](https://eips.ethereum.org/EIPS/eip-8126) — AI Agent Verification (Final)
- [ERC-8263](https://ethereum-magicians.org/t/erc-8263) — Onchain Proof Layer for AI Agent Actions (Vincent Wu / @TruthAnchor-AI)
- [ERC-8274](https://ethereum-magicians.org/t/erc-8274-ai-inference-proof-verification/28083) — AI Inference Proof Verification (Jimmy Shi)
- [ERC-8275](https://ethereum-magicians.org/t/erc-8275-agent-service-discovery-and-escrow-payments/28622) — Mesh Node Compensation (Panini)
- [ERC-8281 / OCP](https://github.com/damonzwicker/observation-commitment-protocol) — Observation Commitment Protocol (Damon Zwicker)
- [OCP Composition Note](https://gist.github.com/damonzwicker/8742e742bdc627b8e2179c00b81289dc) — L3+L4 AI inference attestation profile
- [Live AnchorProof interop tx](https://etherscan.io/tx/0xc32b66ae9446e0d5282a6fc813ba106126a8da05bced638b83840d9c2510e4d0) — ccip-router `commitmentHash` carried as `proofHash` in TruthAnchorV1 (ERC-8263), mainnet block 25289963. `agentIdScheme=1` (REGISTRY), `aux="ccip-router"`. Cross-reference: AttestationIndex `commitmentHash` in block 25289932.
- [ERC-8274 Worked Example](https://gist.github.com/damonzwicker/b6bef149db0bb4faa390a760b516db51) — claimType field mapping, RecordPointer schema, and verify() semantics for judgment claims (Damon Zwicker)

---

## Acknowledgements

- **Vincent Wu** (@TruthAnchor-AI) — co-author. Contributions: ERC-8263 layer-boundary definition establishing the proof-commitment / anchor surface as a distinct primitive from OCP / ERC-8281 (observation commitment); TruthAnchorV1 / AnchorProof canonical event as the ERC-8263 anchor layer; separation of AttestationIndex (commitment store) from TruthAnchorV1 (event layer) as composable without either absorbing the other; interoperability path from gateway-produced signed attestation through to IProofVerifier-style settlement consumption.

- **Jimmy Shi** — first external implementation of WYRIWE: WyriweVerifier for ERC-8274, wrapping the triple-hash scheme as an `IProofVerifier`. Co-author contributions include technical corrections to `inputHash` derivation (not keccak of the two hashes), `ATTESTATION_TYPEHASH` field names (`manifestHash→modelHash`, `agentId uint256→bytes32`, `timestamp uint64→uint256`), `block.chainid` dynamic requirement, and ERC-8274 `proofSystem = "attestation/wyriwe"` taxonomy placement.

- **Damon Zwicker** (@damonzwicker) — co-author. Contributions: `ClaimType` enum definition and proofSystem / claimType separation rationale (Section 7); `RecordPointer` typed schema formalizing the `commitmentProof` / `outcomeEvidence` distinction; `JudgmentVerificationCompleted` event definition; `verify()` three-layer accountability boundary for `ClaimType.Judgment`; OCP / ERC-8281 commitment discipline integration; ERC-8274 worked example gist.

- **babyblueviper1** (@babyblueviper1) — co-author. Production judgment validator operator. Primary author of the L4 Composition section: `JudgmentExecutionAttestation` EIP-712 struct and triple-hash construction; slot-for-slot WYRIWE mapping; `claimType` field concept; `verify()` semantic clarification (authenticates verdict, does not endorse soundness); `recordPointer` field and commitment/outcome separability invariant; Nostr relay anchoring as timestamp commitment primitive; `codeMeasurement` MUST be absent for `claimType = Judgment`; `verdictHash` construction clarification (`verdict_artifact_ref` covers both IPFS CID and Nostr event ID forms); closing the `string recordPointer` vs inline struct question ("attestation frozen, record alive"); Appendix A verification against deployed code. Production reference implementation at [api.babyblueviper.com/ledger](https://api.babyblueviper.com/ledger) — running against real capital.

---

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
