---
eip: 3445
title: Standardized Shamir Secret Sharing Scheme for BIP-39 Mnemonics
author: Daniel Streit (@danielstreit)
status: Draft
type: Standards Track
category: ERC
created: 2021-03-14
---

## Simple Summary

A standardized algorithm for applying Shamir's Secret Sharing Scheme to BIP-39 mnemonics.

## Abstract

A standardized approach to splitting a BIP-39 mnemonic into _N_ BIP-39 mnemonics, called shares, so that _T_ shares are required to recover the original
mnemonic and no information about the original mnemonic, other than its size, is leaked with less than _T_ shares.

## Motivation

Mnemonics are a great UX (and security) improvement over hex secrets. But, they are still a single point of failure.

Shamir's Secret Sharing Scheme is great for sharing secrets so that there is no single point of failure. But, there is no standard implementation of Sharmir's, putting recovery at risk.

In this EIP, we combine mnemonics with Sharmir's Secret Sharing Scheme and propose a standardized algorithm to make storing keys easier and more secure.

## Specification

For a general overview of Shamir's Secret Sharing Scheme see:

- [SLIP-0039: Shamir's Secret-Sharing for Mnemonic Codes](https://github.com/satoshilabs/slips/blob/master/slip-0039.md#shamirs-secret-sharing)
- [Wikipedia: Shamir's Secret Sharing](https://en.wikipedia.org/wiki/Shamir%27s_Secret_Sharing)

There are two operations: Splitting a BIP-39 mnemonic into shares and recovering the original mnemonic with a subset of the shares.

### Definition: Share

A share represents a point on the curve described by the underlying polynomial used to split the secret. It includes two pieces of data:

- An id: the _x_ value of the share
- A BIP-39 mnemonic: _f(x)_ converted to a mnemonic

### Polynomial Interpolation

Interpolation is used to recover the mnemonic. See [Recover Mnemonic](#recover-mnemonic) below.

This follows the [SLIP-0039 specification for polynomial interpolation](https://github.com/satoshilabs/slips/blob/master/slip-0039.md#polynomial-interpolation) closely.

Given a set of _K_ points (_x<sub>i</sub>_, _y<sub>i</sub>_), 1 ≤ _i_ ≤ _K_, such that no two _x<sub>i</sub>_ values equal,
there exists a polynomial that assumes the value _y<sub>i</sub>_ at each point _x<sub>i</sub>_. The polynomial of lowest degree
that satisfies these conditions is uniquely determined and can be obtained using the Lagrange interpolation formula given below.

Since Shamir's secret sharing scheme is applied separately to each of the _n_ bytes of the shared secret, we work with
_y<sub>i</sub>_ as a vector of _n_ values, where _y<sub>i</sub>_[_l_] = _f<sub>l</sub>_(_x<sub>i</sub>_), 1 ≤ _l_ ≤ _n_,
and _f<sub>j</sub>_ is the polynomial in the _j_-th instance of the scheme.

Interpolate(_x_, {(_x<sub>i</sub>_, _y<sub>i</sub>_), 1 ≤ _i_ ≤ _K_})

Input: the desired index _x_, a set of index/value-vector pairs {(_x<sub>i</sub>_, _y<sub>i</sub>_), 1 ≤ _i_ ≤ _K_} ⊆ GF(256) × GF(256)<sup>n</sup>

Output: the value-vector (_f<sub>1</sub>_(_x_), ... , _f<sub>n</sub>_(_x_))

_f<sub>l</sub>_(_x_) = $\sum_{i=1}^{K} y_i[l] \prod_{\underset{j \neq i}{j=1}}^{K} \frac{x - x_j}{x_i - x_j}$

### Split Mnemonic

Inputs: BIP-39 mnemonic, number of shares (_N_), threshold (_T_)
Output: N Shares, each share including an id (_x_ ⊆ GF(256)) and a BIP-39 mnemonic

1. Check the following conditions:
   - 1 < T <= N < 255
   - The mnemonic is a valid BIP-39 mnemonic
1. Convert the mnemonic to its underlying entropy
   - See [BIP-39: Generating the Mnemonic](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#generating-the-mnemonic) for precise steps
1. Define values:
   - Let _E_ be the entropy as a vector of bytes (ie, each value in the vector belongs to GF(256))
   - Let _n_ be the length of _E_
   - Let _coeff<sub>1</sub>_, ... , _coeff<sub>T - 1</sub>_ ∈ GF(256)_<sup>n</sup>_ be generated randomly, independently with uniform distribution from a source suitable for generating cryptographic keys
1. Evaluate the polynomial for each share
   - For each _x_ from 1 to _N_, evaluate the polynomial _f(x)_ = _E_ + _coeff<sub>1</sub>x<sup>1</sup>_ + ... + \*coeff<sub>T - 1</sub>x<sup>T - 1</sup>, where _x_ is the share id and _f(x)_ is the share value
1. Convert the share value to a BIP-39 mnemonic
   - As above, according to the [BIP-39 specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#generating-the-mnemonic)
1. Return the id (_x_) and mnemonic of each share

### Recover Mnemonic

Input: _K_ Shares, where _T_ <= K <= _N_
Output: The original BIP-39 mnemonic

1. Convert each share mnemonic into its underlying entropy
   - See [BIP-39: Generating the Mnemonic](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#generating-the-mnemonic) for precise steps
1. Define values:
   - Let _x<sub>k</sub>_ be the id of share _k_
   - Let _y<sub>k</sub>_ be a vector of bytes (ie, each value in the vector belongs to GF(256)) representing the entropy of share _k_
1. Calculate _E_ = Interpolate(0, [(_x<sub>1</sub>_, _y<sub>1</sub>_),...,(_x<sub>K</sub>_, _y<sub>K</sub>_)])
   - See [Polynomial Interpolation](#polynomial-interpolation) above
1. Convert _E_, the recovered entropy value, to a BIP-39 mnemonic
   - As above, according to the [BIP-39 specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#generating-the-mnemonic)

## Rationale

Although there is no standard implementation of Shamir's algorithm, there are a lot of commonalities between implementations. We've tried
to align with these as much as possible:

- 8 bit Galois field for arithmetic
- Storing the secret a _x_ = 0

## Test Cases

[Test vectors](https://github.com/danielstreit/shamir-bip-39/blob/272333114ce03dfb5f4ed94f7ddb22e7cc0c93c4/test/vectors.ts)

All implementations must be able to:

- Split and recover each `mnemonic` with the given `numShares` and `threshold`.
- Recover the `mnemonic` from the given `knownShares`.

## Reference Implementation

https://github.com/danielstreit/shamir-bip-39

## Security Considerations

The shares produced by the specification include an id in addition to the BIP-39 mnemonic. This raises two security concerns:

Users **must** keep this id in order to recover the original mnemonic. If the id is lost, or separated from the share mnemonic, it may not be
possible to recover the original. (Brute force recovery may or may not be possible depending on how much is known about the number of shares and threshold)

The additional data may hint to an attacker of the existence of other keys and the scheme under which they are stored. Ideally,
if we could only store the BIP-39 mnemonic, this would be indistinguishable from any other BIP-39 mnemonic and an attacker may not
look for additional shares. If an attacker recognized that the BIP-39 mnemonic came with an id, it might hint to them that there
are additional shares.

A potential alternative specification might include a "digest" in the polynomial that could be used to validate the recovered secret. See
[SLIP-0039]
If we combined this validation with a limited share count so that we could brute force the ids by attempting every permutation of
shares and ids until we recovered a valid mnemonic, we could avoid storing the id.

We decided against this approach and in favor of storing the id because, while the id may leak some information, recovery validation also leaks information.
Without validation, an attacker may never know when they have sufficient shares for recovery. With validation, the status of recovery is known.

To mitigate leaking information, users can consider using an alias for ids.

## References and Credits

This specification leans heavily on prior work, including:

- The [SLIP-0039 Specification](https://github.com/satoshilabs/slips/blob/master/slip-0039.md)
- Grempe's [secrets.js](https://github.com/grempe/secrets.js) implementation of Shamir's Secret Sharing Scheme

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
