---
eip: TBD
title: Precompile for BN256 HashToCurve Algorithms
author: Dr. Christopher Gorman, MadHive (@chgormanMH)
discussions-to: https://ethereum-magicians.org/t/pre-compile-for-bls/3973
status: Draft
type: Standards Track
category: Core
created: 2020-10-23
requires: EIP-198, EIP-1108
---

## Simple Summary

This EIP opens up opportunities for greater use of BN256
elliptic curve operations by adding a precompiled contract for a
deterministic hash-to-curve algorithm.
In particular, this enables BLS signature verification in the EVM
and reduces its cost to essentially that of one pairing check.

There is a similar proposal to add precompiled contracts for the
elliptic curve BLS12-381 in
[EIP-2537](./eip-2537.md);
this proposal includes a deterministic map-to-curve algorithm.

## Abstract
There is currently no inexpensive way to perform BLS signature
verification for arbitrary messages.
This stems from the fact that there is no precompiled contract
in the EVM for a hash-to-curve algorithm for the BN256 elliptic curve.
The gas cost of calling a deterministic hash-to-curve algorithm
written in Solidity is approximately that of one pairing check,
although the latter requires an order of magnitude
more computation.
This EIP seeks to remedy this by implementing an algorithm
for hashing to BN256 G1 curve, which would reduce the cost of
signature verification to essentially that of the pairing check
precompiled contract.
We also include a hash-to-curve algorithm for the BN256 G2 group.

## Motivation

The precompiled contracts in
[EIP-198](./eip-198.md) and
[EIP-1108](./eip-1108.md)
increased usage of cryptographic operations in the EVM
by reducing the gas costs.
In particular, the cost reduction from
[EIP-1108](./eip-1108.md)
helps increase the use of SNARKs in Ethereum
via an elliptic curve pairing check;
however, a hash-to-curve algorithm enabling arbitrary
BLS signature verification on BN256 in the EVM was noticeably missing.
There is interest in having a precompiled contract which would allow
for signature verification, as noted
[here](https://ethereum-magicians.org/t/pre-compile-for-bls/3973).
If added, [EIP-2537](./eip-2537.md)
would enable BLS signature verification on the BLS12-381 elliptic curve;
however, no precompiled contracts currently exist
for BLS12-381 elliptic curve operations.

At this time, we are able to perform addition, scalar multiplication,
and pairing checks in BN256.
Reducing these costs in
[EIP-1108](./eip-1108.md)
made [ETHDKG](https://github.com/PhilippSchindler/ethdkg),
a distributed key generation protocol in Ethereum,
less expensive.
ETHDKG by itself is useful; however, what it is lacking is
the ability to verify arbitrary BLS signatures.
Creating group signatures by aggregating partial signatures
is one goal of a DKG protocol.
The DKG enables the computation of partial signatures to be
combined into a group signature offline, but there is no
easy way to verify partial signatures or group signatures
in the EVM.

In order to perform BLS signature validation, a hash-to-curve
function is required.
While the MapToGroup method initially discussed in the original BLS
[paper](https://crypto.stanford.edu/~dabo/pubs/abstracts/weilsigs.html)
works in practice, the nondeterministic nature of the algorithm
leaves something to be desired, as we would like to bound
the overall computational cost in the EVM.
A deterministic method for mapping to BN curves is given
[here](https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf);
in the paper, Fouque and Tibouchi proved their mapping
was indifferentiable from a random oracle.
This paper gives us the desired algorithm.

## Specification
We mostly follow the Fouque and Tibouchi
[paper](https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf)
for the hash-to-curve algorithm.
This algorithm, as with the current IRTF
[draft](https://tools.ietf.org/html/draft-irtf-cfrg-hash-to-curve-10),
separates the hash-to-curve operation into a
hash-to-field function and a deterministic field-to-curve map.
We include some improvements from another
[paper](https://eprint.iacr.org/2019/403);
one improvement enables there to be no special points in the
deterministic mapping as long as the multiplicative inverse
function call ensures `inverse(0) == 0`;
this always happens when inversion is computed via exponentiation.
Furthermore, the Wahby and Boneh paper allows us to make
a hash-to-curve algorithm for mapping to G2;
the algorithm is effectively the same, and the only difference
in the different constants and the base field.
All of the required operations in these functions
involve operations on the underlying finite fields.
Algorithms for necessary GF(p^2) operations are referenced below.

On a local machine, ScalarMult was clocked at 68 microseconds
per operation.
The same machine clocked HashToG1 at 94 microseconds per operation
when hashing 32 bytes into G1; it took 105 microseconds per operation
when hashing 1024 bytes into G1.
Given that it currently costs 6000 gas for ECMul, this gives us
an estimated gas cost for HashToG1 at 8500 + len(bytes).
Similarly, HashToG2 was clocked at 886 microseconds per operation
when hashing 32 bytes into G2 and 912 microseconds per operation when
hashing 1024 bytes into G2.
This allows us to estimate the gas cost at 80000 + 3*len(bytes).

We now give the pseudocode the HashToG1 function:

```
function HashToG1(msg)
    t0 = HashToBase(msg, 0x00, 0x01)
    t1 = HashToBase(msg, 0x02, 0x03)
    h0 = BaseToG1(t0)
    h1 = BaseToG1(t1)
    h = ECAdd(h0, h1)       # Elliptic curve addition
    return h
end function
```

Here is the pseudocode for HashToBase;
msg is the byte slice to be hashed and i and j
are bytes for domain separation.
p is the prime of the underlying field.
We chose to use Keccak256 for our hash function as it is
the standard hash function in Ethereum.

```
function HashToBase(msg, i, j)
    s0 = uint256(Keccak256(i||msg))
    s1 = uint256(Keccak256(j||msg))
    c = 2^256 mod p
    t0 = s0*c mod p
    t1 = s1 mod p
    t = t0 + t1 mod p
    return t
end function
```

Here is the pseudocode for BaseToG1. This is the deterministic
mapping from the Fouque and Tibouchi
[paper](https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf)
with some slight modifications.
All of these operations are performed in the finite field.
`CTEq(a, b)` returns 1 if `a == b` and 0 otherwise and performs
this equality check in constant time.
`inverse` computes the multiplicative inverse in the underlying
finite field; we use the convention `inverse(0) == 0`.
`is_square` computes the Legendre symbol of the element,
which determines whether an element of the finite field
is a square.
`sqrt` computes the square root of the element in the finite
field; a square root is assumed to exist when this function is called.
`sign0` returns the sign of a finite field element.
Wahby and Boneh use this to reduce the overall computation,
as it allows us to replace a costly `is_square` call
(which requires exponentiation) with a cheaper if-else block.

```
function BaseToG1(t)
    # All operations are done in the finite field GF(p)
    # Here, the elliptic curve satisfies the equation
    #       y^2 == g(x) == x^3 + b
    p1 = (−1 + sqrt(−3))/2
    p2 = −3
    p3 = 1/3
    p4 = g(1)
    s = (p4 + t^2)^3
    alpha = inverse(t^2*(p4 + t^2))
    x1 = p1 − p2*t^4*alpha
    x2 = −1 − x1
    x3 = 1 − p3*s*alpha
    a1 = x1^3 + b
    a2 = x2^3 + b
    r1 = is_square(a1)
    r2 = is_square(a2)
    i = (r1 − 1)*(r2 − 3)/4 + 1
    c1 = CTEq(1, i)
    c2 = CTEq(2, i)
    c3 = CTEq(3, i)
    x = c1*x1 + c2*x2 + c3*x3
    y = sign0(t)*sqrt(x^3 + b)
    return (x, y)
end function

function sign0(t)
    if t <= (p-1)/2
        return 1
    else
        return -1
    end
end function
```

In HashToG2, we first map to the underlying twist curve
and then clear the cofactor.
Here is the pseudocode for HashToG2:

```
function HashToG2(m)
    t00 = HashToBase(m, 0x04, 0x05)
    t01 = HashToBase(m, 0x06, 0x07)
    t10 = HashToBase(m, 0x08, 0x09)
    t11 = HashToBase(m, 0x0a, 0x0b)
    t0 = (t00, t01)
    t1 = (t10, t11)
    h0 = BaseToTwist(t0)
    h1 = BaseToTwist(t1)
    h = ECAdd(h0, h1)
    g = ECMul(h, r)     # Clear cofactor; g is now an element of G2
    return g
end function
```

Here is the pseudocode for BaseToTwist; the only real difference
between BaseToG1 and BaseToTwist are the different constants
and the different finite fields.
All of these operations are performed in the finite field
of the twist curve.
As in BaseToG1, `inverse`, `is_square`, and `sqrt` perform
the same operations in the underlying finite field GF(p^2).
Our algorithms for `is_square` and `sqrt` come from this
[paper](https://eprint.iacr.org/2012/685).

```
function BaseToTwist(t)
    # All operations are done in the finite field GF(p^2)
    # Here, the twist curve satisfies the equation
    #       y^2 == g'(x) == x^3 + b'
    p1 = (−1 + sqrt(−3))/2
    p2 = −3
    p3 = 1/3
    p4 = g'(1)
    s = (p4 + t^2)^3
    alpha = inverse(t^2*(p4 + t^2))
    x1 = p1 − p2*t^4*alpha
    x2 = 1 − x1
    x3 = −1 − p3*s*alpha
    a1 = x1^3 + b'
    a2 = x2^3 + b'
    r1 = is_square(a1)
    r2 = is_square(a2)
    i = (r1 − 1)*(r2 − 3)/4 + 1
    c1 = CTEq(1, i)
    c2 = CTEq(2, i)
    c3 = CTEq(3, i)
    x = c1*x1 + c2*x2 + c3*x3
    y = sign0(t)*sqrt(x^3 + b')
    return (x, y)
end function
```

## Rationale
The current design choices reflect one choice of hashing algorithm.
There is freedom in choosing the HashToBase function
and this could easily be changed.
Within HashToBase, the particular hashing algorithm
(Keccak256 in our case) could also be modified.
It may be desired to change the call to `sign0`
at the end with `is_square`, as this would result
in the same deterministic map to curve from the
Fouque and Tibouchi
[paper](https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf)
and ensure HashToG1 is indifferentiable from a random oracle;
they proved this result in their paper.
It may be possible to show that switching the `is_square`
call with `sign0` does not affect indifferentiability,
although this has not been proven at this time.

[EIP-2537](./eip-2537.md)
would allow for similar BLS signatures to be computed on
the BLS12-381 elliptic curve.
This proposal calls for additional precompiled contracts
to allow for full use of pairing-based cryptography with
this elliptic curve.
This is the same rationale for wanting to add a hash-to-curve
algorithm for BN256.

## Backwards Compatibility
There are no backward compatibility concerns.

## Test Cases
No underlying algorithms are being changed and so there is no need
to specify additional test cases.

## Implementation
An implementation based on go-ethereum is forthcoming.
It will contain the aforementioned functions and the necessary
additions to the go-ethereum/crypto/bn256/cloudflare library.
These additions could also be ported to the other Ethereum platforms.
The required operations are inverses, square roots,
and Legendre symbols in GF(p) and GF(p^2).
These algorithms are straight-forward to implement.

## Security Considerations
Due to recent [work](https://eprint.iacr.org/2015/1027), the
128-bit security promised by the BN256 elliptic curve no longer applies;
this was mentioned in the Cloudflare BN256
[library](https://github.com/cloudflare/bn256).
There has been some discussion on the exact security decrease
from this advancement; see these
[two](https://eprint.iacr.org/2016/1102)
[papers](https://eprint.iacr.org/2017/334)
for different estimates.
The more conservative estimate puts the security of BN256 at
100-bits.
While this is likely still out of reach for many adversaries,
it should give one pause.
This reduced security was noted in the recent MadNet
[whitepaper](https://www.madnetwork.com/),
and this security concern was partially mitigated by
requiring Secp256k1 signatures of the partial group signatures
in order for those partial signatures to be valid.
Full disclosure: the author of this EIP works for MadHive,
assisted in the development of MadNet, and
helped write the MadNet whitepaper.

The security concerns of the BN256 elliptic curve
affect any operation using pairing check because it is
related to the elliptic curve pairing;
they are independent of this EIP.

## Copyright
Copyright and related rights waived via
[CC0](https://creativecommons.org/publicdomain/zero/1.0/).
