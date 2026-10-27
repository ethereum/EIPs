---
title: Batched KZG Point Evaluation via EIP-2537
description: Verify many EIP-4844 blob openings with one pairing check by composing the BLS12-381 G1 MSM and pairing precompiles
author: Marko Lazic (@markolazic01) <markolazic01@gmail.com>, Cristian Conache (@conache) <cconache@gmail.com>
discussions-to: https://ethereum-magicians.org/t/eip-8457-batched-kzg-point-evaluation-via-eip-2537/28534
status: Draft
type: Informational
created: 2026-07-06
requires: 2537, 4844
---

## Abstract

This EIP describes a contract-level technique for verifying `n` Kate-Zaverucha-Goldberg (KZG) opening claims against [EIP-4844](./eip-4844.md) blob commitments with a constant number of precompile calls: two multi-scalar multiplication (MSM) calls to `BLS12_G1MSM` and one `BLS12_PAIRING_CHECK` call from [EIP-2537](./eip-2537.md), instead of `n` calls to the EIP-4844 point evaluation precompile. The `n` claims are folded into a single pairing equation using a Fiat-Shamir random linear combination, so an invalid batch passes with negligible probability. The general case of `n` distinct commitments opened at `n` distinct points is covered, along with the two cheaper shapes that arise in practice: many blobs opened at one shared evaluation point, and one blob opened at many evaluation points. The technique consumes the standard per-opening proofs that existing KZG libraries produce, requires no change to provers and no change to the protocol, and becomes cheaper than the looped precompile from five openings upward, saving roughly two thirds of verification gas at large batch sizes.

## Motivation

Rollups and data-availability contracts that consume blobs commonly need to check several KZG openings in one transaction: one opening per blob when a settlement transaction carries multiple blobs, or several openings of one blob when a proof system samples a commitment at more than one point. The established pattern is to call the EIP-4844 point evaluation precompile once per opening. Each call costs `POINT_EVALUATION_PRECOMPILE_GAS = 50000` plus call and calldata overhead, so a settlement that verifies six blobs already spends more than 300,000 gas on verification alone, and the cost grows linearly with the number of openings. As the per-block blob limit rises, the number of openings a single settlement can be asked to verify rises with it. Over a 90-day window, the settlement transactions of one production rollup each verified six blobs this way, 4,102 transactions in total; the technique described here would have saved about 17% of their verification gas, roughly 224 million gas over the window, and the fraction grows with the batch size.

Each point evaluation precompile call performs a full two-pairing check. Because pairing verification is bilinear, `n` such checks can be replaced by one check on a random linear combination of the claims, at the cost of two MSMs whose per-element price is far below a pairing. EIP-2537 exposes exactly the primitives needed for this, `BLS12_G1MSM` and `BLS12_PAIRING_CHECK`, on the same curve that EIP-4844 commitments live on. Composing them correctly is not hard, but it is easy to get subtly wrong: the verification equation, the challenge derivation and the binding checks each have a variant that accepts every valid batch and also accepts some invalid ones, so a mistake in any of them is invisible to ordinary testing. This document records the technique once, together with the checks that an implementation cannot omit, so that it can be reviewed and reused rather than reinvented.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Notation

The following symbols are used throughout this section.

| Symbol | Meaning |
| --- | --- |
| `q` | The BLS12-381 scalar field modulus, equal to `BLS_MODULUS` in EIP-4844 |
| `p` | The BLS12-381 base field modulus |
| `G1`, `G2` | The BLS12-381 subgroup generators used by EIP-2537 and the EIP-4844 trusted setup |
| `[τ]₂` | The second G2 monomial point of the EIP-4844 trusted setup, that is `τ · G2` |
| `e(·, ·)` | The BLS12-381 pairing |
| `C` | A KZG commitment, a G1 point |
| `π` | A KZG opening proof, a G1 point |
| `z`, `y` | An evaluation point and the claimed evaluation, both scalars in `[0, q)` |
| `h` | An EIP-4844 versioned hash |

An opening claim `(h, C, z, y, π)` asserts that the polynomial committed to by `C` evaluates to `y` at `z`, and that `C` is the commitment named by the versioned hash `h`. The EIP-4844 point evaluation precompile accepts exactly one such claim per call and accepts it if and only if `kzg_to_versioned_hash(C) == h` and

```
e(C - y·G1 + z·π, G2) == e(π, [τ]₂)
```

which is the standard KZG verification equation rearranged so that the only G2 inputs are the generator and `[τ]₂`.

### Point Encoding

All G1 points passed to the batched verifier MUST use the 128-byte uncompressed encoding defined in EIP-2537, since that is the only encoding the EIP-2537 precompiles accept; the 48-byte compressed encoding of EIP-4844 is derived from it where needed and never the reverse.

To bind a commitment to its versioned hash, the verifier MUST compute the 48-byte compressed encoding of the uncompressed commitment and check `kzg_to_versioned_hash(compress(C)) == h`. The compressed encoding is the 48-byte big-endian `x` coordinate with the three most significant bits set as follows: bit 7 is always set, bit 6 is set only for the point at infinity (in which case all other bits are zero), and bit 5 is set if and only if `y > (p - 1) / 2`. This is the same encoding that EIP-4844 commitments use.

### Input Validation

Before any precompile is called, the verifier MUST check all of the following and reject the batch if any check fails:

- `n ≥ 1`, and every input array has exactly `n` elements.
- Every scalar `z` and `y` is strictly less than `q`.
- Every G1 point is exactly 128 bytes long.
- Every commitment binds to its versioned hash as described in [Point Encoding](#point-encoding).

These checks precede the challenge derivation, so the transcript hashed in the next section is always over canonical, well-formed inputs and one claim has exactly one byte representation. Canonical encoding, on-curve and subgroup membership of the points are enforced by the `BLS12_G1MSM` and `BLS12_PAIRING_CHECK` precompiles, which reject non-canonical inputs and points outside the prime-order subgroup. The verifier MUST NOT use `BLS12_G1ADD` on untrusted points, since that precompile does not perform a subgroup check.

### Challenge Derivation

The verifier MUST derive `n` challenge scalars `r_1, ..., r_n` from a hash of the entire batch, including every versioned hash, commitment, evaluation point, claimed evaluation and proof. No input that a prover controls, and no input that enters `LHS` or `RHS`, may be left out of the hash. The derivation MUST be performed after all inputs are known and MUST NOT depend on any value that a prover can choose after seeing the challenges.

The RECOMMENDED derivation is

```
seed = keccak256(DOMAIN || h_1..h_n || z_1..z_n || y_1..y_n || C_1..C_n || π_1..π_n)
r_i  = keccak256(seed || i) mod q          for i in 1..n
if r_i == 0: r_i = 1
```

where `DOMAIN` is a fixed byte string that distinguishes the verifier and batch shape, and `||` denotes concatenation with ABI encoding of the arrays. Each `r_i` is non-zero so that no claim drops out of the combination.

### Batched Verification

The verifier computes two G1 points `LHS` and `RHS` with `BLS12_G1MSM`, then accepts the batch if and only if `BLS12_PAIRING_CHECK` returns `1` for the two pairs

```
(LHS, -G2), (RHS, [τ]₂)
```

that is, if `e(LHS, -G2) · e(RHS, [τ]₂) == 1`. The constant `-G2` is the negation of the G2 generator; embedding it avoids negating a G1 point on chain. `RHS` is the same in every shape below:

```
RHS = Σ r_i · π_i
```

#### General Shape

Given `n` claims `(h_i, C_i, z_i, y_i, π_i)` with no shared values, the verifier computes

```
LHS = Σ r_i · C_i  +  Σ (r_i · z_i) · π_i  -  (Σ r_i · y_i) · G1
```

The `LHS` MSM has `2n + 1` slots: the `n` commitments with scalars `r_i`, the `n` proofs with scalars `r_i · z_i mod q`, and the generator with scalar `-(Σ r_i · y_i) mod q`. All scalar arithmetic is modulo `q`. This shape applies when each blob is opened at its own evaluation point, for example when the point is derived per blob from a hash of that blob's commitment. The two shapes that follow are algebraic simplifications of it for inputs with shared values; a verifier MAY implement only the general shape and remain correct for all inputs.

#### Many Blobs, One Shared Point

When every claim shares the evaluation point `z`, the proof terms factor as `Σ (r_i · z) · π_i = z · RHS`, and the verifier computes

```
LHS = Σ r_i · C_i  +  z · RHS  -  (Σ r_i · y_i) · G1
```

The `RHS` point is computed first and then occupies a single slot of the `LHS` MSM with scalar `z`, so the `LHS` MSM has `n + 2` slots: `n` commitments, the `RHS` point, and the generator with scalar `-(Σ r_i · y_i) mod q`.

#### One Blob, Many Points

When every claim shares the commitment `C`, the commitment terms factor as `Σ r_i · C_i = (Σ r_i) · C`, and the verifier computes

```
LHS = Σ (r_i · z_i) · π_i  +  (Σ r_i) · C  -  (Σ r_i · y_i) · G1
```

The `LHS` MSM has `n + 2` slots: the `n` proofs with scalars `r_i · z_i mod q`, the commitment with scalar `Σ r_i mod q`, and the generator with scalar `-(Σ r_i · y_i) mod q`. The two MSMs are independent and can be issued in either order.

### Constants

The following constants, given in EIP-2537 encoding, are those of the EIP-4844 trusted setup and of the BLS12-381 generators. An implementation for Ethereum mainnet MUST use exactly these values.

`G1` (128 bytes):

```
0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb
0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1
```

`-G2` (256 bytes):

```
00000000000000000000000000000000024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8
0000000000000000000000000000000013e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e
000000000000000000000000000000000d1b3cc2c7027888be51d9ef691d77bcb679afda66c73f17f9ee3837a55024f78c71363275a75d75d86bab79f74782aa
0000000000000000000000000000000013fa4d4a0ad8b1ce186ed5061789213d993923066dddaf1040bc3ff59f825c78df74f2d75467e25e0f55f8a00fa030ed
```

`[τ]₂` (256 bytes), the decompressed `g2_monomial[1]` of the EIP-4844 trusted setup:

```
00000000000000000000000000000000185cbfee53492714734429b7b38608e23926c911cceceac9a36851477ba4c60b087041de621000edc98edada20c1def2
0000000000000000000000000000000015bfd7dd8cdeb128843bc287230af38926187075cbfbefa81009a2ce615ac53d2914e5870cb452d2afaaab24f3499f72
00000000000000000000000000000000014353bdb96b626dd7d5ee8599d1fca2131569490e28de18e82451a496a9c9794ce26d105941f383ee689bfbbb832a99
000000000000000000000000000000001666c54b0a32529503432fcae0181b4bef79de09fc63671fda5ed1ba9bfa07899495346f3d7ac9cd23048ef30d0a154f
```

Line breaks are for readability only; each constant is a single contiguous byte string.

### Small Batches

For batches smaller than the crossover size, the batched path costs more than looping the point evaluation precompile. A verifier that accepts arbitrary batch sizes SHOULD fall back to one point evaluation precompile call per claim when `n` is below the crossover. Under the gas schedules of EIP-2537 and EIP-4844 the measured crossover is `5` for both shared-value shapes and `6` for the general shape, as derived in the Rationale. When falling back, the verifier MUST compress each 128-byte point to the 48-byte encoding before calling the point evaluation precompile.

## Rationale

### Soundness of the Random Linear Combination

Each claim `i` corresponds to a target-group element `t_i = e(C_i - y_i·G1 + z_i·π_i, G2) · e(π_i, [τ]₂)⁻¹`, which equals the identity exactly when the claim holds. Raising each `t_i` to a random power `r_i` and multiplying gives `Π t_i^{r_i} = e(LHS, G2) · e(RHS, [τ]₂)⁻¹` by bilinearity, which is what the pairing check evaluates. If any single `t_j` is not the identity, the exponent `Σ r_i · log(t_i)` is a non-constant linear function of `r_j`, so the product is the identity for exactly one value of `r_j` in `[0, q)`. With `r_i` uniform and independent of the claims, an invalid batch is accepted with probability `1/q ≈ 2⁻²⁵⁵`; this is the degree-one case of the Schwartz-Zippel lemma, and it does not depend on how many of the `n` claims are invalid. Using powers `r⁰, r¹, ..., rⁿ⁻¹` of a single challenge `r` instead, as the consensus-layer batch verifier does, makes the exponent a polynomial of degree `n - 1` in `r` and loosens the bound to `(n - 1)/q`, still negligible; the per-index hashes specified here cost one `keccak256` per claim rather than one field multiplication, which is immaterial next to the MSM, and keep the tighter bound. The `mod q` reduction of a 256-bit hash output and the zero-to-one clamp bias this by at most a factor of two, which is irrelevant at this scale. Independence of the challenges from the claims is what the Fiat-Shamir derivation in the Specification provides, under the usual random-oracle model for the hash; it is a strong Fiat-Shamir transform in that the statement being proved, not only the proofs, enters the transcript.

### Two MSMs and One Pairing Check

Folding the claims moves the per-claim work from a pairing to a scalar multiplication inside an MSM, which the EIP-2537 gas schedule prices at `12000 · discount(k) / 1000` per element with `discount` decreasing towards `519 / 1000` for large `k`. The pairing check itself is a fixed `2 · 32600 + 37700 = 102900` gas regardless of `n`. Counting precompile gas alone, the two shared-value shapes cost `MSM(n) + MSM(n + 2) + 102900` against `50000 · n` for the loop, which is `98%` of the loop cost at `n = 4` and `58%` at `n = 10`; the general shape costs `MSM(n) + MSM(2n + 1) + 102900`, which is `97%` at `n = 5` and `88%` at `n = 6`. Measured end to end, including calldata and contract overhead, each crossover moves one step later, to `n = 5` for the shared-value shapes and `n = 6` for the general shape, which is where the reference implementation switches paths. The pairing cost does not depend on the shape, because every claim pairs against the same two G2 points, so after the MSMs exactly two G1 points remain regardless of `n`.

### Factoring the Shared Point

The general shape spends `2n + 1` slots on the `LHS` MSM. In the many-blobs shape every claim uses the same `z`, so `Σ (r_i · z) · π_i = z · Σ r_i · π_i = z · RHS`. Reusing the already computed `RHS` as one slot of the `LHS` MSM shrinks that MSM to `n + 2` slots, which is why `RHS` is computed first in that shape. In the one-blob shape the commitment is shared instead, so the `n` commitment slots collapse into a single slot with scalar `Σ r_i`; the proofs cannot be folded because each has its own `z_i`. The one-blob shape ends up slightly cheaper for the same `n` since its `LHS` MSM has one large shared slot rather than `n` distinct commitment slots.

### Embedding the Negated G2 Generator

The pairing check precompile returns `1` when the product of pairings equals the identity, so the verification equation has to be written as `e(LHS, -G2) · e(RHS, [τ]₂) == 1`. Negation can be applied to either side; negating `G2` once and embedding the result as a constant is free at run time, whereas negating `LHS` on chain would require an extra field subtraction on a freshly returned point.

### Uncompressed Points

EIP-2537 accepts only uncompressed points, while EIP-4844 commitments and proofs are transported compressed. Decompressing on chain requires a square root in the 381-bit base field, which costs far more than the 80 additional calldata bytes per point (at most 1280 gas each, less in practice since the padding bytes are zero). Every party that produces a compressed point holds the uncompressed one, so the batched verifier takes uncompressed inputs and derives the compressed form, which needs no field arithmetic, only for the versioned hash binding.

### Binding Commitments to Versioned Hashes

The point evaluation precompile checks `kzg_to_versioned_hash(C) == h` internally. Once the precompile is bypassed nothing else performs that check, so the batched verifier has to do it explicitly, otherwise a prover could open an arbitrary commitment of its choosing in place of the blob the transaction actually carries. The check is listed under input validation rather than left to callers because omitting it produces a verifier that accepts all valid batches and is therefore hard to catch in testing.

### Relation to the Consensus-Layer Batch Verifier

The construction is not new: `verify_kzg_proof_batch` in the [Deneb polynomial commitments specification](https://github.com/ethereum/consensus-specs/blob/86fb82b221474cc89387fa6436806507b3849d88/specs/deneb/polynomial-commitments.md) folds `n` openings into the same two-pair pairing check with a random linear combination, and consensus clients use it to verify every blob in a block at once. That verifier runs natively inside a client, takes compressed points, trusts its own copy of the setup, and does not need to bind commitments to versioned hashes. This document transposes it to the EVM, where each of those differences becomes a decision: points have to be uncompressed for EIP-2537, `[τ]₂` has to be carried as a contract constant, the versioned-hash binding that the point evaluation precompile performed has to be restored explicitly, the MSM gas schedule rewards the two shared-value factorisations, and a crossover against the per-opening precompile decides when to batch at all. Those are the parts an implementer cannot take from the consensus-layer specification, and they are what this document adds.

### Alternatives Considered

A dedicated multi-point evaluation precompile, which has been proposed separately, would verify one blob at many points against a single aggregated proof, a KZG multi-proof rather than a batch of per-point proofs. It needs a protocol change and a new proof format before it can be used, and it cannot span several commitments, so it does not address the many-blobs case at all. The composition described here runs on the current protocol, keeps the existing proof format, and covers every shape. The two are orthogonal rather than competing: one reduces proof bytes for a single blob, the other reduces pairings across claims, and a contract could in principle batch several multi-proofs with the same random-combination technique.

KZG multi-proofs, which prove a set of openings with a single proof by dividing by the vanishing polynomial of the evaluation points, reduce proof size but need a different prover and a pairing against a G2 MSM. The technique here deliberately stays with the per-opening proofs that every existing KZG library already emits, so provers and blob producers need no modification.

The batching itself is not specific to blobs. It applies to any set of pairing equations whose G2 arguments are the same two fixed points, which is true of every KZG opening against the EIP-4844 trusted setup. It does not collapse equations with varying G2 arguments, such as BLS signatures under distinct public keys or multi-proofs with distinct vanishing polynomials; those still batch, but to `n + 1` pairs rather than two, on a different cost curve.

### Measured Gas

The following figures were measured with the reference implementation against a minimal loop of point evaluation precompile calls. Both verifiers are called externally from a test harness on the same inputs, and the figure recorded is the gas consumed by that external call, so both sides carry the same fixed call overhead of roughly 21,000 gas. Inputs are randomly generated blobs with proofs produced by a standard KZG library; the many-blobs rows open `n` distinct blobs at one point, the one-blob rows open one blob at `n` distinct points. The loop baseline is a bare port of the verification loop used in production settlement contracts, with all protocol-specific work removed, so it is the cheapest version of the pattern it represents and the savings are measured against a best-case baseline. Below the crossover the batched verifier dispatches to the loop and pays only the compression overhead.

| `n` | Loop gas | Batched gas, many blobs | Batched gas, one blob | Batched gas, general |
| --- | --- | --- | --- | --- |
| 1 | 57,125 | 58,801 | 69,310 | 59,437 |
| 4 | 212,269 | 218,421 | 215,205 | 219,831 |
| 5 | 264,851 | 241,224 | 232,312 | 274,148 |
| 10 | 527,720 | 340,845 | 320,742 | 410,383 |
| 25 | 1,316,867 | 621,295 | 566,901 | 787,017 |
| 50 | 2,634,392 | 1,059,175 | 945,665 | 1,365,241 |
| 100 | 5,277,491 | 1,877,504 | 1,637,590 | 2,515,764 |

The loop column is from the many-blobs run; the general-shape loop differs from it by under `0.5%` at every `n`. Savings for the shared-value shapes grow from `9%` to `12%` at `n = 5` to roughly `65%` to `69%` at `n = 100`; the general shape, with its larger `LHS` MSM, saves `23%` at `n = 10` and about `53%` at `n = 100`. The per-`n` measurements are in [`gas_many_blobs_one_point.csv`](../assets/eip-NNNN/gas_many_blobs_one_point.csv), [`gas_one_blob_many_points.csv`](../assets/eip-NNNN/gas_one_blob_many_points.csv) and [`gas_general.csv`](../assets/eip-NNNN/gas_general.csv) in this proposal's assets.

## Backwards Compatibility

The technique introduces no protocol change and affects no consensus rule; it is a pattern for contract code built entirely on the precompiles already available after EIP-2537 activation. Provers, blob producers and the EIP-4844 proof format are unchanged. A contract that adopts the batched verifier changes only its own calldata interface, from 48-byte to 128-byte points, and can keep a point evaluation precompile path for callers that continue to submit compressed points or small batches.

## Test Cases

One fixture per shape is included in this proposal's assets, each a set of valid claims in the 128-byte encoding with proofs produced by a standard KZG library, large enough to take the batched path rather than the small-batch fallback.

- [`multi_point_one_blob_128.json`](../assets/eip-NNNN/fixtures/multi_point_one_blob_128.json): six openings of one blob at six distinct points, for the one-blob shape.
- [`multi_blob_one_point_z1_6_128.json`](../assets/eip-NNNN/fixtures/multi_blob_one_point_z1_6_128.json): three blobs opened at the shared point `z = 1`, each listed twice, for the many-blobs shape; a repeated blob is a valid input.
- [`multi_blob_multi_point_128.json`](../assets/eip-NNNN/fixtures/multi_blob_multi_point_128.json): seven claims over three blobs at five distinct points, for the general shape.

Each fixture is expected to be accepted as given. Each is expected to be rejected when any single `y_i` is altered, when any proof is replaced by the G1 generator, when two proofs of the same blob are exchanged, when a commitment is presented under a versioned hash it does not bind to, when any scalar is greater than or equal to `q`, when any point has a length other than 128 bytes, when the array lengths disagree, and when the batch is empty. The shared point `z = 0`, which zeroes the `RHS` slot of the `LHS` MSM, and commitments or proofs at infinity are also expected to be accepted when the underlying openings are valid.

## Reference Implementation

A Solidity implementation is included in this proposal's assets. [`Bls12381.sol`](../assets/eip-NNNN/Bls12381.sol) wraps the EIP-2537 precompiles and implements the point compression used for versioned hash binding; [`BlobVerifier.sol`](../assets/eip-NNNN/BlobVerifier.sol) implements all three shapes with their threshold fallbacks, and the single-opening path through the point evaluation precompile. The core of the many-blobs shape, with encoding details omitted, reads as follows:

```python
def verify_many_blobs_one_point(hs, Cs, z, ys, proofs):
    n = len(hs)
    assert n >= 1 and len(Cs) == len(ys) == len(proofs) == n
    assert z < q and all(y < q for y in ys)
    for h, C in zip(hs, Cs):
        assert kzg_to_versioned_hash(compress(C)) == h

    seed = keccak256(DOMAIN, hs, z, ys, Cs, proofs)
    rs = [max(1, int(keccak256(seed, i)) % q) for i in range(n)]

    rhs = g1_msm([(proofs[i], rs[i]) for i in range(n)])
    y_sum = sum(rs[i] * ys[i] for i in range(n)) % q
    lhs = g1_msm(
        [(Cs[i], rs[i]) for i in range(n)]
        + [(rhs, z), (G1, (q - y_sum) % q)]
    )
    assert pairing_check([(lhs, NEG_G2), (rhs, TAU_G2)]) == 1
```

The one-blob shape differs only in the `lhs` construction, which uses `[(proofs[i], rs[i] * z_i % q) ...] + [(C, sum(rs) % q), (G1, (q - y_sum) % q)]`.

## Security Considerations

### Challenge Binding

The soundness argument in the Rationale requires the challenges to be independent of the claims. If a prover could influence `r_i` after choosing `π_i`, or if any prover-controlled input were left out of the hash, the prover could pick proofs that cancel across the combination and have an invalid batch accepted. In particular the proofs and the claimed evaluations, not only the commitments and points, have to be hashed. Deriving the challenges from the full batch as specified makes the combination a Fiat-Shamir transform whose security rests on modelling the hash as a random oracle, which is the standard assumption for this construction.

### Versioned Hash Binding

Bypassing the point evaluation precompile bypasses its internal `kzg_to_versioned_hash` check. An implementation that omits the explicit binding accepts a proof for any commitment the prover supplies, regardless of which blob the transaction carries, while still accepting every honest batch. Because this failure is invisible to tests that only use honest inputs, test suites need a case that swaps a commitment for one with a mismatched versioned hash. For the same reason, a test suite for the challenge derivation needs a case that alters a single claimed evaluation `y_i` in an otherwise valid batch, since an omitted transcript input is the one mistake that honest inputs cannot reveal.

### Trusted Setup Constant

The batched verifier embeds `[τ]₂` as a constant instead of relying on the precompile's built-in copy. A wrong constant, including one from a different ceremony or a mis-decompressed point, produces a verifier that rejects all honest proofs or, worse, accepts proofs for a different setup. Implementers are expected to check the embedded value against the one in this document and against the trusted setup that the point evaluation precompile uses on the target chain.

### Subgroup and Encoding Checks

`BLS12_G1MSM` and `BLS12_PAIRING_CHECK` reject non-canonical field elements, points not on the curve, and points outside the prime-order subgroup, and the batched path routes every untrusted point through one of them. `BLS12_G1ADD` performs no subgroup check and is therefore unsuitable for combining untrusted points; implementations that restructure the computation around `BLS12_G1ADD` lose the check and admit small-subgroup inputs.

### Degenerate Inputs

Challenges equal to zero are clamped to one so that no claim is silently removed from the combination. The empty batch is rejected rather than treated as trivially valid. A shared point `z = 0` zeroes the `RHS` term of the `LHS` MSM, which is correct since the verification equation reduces to `e(C - y·G1, G2) == e(π, [τ]₂)`; the fixtures exercise this path explicitly. Commitments or proofs at infinity are valid inputs, correspond to the zero polynomial, and are handled by the compression rule that sets the infinity flag.

### Failure Attribution

A rejected batch reveals only that at least one claim is invalid, not which one. Callers that need to attribute a failure to a specific claim, for instance in a dispute game that slashes the party responsible, have to re-verify the claims individually with the point evaluation precompile after a batched rejection, or avoid batching in that code path.

### Gas Griefing

All EIP-2537 precompiles burn the entire gas supplied on error. The length, range and array checks are placed before any precompile call so that malformed inputs fail with a normal revert and refund unused gas. The batched path is a view operation with no state and no external calls other than precompiles, so it introduces no reentrancy surface.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
