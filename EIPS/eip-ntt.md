---
title: <Precompile for NTT operations>
description: <Proposal to add a precompiled contract that performs number theoretical transformation (NTT) and inverse (InvNTT).>
author: <Renaud Dubois (@rdubois-crypto), Simon Masson (@simonmasson)>
discussions-to: <TBD>
status: Draft
type: <Standards Track>
category: <Core> # Only required for Standards Track. Otherwise, remove this field.
created: <2025-02-12>
requires: <EIP number(s)> # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---

<!--
  READ EIP-1 (https://eips.ethereum.org/EIPS/eip-1) BEFORE USING THIS TEMPLATE!

  This is the suggested template for new EIPs. After you have filled in the requisite fields, please delete these comments.

  Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

  The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category.

  TODO: Remove this comment before submitting
-->

## Abstract

This proposal creates a precompiled contract that performs NTT and Inverse NTT transformations. This provides a way to have efficient and fast polynomial multiplication for Post Quantum and Starks applications.

## Motivation

With the release of Willow cheap, the concern for quantum threat against Ethereum accelerated. Today ECDSA is the EOA signature algorithms, which is prone to quantum computing. Efficient replacement algorithms use polynomial multiplication as the core operation. Once NTT and Inverse NTT are available, the remaining of the verification algorithm is trivial. Chosing to integrate NTT and InvNTT instead of a specific algorithm provides agility, as DILITHIUM or FALCON or any equivalent can be implemented with a modest cost from those operators. NTT is also of interest to speed-up STARK verifiers. This single operator would thus benefit to both the Ethereum scaling and Post Quantum threat mitigation.

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

## Specification

### Constants

| Name                | Value | Comment            |
|---------------------|-------|--------------------|
| NTT_FW              | 0x0f | precompile address |
| NTT_INV             | 0x10  | precompile address |
| NTT_VECMULMOD          | 0x11  | precompile address |
| NTT_VECADDMOD          | 0x12  | precompile address |

We introduce *four* separate precompiles to perform the following operations:

- NTT_FW - to perform the forward NTT transformation (Negative wrap convolution) with a gas cost of `600` gas
- NTT_INV - to perform the inverse NTT transformation (Negative wrap convolution) with a gas cost of `600` gas
- NTT_VECMULMOD - to perform vectorized modular multiplication with a gas cost formula defined in the corresponding section
- NTT_VECADDMOD - to perform vectorized modular addition with a gas cost formula defined in the corresponding section


### Field parameters

The NTT_FW and NTT_INV are fully defined  by the following set of parameters. 
Let R be the ring of cyclotomic integers, i.e $R=Z[X]/X^n+1 \mod q $, where
- $n$ is the degree
- $q$ is the field characteristic such that $q=1 \mod 2n$
- $\omega$ is a n-th root of unity in $\mathbb Z_q$ i.e $\omega^n=1 \mod q$
- $\psi$ is a n-th root of unity in $\mathbb Z_q$ i.e $\psi^n=1 \mod q$

Any element $a \in R$ is a polynomial of degree at most $n − 1$ with integer coefficients, written
as $a=\sum_{i=0}^{n-1} aiX^i$


### NTT_FW
The NTT transformation is described by the following algorithm.

**Input:** A vector $a = (a[0], a[1], \dots, a[n-1]) \in \mathbb{Z}_q^n$ in standard ordering, where $q$ is a prime such that $q \equiv 1 \mod 2n$ and $n$ is a power of two, and a precomputed table $\Psi_{rev} \in \mathbb{Z}_q^n$ storing powers of $\psi$ in bit-reversed order.

**Output:** $a \leftarrow \text{NTT}(a)$ in bit-reversed ordering.

```plaintext
t ← n
for m = 1 to n-1 by 2m do
    t ← t / 2
    for i = 0 to m-1 do
        j1 ← 2 ⋅ i ⋅ t
        j2 ← j1 + t - 1
        S ← Ψrev[m + i]
        for j = j1 to j2 do
            U ← a[j]
            V ← a[j + t] ⋅ S
            a[j] ← (U + V) mod q
            a[j + t] ← (U - V) mod q
        end for
    end for
end for
return a
```

### NTT_INV
The Inverse NTT is described by the following algorithm.



Input: A vector $a = (a[0], a[1], \dots, a[n-1]) \in \mathbb{Z}q^n$ in bit-reversed ordering, where $q$ is a prime such that $q \equiv 1 \mod 2n$ and $n$ is a power of two, and a precomputed table $\Psi^{-1}{rev} \in \mathbb{Z}_q^n$ storing powers of $\psi^{-1}$ in bit-reversed order.

Output: $a \leftarrow \text{INTT}(a)$ in standard ordering.

```plaintext
t ← 1
for m = n to 1 by m/2 do
    j1 ← 0
    h ← m / 2
    for i = 0 to h-1 do
        j2 ← j1 + t - 1
        S ← Ψ⁻¹rev[h + i]
        for j = j1 to j2 do
            U ← a[j]
            V ← a[j + t]
            a[j] ← (U + V) mod q
            a[j + t] ← (U - V) ⋅ S mod q
        end for
        j1 ← j1 + 2t
    end for
    t ← 2t
end for
for j = 0 to n-1 do
    a[j] ← a[j] ⋅ n⁻¹ mod q
end for
return a
```


### NTT_VECMULMOD

The NTT_VECMULMOD is similar to SIMD in the functionning, but operates with larger sizes it takes as input:
- q is the 
- n the bit size of q, coded over the smallest integer in {16, 32, 64, 128, 256}
- x the length of the vector of operands. x is  a power of 2 in {4, 8, 16, 32, 64, 128,256, 512}
- a the first operand of x elements of size n
- b the second operand of x elements of size n

and computes the element-wise products mulmod(ai,bi,q) .
The gas cost of the operation is $\log_2(x).n \over 8$


### NTT_VECADDMOD

The Inverse NTT is described by the following algorithm.

The NTT_VECMULMOD is similar to SIMD in the functionning, but operates with larger sizes it takes as input:
- q is the 
- n the bit size of q, coded over the smaller integer in {16, 32, 64, 128, 256}
- x the size of the vector of operands. x is  a power of 2 in {16, 32, 64, 128,512}
- a the first operand of x elements of size n
- b the second operand of x elements of size n

and computes the element-wise addition addmod(ai,bi,q) .
The gas cost of the operation is $\log_2(x).n \over 32$

## Rationale

If $f$ and $g$ are two polynomials of $R$, then $fg$=NTT_INV(NTT_VECMULMOD(NTT_FW(a), NTT_FW(b))) is equal to the product of f and g in R. 
The algorithm has a complexity of $n \log n$ rather than $n^2$ of the classical schoolbook multiplication.



### Fields of interest

- FALCON: $q=3.2^{12}+1$
- DILITHIUM: $q=1023.2^{13}+1$
- KYBER: $q=13.2^8+1$
- Babybear: $q=15.2^{27}+1$ (Risc0)
- Goldilocks: $q=2^{64}-2^{32}+1$ (Polygon's Plonky2)
- M31: $q=2^{31}-1$ (Circle STARKS, STwo, Plonky3)
- StarkCurve: $q=2^{251}+17.2^{192}+1$


### Benchmarks

#### Pure solidity

To illustrate the interest of the precompile, the assets provide the measured gas const for a single NTT and extrapolates the minimal gas cost taking into account the required number of NTT_FW and NTT_INV. The provided assets use pure Yul optimizations, with memory access hacks. It is unlikely that more than one order of magnitude could be spared on such a minimal code. 

|Use case| Parameters                   | single NTT gas cost         |  Required NTT(FW/INV)    | Estimated NTT/Full cost |
|--|------------------------|---------------------|---------------------|---|
|Falcon| $q=512, n=512$       | 1.8 M | 1 NTTFW+1 NTTINV |3.6 M| 
|Dilithium| $q=1023.2^{13}+1, n=256$| 460K | 4 NTTFW +1 NTTINV|2.3M|

Falcon cost has been measured over a full implementation and is compliant to the estimation. Dilithium cost is evaluated assuming

This demonstrates that using pure solidity enables cheap L2s to experiment with FALCON from now, but is to expensive for L1.
This numbers are reduced to 1500 gas when this EIP is adopted.
Adopting the Hash function as a separate EIP would enable a gas verification cost of 2000 gas.
This is in line with the ratio  looking at SUPERCOP implementations.


<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->


## Backwards Compatibility
There are no backward compatibility questions.
<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

## Test Cases
There is no edge cases in the considered operations.

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation


There are two fully spec compatible implementations on the day of writing:
- a python reference code provided in the [assets]() of this EIP
- a solidity reference code provided in the [assets]() of this EIP
Both codes have been validated over a large base of reference vectors, and implementing both FALCON and DILITHIUM algorithms as demonstration of the usefulness of the precompile.

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
