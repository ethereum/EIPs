# EIP-8182 — Response to Reviewer Feedback

## Proof system PQ readiness

You write: Why can't we strictly improve the EIP in terms of PQ readiness?

We investigated three options for improving the PQ readiness of the proof system:

1. **Direct STARK proof system.** This gives the cleanest PQ story, but the proof is too large today. The Plonky3 feasibility test produced about 384 KB at the spec parameters and still about 167 KB under the most aggressive tested low-rate configuration. That is over the practical L1 calldata target.
2. **STARK + SNARK wrap.** Wrap a PQ-secure STARK in a thin classical SNARK to collapse the proof to a few hundred bytes. Appeal: everything underneath is PQ; the wrapper is the only classical part, so the PQ fork just removes it. Trade-off: The wrap step takes 5-30 minutes on a top of the line Macbook Pro.
3. **PQ-friendly hash in classical SNARK.** Use BN254 Groth16 today but with Goldilocks-Poseidon2 (non-native), so a future PQ STARK proves the same relation cheaply. Appeal: weaker than wrap (the proof system itself has to change at the fork) but at least the state hash is in PQ-friendly form. Trade-off: 52 GB RAM to prove.

So when we say we cannot “just” make it more PQ-ready, we mean every stronger version moves cost somewhere real: L1 calldata, prover hardware, delegated proving, proof-system complexity, or live classical assumptions.

The current design still takes the low-cost PQ-readiness wins:

* ML-KEM-768 for note delivery, where harvest-now-decrypt-later directly applies;
* no recursive proof dependency;
* a fork-managed pool proof precompile;
* stable state schema and preimage layouts so the future proof-system fork has a defined target.

That is the line we think is worth drawing today: practical local proving now, with the future PQ migration surface made explicit and narrow.

---

## Recursive proofs and intents

We agree with the recursion feedback. The current design removes recursive proofs. A spend now has two independent proofs:

* a fork-managed pool proof verified by the pool proof precompile;
* a user-selected auth proof verified by the user-selected auth verifier contract via `staticcall`.

This change also reduces the requirements for creating proofs.

As you note there is no longer an "intent transaction" enshrined in the protocol. That is, there is no prescribed way for users to express their intent for a private transfer.

However the idea of an intent is still important for making delegated proving safe. If users always generated and submitted their own proofs directly, the protocol could be thinner. But once a wallet can hand proving work to another party, the signer needs a compact object that binds the exact spend fields, output locks, expiry, chain, and auth verifier. That's the role of "intents" in this version of the protocol.

We could remove these as well and require users to generate their own proofs, but in our view that limits the utility of the protocol too much.

## The five deployment concerns

### 1. Which zkSNARK to use

The current proposal chooses Groth16 over BN254 for the pool proof.

Reasons:

* 256-byte proofs;
* low verifier gas;
* mature Circom/Groth16 tooling and native mobile proving through rapidsnark-style provers;
* simple verifier model;
* current reference implementation exists and proves the pool circuit.

The reference implementation currently has a pool circuit at about 223k R1CS constraints. On the M3 Max benchmark, pool proving is about 0.45s with rapidsnark native and about 4s through snarkjs/WASM. For this circuit size, native proving is the mobile path; snarkjs/WASM is useful for desktop/browser validation but has too much memory overhead for typical mobile apps. The trusted setup is an operational cost, but it is tractable for a fixed fork-managed pool circuit.


### 2. Key sizes

Concrete numbers from the reference implementation (worst-case witness, 224K R1CS constraints):

| Artifact | Size |
|---|---|
| Verification key (`pool_vk.bin`, normative, pinned by SHA-256 in spec) | 1.8 KB |
| Proof | 256 bytes (3 G1 + 1 G2 elements) |
| Proving key (`pool_final.zkey`) | 131 MB (snarkjs) / 84 MB (arkworks compressed) |
| Genesis state dump | 83 KB |
| ML-KEM-768 public key per recipient | 1184 bytes |
| ML-KEM-768 ciphertext per emitted note | 1088 bytes |

The 131 MB proving key is the headline number — same order of magnitude as Tornado Cash's ~50 MB, well within phone storage. Native rapidsnark mmaps it and operates at ~330 MB peak RSS while proving.

### 3. Gas costs

Real measurements from the reference implementation:

| Operation | Gas |
|---|---|
| `registerUser` (depth-160 sparse Merkle insert) | 8.8M |
| `registerAuthPolicy` (depth-32 append-only insert) | 1.7M |
| `deposit` (1 commitment insert) | 1.8M |
| `transact` (3 commitment inserts + verifier wiring, mocked verifiers) | 3.6M |
| Pool proof verification (spec-set precompile gas) | 1.0M |
| Auth verifier staticcall (typical Groth16-style) | ~250K |
| **Real `transact` total** | **~4.85M** |

The majority of this gas cost is due to the cost of Poseidon2 hashing (25k gas per permutation). A Poseidon2-BN254 precompile would reduce this cost significantly, but we didn't include it in the spec because even at these gas costs we believe the protocol will still get significant use.

However we are happy to publish that as a companion EIP that EIP-8182 then `requires:` if reviewers think it should block launch.

### 4. Scalable note scanning

The current design uses the standard private-payment pattern: wallets scan emitted output payloads and attempt decryption with their delivery keys. The EIP specifies the delivery-key registry and output payload structure, but it does not try to standardize the full wallet/indexer scanning layer.

Improvements here can be made on the application layer with companion ERCs. Given the complexity of the EIP as a whole we thought it would be best to use standard patterns that are well understood for note discovery.

### 5. New hardware wallet requirements

EIP-8182 does not create any new hardware wallet requirements because hardware wallets are not expected to produce proofs. Instead they will delegate their proving to a more powerful device (either first party or third party).

It works like this:

1) The hardware wallet signs an EIP-712 typed message encoding the intent (amount, recipient, etc)
2) This intent is sent to a prover who generates the proof and submits it on-chain


