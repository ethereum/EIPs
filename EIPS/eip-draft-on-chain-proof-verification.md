---
eip: <to be assigned>
title: On-chain Proof Verification Standard
description: A minimal, proof-system-agnostic interface for on-chain verification of succinct zero-knowledge proofs (SNARKs/STARKs) and zkVM receipts, using field-aligned public inputs (bytes32[]).
author: Walid Khemiri <walidelkhemiri@gmail.com>
discussions-to: https://ethereum-magicians.org/t/erc-on-chain-proof-verification-standardization/25612
status: Draft
type: Standards Track
category: ERC
created: 2025-09-28
requires: 165
---

## Abstract

This ERC defines a minimal, proof-system-agnostic interface for on-chain verification of succinct zero-knowledge proofs.  
Callers provide **field-aligned public inputs** (`bytes32[]`) and an opaque proof; the contract returns a **magic value** on success.  
**Domain-separation fields are carried inside `publicInputs`** (e.g., chain id, verifying contract, nonces, expiries) and **must be consumed as public signals** by the underlying verifier.

---

## Motivation

On-chain verifiers expose bespoke ABIs: SNARK contracts expect `(a,b,c,inputs)`, zkVM wrappers accept receipts/journals and custom layouts, and domain separation is inconsistent.  
This fragmentation complicates generic integration by wallets, paymasters, bridges, and smart accounts.

This proposal standardizes a **single entrypoint** that:
- accepts **field-aligned public inputs** (`bytes32[]`) plus an opaque proof,
- requires schemas to **embed domain separation** inside those inputs,
- returns a **magic value** on success—uniform across proof systems.
- **does not revert on invalid proofs: MUST NOT** revert; **MUST** return any value other than this.isValidProof.selector.

---

## Scope

This ERC covers application-level verification of **succinct zero-knowledge proofs** produced by proof systems such as **SNARK** or **STARK** systems.  
It explicitly **includes zkVM receipts** where on-chain verification reduces to checking a SNARK/STARK proof via the appropriate verifier contract.

---

## Specification

### Interface

```solidity
interface IERCXXXXProofVerifier /* is ERC165 */ {
    /// @notice Verify a proof for the given public inputs under the specified schema.
    /// @param schema       32-byte identifier for proof system, layout, and version.
    /// @param publicInputs Field-aligned public inputs (bytes32 lanes). Schemas MUST
    ///                     define a fixed order and meaning for each lane, and MUST
    ///                     include domain-separation fields (e.g., chainId, verifying
    ///                     contract, nonce, expiry) when required. Lanes that encode
    ///                     numeric values MUST be pre-reduced to the target field if applicable.
    /// @param proof        Opaque proof/receipt bytes for the underlying proving system.
    /// @return magicValue  MUST equal this function’s selector if valid, else any other value.
    function isValidProof(
        bytes32 schema,
        bytes32[] calldata publicInputs,
        bytes calldata proof
    ) external view returns (bytes4 magicValue);
}
```

### Schema Identifier

The `schema` parameter uniquely identifies the proving **relation** (circuit/program + verifier layout + rules).

Implementations **SHOULD** compute `schema` as a collision-resistant digest over fixed-width, versioned components, anchored by a human-readable name:

- **Recommended construction (fixed-width fields):**
  ```
  schema = keccak256(
      abi.encode(
          keccak256("name of the circuit or program"),  // e.g., "age-merkle-threshold", "zkvm:transfer-v2"
          uint32(circuitOrProgramVersion),               // semantic version of the relation
          vkHashOrProgramId,                             // bytes32: verifying key hash (SNARK/STARK) or programId (zkVM)
          layoutHash                                     // bytes32: hash of lane order & field rules for publicInputs
      )
  );
  ```
  - `vkHashOrProgramId`:
    - SNARK/STARK: a stable hash/commitment to the verifying key (or succinct verifier).
    - zkVM: the immutable program identifier (`programId` / code digest).
  - `layoutHash` commits to the **exact lane order**, endianness, and field-reduction rules for `publicInputs`.

- **Examples**
  - **Groth16 circuit:**
    ```
    schema = keccak256(
        abi.encode(
            keccak256("age-merkle-threshold"),
            uint32(1),
            vkHash,        // bytes32
            layoutHash     // bytes32, commits to [root, threshold, subjectHash, chainId, ...]
        )
    );
    ```
  - **zkVM program:**
    ```
    schema = keccak256(
        abi.encode(
            keccak256("zkvm:transfer-v2"),
            uint32(2),
            programId,     // bytes32
            layoutHash
        )
    );
    ```

**Rationale.**  
This construction provides:
- **Domain & versioning:** The **name hash** (`keccak256("name of the circuit or program")`) and explicit version prevent accidental collisions and allow circuit/program upgrades without changing the ERC interface.
- **Verifier binding:** `vkHashOrProgramId` ties `schema` to a specific verifying key or succinct verifier/program, avoiding silent key swaps.
- **Input layout stability:** `layoutHash` ensures that any change to lane order or field rules mints a **new** `schema`.

**Norms & pitfalls**
- Prefer `abi.encode` (not `abi.encodePacked`) to avoid variable-length concatenation collisions.
- Keep `schema` **chain-agnostic**; do **not** include `chainId` here—domain separation belongs in `publicInputs` lanes.
- Any change to verifying key/program or lane layout/version **MUST** produce a new `schema` value.

**Minimal helper (illustrative):**
```solidity
function computeSchema(
    bytes32 circuitOrProgramNameHash,  // keccak256("name of the circuit or program")
    uint32 version,
    bytes32 vkHashOrProgramId,
    bytes32 layoutHash
) internal pure returns (bytes32) {
    return keccak256(abi.encode(
        circuitOrProgramNameHash,
        version,
        vkHashOrProgramId,
        layoutHash
    ));
}
```

### Public Inputs (typed, no extra hash)

Implementations **MUST** ensure that **all schema-mandated fields** inside `publicInputs` are **public signals** consumed by the underlying verifier, so that a valid proof is cryptographically bound to those values.  
Schemas **MUST** document:
- exact **lane order** and **semantics**,
- **endianness** (recommendation: big-endian for numeric interpretation),
- whether elements must be **pre-reduced** modulo the target field (e.g., BN254 `Fr`).

> If a schema later needs to add/remove/reorder lanes, it **MUST** mint a new `schema` identifier and, if applicable, deploy or reference a corresponding verifier.

### ERC-165

- Implementers MUST support ERC-165.  
- The interface ID is `type(IERCXXXXProofVerifier).interfaceId`.  
  For this single-method interface, it equals the selector of `isValidProof(bytes32,bytes32[],bytes)`.

---

## Rationale

### Why `schema` (bytes32)
Proofs are meaningful only relative to a particular verifier/program/layout.  
`schema` uniquely identifies that relation and its expected input layout as described above.

### Why `bytes32[]` public inputs
- Matches common verifier expectations (`uint256[]`/`bytes32[]` lanes).  
- Avoids parsing overhead and encoding ambiguity.  
- Forces callers to **reduce and align** values off-chain, minimizing on-chain footguns.  
- Cleanly supports zkVM receipts by exposing `programId`, `journalHash`, and domain fields as fixed-width lanes.

### Terminology note
In proof-theoretic terms, **`schema` corresponds to the relation** and **`publicInputs` to the instance**.

---

## Backwards Compatibility

- Existing Groth16/Plonk verifiers typically accept `uint256[]` public inputs. A thin adapter can cast each lane with `uint256(publicInputs[i])` and forward.  
- zkVM receipts verified on-chain via SNARK/STARK: expose `programId`, `journalHash`, and domain fields as `bytes32` lanes and forward them as `uint256[]` to the underlying verifier.  
- This ERC does not modify existing verifier contracts; it provides a uniform adapter surface.

---

## Reference Implementations (Adapters)

> **Note:** These are minimal **adapters** demonstrating how to implement the interface for a single circuit/program. Routing and other patterns are left to integrators.

### A) Groth16 Adapter (single circuit; lane order fixed)

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

interface IERCXXXXProofVerifier {
    function isValidProof(
        bytes32 schema,
        bytes32[] calldata publicInputs,
        bytes calldata proof
    ) external view returns (bytes4 magicValue);
}

// Typical Groth16 verifier interface
interface IGroth16Verifier {
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata publicInputs
    ) external view returns (bool);
}

/**
 * @title Groth16Adapter
 * @notice Minimal adapter for a single Groth16 circuit.
 *
 * Example lane order (schema-defined):
 *   [0] bytes32 treeRoot
 *   [1] bytes32 threshold              // numeric
 *   [2] bytes32 subjectHash
 *   [3] bytes32 chainId                // numeric
 *   [4] bytes32 verifyingContract      // lower 160 bits = address
 *   [5] bytes32 nonce                  // numeric
 *   [6] bytes32 expiry                 // numeric (unix time)
 */
contract Groth16Adapter is IERCXXXXProofVerifier {
    bytes4 constant MAGIC = this.isValidProof.selector;

    // Fixed schema for this adapter (example)
    bytes32 public constant SCHEMA_AGE_MERKLE_V1 =
        keccak256("age-merkle-threshold:v1:vk=<hash>:lanes-7");

    IGroth16Verifier public immutable verifier;

    constructor(address verifier_) {
        require(verifier_ != address(0), "zero verifier");
        verifier = IGroth16Verifier(verifier_);
    }

    function isValidProof(
        bytes32 schema,
        bytes32[] calldata publicInputs,
        bytes calldata proof
    ) external view returns (bytes4) {
        if (schema != SCHEMA_AGE_MERKLE_V1) return bytes4(0);
        if (publicInputs.length != 7) return bytes4(0);

        // Optional runtime checks (defense in depth)
        if (uint256(publicInputs[3]) != block.chainid) return bytes4(0);
        if (address(uint160(uint256(publicInputs[4]))) != address(this)) return bytes4(0);
        if (block.timestamp > uint256(publicInputs[6])) return bytes4(0);

        (uint256[2] memory a,
         uint256[2][2] memory b,
         uint256[2] memory c) = abi.decode(
            proof, (uint256[2], uint256[2][2], uint256[2])
        );

        uint256[] memory inputs = new uint256[](publicInputs.length);
        for (uint256 i = 0; i < publicInputs.length; ++i) {
            inputs[i] = uint256(publicInputs[i]);
        }

        bool ok = verifier.verifyProof(a, b, c, inputs);
        return ok ? MAGIC : bytes4(0);
    }
}
```

### B) zkVM Adapter (SNARK/STARK-backed; single program)

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

interface IERCXXXXProofVerifier {
    function isValidProof(
        bytes32 schema,
        bytes32[] calldata publicInputs,
        bytes calldata proof
    ) external view returns (bytes4 magicValue);
}

interface IUnderlyingSuccinctVerifier {
    function verify(bytes calldata proof, uint256[] calldata publicInputs) external view returns (bool);
}

/**
 * @title ZkVMAdapter
 * @notice Minimal adapter for a single zkVM program whose on-chain verification reduces
 *         to a SNARK/STARK verifier.
 *
 * Example lane order (schema-defined):
 *   [0] bytes32 programId
 *   [1] bytes32 journalHash
 *   [2] bytes32 chainId
 *   [3] bytes32 verifyingContract      // lower 160 bits = address
 *   [4] bytes32 nonce
 *   [5] bytes32 expiry
 */
contract ZkVMAdapter is IERCXXXXProofVerifier {
    bytes4 constant MAGIC = this.isValidProof.selector;

    // Fixed schema for this adapter (example)
    bytes32 public constant SCHEMA_ZKVM_TRANSFER_V2 =
        keccak256("zkvm:transfer-v2:prog=<id>:lanes-6");

    IUnderlyingSuccinctVerifier public immutable succinct;

    constructor(address succinctVerifier) {
        require(succinctVerifier != address(0), "zero verifier");
        succinct = IUnderlyingSuccinctVerifier(succinctVerifier);
    }

    function isValidProof(
        bytes32 schema,
        bytes32[] calldata publicInputs,
        bytes calldata proof
    ) external view returns (bytes4) {
        if (schema != SCHEMA_ZKVM_TRANSFER_V2) return bytes4(0);
        if (publicInputs.length != 6) return bytes4(0);

        if (uint256(publicInputs[2]) != block.chainid) return bytes4(0);
        if (address(uint160(uint256(publicInputs[3]))) != address(this)) return bytes4(0);
        if (block.timestamp > uint256(publicInputs[5])) return bytes4(0);

        uint256[] memory inputs = new uint256[](publicInputs.length);
        for (uint256 i = 0; i < publicInputs.length; ++i) {
            inputs[i] = uint256(publicInputs[i]);
        }

        bool ok = succinct.verify(proof, inputs);
        return ok ? MAGIC : bytes4(0);
    }
}
```

---

## Security Considerations

- **Replay resistance:** Domain lanes (e.g., `chainId`, `verifyingContract`, `expiry`, `nonce`) are **included inside `publicInputs`** and must be **public signals** in the circuit/program; thus a valid proof is cryptographically tied to the intended domain.  
- **Encoding determinism:** Each schema publishes an exact lane order. Any change requires a **new `schema`**.  
- **Field reduction & endianness:** Schemas MUST state reduction requirements (e.g., BN254 `Fr`) and endianness (recommended: big-endian when interpreted as `uint256`).  
- **Address lane:** `verifyingContract` SHOULD be encoded as the lower 160 bits of a lane; higher bits SHOULD be zero and MAY be checked.  
- **DoS:** Implementations MUST bound `publicInputs.length` and `proof.length`; adapters SHOULD early-return on absurd sizes.  
- **Key/VK rotation:** When a VK changes, either (a) publish a new `schema` (preferred) or (b) gate by a **version lane** as shown in the versioned adapter and document which versions are acceptable.

---

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
