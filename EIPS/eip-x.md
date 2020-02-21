---
eip: <to be assigned>
title: BLS12-381
author: <a list of the author's or authors' name(s) and/or username(s), or name(s) and email(s), e.g. (use with the parentheses or triangular brackets): FirstName LastName (@GitHubUsername), FirstName LastName <foo@bar.com>, FirstName (@GitHubUsername) and GitHubUsername (@GitHubUsername)>
discussions-to: <URL>
status: Draft
type: Standards Track
category (*only required for Standard Track): Core
created: <date created on, in ISO 8601 (yyyy-mm-dd) format>
requires (*optional): EIP1109
replaces (*optional): -
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

This precompile adds operation on BLS12-381 curve as a precompile in a set necessary to *efficiently* perform operations such as BLS signature verification and perform SNARKs verifications.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

If `block.number >= X` we introduce *seven* separate precompiles to perform the following operations (addresses to be determined):

- G1ADD - to perform point addition on a curve defined over prime field
- G1MUL - to perform point multiplication on a curve defined over prime field
- G1MULTIEXP - to perform multiexponentiation on a curve defined over prime field
- G2ADD - to perform point addition on a curve twist defined over quadratic extension of the base field
- G1MUL - to perform point multiplication on a curve twist defined over quadratic extension of the base field
- G1MULTIEXP - to perform multiexponentiation on a curve twist defined over quadratic extension of the base field
- PAIRING - to perform a pairing operations between a set of *pairs* of (G1, G2) points

Multiexponentiation operation is included to efficiently aggregate public keys or individual signer's signatures during BLS signature verification.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

Motivation of this precompile is to add a cryptographic primitive that allows to get 120+ bits of security for operations over pairing friendly curve compared to the existing BN254 precompile that only provides 80 bits of security.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

Curve parameters:

BLS12 curve is fully defined by the following set of parameters:

```
Base field modulus = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
B coefficient = 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
Main subgroup order = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
Extension tower
Fp2 construction:
Fp quadratic non-residue = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa
Fp6/Fp12 construction:
Fp2 quandratic non-residue c0 = 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
Fp2 quandratic non-residue c1 = 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
Twist parameters:
Twist type: M
B coefficient for twist c0 = 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
B coefficient for twist c1 = 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
Generators:
G1:
X = 0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb
Y = 0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1
G2:
X c0 = 0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8
X c1 = 0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e
Y c0 = 0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801
Y c1 = 0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be
Pairing parameters:
|x| (miller loop scalar) = 0xd201000000010000
x is negative = true
```

#### Fine points and encoding of base elements

##### Field elements encoding:

To encode points involved in the operation one has to encode elements of the base field and the extension field.

Base field element (Fp) is encoded as `48` bytes by performing BigEndian encoding of the corresponding (unsigned) integer. Corresponding integer **must** be less than field modulus.

For elements of the quadratic extension field (Fp2) encoding is byte concatenation of individual encoding of the coefficients totaling in `96` bytes for a total encoding. For an Fp2 element in a form `el = c0 + c1 * v` where `v` is formal quadratic non-residue corresponding byte encoding will be `encode(c0) || encode(c1)` where `||` means byte concatenation.

##### Encoding of points:

Points in either G1 (in base field) or in G2 (in extension field) are encoded as byte concatenation of encodings of the `x` and `y` affine coordinates. Total encoding length for G1 point is thus `96` bytes and for G2 point is `192` bytes.

##### Point of infinity encoding:

Also refered as "zero point". For BLS12 curves point with coordinates `(0, 0)` (formal zeroes in Fp or Fp2) is *not* on the curve, so encoding of such point `(0, 0)` is used as a convention to encode point of infinity.

##### Boolean encoding for subgroup checks:

For subgroup checks it's required to encode a whether it's required to run a subgroup check for the G1/G2 point. For this we encode a boolean as a *single byte* `0x00` for `false` and `0x01` for `true`.

##### Encoding of scalars for multiplication operation:

Scalar for multiplication operation is encoded as `32` bytes by performing BigEndian encoding of the corresponding (unsigned) integer. Corresponding integer is **not** required to be less than or equal than main subgroup size.

#### ABI for operations

TBD

#### Gas schedule

Assuming a constant `30 MGas/second` following prices are suggested.

##### G1 addition

`600` gas

##### G1 multiplication

`12000` gas

##### G2 addition

`4500` gas

##### G2 multiplication

`55000` gas

##### G1/G2 Multiexponentiation

TBD

##### Pairing operaiton

Base cost of the pairing operation is `23000*k + 80000` where `k` is a number of pairs.

Each point for which subgroup check is performed adds the corresponding G1/G2 multiplication cost to it.


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Motivation section covers a total motivation to have operations over BLS12-381 curve available. We also extend a rationale for move specific fine points.

#### Multiexponentiation as a separate call

Explicit separate multiexponentiation operation that allows one to save execution time (so gas) by both the algorithm used (namely Peppinger algorithm) and (usually forgotten) by the fact that `CALL` operation in Ethereum is expensive (at the time of writing), so one would have to pay non-negigible overhead if e.g. for multiexponentiation of `100` points would have to call the multipication precompile `100` times and addition for `99` times (roughly `138600` would be saved).


#### Explicit subgroup checks

Subgroup checks are made optional both due to the fact that they can be performed explicitly by the caller (by multiplication operation) and due to the fact that subgroup checks in G2 that are expensive are not required in most of the cases cause G2 points are usually "hardcoded" and not supplied by the untrusted third party.

Concretely, G2 subgroup check is around `50000` gas.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
There are no backward compatibility questions.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
Test vectors for all operations.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
There is a various choice of existing implementations:
- BLS12 code bases for Eth 2.0 clients
- EIP1962 code bases with fixed parameters

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
Strictly following the spec will eliminate security implications or consensus implications in a contrast to the previous BN254 precompile.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).