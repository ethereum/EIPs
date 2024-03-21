# Fast subgroup checks used by EIP 2537


## Curve parameters

The set of parameters used by fast subgroup checks:

```
|x| (seed) = 0xd201000000010000
x is negative = true
Cube root of unity modulo p - Beta = 0x1a0111ea397fe699ec02408663d4de85aa0d857d89759ad4897d29650fb85f9b409427eb4f49fffd8bfd00000000aaac
```

## G1 endomorphism

## G2 endomorphism

# The G1 case

Before accepting a point `P(x,y)` as input that purports to be a member of G1 subject the input to the following endomorphism test: `phi(P) + u^2*P = 0`


# The G2 case

Before accepting a point `P(x,y)` as input that purports to be a member of G2 subject the input to the following endomorphism test:
