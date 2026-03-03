---
eip: TBD
title: Protocol-Enshrined Privacy Pool
description: Shielded transfers via enshrined system contract with wallet-compatible intent authorization
author: Tom Lehman (@RogerPodacter)
discussions-to: https://ethereum-magicians.org/t/eip-xxxx-protocol-enshrined-privacy-pool/27889
status: Draft
type: Standards Track
category: Core
created: 2026-03-03
requires: 20, 712, 1559, 2718
---

## Abstract

This EIP introduces a protocol-enshrined privacy pool for shielded transfers and withdrawals of Ether and ERC-20 tokens, deployed as a system contract at a fixed address with a single canonical note tree and nullifier set. Users authorize shielded operations by signing standard [EIP-1559](./eip-1559.md) (type-2) transactions on reserved intent chain IDs; a zero-knowledge proof is submitted on-chain. Deposits are public. The system contract can only be replaced by a hard fork — there is no proxy or admin key. A proof verification precompile, user and issuer registries, and a label-based lineage system supporting proof of innocence are specified alongside the core pool.

## Motivation

Ethereum transactions and balances are public by default. This deters real demand — payroll, treasury operations, institutional flows, everyday payments — from users and organizations that require basic financial privacy.

App-level privacy protocols have attempted to fill this gap but face two independent problems that no single deployment resolves simultaneously:

1. **Governance vs. ossification dilemma.** An upgradeable pool contract relies on admin keys or governance tokens — a malicious or compromised upgrade can drain funds. An immutable contract eliminates governance risk but cannot evolve: if the proof system weakens or better authentication becomes available, there is no migration path and funds are locked behind aging cryptography. At the app layer, there is no good option.
2. **Fragmented anonymity sets.** Multiple competing pools split depositors across deployments, degrading privacy for everyone. Migrating between pools requires coordinated withdrawal and redeposit, fragmenting the anonymity set each time. A single canonical pool is a Schelling point that app-layer contracts do not achieve organically.

Precompiles alone (for hashing or proof verification) make on-chain operations gas-feasible but do not simultaneously resolve governance risk, ossification, or anonymity-set fragmentation — the pool contract itself is still either immutable or upgradeable, and its anonymity set must still be bootstrapped from zero.

Protocol enshrinement resolves both problems. The system contract has no admin key and cannot be upgraded outside of a hard fork, eliminating governance risk. When cryptographic assumptions change, the protocol migrates through the same social-consensus process as any other protocol upgrade, eliminating ossification risk. The anonymity set is canonical from day one. Ethereum defines valid public transactions; a canonical definition of valid private transactions is a natural complement.

This work builds on the Privacy Pools framework (Buterin, Soleimani, et al.), which introduced proof of innocence but left deployment as an app-layer concern.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### 1. Overview

This EIP defines:

1. A **Privacy Pool System Contract** deployed at a fixed address, holding all privacy state (note commitment tree, nullifier set, intent-nullifier set, user registry, issuer registry).
2. A **hard-fork-only upgrade model**: the system contract's code can only be replaced by a hard fork; there is no proxy or admin function.
3. A **wallet-compatible intent authorization format**: users sign standard EIP-1559 (type-2) transactions on reserved chain IDs to authorize shielded transfers and withdrawals.
4. A **public-input interface** for spend proofs and required contract execution checks.
5. A **label-based lineage system** enabling proof of innocence without fragmenting the anonymity set.
6. An **issuer viewing key registry** enabling scoped visibility for permissioned asset issuers.
7. A **proof verification precompile** enabling fork-managed circuit upgrades without admin keys.

These components are presented as a single EIP because they share state and form a single deployment unit; the precompile MAY be specified as a companion EIP.

App-level policy (e.g., proof-of-innocence enforcement, compliance wrappers, fees) is out of scope for the base contract and MAY be implemented by wrapper contracts.

### 2. Terminology

* **Note**: A shielded UTXO-like object represented on-chain by a commitment.
* **Commitment**: A Poseidon hash committing to a note's fields.
* **Nullifier**: A value published when spending a note to prevent double-spends.
* **Label**: A cryptographic lineage tag tracing a note back to its original deposit(s). Used for proof of innocence.
* **Intent transaction (intent tx)**: A signed EIP-1559 (type-2) transaction on a reserved intent chain ID that authorizes a shielded transfer or withdrawal. The intent tx is never broadcast to any real chain.
* **On-chain transaction (pool tx)**: A normal Ethereum transaction calling the privacy pool contract with a proof and public inputs.
* **Privacy RPC**: A JSON-RPC endpoint that presents the intent chain as a standard EVM network. It serves private ETH balances (via `eth_getBalance`), private ERC-20 balances (via `eth_call` to `balanceOf`), provides packed nonces (via `eth_getTransactionCount`), intercepts signed intent transactions, generates proofs, and submits pool transactions on the user's behalf.
* **Phantom input**: A dummy input slot used to maintain constant arity (2-input circuit) while spending only one real note. An observer MUST NOT be able to distinguish phantom from real inputs.
* **Dummy output**: A dummy output slot used to maintain constant output count (2 outputs) while producing fewer real notes.
* **Registry (user registry)**: A Merkleized mapping from `address` to `(viewingPubKey, nullifierKeyHash)`, binding Ethereum addresses to encryption and nullifier keys.
* **Issuer registry**: A Merkleized mapping from `tokenAddress` to `(issuerPubKey, issuerEpoch)`, enabling optional issuer visibility.
* **Association Set Provider (ASP)**: A party that publishes Merkle roots over sets of deposit labels it considers clean, enabling proof of innocence.

### 3. Parameters and Constants

The following items MUST be concretely assigned before this EIP can advance beyond Draft:

* `PRIVACY_POOL_ADDRESS` — fixed address for the system contract
* `PROOF_VERIFY_PRECOMPILE_ADDRESS`
* Proof system and verification key format(s)
* Merkle tree depth (v0: 32, supporting ~4B leaves)
* Root-history buffer sizes (v0 RECOMMENDED: >= 500)

The following values are defined structurally:

#### 3.1 Reserved Intent Chain IDs

For each execution chain with chain ID `E` (`E = block.chainid`), two intent chain IDs are derived deterministically:

```
TRANSFER_CHAIN_ID(E)   = uint64(uint256(keccak256(abi.encode("PRIVACY_POOL_TRANSFER", uint256(E)))))
WITHDRAWAL_CHAIN_ID(E) = uint64(uint256(keccak256(abi.encode("PRIVACY_POOL_WITHDRAWAL", uint256(E)))))
```

`TRANSFER_CHAIN_ID(E)` and `WITHDRAWAL_CHAIN_ID(E)` are distinct from each other and from `E` with overwhelming probability — collision probability is ~1/2^64 per chain pair, which is negligible across all deployed EVM chains. A leaked intent tx is a valid Ethereum transaction — if its chain ID matched a real chain, it could be replayed there. Wallets and middleware MUST handle chain IDs and nonces as 64-bit or larger integers; JavaScript implementations MUST use BigInt.

Intent chain IDs are per-execution-chain, so an intent signed for one chain's pool cannot be replayed on another chain's pool — the chain ID in the ECDSA signature will not match the target chain's expected intent chain IDs.

#### 3.2 Packed Intent Nonce

For intent transactions, the nonce MUST be interpreted as:

```
nonce = (validUntilSeconds << 32) | random32
```

* `validUntilSeconds` — unsigned 32-bit UNIX timestamp providing bounded intent lifetime.
* `random32` — uniformly random 32-bit value providing `intentNullifier` uniqueness.

The Privacy RPC MUST return a packed nonce when the wallet queries `eth_getTransactionCount` on the fictional chain ID.

#### 3.3 Domain Separators

All Poseidon hashes that require domain separation MUST include a distinct domain tag (field element). Each domain tag is derived as:

```
DOMAIN = uint256(keccak256("privacy_pool.<context_name>")) mod p
```

where `p` is the BN254 scalar field order (the field over which SNARK circuits and Poseidon operate) and `<context_name>` is the string identifier listed below. This derivation is deterministic and removes all domain tag TBDs.

The following domain tags are defined by this EIP:

* `NULLIFIER_DOMAIN` — `keccak256("privacy_pool.nullifier") mod p` — real note nullifiers
* `PHANTOM_DOMAIN` — `keccak256("privacy_pool.phantom") mod p` — phantom nullifiers
* `LABEL_DOMAIN` — `keccak256("privacy_pool.label") mod p` — deposit labels
* `LABEL_MERGE_DOMAIN` — `keccak256("privacy_pool.label_merge") mod p` — merged transfer labels
* `INTENT_DOMAIN` — `keccak256("privacy_pool.intent") mod p` — intent nullifiers
* `NK_DOMAIN` — `keccak256("privacy_pool.nk") mod p` — nullifier key hashing (`nullifierKeyHash = poseidon(NK_DOMAIN, nullifierKey)`)
* `RANDOMNESS_DOMAIN` — `keccak256("privacy_pool.randomness") mod p` — deterministic output randomness derivation
* `DUMMY_CIPHER_DOMAIN` — `keccak256("privacy_pool.dummy_cipher") mod p` — dummy ciphertext derivation

All values are deterministically computable from the derivation formula above and MUST be `< p`.

#### 3.4 Fixed Constants

* `MAX_INTENT_LIFETIME = 86400` — maximum allowed `validUntilSeconds` offset from `block.timestamp`, in seconds (24 hours). Long enough to tolerate network congestion; short enough to bound stale intent risk.
* `DUMMY_NK_HASH` — a nothing-up-my-sleeve constant computed as `poseidon(NK_DOMAIN, 0xdead)` using the parameters in Section 3.5. Security does not depend on preimage resistance — the preimage (`0xdead`) is public. The circuit enforces `amount == 0` for dummy outputs, preventing value extraction regardless. Used for dummy output slots.

#### 3.5 Poseidon Hash Construction

This EIP uses Poseidon over the BN254 scalar field `p` (defined in Section 3.3) with the following parameters:

* State width: `t = 3` (2-arity, absorbing 2 field elements per permutation)
* S-box: `x^5` (`α = 5`)
* Full rounds: `R_F = 8`
* Partial rounds: `R_P = 57`
* Round constants and MDS matrix: TBD. The intended instantiation follows the Grassi–Khovratovich–Rechberger–Roy parameter generation for BN254 at 128-bit security. Exact constants and test vectors MUST be provided before this EIP advances past Draft.

The primitive operation is `hash_2(a, b)`: a single Poseidon permutation with initial state `[a, b, 0]`, returning element 0 of the output state.

For inputs of arity `n > 2`, a **left-balanced binary tree** composition is used: the left subtree receives the largest power of 2 strictly less than `n` inputs; the right subtree receives the remainder. Each subtree is composed recursively. We write `hash_n(x_0, ..., x_{n-1})` for this composition. For example, `hash_4(a, b, c, d) = hash_2(hash_2(a, b), hash_2(c, d))` and `hash_5(a, b, c, d, e) = hash_2(hash_4(a, b, c, d), e)`.

This ensures only a single Poseidon instantiation (T=3) is required across all circuit and on-chain contexts (matching `poseidon-solidity` and Noir's `poseidon::bn254::hash_2`).

#### 3.6 Grumpkin Curve

This EIP uses the Grumpkin curve for ECDH key agreement in note encryption (Section 10.7.1) and issuer encryption (Section 10.11). Grumpkin is a short Weierstrass curve embedded in the BN254 scalar field:

* Equation: `y² = x³ − 17` (i.e., `a = 0`, `b = -17`)
* Base field: the BN254 scalar field `p` (defined in Section 3.3)
* Curve order: the BN254 base field modulus (the two curves form a 2-cycle)
* Cofactor: `1` (no subgroup check required)
* Generator: `G = (1, 17631683881184975370165255887551781615748388533673675138860)`

Points are represented as two BN254 scalar field elements `(x, y)`. Implementations MUST validate that coordinates are canonical (`< p`), satisfy the curve equation, and are not the point at infinity.

#### 3.7 Circuit Identifiers

Each circuit supported by the proof verification precompile is identified by a `circuitId` (`uint256`). The following table is fork-defined:

| `circuitId` | Description | Proof System | Curve | Auth |
|-------------|-------------|--------------|-------|------|
| 0 | Circuit A | HONK | BN254 | ECDSA/secp256k1 |

Each `circuitId` is bound to an exact proof byte encoding, public-input count/order, and verification key. The precompile MUST reject any unknown `circuitId`. Hard forks append new entries; existing `circuitId` meanings MUST NOT change. The initial circuit (`circuitId = 0`) targets the UltraHONK proving system (Aztec Labs / Barretenberg). Exact proof serialization and verification key formats MUST be pinned before this EIP advances past Draft.

All `poseidon(...)` expressions in this EIP denote this binary-tree construction applied to the listed inputs in order. The following table lists each hash context and its input vector:

| Context | Inputs (in order) | Arity |
|---------|-------------------|-------|
| Note commitment | `amount, ownerAddress, randomness, nullifierKeyHash, tokenAddress, label` | 6 |
| Nullifier | `NULLIFIER_DOMAIN, nullifierKey, leafIndex_u32, randomness` | 4 |
| Phantom nullifier | `PHANTOM_DOMAIN, nullifierKey, intentNullifier, slotIndex` | 4 |
| Nullifier key hash | `NK_DOMAIN, nullifierKey` | 2 |
| Output randomness | `RANDOMNESS_DOMAIN, nullifierKey, intentNullifier, slotIndex` | 4 |
| Intent nullifier | `INTENT_DOMAIN, nullifierKey, intentChainId, nonce` | 4 |
| Deposit label | `LABEL_DOMAIN, executionChainId, depositorAddress, tokenAddress, amount, intentNullifier` | 6 |
| Label merge | `LABEL_MERGE_DOMAIN, min(labelA, labelB), max(labelA, labelB)` | 3 |
| Merkle tree node | `left, right` | 2 |
| Encryption seed | `nullifierKey, ENC_KEY_DOMAIN` | 2 |
| Ephemeral scalar | `encSeed, recipientPubKey.x, recipientPubKey.y, intentNullifier, slotIndex, randomness, EPHEMERAL_DOMAIN` | 7 |
| Shared secret | `ECDH_x, SHARED_DOMAIN` | 2 |
| Keystream element | `sharedSecret, i, KEYSTREAM_DOMAIN` | 3 |
| Self-scalar | `encSeed, intentNullifier, slotIndex, SELF_EPHEMERAL_DOMAIN` | 4 |
| Self-secret | `encSeed, S.x, SELF_SECRET_DOMAIN` | 3 |
| Dummy cipher scalar | `nullifierKey, intentNullifier, slotIndex, DUMMY_CIPHER_DOMAIN` | 4 |
| Dummy cipher element | `nullifierKey, intentNullifier, slotIndex, i, DUMMY_CIPHER_DOMAIN` | 5 |
| Issuer ephemeral scalar | `encSeed, issuerPubKey.x, issuerPubKey.y, issuerEpoch, intentNullifier, slotIndex, ISSUER_EPHEMERAL_DOMAIN` | 7 |
| Issuer dummy scalar | `nullifierKey, intentNullifier, slotIndex, ISSUER_DUMMY_DOMAIN` | 4 |
| Issuer dummy element | `nullifierKey, intentNullifier, slotIndex, i, ISSUER_DUMMY_DOMAIN` | 5 |
| Encrypted notes hash | `hash_9(ciphertext_0), hash_9(ciphertext_1)` | 2 |
| Issuer ciphertext hash | `hash_7(issuerCiphertext_0), hash_7(issuerCiphertext_1)` | 2 |

Domain tags appear as the first input in nullifier and label contexts. In encryption/KDF contexts, domain tags appear as the last input. Both conventions are fixed by this specification. Note commitments do not include a domain tag.

### 4. Privacy Pool System Contract

#### 4.1 Deployment and Upgrade Model

The privacy pool is deployed as a system contract at `PRIVACY_POOL_ADDRESS` (TBD), following the pattern established by [EIP-4788](./eip-4788.md) (beacon block root), [EIP-2935](./eip-2935.md) (historical block hashes), [EIP-7002](./eip-7002.md) (execution layer exits), and [EIP-7251](./eip-7251.md) (consolidations).

* The contract is deployed via Nick's method (a pre-signed transaction from a single-use deployer account) for a deterministic, cross-chain address.
* The code at `PRIVACY_POOL_ADDRESS` can only be replaced by a subsequent hard fork that sets new code as part of its state transition rules.
* There is no proxy, no admin function, and no on-chain upgrade mechanism.
* Storage persists across fork-initiated code replacements; implementations MUST maintain storage layout compatibility (see Section 4.2).

#### 4.2 State

The pool MUST maintain:

* **Commitment Merkle tree** — append-only Poseidon Merkle tree (depth: 32, ~4B leaves). Empty leaf = 0. Holds multi-asset notes (`tokenAddress` is inside the commitment). The contract MUST revert when `nextLeafIndex == 2^32`.
* **Commitment root history** — circular buffer of recent roots (size RECOMMENDED: >= 500) so proofs against slightly stale roots remain valid.
* **Nullifier set** — `mapping(uint256 => bool)`.
* **Intent nullifier set** — `mapping(uint256 => bool)`.
* **User registry** — Poseidon Merkle tree mapping `address → (viewingPubKey, nullifierKeyHash)`, with its own root history.
* **Issuer registry** — sparse Poseidon Merkle tree keyed by `tokenAddress`, with leaves containing `(issuerPubKeyX, issuerPubKeyY, issuerEpoch)` and default leaf `(0, 0, 0)`, with its own root history.
* **Registration nonces** — `mapping(address => uint256)` for EIP-712 delegated registration replay protection.

Implementations MUST maintain storage layout compatibility across hard-fork code replacements. The commitment tree root, next leaf index, root history buffer, nullifier mappings, intent nullifier mapping, and registry trees MUST occupy stable storage slots. A hard fork that replaces the contract code MUST NOT alter or reinterpret existing storage.

Apps that need custom policy can deploy wrapper contracts on top, but all calls operate against this single canonical contract state.

#### 4.3 Contract Interface

The pool MUST expose the following functions:

**Pool transaction:**

```solidity
function transact(
    bytes calldata proof,
    uint256 circuitId,
    uint256[17] calldata publicInputs,
    bytes calldata encryptedNoteData,
    bytes calldata issuerCiphertextData
) external payable
```

`publicInputs` is a fixed-size array of 17 `uint256` values in the order defined by Section 11: `[merkleRoot, nullifier0, nullifier1, commitment0, commitment1, publicAmountIn, publicAmountOut, publicRecipient, publicTokenAddress, depositorAddress, encryptedNotesHash, intentNullifier, registryRoot, issuerRegistryRoot, validUntilSeconds, issuerCiphertextHash, executionChainId]`.

**User registration:**

```solidity
function register(
    uint256 viewingPubKeyX,
    uint256 viewingPubKeyY,
    uint256 nullifierKeyHash
) external

function registerFor(
    address user,
    uint256 viewingPubKeyX,
    uint256 viewingPubKeyY,
    uint256 nullifierKeyHash,
    uint256 userNonce,
    bytes calldata signature
) external
```

`register` is called by `msg.sender` to bind their address to a viewing public key and nullifier key hash. `registerFor` allows a third party to register on behalf of `user` using an EIP-712 signature (see Section 9.2).

**Issuer registration:**

```solidity
function registerIssuer(
    address tokenAddress,
    uint256 issuerPubKeyX,
    uint256 issuerPubKeyY
) external
```

`registerIssuer` is called by the token's issuer authority (see Section 9.4) to bind the token to an issuer viewing key.

#### 4.4 Execution

On each call, the pool MUST execute the following steps:

1. **Verify the proof** via the verification precompile using `circuitId`, `proof`, and `publicInputs`.

2. **Verify execution chain ID.** Require `executionChainId == block.chainid`.

3. **Enforce intent expiry.**
   * If `depositorAddress == 0`: require `validUntilSeconds > 0`.
   * If `depositorAddress != 0`: require `validUntilSeconds == 0`.
   * If `validUntilSeconds > 0`:
     * Require `block.timestamp <= validUntilSeconds`.
     * Require `validUntilSeconds <= block.timestamp + MAX_INTENT_LIFETIME`.

4. **Check merkle root.** Require `merkleRoot` is in the commitment root history.

5. **Check registry root.** Require `registryRoot` is in the user registry root history. `registryRoot` MUST be nonzero.

6. **Check issuer registry root.** Require `issuerRegistryRoot` is in the issuer registry root history. `issuerRegistryRoot` MUST be nonzero.

7. **Enforce nullifier uniqueness.** Require `nullifier0 != nullifier1` (defense-in-depth; the circuit guarantees this — real nullifiers use distinct `leafIndex` values; phantom nullifiers use distinct `slotIndex` values). The contract MUST NOT attempt to distinguish phantom nullifiers from real ones.

8. **Mark nullifiers spent.** Require both nullifiers are unspent; then mark them spent.

9. **Mark intent nullifier used.** Require `intentNullifier` is unused; then mark it used.

10. **Insert commitments.** Insert `commitment0` and `commitment1` into the Merkle tree. Commitments MUST be nonzero — dummy outputs use nonzero dummy commitments (inserting 0 is indistinguishable from the tree's empty leaf value).

11. **Verify encrypted note data.** `encryptedNoteData` is 576 bytes: each field element is encoded as a 32-byte big-endian `uint256`, concatenated in order — `ciphertext_0[0..8]` then `ciphertext_1[0..8]` (9 elements per note, 18 total). Recompute `poseidon(hash_9(ciphertext_0), hash_9(ciphertext_1))` and require the result equals `encryptedNotesHash`. Each 32-byte element MUST be `< p`; the contract MUST reject the transaction if any ciphertext element is non-canonical.

12. **Verify issuer ciphertext data.** Require `issuerCiphertextHash != 0`. `issuerCiphertextData` is 448 bytes: each field element is encoded as a 32-byte big-endian `uint256`, concatenated in order — `issuerCiphertext_0[0..6]` then `issuerCiphertext_1[0..6]` (7 elements per note, 14 total). Recompute the Poseidon hash and require the result equals `issuerCiphertextHash`. Each 32-byte element MUST be `< p`; the contract MUST reject the transaction if any ciphertext element is non-canonical.

13. **Execute asset movement based on operation mode.** Exactly one of the following three branches MUST match; the conditions are mutually exclusive:

    **Deposit** (`depositorAddress != 0`):
    * Enforce deposit value constraints per Section 6.1 (`msg.sender == depositorAddress`, `publicAmountIn > 0`, `publicAmountOut == 0`, `publicRecipient == 0`).
    * If `publicTokenAddress == 0` (ETH): require `msg.value == publicAmountIn`.
    * If `publicTokenAddress != 0` (ERC-20): require `msg.value == 0`. Record `balBefore = balanceOf(address(this))`. Execute `transferFrom(msg.sender, address(this), publicAmountIn)` and require success. Require `balanceOf(address(this)) - balBefore == publicAmountIn`, else revert. Exact approvals are RECOMMENDED — large standing approvals expose users to excess deposit risk if the RPC is compromised.

    **Withdrawal** (`depositorAddress == 0` AND `publicAmountOut > 0`):
    * Require `msg.value == 0`.
    * Enforce withdrawal value constraints per Section 6.3 (`publicAmountIn == 0`, `publicRecipient != 0`).
    * If `publicTokenAddress == 0` (ETH): send `publicAmountOut` to `publicRecipient`.
    * If `publicTokenAddress != 0` (ERC-20): execute `transfer(publicRecipient, publicAmountOut)` and require success.
    * The on-chain tx submitter MAY be a relayer whose address is irrelevant to the proof — only the intent tx signer matters.

    **Transfer** (`depositorAddress == 0` AND `publicAmountOut == 0`):
    * Require `msg.value == 0`.
    * Enforce transfer value constraints per Section 6.2 (`publicAmountIn == 0`, `publicRecipient == 0`, `publicTokenAddress == 0`).
    * The on-chain tx submitter MAY be a relayer whose address is irrelevant to the proof — only the intent tx signer matters.

    ERC-20 `transfer` and `transferFrom` calls MUST use safe call semantics:
    * Empty return data → success.
    * 32-byte ABI-encoded `true` (`uint256(1)`) → success.
    * 32-byte ABI-encoded `false` (`uint256(0)`) → revert.
    * Any other return data length or content → revert.
    * Call revert → revert.

    ERC-20 `balanceOf` calls MUST return exactly 32 bytes of data, decoded as `uint256`. If the call reverts or returns any other data length, the transaction MUST revert.

    Fee-on-transfer and rebasing tokens are incompatible. The deposit-side balance-delta check rejects fee-on-transfer tokens; rebasing tokens are not reliably detectable. Tokens that charge fees only on outbound `transfer` (not on `transferFrom`) pass the deposit check but deliver less than `publicAmountOut` on withdrawal. Such tokens MUST NOT be deposited.

14. **Emit events.** Emit the following event:

    ```solidity
    event PrivacyPoolTransact(
        uint256 indexed nullifier0,
        uint256 indexed nullifier1,
        uint256 indexed intentNullifier,
        uint256 commitment0,
        uint256 commitment1,
        uint256 merkleRoot,
        bytes encryptedNoteData,
        bytes issuerCiphertextData
    );
    ```

    Nullifiers and `intentNullifier` are indexed for efficient scanning and lookup. Commitments and `merkleRoot` are non-indexed (scanners decrypt ciphertexts, not search by commitment). Ciphertext bytes are non-indexed (too large for topic slots). Ciphertext MUST NOT be written to contract storage — scanners read events or calldata.

    **Registration events:**

    ```solidity
    event UserRegistered(
        address indexed user,
        uint256 viewingPubKeyX,
        uint256 viewingPubKeyY,
        uint256 nullifierKeyHash
    );

    event IssuerRegistered(
        address indexed tokenAddress,
        uint256 issuerPubKeyX,
        uint256 issuerPubKeyY
    );
    ```

    `register` and `registerFor` MUST emit `UserRegistered`. `registerIssuer` MUST emit `IssuerRegistered`. Scanners use these events to maintain local copies of the registry trees.

### 5. Intent Transactions (Wallet Authorization)

#### 5.1 Supported Format

Only **EIP-1559 type-2** transactions are valid intent transactions.

The circuit MUST parse:

```
0x02 || rlp([
  chainId,
  nonce,
  maxPriorityFeePerGas,
  maxFeePerGas,
  gasLimit,
  to,
  value,
  data,
  accessList,
  signatureYParity,
  r,
  s
])
```

Constraints:

* `accessList` MUST be empty.
* `maxPriorityFeePerGas`, `maxFeePerGas`, and `gasLimit` are unconstrained by the circuit and MAY be set to any value. The Privacy RPC SHOULD return values that produce normal-looking transactions for the wallet (e.g., via `eth_gasPrice` and `eth_estimateGas` responses on the fictional chain). These fields are parsed during RLP decoding but do not affect proof validity.
* `chainId` MUST equal `TRANSFER_CHAIN_ID(block.chainid)` for transfers or `WITHDRAWAL_CHAIN_ID(block.chainid)` for withdrawals.
* Legacy (type-0) transactions MUST be rejected in v0.

#### 5.2 Intent Semantics

An intent tx is either:

**ETH intent:**

* `to` = recipient address
* `value` = amount
* `data` MUST be empty

**[ERC-20](./eip-20.md) intent:**

* `to` = token contract address
* `data` MUST be exactly an ABI-encoded `transfer(address,uint256)` call with the 4-byte `transfer(address,uint256)` selector
* `value` MUST be 0

Any other calldata MUST be rejected.

#### 5.3 Binding Operation Type

The intent chain ID is included in the type-2 signed payload. Therefore, a valid signature on `TRANSFER_CHAIN_ID(E)` MUST NOT be accepted as authorization for a withdrawal, and vice versa. The RPC cannot convert a signed transfer into a withdrawal or vice versa because the chain ID is bound in the ECDSA signature.

#### 5.4 Intent Expiry

For transfers and withdrawals, the circuit MUST extract:

```
validUntilSeconds = nonce >> 32
```

and expose it as a public input.

The privacy pool contract MUST enforce:

* If `depositorAddress == 0` (transfer or withdrawal): `validUntilSeconds` MUST be nonzero. The contract MUST reject `validUntilSeconds == 0`.
* If `depositorAddress != 0` (deposit): `validUntilSeconds` MUST be 0. The contract MUST reject nonzero values.
* When `validUntilSeconds > 0`: `block.timestamp <= validUntilSeconds` AND `validUntilSeconds <= block.timestamp + MAX_INTENT_LIFETIME`.

The upper bound prevents execution of intents with absurdly far-future expiry timestamps — at execution time, `validUntilSeconds` must be at most `MAX_INTENT_LIFETIME` seconds in the future. Note that this bounds the execution window, not the delay from signing to execution.

#### 5.5 Wallet Compatibility

Wallets that natively support the privacy pool can manage shielded balances, construct intents, and interact with the Privacy RPC directly — this is the preferred path.

For wallets without native support, the intent format is designed to work without modification: the wallet connects to the Privacy RPC as a standard JSON-RPC endpoint on the intent chain ID network. It constructs an ordinary transfer, signs it, and hands it to the RPC, which handles proof generation and on-chain submission. Deposits require the wallet to be connected to Ethereum mainnet (real chain ID). Transfers and withdrawals require the wallet to be connected to the Privacy RPC's intent chain ID network — standard network-switching UX, no special wallet behavior.

### 6. Operation Modes

The privacy pool supports three operation modes, determined by public inputs:

#### 6.1 Deposit Mode (Public Deposit-to-Self)

Deposit mode is selected when `depositorAddress != 0`.

Requirements:

* The pool tx sender MUST equal `depositorAddress` (`msg.sender == depositorAddress`).
* `publicTokenAddress` specifies the deposited asset (`0` for ETH, otherwise an ERC-20 address).
* `publicAmountIn > 0`.
* `publicAmountOut == 0`.
* `publicRecipient == 0`.
* Both input slots MUST be phantom.
* Output notes MUST be owned by `depositorAddress`.
* `validUntilSeconds == 0`.

Deposits are fully public with respect to token, amount, and depositor address. No intent transaction is needed — the depositor submits the pool transaction directly (proof, public inputs, encrypted notes) as a standard L1 transaction.

Atomic deposit-to-third-party is out of scope for v0.

#### 6.2 Transfer Mode (Shielded Transfer)

Transfer mode is selected when:

* `depositorAddress == 0`
* Intent tx `chainId == TRANSFER_CHAIN_ID(block.chainid)`
* `publicAmountIn == 0`
* `publicAmountOut == 0`
* `publicRecipient == 0`
* `publicTokenAddress == 0`

In transfer mode the token MUST be private (enforced inside the circuit); the on-chain transaction MUST NOT reveal token or amount. The transfer anonymity set spans all tokens because `publicTokenAddress` is zero.

Coin selection is delegated to the prover. The intent binds payment semantics (recipient, amount, token, operation type), not which notes are spent or which labels merge.

#### 6.3 Withdrawal Mode (Public Withdrawal)

Withdrawal mode is selected when:

* `depositorAddress == 0`
* Intent tx `chainId == WITHDRAWAL_CHAIN_ID(block.chainid)`
* `publicAmountIn == 0`
* `publicAmountOut > 0`
* `publicRecipient != 0`
* `publicTokenAddress` specifies the withdrawn token (`0` for ETH, otherwise ERC-20 address)

Withdrawals are public with respect to token, amount, and recipient address.

### 7. Note Commitment and Nullifiers

#### 7.1 Address and Amount Constraints

Inside the circuit:

* All address-valued fields (`ownerAddress`, `tokenAddress`, `depositorAddress`, `publicRecipient`) MUST be constrained to `< 2^160`. Without this, field aliasing could produce commitments or public inputs that pass proof verification but bind to different addresses than the EVM expects.
* Amounts MUST be constrained to `< 2^248`. ERC-20 amounts are `uint256`, but the SNARK field is ~254 bits. The balance equation sums at most 3 terms per side; `3 * 2^248 < p` prevents field overflow. The contract MUST also reject `publicAmountIn` or `publicAmountOut` values `>= 2^248`.

#### 7.2 Note Commitment

Notes MUST commit to at least:

```
commitment = poseidon(
  amount,
  ownerAddress,
  randomness,
  nullifierKeyHash,
  tokenAddress,
  label
)
```

* `ownerAddress` — 20-byte Ethereum address. Ties note ownership to existing identity.
* `randomness` — blinding factor. Two notes with same amount/owner produce different commitments.
* `nullifierKeyHash` — hash of the owner's nullifier key: `poseidon(NK_DOMAIN, nullifierKey)`.
* `tokenAddress` — ERC-20 contract address, or `0` for ETH.
* `label` — cryptographic lineage tag (see Section 8).

The binary-tree Poseidon construction and exact input ordering are defined in Section 3.5.

#### 7.3 Nullifier

A real input note nullifier MUST be computed as:

```
nullifier = poseidon(NULLIFIER_DOMAIN, nullifierKey, leafIndex_u32, randomness)
```

* `nullifierKey` — a secret scalar known only to the note owner. Required to spend notes and derive encryption keys. Loss of this key means permanent loss of access to the associated shielded funds. Key derivation and storage are implementation-defined.
* `leafIndex_u32` — position in the Merkle tree, as `u32` (not raw Field) to prevent index aliasing double-spends.
* `randomness` — the note's blinding factor.

#### 7.4 Phantom Nullifier

If an input slot is phantom, the circuit MUST use:

```
phantom_nullifier = poseidon(PHANTOM_DOMAIN, nullifierKey, intentNullifier, slotIndex)
```

* `slotIndex` is 0 or 1 (the unused input slot).
* `PHANTOM_DOMAIN` prevents collision with real nullifiers.
* `nullifierKey` is the spender's secret — because it is private, an observer MUST NOT be able to distinguish phantom nullifiers from real ones.
* `intentNullifier` (which incorporates `chainId`) provides per-transaction and per-chain uniqueness, preventing cross-chain phantom nullifier collisions.

The contract MUST treat phantom nullifiers indistinguishably from real nullifiers.

### 8. Labels and Lineage

Every note MUST carry a `label` field — a Poseidon hash that traces the note's lineage back to the original deposit(s). Labels are enforced by the circuit; they cannot be forged.

#### 8.1 Deposit Label

In deposit mode, output labels MUST be derived from the deposit's public inputs:

```
label = poseidon(
  LABEL_DOMAIN,
  executionChainId,
  depositorAddress,
  tokenAddress,
  publicAmountIn,
  intentNullifier
)
```

`publicAmountIn` is the total public deposit amount, not individual output note amounts.

`executionChainId` (= `block.chainid`) prevents cross-chain label collisions. `intentNullifier` is unique per transaction and known at proof generation time. Because all inputs are public, anyone can compute a deposit label.

The deposit `intentNullifier` depends on a nonce chosen by the RPC rather than signed by the user. Deposit labels are therefore RPC-dependent — two RPCs serving the same deposit would produce different labels. ASPs MUST track deposit labels using the `intentNullifier` value from on-chain public inputs, not by predicting it. Uniqueness is enforced by the contract's intent nullifier set, not by a signature.

#### 8.2 Transfer Label Propagation

* **Single origin**: if both real input notes share the same label, output notes MUST inherit that label unchanged.
* **Mixed origins**: if the two real input notes have different labels, output notes MUST use a commutative merge:

```
label = poseidon(LABEL_MERGE_DOMAIN, min(labelA, labelB), max(labelA, labelB))
```

The merge is commutative — the same pair of labels always produces the same merged label regardless of which input slot they occupy. `LABEL_MERGE_DOMAIN` is domain-separated from `LABEL_DOMAIN`. A merge creates a new label — proof of innocence must handle the full label tree, not just a single hop.

* **Phantom input**: if one input slot is phantom (`isPhantom == 1`), its label MUST be ignored. Output labels inherit the real input's label — no merge occurs. If both inputs are phantom (deposit mode), output labels are the freshly derived deposit label. The circuit MUST enforce these rules: phantom slots contribute no label to the merge logic.

#### 8.3 Label Ancestry in Encrypted Payloads

For mixed-origin notes, the encrypted note payload MUST include the two parent labels that were merged to produce the output label. The circuit MUST include parent labels in the encrypted note plaintext — they are bound by `encryptedNotesHash`.

When a merge occurs, the plaintext MUST contain `(parentLabelA, parentLabelB)` sorted canonically; the circuit MUST verify these match the actual input labels used. For single-origin notes, the plaintext MUST include `(label, 0)`.

A malicious sender cannot provide false ancestry because the circuit binds the parent labels to the ciphertext hash. Wallet software accumulates these into a local label DAG: each merged label maps to its two children, and deposit labels are leaves.

#### 8.4 Ancestry Transfer at Spend Time

When a sender transfers a merged-label note, the recipient receives only the immediate parent labels in the encrypted payload. For deep ancestry (parents that are themselves merges), the sender MUST provide the full label DAG to the recipient — either embedded in an extended ciphertext payload or via an out-of-band channel.

Without the full DAG, the recipient cannot produce proof-of-innocence proofs for the note. Wallet software MUST track and forward complete ancestry when spending merged-label notes.

In practice, most notes have shallow label DAGs. A user who deposits and transfers without mixing origins has a single deposit label (depth 0). A merge occurs only when two notes with different deposit lineages are spent together, producing depth 1. Repeated mixed-origin merges deepen the DAG, but counterparties requiring proof of innocence create market pressure to keep ancestry shallow — notes with deep or incomplete DAGs are harder to spend. Typical usage patterns (deposit, transfer, withdraw) produce DAGs of depth 0–2.

A future version SHOULD replace hash-merge labels with an accumulator-based scheme (e.g., RSA or bilinear accumulators) where ancestry witnesses are constant-size and self-contained, eliminating the DAG transfer requirement entirely.

### 9. Registries

#### 9.1 User Registry

The privacy pool MUST maintain a Poseidon Merkle tree mapping:

```
address → (viewingPubKeyX, viewingPubKeyY, nullifierKeyHash)
```

The viewing public key is a Grumpkin curve point represented as two BN254 field elements `(viewingPubKeyX, viewingPubKeyY)`. The tree has its own root history buffer (size RECOMMENDED: >= 500).

Registration is REQUIRED before any pool operation that creates notes owned by an address. The circuit enforces that the depositor's or recipient's `nullifierKeyHash` matches a registry Merkle proof — an unregistered address cannot receive notes. Registration is a one-time operation per address (separate transaction via `register` or the delegated `registerFor` flow). Withdrawal recipients (`publicRecipient`) do not need to be registered — withdrawals send to any Ethereum address.

#### 9.2 Registration Methods

The contract MUST provide:

* `register(viewingPubKeyX, viewingPubKeyY, nullifierKeyHash)` — callable by `msg.sender`. MUST revert if the address is already registered.
* `registerFor(address user, viewingPubKeyX, viewingPubKeyY, nullifierKeyHash, userNonce, signature)` — using an [EIP-712](./eip-712.md) signature. The signature MUST commit to the address, viewing public key, nullifier key hash, and a per-user registration nonce. MUST revert if the address is already registered.

Both methods MUST validate that the viewing public key `(viewingPubKeyX, viewingPubKeyY)` is a valid Grumpkin curve point: coordinates are canonical BN254 field elements (`< p`), the point is on the curve, and the point is not the identity. Grumpkin is cofactor-1, so no subgroup check is needed.

The contract MUST maintain a per-user `registrationNonce` that increments on each successful registration and is included in the signed payload to prevent replay of old signatures.

The EIP-712 domain is `{ name: "PrivacyPool", version: "1", chainId: block.chainid, verifyingContract: PRIVACY_POOL_ADDRESS }`. The typed struct is `Register(address user, uint256 viewingPubKeyX, uint256 viewingPubKeyY, uint256 nullifierKeyHash, uint256 nonce)`. The contract MUST verify the signature, require `nonce == registrationNonce[user]`, and increment `registrationNonce[user]` on success.

#### 9.3 Key Immutability (v0)

In v0, all registry entries are immutable after registration. `nullifierKeyHash` and `viewingPubKey` MUST NOT be changed after registration.

* `nullifierKeyHash` is embedded in every note's commitment — rotating it would make existing notes unspendable.
* `viewingPubKey` immutability avoids stale-key ambiguity in the write-once registry tree: old keys remain provable forever, and rotation would create windows where senders encrypt to keys the owner no longer controls.

If any key is compromised, the user MUST register a new Ethereum address and transfer funds from the compromised address to the new one.

A future fork MAY introduce key rotation with keyed/indexed Merkle trees.

#### 9.4 Issuer Registry

The contract MUST maintain a sparse Poseidon Merkle tree for the issuer registry. Each leaf is keyed by `tokenAddress` and contains `(issuerPubKeyX, issuerPubKeyY, issuerEpoch)`. Unregistered tokens have the default leaf value `(0, 0, 0)`. `registerIssuer` updates the leaf at the given token address and recomputes the root. Tree depth and key derivation are TBD.

The tree MUST have its own root history buffer (size RECOMMENDED: >= 500).

* `issuerEpoch == 0` indicates no issuer key registered (dummy ciphertext mode).
* `issuerEpoch == 1` indicates an issuer key has been registered.
* In v0, `issuerEpoch` is constrained to `{0, 1}` — no key rotation. The field is preserved for future rotation support without migration.

The contract MUST provide:

```solidity
function registerIssuer(
    address tokenAddress,
    uint256 issuerPubKeyX,
    uint256 issuerPubKeyY
) external
```

* MUST reject `tokenAddress == address(0)`.
* MUST issue a `STATICCALL` to `privacyIssuerAuthority()` on `tokenAddress` with a gas stipend of 30,000. This call resolves the issuer authority — the sole address authorized to register an issuer key for that token. If the call reverts, runs out of gas, or returns unexpected data, no issuer key can be registered and the token operates in fully private (dummy ciphertext) mode. On success, MUST require the returned authority is nonzero and `msg.sender` equals the returned address.
* MUST validate the issuer public key is a valid Grumpkin curve point: coordinates are canonical BN254 field elements (`< p`), the point is on the curve, and the point is not the identity.
* Sets `issuerEpoch = 1` on registration.
* MUST revert if the token already has a registered issuer key (immutable in v0).

#### 9.5 Issuer Visibility Scope

Issuer visibility is scoped by the circuit (Section 10.11): the issuer registry is keyed by `tokenAddress`, so the circuit only encrypts to an issuer's key when the note's token matches their registered address. An issuer can only decrypt ciphertexts for their own token. Tokens without a registered issuer key produce dummy ciphertexts that no party can decrypt.

Issuer visibility is eventual, not immediate. Because provers can prove against any root in the issuer registry's root history buffer, a newly registered issuer key does not take effect until all older roots expire from the buffer. Roots expire after N subsequent issuer registry updates (not N pool transactions), so if few tokens register issuers, pre-registration roots may remain valid for an extended period. This is a deliberate tradeoff: requiring latest-only roots would provide immediate visibility but invalidate in-flight proofs on every registration.

### 10. Circuit Requirements

This EIP specifies a proof system (Circuit A) that verifies ECDSA authorization and registry membership. Implementations MAY use one or more circuits; all circuits MUST share the same public-input interface (Section 11).

#### 10.1 Authorization

The circuit MUST use `depositorAddress` (a public input) to determine the operation mode. The public-input constraints for each mode (amount directions, phantom/dummy slot requirements) are defined in Section 6. This section specifies the additional circuit-level enforcement per mode.

**Deposit mode** (`depositorAddress != 0`):

* ECDSA verification MUST be skipped. Authorization comes from `msg.sender` on-chain (the contract verifies `depositorAddress == msg.sender`).
* Output notes MUST be owned by `depositorAddress`.

**Transfer mode** (`depositorAddress == 0`, chain ID = `TRANSFER_CHAIN_ID(E)`):

* The circuit MUST verify the ECDSA signature of the intent tx and recover the signer's Ethereum address.
* The circuit MUST extract recipient, amount, and token from the intent tx structure: for ETH, `to` is the recipient and `value` is the amount; for ERC-20, `to` is the token address, and `transfer(recipient, amount)` is decoded from calldata.
* Recipient MUST match the output note owner.
* `recipientNote.amount == intentAmount`.
* `changeNote.amount == sum(inputs) - intentAmount` (or change note is dummy if exact).
* Token from the intent tx MUST match all note token addresses (enforced privately).
* The intent tx nonce MUST be verified consistent with `intentNullifier`.

**Withdrawal mode** (`depositorAddress == 0`, chain ID = `WITHDRAWAL_CHAIN_ID(E)`):

* Same ECDSA verification as transfer mode.
* `publicRecipient == intentRecipient`.
* `publicAmountOut == intentAmount`.
* Token MUST match `publicTokenAddress`.

The chain ID is committed in the ECDSA signature, so a valid signature on a transfer intent cannot be accepted as authorization for a withdrawal or vice versa.

#### 10.2 Note Ownership and Membership

For each input slot:

* If `isPhantom == 0` (real input): the circuit MUST prove Merkle membership in `merkleRoot`. The commitment MUST include the signer's address, so only notes owned by the signer match.
* If `isPhantom == 1` (phantom input): membership MUST be skipped. The circuit MUST enforce `nullifier = poseidon(PHANTOM_DOMAIN, nullifierKey, intentNullifier, slotIndex)` and `amount = 0`.

`isPhantom` MUST be constrained to 0 or 1.

#### 10.3 Nullifier-Key Binding

For real input slots, the circuit MUST enforce:

```
poseidon(NK_DOMAIN, nullifierKey) == note.nullifierKeyHash
```

This binds the nullifier key to the key hash committed in the note.

For phantom input slots, the nullifier-key binding MUST be skipped.

In deposit mode (both inputs phantom), the circuit MUST still enforce that `poseidon(NK_DOMAIN, nullifierKey) == registryNullifierKeyHash(depositorAddress)`, where `registryNullifierKeyHash` is the depositor's registered nullifier key hash proven via the user registry Merkle proof. This ensures a single valid set of output commitments exists for each deposit intent, preventing an untrusted RPC from choosing an arbitrary `nullifierKey`.

#### 10.4 Value Conservation

The circuit MUST enforce:

```
sum(input_amounts) + publicAmountIn == sum(output_amounts) + publicAmountOut
```

Both sides MUST include range checks to prevent overflow. `publicAmountIn` and `publicAmountOut` are public inputs bound by this constraint.

#### 10.5 Output Well-Formedness and Determinism

For each output slot, per-slot `isDummy` flag (constrained to 0 or 1):

* If `isDummy == 0` (real output): the output commitment MUST be correctly formed for its owner and token. `nullifierKeyHash` MUST match the recipient's registry-proven key hash (recipient note) or the signer's own key hash (change note).
* If `isDummy == 1` (dummy output):
    * `amount` MUST equal 0.
    * `ownerAddress` MUST equal 0.
    * `tokenAddress` MUST equal 0.
    * `label` MUST equal 0.
    * `nullifierKeyHash` MUST equal `DUMMY_NK_HASH`.
    * The `amount == 0` constraint prevents value extraction even if a preimage for `DUMMY_NK_HASH` were found.
    * **Dummy ciphertext derivation** (9 field elements per note):
        * `dummyScalar = poseidon(nullifierKey, intentNullifier, slotIndex, DUMMY_CIPHER_DOMAIN)`
        * `D = G * dummyScalar` (fixed-base Grumpkin scalar multiplication)
        * `dummy_cipher_0 = D.x`, `dummy_cipher_1 = D.y`
        * `dummy_cipher_i = poseidon(nullifierKey, intentNullifier, slotIndex, i, DUMMY_CIPHER_DOMAIN)` for `i` in `{2, ..., 8}`
        * The first two elements form a valid Grumpkin point, matching the ephemeral point layout of real ciphertexts. All fields are deterministic, leaving no discretion over dummy commitments or ciphertexts.

Output note randomness MUST be deterministically derived:

```
randomness = poseidon(RANDOMNESS_DOMAIN, nullifierKey, intentNullifier, slotIndex)
```

Given a fixed set of spent notes, this ensures a single valid set of output commitments exists per intent. No alternative valid proof for the same signed intent and nullifiers can produce different output commitments.

#### 10.6 Registry Binding

Gated by operation type:

* **Transfer**: the circuit MUST prove the recipient address has a registry entry (for output note encryption and `nullifierKeyHash`). The circuit MUST also prove the sender (ECDSA signer) has a registry entry, extracting the sender's viewing public key for change note encryption.
* **Withdrawal**: the circuit MUST prove the sender has a registry entry, extracting the sender's viewing public key for output note encryption. Recipient binding is skipped — the recipient receives unshielded funds via `publicRecipient`. Any address can be a withdrawal destination; compliance is handled by proof of innocence at the counterparty level, not by registry membership.
* **Deposit**: the circuit MUST prove `depositorAddress` has a registry entry, extracting the depositor's viewing public key and nullifier key hash for output note encryption and `nullifierKeyHash`.

#### 10.7 Encryption Correctness

Gated by operation type:

* **Transfer**: encrypts the recipient note to the recipient's registry-proven key and the change note to the sender's key. Checks against `encryptedNotesHash`.
* **Withdrawal**: only the change note (if any) is a real output — it is encrypted to the sender's registry-proven key. If the entire input value is withdrawn (`publicAmountOut` equals total input), both output slots are dummy. Checks against `encryptedNotesHash`.
* **Deposit**: encrypts output notes to the depositor's registry-proven key. Checks against `encryptedNotesHash`.

#### 10.7.1 Encryption Scheme

Note encryption uses ECDH over Grumpkin with a Poseidon-based KDF. All ephemeral scalars are deterministically derived from `nullifierKey` and `intentNullifier`, ensuring a single valid ciphertext per intent.

The plaintext per note is: `(amount, ownerAddress, randomness, tokenAddress, label, parentLabelA, parentLabelB)` — 7 field elements. For single-origin notes, `parentLabelA = label` and `parentLabelB = 0`.

**Recipient notes (ECDH mode):**

1. `encSeed = poseidon(nullifierKey, ENC_KEY_DOMAIN)`
2. `eph = poseidon(encSeed, recipientPubKey.x, recipientPubKey.y, intentNullifier, slotIndex, randomness, EPHEMERAL_DOMAIN)`
3. `E = G * eph`
4. `ss = poseidon(ECDH(eph, recipientPubKey).x, SHARED_DOMAIN)`
5. `key_i = poseidon(ss, i, KEYSTREAM_DOMAIN)` for `i` in `{0, ..., 6}`
6. `enc_i = plaintext_i + key_i` (field addition)

Ciphertext: `(E.x, E.y, enc[0..6])` — 9 field elements per note.

**Change notes (self-encryption):**

1. `selfScalar = poseidon(encSeed, intentNullifier, slotIndex, SELF_EPHEMERAL_DOMAIN)`
2. `S = G * selfScalar`
3. `selfSecret = poseidon(encSeed, S.x, SELF_SECRET_DOMAIN)`
4. Keystream and encryption as above.

Ciphertext format is identical (9 field elements). Self-encryption does not use the recipient's public key.

**Ciphertext hash:** `encryptedNotesHash = poseidon(hash_9(ciphertext_0), hash_9(ciphertext_1))`. The contract recomputes this from `encryptedNoteData` and verifies it matches the public input.

The following domain separators are derived using the procedure in Section 3.3: `ENC_KEY_DOMAIN` (`privacy_pool.enc_key`), `EPHEMERAL_DOMAIN` (`privacy_pool.ephemeral`), `KEYSTREAM_DOMAIN` (`privacy_pool.keystream`), `SHARED_DOMAIN` (`privacy_pool.shared`), `SELF_EPHEMERAL_DOMAIN` (`privacy_pool.self_ephemeral`), `SELF_SECRET_DOMAIN` (`privacy_pool.self_secret`).

#### 10.8 Intent Nullifier

The circuit MUST enforce:

```
intentNullifier = poseidon(INTENT_DOMAIN, nullifierKey, intentChainId, nonce)
```

* In transfer/withdrawal modes, `intentChainId` and `nonce` MUST be parsed from the intent tx. `intentChainId` is the chain ID field from the signed type-2 transaction (i.e., `TRANSFER_CHAIN_ID(E)` or `WITHDRAWAL_CHAIN_ID(E)`). The circuit MUST also extract `validUntilSeconds` from the upper 32 bits of the nonce and expose it as a public input.
* In deposit mode, `intentChainId` MUST be the execution chain ID (`block.chainid`), and `nonce` is a private random value provided by the RPC. `validUntilSeconds` MUST be 0.

#### 10.9 Label Propagation

The circuit MUST enforce output labels are correctly derived from input labels per the rules in Section 8:

* Deposit: label derived from public inputs per Section 8.1.
* Single-origin transfer: label inherited unchanged.
* Mixed-origin transfer: commutative merge per Section 8.2.
* Phantom inputs: label ignored per Section 8.2.

The circuit MUST include parent labels in the encrypted note plaintext, bound by `encryptedNotesHash`, per Section 8.3.

#### 10.10 Token Consistency

All real input and output notes MUST use the same `tokenAddress`.

* For deposits and withdrawals: `tokenAddress == publicTokenAddress`. This binds the notes' private token to the public input that drives fund movement.
* For transfers: `publicTokenAddress == 0`. Token consistency is enforced privately within the circuit.

#### 10.11 Issuer Key Check

The circuit MUST prove `(tokenAddress, issuerPubKey, issuerEpoch)` membership in the issuer registry against `issuerRegistryRoot` for all operations.

* If `issuerEpoch > 0`: encrypt the issuer plaintext to `issuerPubKey` as specified below. Checks against `issuerCiphertextHash`.
* If `issuerEpoch == 0`: produce a dummy ciphertext. Checks against `issuerCiphertextHash`.

**Issuer ciphertext layout.** The issuer plaintext per note is: `(amount, ownerAddress, randomness, tokenAddress, label)` — 5 field elements. Encryption uses the same ECDH/Poseidon-KDF scheme as user-facing encryption (Section 10.7.1) but with the issuer's registry-proven public key as the recipient key. The ephemeral scalar MUST incorporate `issuerEpoch` to bind the ciphertext to the current key epoch:

```
issuerEph = poseidon(encSeed, issuerPubKey.x, issuerPubKey.y, issuerEpoch, intentNullifier, slotIndex, ISSUER_EPHEMERAL_DOMAIN)
```

Keystream: `key_i = poseidon(issuerSharedSecret, i, KEYSTREAM_DOMAIN)` for `i` in `{0, ..., 4}`. Ciphertext per note: `(IE.x, IE.y, enc[0], enc[1], enc[2], enc[3], enc[4])` — 7 field elements.

`issuerCiphertextHash = poseidon(hash_7(issuerCiphertext_0), hash_7(issuerCiphertext_1))`, where `hash_7` is the binary-tree Poseidon over the 7 ciphertext field elements per note. The contract deserializes `issuerCiphertextData` into 14 field elements and recomputes this hash.

**Dummy ciphertexts.** When `issuerEpoch == 0`, the circuit MUST produce a dummy ciphertext of the same size (7 field elements per note, 14 total). Dummy ciphertext values MUST be deterministically derived as follows per note: derive a deterministic scalar `dummyScalar = poseidon(nullifierKey, intentNullifier, slotIndex, ISSUER_DUMMY_DOMAIN)`, compute the on-curve Grumpkin point `D = G * dummyScalar` (fixed-base scalar multiplication), and set `dummy_0 = D.x`, `dummy_1 = D.y`, `dummy_i = poseidon(nullifierKey, intentNullifier, slotIndex, i, ISSUER_DUMMY_DOMAIN)` for `i` in `{2, ..., 6}`. The first two elements form a valid Grumpkin point, matching the ephemeral point layout of real issuer ciphertexts. Without the decryption key, observers MUST NOT be able to distinguish real from dummy. `issuerCiphertextHash` MUST always be nonzero.

`ISSUER_EPHEMERAL_DOMAIN` and `ISSUER_DUMMY_DOMAIN` are encryption-specific domain separators derived using the same procedure as Section 3.3:

* `ISSUER_EPHEMERAL_DOMAIN` — `keccak256("privacy_pool.issuer_ephemeral") mod p`
* `ISSUER_DUMMY_DOMAIN` — `keccak256("privacy_pool.issuer_dummy") mod p`

### 11. Public Inputs

All proofs verified by the pool MUST share the following public-input vector:

```
merkleRoot            // commitment tree root the proof is against
nullifier0            // first input note nullifier
nullifier1            // second input note nullifier (phantom if unused)
commitment0           // new note (recipient or self)
commitment1           // new note (change to sender, or dummy if unused)
publicAmountIn        // tokens entering the shielded state (deposit), 0 otherwise
publicAmountOut       // tokens leaving the shielded state (withdrawal), 0 otherwise
publicRecipient       // withdrawal destination address, 0 otherwise
publicTokenAddress    // token being transacted (0 for ETH); 0 for transfers
depositorAddress      // depositor's Ethereum address (deposit), 0 for transfers/withdrawals
encryptedNotesHash    // hash of encrypted note ciphertexts
intentNullifier       // replay protection
registryRoot          // root of user registry (always nonzero)
issuerRegistryRoot    // root of issuer key registry (always nonzero)
validUntilSeconds     // intent expiry timestamp (transfers/withdrawals); 0 for deposits
issuerCiphertextHash  // hash of issuer ciphertext (always nonzero; dummy if no issuer key)
executionChainId      // block.chainid of the target execution chain
```

`publicAmountIn` and `publicAmountOut` apply to the token specified by `publicTokenAddress`. For transfers, all three are zero.

`registryRoot` and `issuerRegistryRoot` MUST always be nonzero.

`executionChainId` is verified by the contract against `block.chainid` (Section 4.4, step 2). This provides defense-in-depth against cross-chain proof replay, complementing the per-chain intent chain IDs.

#### 11.1 Canonical Field Element Validation

The verifier MUST reject any public input that is not a canonical field element (i.e., `>= p`, the SNARK field modulus). Without this, `x` and `x + p` would verify identically but map to different `uint256` keys in contract storage, enabling nullifier reuse or intent replay.

### 12. Precompile

#### 12.1 Proof Verification

A proof verification precompile MUST verify proofs for the circuit family identified by `circuitId` (see Section 3.7). The precompile routes to the correct verification key based on the circuit identifier.

* Address: `PROOF_VERIFY_PRECOMPILE_ADDRESS` (TBD)
* Input: `abi.encode(uint256 circuitId, bytes proof, uint256[17] publicInputs)`.
* Output: 32 bytes — `uint256(1)` on success, empty on failure (precompile failure).
* Gas: TBD (MUST be set before advancing to Review).
* Error: unknown `circuitId`, malformed input, or verification failure returns empty.

A Solidity verifier fallback is possible for the canonical contract, but a precompile lets other pools and wrapper contracts verify proofs from this scheme without deploying their own verifiers or tracking circuit upgrades.

### 13. Proof of Innocence

Users can prove their funds descend from deposits not associated with sanctioned addresses, without revealing which deposits are theirs. Proof of innocence is NOT enforced by the base contract — it is a separate proof verified by counterparties. A user who wants unconditional privacy simply does not generate a proof of innocence.

#### 13.1 Association Set Providers

ASPs publish Merkle roots over sets of deposit labels they consider clean. Anyone can run an ASP. Different counterparties can trust different ASPs.

#### 13.2 The Proof

A user proves their note's label ancestry resolves entirely to deposit labels that are members of the ASP's clean set:

* **Single-origin notes** (label inherited from one deposit): a simple Merkle membership proof against the ASP root.
* **Mixed-origin notes** (label derived from merging): the user MUST prove membership for every leaf in their label tree — every original deposit that contributed to the note's lineage. The wallet traverses from the note's label down to deposit leaves and proves membership for each.

#### 13.3 Binding to the Spend

The PoI proof binds to the spend via nullifiers, which are public inputs of the spend transaction. The PoI prover (the note owner) knows the full note opening, including the label. The PoI circuit re-proves that a note producing the given nullifier exists in the commitment tree, extracts its label, and proves that label's ancestry resolves to clean deposits in the ASP's set.

No additional public inputs are needed on the spend proof — the nullifier uniquely identifies the spent note and serves as the binding point. This prevents replay: a PoI proof is only valid for the specific nullifier it was generated against.

#### 13.4 Multi-Input Spends

The PoI verifier MUST require a PoI proof for both nullifiers — it cannot distinguish phantom from real (by design). The PoI circuit handles each nullifier in one of two modes:

* **Real mode**: proves a note producing that nullifier exists in the commitment tree, extracts its label, and proves the label's ancestry resolves to clean deposits in the ASP's set.
* **Phantom mode**: proves the nullifier matches the phantom formula `poseidon(PHANTOM_DOMAIN, nullifierKey, intentNullifier, slotIndex)`, without revealing which mode was used.

The PoI proof MUST NOT leak whether an input is phantom.

#### 13.5 Limitations (v0)

PoI in v0 is best-effort: notes with incomplete ancestry (e.g., from a sender who withheld the label DAG) simply cannot produce PoI proofs. Counterparties requiring PoI MAY reject such notes. A future accumulator-based scheme (see Section 8.4) SHOULD make ancestry self-contained and eliminate this limitation.

### 14. Threat Model

The system supports two proving modes. In **local proving** mode, the user generates proofs on their own device and submits pool transactions through any relayer. In **RPC proving** mode, the user delegates proof generation to a Privacy RPC, which learns transfer details but cannot steal funds or forge proofs.

|  | Chain observer | Relayer | Privacy RPC | Local proving |
|---|---|---|---|---|
| Tx occurs | yes | yes | yes | yes |
| Token | no | no | yes | no |
| Amount | no | no | yes | no |
| Sender | no | no | yes | no |
| Recipient | no | no | yes | no |
| Which notes spent | no | no | yes | no |
| Note balances | no | no | yes | no |

The "no" entries for amount, sender, recipient, and token apply to **shielded transfers only**. Deposits are fully public: depositor address, amount, and token are all visible on-chain. Withdrawals expose `publicAmountOut`, `publicRecipient`, and token on-chain. This is by design — deposits pull funds from `msg.sender` and withdrawals push funds to a named address; both require public visibility.

**Local proving** provides full privacy: no party other than the user learns transfer details. The proof is generated locally and submitted via any relayer. The relayer sees only the on-chain public inputs — the same as any chain observer.

**RPC proving** trades metadata privacy for convenience. The RPC learns transfer details (token, amount, sender, recipient, note selection) but cannot: steal funds (the intent signature authorizes only the user's specified operation), forge proofs for unauthorized operations, redirect payments, or produce alternative valid proofs for the same intent (deterministic outputs and encryption). RPC proving reduces the audience from the entire world to a single party — the RPC — and works with every existing wallet without modification.

### 15. App-Level Extensions

Apps MAY deploy wrapper contracts that impose additional requirements before or after a privacy pool interaction:

* **Proof of innocence**: a receiving contract or counterparty verifies a PoI proof against an ASP root before accepting a withdrawal.
* **Compliance**: wrapper contracts can enforce KYC gating, fee collection, or other restrictions at the withdrawal destination.
* **Custom policy**: any logic a contract wants to run conditional on a privacy pool call completing.

These extensions operate on top of the canonical contract without fragmenting the anonymity set.

### 16. Future Auth Methods

Each new auth method in the v0 2-input/2-output family is a new circuit with the same public-input interface and a new `circuitId` (see Section 3.7); changing input/output arity requires a new public-input interface and a new `transact` ABI version, introduced by hard fork. Adding a circuit requires replacing the system contract code via hard fork.

* **Circuit C — P-256 (passkeys/Face ID):** Same as Circuit A but verifies P-256 instead of secp256k1 ECDSA. A different intent format (e.g., EIP-712 typed data signed with P-256, or a WebAuthn assertion) would be required.
* **Circuit D — Post-quantum:** Same interface, different signature verification.

All circuits share the same note tree, same notes, same anonymity set.

### 17. Future: Stealth Addresses

The registry can be upgraded from static viewing keys to [ERC-5564](./eip-5564.md) style meta-addresses. The sender derives a one-time key per transaction from the meta-address. This requires a new circuit (same interface) that verifies the stealth derivation instead of a simple registry lookup. Better recipient privacy, same note format, same storage layout, same public inputs. Added by hard fork.

### 18. Chain Specifics

* Each network derives its own intent chain IDs from `block.chainid` per the formula in Section 3.1. Testnets, devnets, and L2s each produce distinct intent chain IDs automatically.
* The system contract and precompiles MUST be deployed at the same addresses across all networks, unless explicitly overridden by the network's genesis specification.
* Clients MUST reject intents whose parsed intent chain ID does not match the expected `TRANSFER_CHAIN_ID(block.chainid)` or `WITHDRAWAL_CHAIN_ID(block.chainid)` for the current execution chain and operation type.
* Clients MUST treat the system contract address as reserved.

## Rationale

* **System contract over native consensus integration** limits failure scope. A bug in the ZK scheme can compromise funds held in the pool — via theft or permanent lock — but does not alter consensus rules, the validator set, or ETH supply semantics. Native integration (e.g., [EIP-7503](./eip-7503.md)) can expose the protocol itself to ZK-scheme failures, including unbounded minting; the system contract pattern (EIP-4788, EIP-2935) scopes failures to pool-held funds. The ZK-scheme risk to depositors is equivalent to existing app-level pools, minus governance risk.
* **Proof verification precompile** — verification dominates on-chain cost; a precompile makes it gas-feasible. The `circuitId` parameter lets new proof systems (Section 16) be added by hard fork without changing the contract interface — the precompile routes to the correct verification key based on the identifier.
* **Type-2 transaction format over EIP-712** trades circuit efficiency (RLP parsing and keccak are significant constraint contributors) for seamless UX. When connected to the Privacy RPC, the wallet constructs and signs a normal transaction on what it sees as a standard EVM network — no typed-data signing prompt, no special wallet behavior. EIP-712 would reduce circuit complexity but surface a distinct signing modal, breaking the transparent RPC experience. A lighter EIP-712-based circuit (same public-input interface) can be added by hard fork if wallets adopt native privacy support.
* **BN254 and Poseidon** are pragmatic choices for the initial deployment — they have the deepest tooling support (Noir, circom, [EIP-197](./eip-197.md) pairing precompile) and ship with existing infrastructure. The `circuitId` abstraction and hard-fork upgrade model mean the protocol can migrate to other curves or proof systems (e.g., BLS12-381, lattice-based) in a future fork without changing the contract interface or note format.

### Feasibility Analysis

This subsection is non-normative.

Measured on a reference transfer circuit (depth-32 commitment tree; simplified feature set) in a local Osaka environment:

* Transfer gas: ~6.8M
  * HONK verification: ~3.97M (58%)
  * Merkle Poseidon hashing: ~1.93M (28%)
  * Remaining execution (ciphertext hashing, storage, calldata, events): ~0.89M (13%)
* Circuit size: 97,727 ACIR opcodes
* Proving time: ~14s (WASM prover, 16 threads, desktop hardware)

Proof verification dominates on-chain cost (58%). Section 12 specifies a proof verification precompile; a future Poseidon hashing precompile (e.g., [EIP-5988](./eip-5988.md)) would further reduce costs but is not required. Exact post-precompile gas depends on final precompile pricing and is intentionally left out of this draft.

## Backwards Compatibility

This EIP introduces new functionality via a system contract and precompiles and requires a network upgrade (hard fork). It does not change the meaning of existing transactions or contracts. No backward compatibility issues are known.

## Test Cases

TBD.

## Security Considerations

### Intent Replay on Real Chains

Intent chain IDs are derived from `block.chainid` via keccak256, making collisions with real chain IDs negligible. Per-chain derivation also prevents cross-chain intent replay between different privacy pool deployments. The `executionChainId` public input provides an additional contract-level check against `block.chainid`. Implementers SHOULD include wallet-side UI labeling that clearly indicates "Privacy Intent Network" to reduce phishing risk.

### Malicious RPC/Relayer

Expiry-limited intents (with `MAX_INTENT_LIFETIME` upper bound) constrain the execution window, though not the signing-to-execution delay (see Section 5.4). Users can invalidate a deferred intent by spending the same notes. Deterministic output commitments and deterministic encryption randomness eliminate covert channels — the RPC cannot produce alternative valid proofs for the same signed intent with different output commitments or embed data in ciphertexts.

However, in "RPC proving" mode, the RPC learns token, amount, sender, recipient, which notes are spent, and note balances. Users requiring privacy from the RPC MUST use local proving (expert mode).

### Key Compromise

All registry keys are immutable in v0 (Section 9.3). A compromised nullifier key or viewing key requires migration to a new Ethereum address and transferring all funds.

### DoS via Root History

Limited root histories allow bounded proof staleness but can cause proof failures under prolonged congestion. Root history sizes SHOULD be chosen conservatively (>= 500).

### Precompile Correctness

The verifier precompile is consensus-critical. Any bugs are chain-splitting risks. Implementations MUST be extensively tested and audited.

### Token Incompatibility

Fee-on-transfer tokens are rejected by the deposit-side balance-delta check (Section 4.4, step 13). Rebasing tokens are not reliably detectable. Tokens that charge fees only on outbound `transfer` (not `transferFrom`) pass the deposit check but deliver less than `publicAmountOut` on withdrawal. Such tokens MUST NOT be deposited.

### Metadata Leakage

Deposits and withdrawals are public by design. Shielded transfer token and amount are private, but network-level metadata (timing, gas patterns, relayer behavior, transaction size) can still leak information. The constant 2-input/2-output shape with phantom/dummy slots mitigates some structural metadata leakage.

### State Growth

Each transaction writes ~4 permanent storage slots (2 nullifiers, 1 intent nullifier, root history entry) plus 2 tree insertions. Nullifiers are not pruneable. This is standard for privacy pools but enshrinement makes it protocol-level state. Future mitigation via stateless clients or accumulator-based nullifier sets.

### Encryption Authentication

The ECDH/Poseidon-KDF encryption scheme used for note and issuer ciphertexts is not standalone-authenticated. Ciphertext integrity depends on the ZK proof binding ciphertexts to `encryptedNotesHash` and `issuerCiphertextHash` — without a valid proof, a ciphertext could be replaced or tampered with. The encryption scheme provides IND-CPA-level confidentiality; authenticity is provided by the proof system, not the encryption primitive.

### Issuer Blacklisting Risk

Permissioned token issuers (e.g., stablecoin issuers with blacklist functionality) could blacklist the pool contract address, freezing all tokens of that type held in the pool. The issuer viewing key registry (Section 9.4) is designed to reduce the incentive for this by giving issuers scoped visibility over their own token's movements, but visibility does not technically prevent a blacklist action. Issuers who do not register a viewing key have no visibility; tokens without a registered issuer operate in fully private mode. Users depositing blacklistable tokens should understand that the issuer retains the ability to freeze the pool contract's token balance regardless of whether an issuer key is registered.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
