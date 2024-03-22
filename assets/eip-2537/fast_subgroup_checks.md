# Fast subgroup checks used by EIP 2537

### Fields and Groups

Field Fp is defined as the finite field of size `p` with elements represented as integers between 0 and p-1 (both inclusive). 

Field Fp2 is defined as `Fp[X]/(X^2-nr2)` with elements  `el = c0 + c1 * v`, where `v` is the formal square root of `nr2` represented as integer pairs `(c0,c1)`.
 
Group G1 is defined as a set of Fp pairs (points) `(x,y)` such that either `(x,y)` is  `(0,0)` or `x,y` satisfy the curve Fp equation.

Group G2 is defined as a set of Fp2 pairs (points) `(x',y')` such that either `(x,y)` is `(0,0)` or `(x',y')` satisfy the curve Fp2 equation.

## Curve parameters

The set of parameters used by fast subgroup checks:

```
|x| (seed) = 15132376222941642752
x is negative = true
Cube root of unity modulo p - Beta = 4002409555221667392624310435006688643935503118305586438271171395842971157480381377015405980053539358417135540939436
r = 4002409555221667392624310435006688643935503118305586438271171395842971157480381377015405980053539358417135540939437*v
```

## Helper function to compute the conjugate over Fp2 - `conjugate`

`phi(conjugate(c0 + c1 * v)) := c0 - c1 * v`

## G1 endomorphism - `phi`

The endomorphism `phi` transform the point from `(x,y)` to `(Beta*x,y)` where `Beta` is a precomputed cube root of unity modulo `p` given above in parameters sections:

`phi((x,y)) := (Beta*x,y)`

## G2 endomorphism - `psi`

# The G1 case

Before accepting a point `P` as input that purports to be a member of G1 subject the input to the following endomorphism test: `phi(P) + x^2*P = 0`


# The G2 case

Before accepting a point `P` as input that purports to be a member of G2 subject the input to the following endomorphism test: `psi(P) + x*P = 0`

# Resources

* https://eprint.iacr.org/2021/1130.pdf, sec.4
* https://eprint.iacr.org/2022/352.pdf, sec. 4.2
