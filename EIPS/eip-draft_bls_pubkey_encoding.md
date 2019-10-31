---
eip: <to be assigned>
title: BLS12-381 Public Key Checksums
author: Carl Beekhuizen (carl@ethereum.org)
discussions-to: <URL> <!--Todo-->
status: Draft
type: Standards Track
category: ERC
created: 2019-09-30
---

## Simple Summary

An encoding scheme for BLS12-381 public keys that provides checksums to reduce errors.

## Abstract

An encoding scheme in a similar vein to [Bech32](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki) for BLS12-381 points. It allows for the detection of several errors within a public key and therefor reduces the chance of mistakes arising in public keys.

## A note on purpose

This specification is designed not only to be an Ethereum 2.0 standard, but one that is adopted by the wider community who have adopted the BLS12-381 signature standard. It is therefore important also to consider the needs of the wider industry along with those specific to Ethereum. As a part of these considerations, it is the intention of the author that this standard eventually migrate to a more neutral repository in the future.

## Motivation

Checksums for PubKeys help reduce errors in the use of PubKeys. Establishing a standard for key-encoding before BLS12-381 sees widespread adoption will allow for the proliferation of a single standard.

Eth1 encodes the bit parity of the Keccak hash of a key in the case of its characters. There are several drawbacks to this scheme:

- Accessibility -it is easy to overlook the case of a letter or two
- Mixed case cannot make use of the QR-code ASCII mode
- Very hard to to write down keys
- Hard to communicate keys verbally
- An error is *only* detectable in 39/40 cases
- The location of an error is not known

### Enter Bech32

Bitcoin addresses are encoded with [Bech32 checksums](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki). These solve most of the above problems and are based on well-studied error detection/correction techniques.

It would be nice therefore to encode BLS12-381 keys using a similar scheme. Unfortunately this is not possible as it stands as Bech32 has a bunch of Segwit garbage bundled with it. Furthermore, even with the removal of the Segwit componentry, Bech32 can only support keys <= 445 bits. While such a limit works for Eth2 keys, other projects involved with the BLS standardisation efforts use pubkeys in $G2$ which are 768 bits.

## Specification

_There is no standard to speak of here yet, this is a call to action/placeholder for a specification._

Bech32 did a lot of great work choosing a sensible alphabet and encoding scheme so reusing as much of that as possible seems sensible.

Increasing the length of `data` is a not trivial exercise. Doing so requires finding a new polynomial or new alphabet for encoding.

Changing the alphabet is an option, but requires re-engineering all the Bech32 work as well as all of the work for the polynomial as the underlying field has changed.

Defining a new polynomial with more coefficients seems to be the most sensible choice then. While the literature on BCH codes gives lower bounds for the number of errors that can be detected and corrected, the actual limit may be much higher.

The polynomial was chosen by enumerating all of the polynomials within the field and testing their correction abilities. See [the specs](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki#checksum-design), [the enumeration code](https://github.com/sipa/ezbase32/), and [Pieter Wuille's talk](https://www.youtube.com/watch?v=NqiN9VFE4CU).

## Rationale

_There is no standard to speak of here yet, this is a call to action/placeholder for a specification._

## Backwards Compatibility

There are no major backwards compatibility issues brought upon by this EIP as it is not designed for use within Ethereum 1.0 as it currently stands.

## Test Cases

_There is no standard to speak of here yet, this is a call to action/placeholder for a specification._

## Implementation

_There is no standard to speak of here yet, this is a call to action/placeholder for a specification._

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
