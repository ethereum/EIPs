---
eip: xxxx
title: BW6-761 curve operations
author: Youssef El Housni (@yelhousni)
discussions-to:
status: Draft
type: Standards Track
category: Core
created:
requires : xxxx
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

his precompile adds operations on BW6-761 curve (from EY/Inria  [research paper](https://eprint.iacr.org/2020/351.pdf)) as a precompile in a set necessary to *efficiently* perform SNARKs verification for efficient one-layer composed proofs. It is inteded to replace the SW6 curve (from Zexe paper) for performance reasons.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

If `block.number >= X` we introduce *seven* separate precompiles to perform the following operations (addresses to be determined):

- G1ADD - to perform point addition on a curve defined over prime field
- G1MUL - to perform point multiplication on a curve defined over prime field
- G1MULTIEXP - to perform multiexponentiation on a curve defined over prime field
- G2ADD - to perform point addition on a curve twist defined over quadratic extension of the base field
- G2MUL - to perform point multiplication on a curve twist defined over quadratic extension of the base field
- G2MULTIEXP - to perform multiexponentiation on a curve twist defined over quadratic extension of the base field
- PAIRING - to perform a pairing operations between a set of *pairs* of (G1, G2) points

Multiexponentiation operation is included to efficiently aggregate public keys or individual signer's signatures during BLS signature verification, as well as public inputs in SNARKs.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

Motivation of this precompile is to allow efficient one layer composition of SNARK proofs. Currently this is done by Zexe using the BW6-761/SW6 pair of curves. This precompile proposes a replacement of SW6 by BW6-761 which allows five times faster verification.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

Curve parameters:

BW6-761 (y^2=x^3-1) curve is fully defined by the following set of parameters:

```
Base field modulus = 0x122e824fb83ce0ad187c94004faff3eb926186a81d14688528275ef8087be41707ba638e584e91903cebaff25b423048689c8ed12f9fd9071dcd3dc73ebff2e98a116c25667a8f8160cf8aeeaf0a437e6913e6870000082f49d00000000008b
A coefficient = 0x0
B coefficient = 0x122e824fb83ce0ad187c94004faff3eb926186a81d14688528275ef8087be41707ba638e584e91903cebaff25b423048689c8ed12f9fd9071dcd3dc73ebff2e98a116c25667a8f8160cf8aeeaf0a437e6913e6870000082f49d00000000008b
Main subgroup order = 0x1ae3a4617c510eac63b05c06ca1493b1a22d9f300f5138f1ef3622fba094800170b5d44300000008508c00000000001
Extension tower:
Fp3 construction:
Fp cubic non-residue = 0x2
Fp6 construction:
Fp2 quadratic non-residue c0 = 0x0
                          c1 = 0x1
                          c3 = 0x0
Twist parameters:
Twist type: M
B coefficient for twist c0 = 0x4
                        c1 = 0x0
Generators:
G1:
X = 0x1075b020ea190c8b277ce98a477beaee6a0cfb7551b27f0ee05c54b85f56fc779017ffac15520ac11dbfcd294c2e746a17a54ce47729b905bd71fa0c9ea097103758f9a280ca27f6750dd0356133e82055928aca6af603f4088f3af66e5b43d
Y = 0x58b84e0a6fc574e6fd637b45cc2a420f952589884c9ec61a7348d2a2e573a3265909f1af7e0dbac5b8fa1771b5b806cc685d31717a4c55be3fb90b6fc2cdd49f9df141b3053253b2b08119cad0fb93ad1cb2be0b20d2a1bafc8f2db4e95363
G2:
X = 0x110133241d9b816c852a82e69d660f9d61053aac5a7115f4c06201013890f6d26b41c5dab3da268734ec3f1f09feb58c5bbcae9ac70e7c7963317a300e1b6bace6948cb3cd208d700e96efbc2ad54b06410cf4fe1bf995ba830c194cd025f1c
Y = 0x17c3357761369f8179eb10e4b6d2dc26b7cf9acec2181c81a78e2753ffe3160a1d86c80b95a59c94c97eb733293fef64f293dbd2c712b88906c170ffa823003ea96fcd504affc758aa2d3a3c5a02a591ec0594f9eac689eb70a16728c73b61
Pairing parameters:
|loop_count_1| (first miller loop count) = 0x8508c00000000002
|loop_count_2| (first miller loop count) = 0x23ed1347970dec008a442f991fffffffffffffffffffffff
loop_count_1 is negative = false
loop_count_2 is negative = false
```

#### Fine points and encoding of base elements

##### Field elements encoding:

To encode points involved in the operation one has to encode elements of only the base field.

Base field element (Fp) is encoded as `96` bytes by performing BigEndian encoding of the corresponding (unsigned) integer. Corresponding integer **must** be less than field modulus.

If encodings to not follow this spec anywhere during parsing in the precompile the precompile *must* return an error.

##### Encoding of uncompressed points:

Points in either G1 (in base field) or in G2 (in base field too) are encoded as byte concatenation of encodings of the `x` and `y` affine coordinates. Total encoding length for a G1/G2 point is thus `96` bytes.

##### Point of infinity encoding:

Also referred as "zero point". For BW6-761 (y^2=x^3-1) and its M-twisted (y^3=x^3+4) curves, point with coordinates `(0, 0)` (formal zeroes in Fp) is *not* on the curve, so encoding of such point `(0, 0)` is used as a convention to encode point of infinity.

##### Boolean encoding for subgroup checks:

For subgroup checks it's required to encode whether it's required to run a subgroup check for the G1/G2 point or not. For this we encode a boolean as a *single byte* `0x00` for `false` and `0x01` for `true`.

##### Encoding of scalars for multiplication operation:

Scalar for multiplication operation is encoded as `48` bytes by performing BigEndian encoding of the corresponding (unsigned) integer. Corresponding integer is **not** required to be less than or equal than main subgroup size.

#### ABI for operations

##### ABI for G1 addition

G1 addition call expects `384` bytes as an input that is interpreted as byte concatenation of two G1 points (`192` bytes each). Output is an encoding of addition operation result.

Error cases:
- Either of points being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

##### ABI for G1 multiplication

G1 multiplication call expects `240` bytes as an input that is interpreted as byte concatenation of encoding of G1 point (`192` bytes) and encoding of a scalar value (`48` bytes). Output is an encoding of multiplication operation result.

Error cases:
- Point being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

##### ABI for G1 multiexponentiation

G1 multiplication call expects `240*k` bytes as an input that is interpreted as byte concatenation of `k` slices each of them being a byte concatenation of encoding of G1 point (`192` bytes) and encoding of a scalar value (`48` bytes). Output is an encoding of multiexponentiation operation result.

Error cases:
- Any of G1 points being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

##### ABI for G2 addition

G2 addition call expects `384` bytes as an input that is interpreted as byte concatenation of two G2 points (`192` bytes each). Output is an encoding of addition operation result.

Error cases:
- Either of points being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

##### ABI for G2 multiplication

G2 multiplication call expects `240` bytes as an input that is interpreted as byte concatenation of encoding of G2 point (`192` bytes) and encoding of a scalar value (`48` bytes). Output is an encoding of multiplication operation result.

Error cases:
- Point being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

##### ABI for G2 multiexponentiation

G2 multiplication call expects `240*k` bytes as an input that is interpreted as byte concatenation of `k` slices each of them being a byte concatenation of encoding of G2 point (`192` bytes) and encoding of a scalar value (`48` bytes). Output is an encoding of multiexponentiation operation result.

Error cases:
- Any of G2 points being not on the curve must result in error
- Field elements encoding rules apply (obviously)
- Input has invalid length

##### ABI for pairing

Pairing call expects `386*k` bytes as an inputs that is interpreted as byte concatenation of `k` slices. Each slice has the following structure:
- single byte to encode if the following G1 point needs a subgroup check
- `192` bytes of G1 point encoding
- single byte to encode if the following G2 point needs a subgroup check
- `192` bytes of G2 point encoding

Output is a single byte `0x01` if pairing result is equal to multiplicative identity in a pairing target field and `0x00` otherwise.

Error cases:
- Invalid encoding of any boolean variable must result in error
- Any of G1 or G2 points being not on the curve must result in error
- Any of G1 or G2 points for which subgroup check is requested in not actually in a subgroup
- Field elements encoding rules apply (obviously)
- Input has invalid length

#### TODO: Gas schedule

Assuming a constant `30 MGas/second` following prices are suggested.

##### G1 addition

`XXX` gas

##### G1 multiplication

`XXXXX` gas

##### G2 addition

`XXXX` gas

##### G2 multiplication

`XXXXX` gas

##### G1/G2 Multiexponentiation

Multiexponentiations are expected to be performed by the Peppinger algorithm. For this case there was a table prepared for discount in case of `k <= 128` points in the multiexponentiation with a discount cup `max_discount` for `k > 128`.

To avoid non-integer arithmetic call cost is calculated as `k * multiplication_cost * discount / multiplier` where `multiplier = 1000`, `k` is a number of (scalar, point) pairs for the call, `multiplication_cost` is a corresponding single multiplication call cost for G1/G2.

Discounts table as a vector of pairs `[k, discount]`:

```
[[1, 1200], [2, 888], [3, 764], [4, 641], [5, 594], [6, 547], [7, 500], [8, 453], [9, 438], [10, 423], [11, 408], [12, 394], [13, 379], [14, 364], [15, 349], [16, 334], [17, 330], [18, 326], [19, 322], [20, 318], [21, 314], [22, 310], [23, 306], [24, 302], [25, 298], [26, 294], [27, 289], [28, 285], [29, 281], [30, 277], [31, 273], [32, 269], [33, 268], [34, 266], [35, 265], [36, 263], [37, 262], [38, 260], [39, 259], [40, 257], [41, 256], [42, 254], [43, 253], [44, 251], [45, 250], [46, 248], [47, 247], [48, 245], [49, 244], [50, 242], [51, 241], [52, 239], [53, 238], [54, 236], [55, 235], [56, 233], [57, 232], [58, 231], [59, 229], [60, 228], [61, 226], [62, 225], [63, 223], [64, 222], [65, 221], [66, 220], [67, 219], [68, 219], [69, 218], [70, 217], [71, 216], [72, 216], [73, 215], [74, 214], [75, 213], [76, 213], [77, 212], [78, 211], [79, 211], [80, 210], [81, 209], [82, 208], [83, 208], [84, 207], [85, 206], [86, 205], [87, 205], [88, 204], [89, 203], [90, 202], [91, 202], [92, 201], [93, 200], [94, 199], [95, 199], [96, 198], [97, 197], [98, 196], [99, 196], [100, 195], [101, 194], [102, 193], [103, 193], [104, 192], [105, 191], [106, 191], [107, 190], [108, 189], [109, 188], [110, 188], [111, 187], [112, 186], [113, 185], [114, 185], [115, 184], [116, 183], [117, 182], [118, 182], [119, 181], [120, 180], [121, 179], [122, 179], [123, 178], [124, 177], [125, 176], [126, 176], [127, 175], [128, 174]]
```

`max_discount = 174`

##### Pairing operaiton

Base cost of the pairing operation is `XXXXX*k + XXXXX` where `k` is a number of pairs.

Each point (either G1 or G2) for which subgroup check is requested and performed adds the corresponding G1/G2 multiplication cost to it.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Motivation section covers a total motivation to have operations over BW6-761 curve available. We also extend a rationale for move specific fine points.

#### Multiexponentiation as a separate call

Explicit separate multiexponentiation operation that allows one to save execution time (so gas) by both the algorithm used (namely Peppinger algorithm) and (usually forgotten) by the fact that `CALL` operation in Ethereum is expensive (at the time of writing), so one would have to pay non-negigible overhead if e.g. for multiexponentiation of `100` points would have to call the multipication precompile `100` times and addition for `99` times (roughly `138600` would be saved).

#### Explicit subgroup checks
G2 subgroup check has the same cost as G1 subgroup check. Endomorphisms can be leverages to optimize this operation.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
There are no backward compatibility questions.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

Due to the large test parameters space we first provide properties that various operations must satisfy. We use additive notation for point operations, capital letters (`P`, `Q`) for points, small letters (`a`, `b`) for scalars. Generator for G1 is labeled as `G`, generator for G2 is labeled as `H`, otherwise we assume random point on a curve in a correct subgroup. `0` means either scalar zero or point of infinity. `1` means either scalar one or multiplicative identity. `group_order` is a main subgroup order. `e(P, Q)` means pairing operation where `P` is in G1, `Q` is in G2.

Requeired properties for basic ops (add/multiply):

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

Test vector for all operations are expanded in this [gist](https://gist.github.com/shamatar/506ab3193a7932fe9302a2f3a31a23e8) until it's final.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
There is a various choice of existing implementations:
- C++ implementation EY/libff: https://github.com/EYBlockchain/zk-swap-libff
- Rust implementation EY/Zexe: https://github.com/yelhousni/zexe/tree/youssef/BW6-761-Fq-ABLR-2ML-M
- (wip) Rust implementation Consensys/gurvy: https://github.com/ConsenSys/gurvy

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
Strictly following the spec will eliminate security implications or consensus implications in a contrast to the previous BN254 precompile.

Important topic is a "constant time" property for performed operations. We explicitly state that this precompile **IS NOT REQUIRED** to perform all the operations using constant time algorithms.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
