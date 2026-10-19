# EIP-8437 transport cases

## Fixtures and scope

[The checker](./check_vectors.py) runs the A, Q and R cases below on decoded message values, represented as Python lists, byte strings and integer scalars. It also checks fixed RLP outputs. It is not an RLP decoder, proof verifier or client implementation. A transport check passing does not authorize admission or relay without full EIP-8288 validation.

- [Announcement vectors](./announcement-vectors.json) use raw bytes `body[i] = i % 251`. These are hash/length fixtures, not valid wrapper bodies. `announcement_rlp` encodes one `[length, hash]` entry.
- [Wrapper vectors](./wrapper-vectors.json) contain two synthetic RLP lists, `W0` and `W1`, obtained by decoding the `mode0.body` and `mode1.body` hex strings. Their witnesses are placeholders. `Hi = keccak256(RLP(Wi))` and `Li = len(RLP(Wi))`. Each `response_rlp` encodes `[7, [Wi]]`, with the wrapper embedded as a list.
- `K(n)` is the 32-byte big-endian encoding of integer `n`. `M = 2,097,152` bytes. Lists shown below are canonically RLP-encoded on the wire.

Run with Python 3.9+ and `pycryptodome` installed:

```sh
python3 assets/eip-8437/check_vectors.py
```

## NewProofWrapperHashes (0x16)

| Case | Input | Expected transport result |
| --- | --- | --- |
| A1 | `[[M, K(1)], ..., [M, K(64)]]`; then the same list with `[M, K(65)]` appended | 64 entries pass and encode in 2,435 bytes; 65 fail the count check |
| A2 | `[]`; `[[M, K(2)], [M, K(1)]]`; `[[M, K(1)], [M, K(1)]]` | Empty list fails the count check; descending or repeated hashes fail strict ordering |
| A3 | One entry with length `1`, `M`, `0` or `M + 1` | First two pass the length check; last two fail |
| A4 | `[1, bytes(31)]` or `[1, K(1), empty_bytes]` as the sole entry | Fail hash width or entry field count, respectively |

## GetProofWrappers (0x17)

Assume the recipient announced `K(1)` through `K(65)`.

| Case | Input | Expected transport result |
| --- | --- | --- |
| Q1 | `[2**64 - 1, [K(1), ..., K(64)]]`; then 65 hashes or an empty list | 64 hashes pass and encode in 2,127 bytes; 65 or zero fail the count check |
| Q2 | `[0, [K(2), K(1)]]`; `[7, [K(1), K(1)]]` | Arbitrary request order passes; repeated hashes fail |
| Q3 | `[2**64, [K(1)]]`; `[7, [bytes(31)]]` | Fail request-ID range or hash width, respectively |
| Q4 | `[7, [K(0)]]` | Fail because this wrapper hash was not announced by the recipient |

## ProofWrappers (0x18)

Unless stated otherwise, the pending request is `[7, [H0, H1]]`, and the responding peer announced lengths `L0` and `L1` for those hashes.

| Case | Input | Expected transport result |
| --- | --- | --- |
| R1 | `[7, [W0, W1]]`, `[7, [W0]]`, `[7, [W1]]` or `[7, []]` | Pass matching and ordering; omissions and truncation are permitted |
| R2 | `[8, [W0]]`; `[7, [W0], empty_bytes]` | Fail request-ID correlation or response field count, respectively |
| R3 | `[7, [RLP(W0), RLP(W1)]]`, with each encoded wrapper wrapped in an RLP byte string | Fail: response entries must be embedded lists |
| R4 | `[7, [W1, W0]]` or `[7, [W0, W0]]` | Fail request ordering or uniqueness |
| R5 | Replace W1's proof bytes `aggregate proof` with `aggregate proog`, leaving the requested hash unchanged | Fail content-hash matching |
| R6 | Return W0 while the responding peer's announcement claims length `L0 + 1` | Fail announced-length matching |
| R7 | Request three variants of W1 whose proof bytes are respectively `0x00`, `0x01` and `0x02`, each repeated 1,000,000 times | Each fixture is 1,000,279 bytes. Two form a 2,000,567-byte response; three would take 3,000,846 bytes. Response construction returns the first two; returning all three fails the soft-limit check |

R7 uses distinct synthetic proofs below the companion EIP's provisional proof-size bound. They are not valid proofs, and the response-packing test does not run EIP-8288 validation.

## Client message sequences (not executed by the checker)

These cases require an implementation harness with an active `eth/73` session and a fixed target verifier. Use valid transactions A and B and a valid covering wrapper W from that verifier's fixtures, rather than the synthetic JSON witnesses above. Begin with neither envelopes nor W held. Let `H = keccak256(RLP(W))` and `L = len(RLP(W))`. Local storage and request budgets are sufficient unless stated otherwise.

### S1: Envelopes before the wrapper

1. Receive `Transactions([A, B])`. If retained, both envelopes remain pending; neither transaction is admitted or relayed.
2. Receive `NewProofWrapperHashes([[L, H]])`, request W with ID 7, then receive `ProofWrappers([7, [W]])`.
3. After full wrapper validation, the dependency-proof gate permits admission and relay, subject to normal transaction and pool checks.

### S2: Wrapper before the envelopes

1. Receive W through the same announcement/request/response sequence, with neither envelope present. A proof check may pass, but W remains incomplete and cannot authorize admission, relay or reaggregation.
2. Request `[hash(A), hash(B)]` through GetPooledTransactions. Receive only A: W remains incomplete.
3. Request and receive B. Full wrapper validation reaches the same result as S1 under the same verifier rules.

### S3: Invalid proof with matching transport metadata

Construct Wbad with the same transaction hashes and dependencies as W but an invalid proof. Announce its actual hash and encoded length. Deliver A, B and Wbad. Hash/length matching passes, proof verification fails, and Wbad cannot authorize admission, relay or reaggregation.

### S4: Envelope absent from the pool

Validate W, remove A from the pool while retaining its envelope, and continue offering W. A GetPooledTransactions request for `hash(A)` should still return A under the serving recommendation.

### S5: Transaction announcement metadata

After receiving W, request A through GetPooledTransactions without a transaction announcement. A matching envelope is not rejected for missing announcement metadata. Repeat with the responding peer first announcing `hash(A)` through NewPooledTransactionHashes using an incorrect type or size: the response must fail that metadata comparison. Normal hash and transaction checks apply in both runs.
