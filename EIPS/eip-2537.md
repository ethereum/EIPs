---
eip: 2537
title: Precompile for BLS12-381 curve operations
author: Alex Vlasov (@shamatar), Kelly Olson (@ineffectualproperty), Alex Stokes (@ralexstokes)
discussions-to: https://ethereum-magicians.org/t/eip2537-bls12-precompile-discussion-thread/4187
status: Stagnant
type: Standards Track
category: Core
created: 2020-02-21
---

## Simple Summary

This precompile adds operation on BLS12-381 curve as a precompile in a set necessary to *efficiently* perform operations such as BLS signature verification and perform SNARKs verifications.

## Abstract

If `block.number >= X` we introduce *nine* separate precompiles to perform the following operations:

- BLS12_G1ADD - to perform point addition in G1 (curve over base prime field) with a gas cost of `500` gas
- BLS12_G1MUL - to perform point multiplication in G1 (curve over base prime field) with a gas cost of `12000` gas
- BLS12_G1MULTIEXP - to perform multiexponentiation in G1 (curve over base prime field) with a gas cost formula defined in the corresponding section
- BLS12_G2ADD - to perform point addition in G2 (curve over quadratic extension of the base prime field) with a gas cost of `800` gas
- BLS12_G2MUL - to perform point multiplication in G2 (curve over quadratic extension of the base prime field) with a gas cost of `45000` gas
- BLS12_G2MULTIEXP - to perform multiexponentiation in G2 (curve over quadratic extension of the base prime field) with a gas cost formula defined in the corresponding section
- BLS12_PAIRING - to perform a pairing operations between a set of *pairs* of (G1, G2) points a gas cost formula defined in the corresponding section
- BLS12_MAP_FP_TO_G1 - maps base field element into the G1 point with a gast cost of `5500` gas
- BLS12_MAP_FP2_TO_G2 - maps extension field element into the G2 point with a gas cost of `75000` gas

Mapping functions specification is included as a separate [document](../assets/eip-2537/field_to_curve.md). Mapping function does NOT perform mapping of the byte string into field element (as it can be implemented in many different ways and can be efficiently performed in EVM), but only does field arithmetic to map field element into curve point. Such functionality is required for signature schemes.

Multiexponentiation operation is included to efficiently aggregate public keys or individual signer's signatures during BLS signature verification.

### Proposed addresses table

|Precompile   |Address   |
|---|---|
|BLS12_G1ADD          | 0x0c  |
|BLS12_G1MUL          | 0x0d  |
|BLS12_G1MULTIEXP     | 0x0e  |
|BLS12_G2ADD          | 0x0f  |
|BLS12_G2MUL          | 0x10  |
|BLS12_G2MULTIEXP     | 0x11  |
|BLS12_PAIRING        | 0x12  |
|BLS12_MAP_FP_TO_G1   | 0x13  |
|BLS12_MAP_FP2_TO_G2  | 0x14  |

## Motivation

Motivation of this precompile is to add a cryptographic primitive that allows to get 120+ bits of security for operations over pairing friendly curve compared to the existing BN254 precompile that only provides 80 bits of security.

## Specification

Curve parameters:

BLS12 curve is fully defined by the following set of parameters (coefficient `A=0` for all BLS12 curves):

```
Base field modulus = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
B coefficient = 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
Main subgroup order = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
Extension tower
Fp2 construction:
Fp quadratic non-residue = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa
Fp6/Fp12 construction:
Fp2 cubic non-residue c0 = 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
Fp2 cubic non-residue c1 = 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
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

One should note that base field modulus is equal to `3 mod 4` that allows an efficient square root extraction, although as described below gas cost of decompression is larger than gas cost of supplying decompressed point data in `calldata`.

### Fine points and encoding of base elements

#### Field elements encoding:

To encode points involved in the operation one has to encode elements of the base field and the extension field.

Base field element (Fp) is encoded as `64` bytes by performing BigEndian encoding of the corresponding (unsigned) integer (top `16` bytes are always zeroes). `64` bytes are chosen to have `32` byte aligned ABI (representable as e.g. `bytes32[2]` or `uint256[2]`). Corresponding integer **must** be less than field modulus.

For elements of the quadratic extension field (Fp2) encoding is byte concatenation of individual encoding of the coefficients totaling in `128` bytes for a total encoding. For an Fp2 element in a form `el = c0 + c1 * v` where `v` is formal quadratic non-residue and `c0` and `c1` are Fp elements the corresponding byte encoding will be `encode(c0) || encode(c1)` where `||` means byte concatenation (or one can use `bytes32[4]` or `uint256[4]` in terms of Solidity types).

*Note on the top `16` bytes being zero*: it's required that the encoded element is "in a field" that means strictly `< modulus`. In BigEndian encoding it automatically means that for a modulus that is just `381` bit long top `16` bytes in `64` bytes encoding are zeroes and it **must** be checked if only a subslice of input data is used for actual decoding.

If encodings do not follow this spec anywhere during parsing in the precompile the precompile *must* return an error.

#### Encoding of points in G1/G2:

Points in either G1 (in base field) or in G2 (in extension field) are encoded as byte concatenation of encodings of the `x` and `y` affine coordinates. Total encoding length for G1 point is thus `128` bytes and for G2 point is `256` bytes.

#### Point of infinity encoding:

Also referred to as "zero point". For BLS12 curves point with coordinates `(0, 0)` (formal zeroes in Fp or Fp2) is *not* on the curve, so encoding of such point `(0, 0)` is used as a convention to encode point of infinity.

#### Encoding of scalars for multiplication operation:

Scalar for multiplication operation is encoded as `32` bytes by performing BigEndian encoding of the corresponding (unsigned) integer. Corresponding integer is **not** required to be less than or equal than main subgroup size.

#### Behavior on empty inputs:

Certain operations have variable length input, such as multiexponentiations (takes a list of pairs `(point, scalar)`), or pairing (takes a list of `(G1, G2)` points). While their behavior is well-defined (from arithmetic perspective) on empty inputs, this EIP discourages such use cases and variable input length operations must return an error if input is empty.

### ABI for operations

#### ABI for G1 addition

G1 addition call expects `256` bytes as an input that is interpreted as byte concatenation of two G1 points (`128` bytes each). Output is an encoding of addition operation result - single G1 point (`128` bytes).

Error cases:

- Either of points being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

#### ABI for G1 multiplication

G1 multiplication call expects `160` bytes as an input that is interpreted as byte concatenation of encoding of G1 point (`128` bytes) and encoding of a scalar value (`32` bytes). Output is an encoding of multiplication operation result - single G1 point (`128` bytes).

Error cases:

- Point being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

#### ABI for G1 multiexponentiation

G1 multiexponentiation call expects `160*k` bytes as an input that is interpreted as byte concatenation of `k` slices each of them being a byte concatenation of encoding of G1 point (`128` bytes) and encoding of a scalar value (`32` bytes). Output is an encoding of multiexponentiation operation result - single G1 point (`128` bytes).

Error cases:

- Any of G1 points being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length
- Input is empty

#### ABI for G2 addition

G2 addition call expects `512` bytes as an input that is interpreted as byte concatenation of two G2 points (`256` bytes each). Output is an encoding of addition operation result - single G2 point (`256` bytes).

Error cases:

- Either of points being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

#### ABI for G2 multiplication

G2 multiplication call expects `288` bytes as an input that is interpreted as byte concatenation of encoding of G2 point (`256` bytes) and encoding of a scalar value (`32` bytes). Output is an encoding of multiplication operation result - single G2 point (`256` bytes).

Error cases:

- Point being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

#### ABI for G2 multiexponentiation

G2 multiexponentiation call expects `288*k` bytes as an input that is interpreted as byte concatenation of `k` slices each of them being a byte concatenation of encoding of G2 point (`256` bytes) and encoding of a scalar value (`32` bytes). Output is an encoding of multiexponentiation operation result - single G2 point (`256` bytes).

Error cases:

- Any of G2 points being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length
- Input is empty

#### ABI for pairing

Pairing call expects `384*k` bytes as an inputs that is interpreted as byte concatenation of `k` slices. Each slice has the following structure:

- `128` bytes of G1 point encoding
- `256` bytes of G2 point encoding

Output is a `32` bytes where first `31` bytes are equal to `0x00` and the last byte is `0x01` if pairing result is equal to multiplicative identity in a pairing target field and `0x00` otherwise.

Error cases:

- Any of G1 or G2 points being not on the curve must result in error
- Any of G1 or G2 points are not in the correct subgroup
- Field elements encoding rules apply (obviously)
- Input has invalid length
- Input is empty

#### ABI for mapping Fp element to G1 point

Field-to-curve call expects `64` bytes an an input that is interpreted as a an element of the base field. Output of this call is `128` bytes and is G1 point following respective encoding rules.

Error cases:

- Input has invalid length
- Input is not a valid field element

#### ABI for mapping Fp2 element to G2 point

Field-to-curve call expects `128` bytes an an input that is interpreted as a an element of the quadratic extension field. Output of this call is `256` bytes and is G2 point following respective encoding rules.

Error cases:

- Input has invalid length
- Input is not a valid field element

### Gas burinig on error

Following the current state of all other precompiles if call to one of the precompiles in this EIP results in an error then all the gas supplied along with a `CALL` or `STATICCALL` is burned.

### DDoS protection

Sane implementation of this EIP *should not* contain infinite cycles (it is possible and not even hard to implement all the functionality without `while` cycles) and gas schedule accurately reflects a time spent on computations of the corresponding function (precompiles pricing reflects an amount of gas consumed in the worst case where such case exists).

### Gas schedule

Assuming a constant `30 MGas/second` following prices are suggested.

#### G1 addition

`500` gas

#### G1 multiplication

`12000` gas

#### G2 addition

`800` gas

#### G2 multiplication

`45000` gas

#### G1/G2 Multiexponentiation

Multiexponentiations are expected to be performed by the Peppinger algorithm (we can also say that is **must** be performed by Peppinger algorithm to have a speedup that results in a discount over naive implementation by multiplying each pair separately and adding the results). For this case there was a table prepared for discount in case of `k <= 128` points in the multiexponentiation with a discount cup `max_discount` for `k > 128`.

To avoid non-integer arithmetic call cost is calculated as `(k * multiplication_cost * discount) / multiplier` where `multiplier = 1000`, `k` is a number of (scalar, point) pairs for the call, `multiplication_cost` is a corresponding single multiplication call cost for G1/G2.

Discounts table as a vector of pairs `[k, discount]`:

```
[[1, 1200], [2, 888], [3, 764], [4, 641], [5, 594], [6, 547], [7, 500], [8, 453], [9, 438], [10, 423], [11, 408], [12, 394], [13, 379], [14, 364], [15, 349], [16, 334], [17, 330], [18, 326], [19, 322], [20, 318], [21, 314], [22, 310], [23, 306], [24, 302], [25, 298], [26, 294], [27, 289], [28, 285], [29, 281], [30, 277], [31, 273], [32, 269], [33, 268], [34, 266], [35, 265], [36, 263], [37, 262], [38, 260], [39, 259], [40, 257], [41, 256], [42, 254], [43, 253], [44, 251], [45, 250], [46, 248], [47, 247], [48, 245], [49, 244], [50, 242], [51, 241], [52, 239], [53, 238], [54, 236], [55, 235], [56, 233], [57, 232], [58, 231], [59, 229], [60, 228], [61, 226], [62, 225], [63, 223], [64, 222], [65, 221], [66, 220], [67, 219], [68, 219], [69, 218], [70, 217], [71, 216], [72, 216], [73, 215], [74, 214], [75, 213], [76, 213], [77, 212], [78, 211], [79, 211], [80, 210], [81, 209], [82, 208], [83, 208], [84, 207], [85, 206], [86, 205], [87, 205], [88, 204], [89, 203], [90, 202], [91, 202], [92, 201], [93, 200], [94, 199], [95, 199], [96, 198], [97, 197], [98, 196], [99, 196], [100, 195], [101, 194], [102, 193], [103, 193], [104, 192], [105, 191], [106, 191], [107, 190], [108, 189], [109, 188], [110, 188], [111, 187], [112, 186], [113, 185], [114, 185], [115, 184], [116, 183], [117, 182], [118, 182], [119, 181], [120, 180], [121, 179], [122, 179], [123, 178], [124, 177], [125, 176], [126, 176], [127, 175], [128, 174]]
```

`max_discount = 174`

#### Pairing operation

Cost of the pairing operation is `43000*k + 65000` where `k` is a number of pairs.

#### Fp-to-G1 mapping operation

Fp -> G1 mapping is `5500` gas.

#### Fp2-to-G2 mapping operation

Fp2 -> G2 mapping is `75000` gas

#### Gas schedule clarifications for the variable-length input

For multiexponentiation and pairing functions gas cost depends on the input length. The current state of how gas schedule is implemented in major clients (at the time of writing) is that gas cost function does *not* perform any validation of the length of the input and never returns an error. So we present a list of rules how gas cost functions **must** be implemented to ensure consistency between clients and safety.

##### Gas schedule clarifications for G1/G2 Multiexponentiation

Define a constant `LEN_PER_PAIR` that is equal to `160` for G1 operation and to `288` for G2 operation. Define a function `discount(k)` following the rules in the corresponding section, where `k` is number of pairs.

The following pseudofunction reflects how gas should be calculated:

```
  k = floor(len(input) / LEN_PER_PAIR);
  if k == 0 {
    return 0;
  }

  gas_cost = k * multiplication_cost * discount(k) / multiplier;

  return gas_cost;

```

We use floor division to get number of pairs. If length of the input is not divisible by `LEN_PER_PAIR` we still produce *some* result, but later on precompile will return an error. Also, case when `k = 0` is safe: `CALL` or `STATICCALL` cost is non-zero, and case with formal zero gas cost is already used in `Blake2f` precompile. In any case, main precompile routine **must** produce an error on such an input because it violated encoding rules.

##### Gas schedule clarifications for pairing

Define a constant `LEN_PER_PAIR = 384`;

The following pseudofunction reflects how gas should be calculated:

```
  k = floor(len(input) / LEN_PER_PAIR);

  gas_cost = 23000*k + 115000;

  return gas_cost;

```

We use floor division to get number of pairs. If length of the input is not divisible by `LEN_PER_PAIR` we still produce *some* result, but later on precompile will return an error (precompile routine **must** produce an error on such an input because it violated encoding rules).

## Rationale

Motivation section covers a total motivation to have operations over BLS12-381 curve available. We also extend a rationale for move specific fine points.

### Multiexponentiation as a separate call

Explicit separate multiexponentiation operation that allows one to save execution time (so gas) by both the algorithm used (namely Peppinger algorithm) and (usually forgotten) by the fact that `CALL` operation in Ethereum is expensive (at the time of writing), so one would have to pay non-negigible overhead if e.g. for multiexponentiation of `100` points would have to call the multipication precompile `100` times and addition for `99` times (roughly `138600` would be saved).

## Backwards Compatibility

There are no backward compatibility questions.

## Important notes

### Subgroup checks

Subgroup check **is mandatory** during the pairing call. Implementations *should* use fast subgroup checks: at the time of writing multiplication gas cost is based on `double-and-add` multiplication method that has a clear "worst case" (all bits are equal to one). For pairing operation it's expected that implementation uses faster subgroup check, e.g. by using wNAF multiplication method for elliptic curves that is ~ `40%` cheaper with windows size equal to 4. (Tested empirically. Savings are due to lower hamming weight of the group order and even lower hamming weight for wNAF. Concretely, subgroup check for both G1 and G2 points in a pair are around `35000` combined).

### Field to curve mapping

Algorithms and set of parameters for SWU mapping method is provided by a separate [document](../assets/eip-2537/field_to_curve.md)

## Test Cases

Due to the large test parameters space we first provide properties that various operations must satisfy. We use additive notation for point operations, capital letters (`P`, `Q`) for points, small letters (`a`, `b`) for scalars. Generator for G1 is labeled as `G`, generator for G2 is labeled as `H`, otherwise we assume random point on a curve in a correct subgroup. `0` means either scalar zero or point of infinity. `1` means either scalar one or multiplicative identity. `group_order` is a main subgroup order. `e(P, Q)` means pairing operation where `P` is in G1, `Q` is in G2.

Required properties for basic ops (add/multiply):

- Commutativity: `P + Q = Q + P`
- Additive negation: `P + (-P) = 0`
- Doubling `P + P = 2*P`
- Subgroup check: `group_order * P = 0`
- Trivial multiplication check: `1 * P = P`
- Multiplication by zero: `0 * P = 0`
- Multiplication by the unnormalized scalar `(scalar + group_order) * P = scalar * P`

Required properties for pairing operation:

- Degeneracy `e(P, 0*Q) = e(0*P, Q) = 1`
- Bilinearity `e(a*P, b*Q) = e(a*b*P, Q) = e(P, a*b*Q)` (internal test, not visible through ABI)

### Benchmarking test cases

A set of test vectors for quick benchmarking on new implementations is located in a separate [file](../assets/eip-2537/bench_vectors.md)

## Reference Implementation

There are two fully spec compatible implementations on the day of writing:

- One in Rust language that is based on the EIP1962 code and integrated with OpenEthereum for this library
- One implemented specifically for Geth as a part of the current codebase

## Security Considerations

Strictly following the spec will eliminate security implications or consensus implications in a contrast to the previous BN254 precompile.

Important topic is a "constant time" property for performed operations. We explicitly state that this precompile **IS NOT REQUIRED** to perform all the operations using constant time algorithms.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
