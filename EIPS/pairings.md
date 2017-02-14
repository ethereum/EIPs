## Preamble
<pre>
  EIP: to be assigned
  Title: Precompiled contracts for optimal ate pairing check
         on the elliptic curve alt_bn128
  Author: Vitalik Buterin &lt;vitalik@ethereum.org&gt;, Christian Reitwiessner &lt;chris@ethereum.org&gt;
  Type: Standard Track
  Category(*only required for Standard Track): Core
  Status: Draft
  Created: 2017-02-06
</pre>

## Simple Summary

Precompiled contracts for elliptic curve pairing operations are required in order to perform zkSNARK verification within the block gas limit.

## Abstract

This EIP suggests to add precompiled contracts for a pairing function on a specific pairing-friendly elliptic curve. This can in turn be combined with https://github.com/ethereum/EIPs/issues/196 to verify zkSNARKs in Ethereum smart contracts. The general benefit of zkSNARKs for Ethereum is that it will increase the privacy for users (because of the Zero-Knowledge property) and might also be a scalability solution (because of the succinctness and efficient verifiability property).

## Motivation

Current smart contract executions on Ethereum are fully transparent, which makes them unsuitable for several use-cases that involve private information like the location, identity or history of past transactions. The technology of zkSNARKs could be a solution to this problem. While the Ethereum Virtual Machine can make use of zkSNARKs in theory, they are currently too expensive
to fit the block gas limit. Because of that, this EIP proposes to specify certain parameters for some elementary primitives that enable zkSNARKs so that they can be implemented more efficiently and the gas cost be reduced.

Note that fixing these parameters will in no way limit the use-cases for zkSNARKs, it will even allow for incorporating some advances in zkSNARK research without the need for a further hard fork.

Pairing functions can be used to perform a limited form of multiplicatively homomorphic operations, which are necessary for current zkSNARKs. This precompile can be used to run such computations within the block gas limit. This precompiled contract only specifies a certain check, and not an evaluation of a pairing function. The reason is that the codomain of a pairing function is a rather complex field which could provide encoding problems and all known uses of pairing function in zkSNARKs only require the specified check.

## Specification

Add a precompiled contracts for a bilinear function on groups on the elliptic curve "alt_bn128". We will define the precompiled contract in terms of a discrete logarithm. The discrete logarithm is of course assumed to be hard to compute, but we will give an equivalent specification that makes use of elliptic curve pairing functions which can be efficiently computed below.

Address: 0x8

For a cyclic group `G` (written additively) of prime order q let `log_P: G -> F_q` be the discrete logarithm on this group with respect to a generator `P`, i.e. `log_P(x)` is the integer `n` such that `n * P = x`.

The precompiled contract is defined as follows, where the two groups `G_1` and `G_2` and their generators `P_1` and `P_2` are defined below (they have the same order `q`):

```
Input: (a1, b1, a2, b2, ..., ak, bk) from (G_1 x G_2)^k
Output: If the length of the input is incorrect or any of the inputs are not elements of
        the respective group or are not encoded correctly, the call fails.
        Otherwise, return one if
        log_P1(a1) * log_P2(b1) + ... + log_P1(ak) * log_P2(bk) = 0
        (in F_q) and zero else.
```

### Definition of the groups

The groups `G_1` and `G_2` are cyclic groups of prime order `q` on the elliptic curve `alt_bn128` defined by the curve equation
`Y^2 = X^3 + 3`.

The group `G_1` is a cyclic group on the above curve over the field `F_p` with `p = 21888242871839275222246405745257275088696311157297823662689037894645226208583` with generator `P1 = (1, 2)`.

The group `G_2` is a cyclic group on the same elliptic curve over a different field `F_p^2 = F_p[X] / (X^2 + 1)` (p is the same as above) with generator
```
P2 = (
  11559732032986387107991004021392285783925812861821192530917403151452391805634 * i +
  10857046999023057135944570762232829481370756359578518086990519993285655852781,
  4082367875863433681332203403145435568316851327593401208105741076214120093531 * i +
  8495653923123431417604973247489272438418190587263600148770280649306958101930
)
```


### Encoding

Elements of `F_p` are encoded as 32 byte big-endian numbers. An encoding value of `p` or larger is invalid.

Elements `a * i + b` of `F_p^2` are encoded as two elements of `F_p`, `(a, b)`.

Elliptic curve points are encoded as a Jacobian pair `(X, Y)` where the point at infinity is encoded as `(0, 0)`.

Note that the number `k` is derived from the input length.

The length of the returned data is always exactly 32 bytes and encoded as a 32 byte big-endian number. 

### Gas costs

To be determined. 

## Rationale

The specific curve `alt_bn128` was chosen because it is particularly well-suited for zkSNARKs, or, more specifically their verification building block of pairing functions. Furthermore, by choosing this curve, we can use synergy effects with ZCash and re-use some of their components and artifacts.

The feature of adding curve and field parameters to the inputs was considered but ultimately rejected since it complicates the specification: The gas costs are much harder to determine and it would be possible to call the contracts on something which is not an actual elliptic curve or does not admit an efficient pairing implementation.

A non-compact point encoding was chosen since it still allows to perform some operations in the smart contract itself (inclusion of the full y coordinate) and two encoded points can be compared for equality (no third projective coordinate).

The encoding of field elements in `F_p^2` was chosen in this order to be in line with the big endian encoding of the elements themselves.

## Backwards Compatibility

As with the introduction of any precompiled contract, contracts that already use the given addresses will change their semantics. Because of that, the addresses are taken from the "reserved range" below 256.

## Test Cases

To be written.

## Implementation

The precompiled contract can be implemented using elliptic curve pairing functions, more specifically, an optimal ate pairing on the alt_bn128 curve, which can be implemented efficiently. In order to see that, first note that a pairing function `e: G_1 x G_2 -> G_T` fulfills the following properties (`G_1` and `G_2` are written additively, `G_T` is written multiplicatively):

(1) `e(m * P1, n * P2) = e(P1, P2)^(m * n)`
(2) `e` is non-degenerate

Now observe that
```
log_P1(a1) * log_P2(b1) + ... + log_P1(ak) * log_P2(bk) = 0
```
if and only if
```
e(P1, P2)^(log_P1(a1) * log_P2(b1) + ... + log_P1(ak) * log_P2(bk)) = e(P1, P2)
```

Furthermore, the left hand side of this equation is equal to
```
e(log_P1(a1) * P1, log_P2(b1) * P2) * ... * e(log_P1(ak) * P1, log_P2(bk) * P2)
= e(a1, b1) * ... * e(ak, bk)
```

And thus, the precompiled contract can be implemented by verifying that
`e(a1, b1) * ... * e(ak, bk) = e(P1, P2)`

Implementations are available here:

 - [libsnark](https://github.com/scipr-lab/libsnark/blob/master/src/algebra/curves/alt_bn128/alt_bn128_g1.hpp) (C++)
 - [bn](https://github.com/zcash/bn/blob/master/src/groups/mod.rs) (Rust)
 - [Python](https://github.com/ethereum/research/blob/master/zksnark/bn128_pairing.py)
