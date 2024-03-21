# Fast subgroup checks used by EIP 2537


## Curve parameters

The set of parameters used by fast subgroup checks:

```
|x| (seed) = 0xd201000000010000
x is negative = true
Cube root of unity modulo p - Beta = 0x1a0111ea397fe699ec02408663d4de85aa0d857d89759ad4897d29650fb85f9b409427eb4f49fffd8bfd00000000aaac
```

## G1 endomorphism - phi

The endomorphism `phi` transform the point from `[x,y]` to `[Beta*x, y]` where `Beta` is a precomputed cube root of unity modulo p given above in parameters sections:

`phi(P[x,y]) := P[Beta*x, y]`

## G2 endomorphism - psi

# The G1 case

Before accepting a point `P` as input that purports to be a member of G1 subject the input to the following endomorphism test: `phi(P) + x^2*P = 0`


# The G2 case

Before accepting a point `P` as input that purports to be a member of G2 subject the input to the following endomorphism test: `psi(P) + x*P = 0`

# Resources

* https://eprint.iacr.org/2021/1130.pdf, sec.4
* https://eprint.iacr.org/2022/352.pdf, sec. 4.2
