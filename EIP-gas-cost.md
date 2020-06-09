# Precompiles
- BW6_G1_ADD - to perform point addition on a curve defined over prime field
- BW6_G1_MUL - to perform point multiplication on a curve defined over prime field
- BW6_G2_ADD - to perform point addition on a curve twist defined the base prime field
- BW6_G2_MUL - to perform point multiplication on a curve twist defined over the base prime field
- BW6_PAIRING - to perform a pairing operations between a set of *pairs* of (G1, G2) points
- BW6_G1_MULTIEXP - to perform multiexponentiation on a curve defined over prime field
- BW6_G2_MULTIEXP - to perform multiexponentiation on a curve twist defined over the base prime field
- BW6_MAP_FP_TO_G1 - to perform mapping of an element in the base field FP to a point (x,y) in the group G1
- BW6_MAP_FP_TO_G2 - to perform mapping of an element in the base field FP to a point (x,y) in the group G2

# Gas cost
Gas cost is derived by taking the average timing the same operations over different implementations and assuming a constant `30 MGas/second`. Since the execution time is machine-specific, this constant is determined based on execution times of [ECRECOVER](https://github.com/matter-labs/eip1962/blob/master/run_bn_pairing_estimate.sh) and [BNPAIR](https://github.com/matter-labs/eip1962/blob/master/run_bn_pairing_estimate.sh) precompiles on my machine and their proposed gas price (`43.5 MGas/s` for ECRECOVER and `16.5 MGas/s` for BNPAIR). Following are the proposed methods to time the precompile operations:

## BW6_G1_ADD
Average timing of 1000 random samples (random G1 points):
- zexe (Rust): 3440 ns/iter (+/- 369)
- libff (C++):
- gnark (Go): **WIP**
- openEthereum Parity (Rust):

## BW6_G1_MUL
Average timing of 1000 samples of radnom worst-case of double-and-add algorithm (scalar of max bit length and max hamming weight and random base points in G1):
- zexe (Rust):
    - *random scalars*: 1275596 ns/iter (+/- 75108)
    - *worst-case scalar*:
- libff (C++):
- gnark (Go): **WIP**
- openEthereum Parity (Rust):

## BW6_G2_ADD
Average timing of 1000 random samples (random G2 points):
- zexe (Rust): 3428 ns/iter (+/- 273)
- libff (C++):
- gnark (Go): **WIP**
- openEthereum Parity (Rust):

## BW6_G2_MUL
Average timing of 1000 samples of radnom worst-case of double-and-add algorithm (scalar of max bit length and max hamming weight and random base points in G2):
- zexe (Rust): 1303347 ns/iter (+/- 107657)
- libff (C++):
- gnark (Go): **WIP**
- openEthereum Parity (Rust):

## BW6_PAIRING
Average timing of 1000 random samples (random points in G1 and G2) for different number of pairs with linear lifting:
- zexe (Rust):
- libff (C++):
- gnark (Go): **WIP**
- openEthereum Parity (Rust):

## BW6_G1_MULTIEXP
Average timing of 1000 random samples (random scalars and random base points) and make a lookup table for discount vs number of pairs:
- zexe (Rust):
- libff (C++):
- gnark (Go): **WIP**
- openEthereum Parity (Rust):

## BW6_G2_MULTIEXP
Average timing of 1000 random samples (random scalars and random base points) and make a lookup table for discount vs number of pairs:
- zexe (Rust):
- libff (C++):
- gnark (Go): **WIP**
- openEthereum Parity (Rust):
