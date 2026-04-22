---
eip: 7939
title: Count leading zeros (CLZ) opcode
description: Opcode to count the number of leading zero bits in a 256-bit word
author: Vectorized (@Vectorized), Georgios Konstantopoulos (@gakonst), Jochem Brouwer (@jochem-brouwer), Ben Adams (@benaadams), Giulio Rebuffo (@Giulio2002)
discussions-to: https://ethereum-magicians.org/t/create-a-new-opcode-for-counting-leading-zeros-clz/10805
status: Final
type: Standards Track
category: Core
created: 2025-04-28
---

## Abstract

Introduce a new opcode, `CLZ(x)`, which pops `x` from the stack and pushes the number of leading zero bits in `x` to the stack. If `x` is zero, pushes 256.

## Motivation

Count leading zeros (CLZ) is a native opcode in many processor architectures (even in RISC architectures like ARM).

It is a basic building block used in math operations, byte operations, compression algorithms, data structures:

- lnWad
- powWad
- lambertW0Wad
- sqrt
- cbrt
- byte string comparisons
- generalized calldata compression/decompression
- bitmaps (for finding the next/previous set/unset bit)
- post quantum signature schemes

Adding a `CLZ` opcode will:

- Lead to cheaper compute.
- Lead to cheaper ZK proving costs. The fastest known Solidity implementation uses several dynamic bitwise right shifts `shr`, which are very expensive to prove. In SP1 rv32im, a 32-bit right shift costs 1.6x more than a 32-bit mul.
- Lead to smaller bytecode size. The fastest known Solidity implementation contains several large constants and is often inlined for performance.

## Specification

A new opcode is introduced: `CLZ` (`0x1e`).

- Pops 1 value from the stack.
- Pushes a value to the stack, according to the following code:

```solidity
/// @dev Count leading zeros.
/// Returns the number of zeros preceding the most significant one bit.
/// If `x` is zero, returns 256.
/// This is the fastest known `CLZ` implementation in Solidity and uses about 184 gas.
function clz(uint256 x) internal pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
        r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
        r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
        r := or(r, shl(4, lt(0xffff, shr(r, x))))
        r := or(r, shl(3, lt(0xff, shr(r, x))))
        // forgefmt: disable-next-item
        r := add(xor(r, byte(and(0x1f, shr(shr(r, x), 0x8421084210842108cc6318c6db6d54be)),
            0xf8f9f9faf9fdfafbf9fdfcfdfafbfcfef9fafdfafcfcfbfefafafcfbffffffff)), iszero(x))
    }
}
```

Or in Python,

```python
def clz(x):
    """Returns the number of zeros preceding the most significant one bit."""
    if x < 0:
        raise ValueError("clz is undefined for negative numbers")
    if x > 2**256 - 1:
        raise ValueError("clz is undefined for numbers larger than 2**256 - 1")
    if x == 0:
        return 256
    # Convert to binary string and remove any '0b' prefix.
    bin_str = bin(x).replace('0b', '')
    return 256 - len(bin_str)
```

Or in C++,

```c++
inline uint32_t clz(uint32_t x) {
    uint32_t r = 0;
    if (!(x & 0xFFFF0000)) { r += 16; x <<= 16; }
    if (!(x & 0xFF000000)) { r += 8;  x <<= 8;  }
    if (!(x & 0xF0000000)) { r += 4;  x <<= 4;  }
    if (!(x & 0xC0000000)) { r += 2;  x <<= 2;  }
    if (!(x & 0x80000000)) { r += 1; }
    return r;
}

// `x` is a uint256 bit number represented with 8 uint32 limbs.
// This implementation is optimized for SP1 proving via rv32im.
// For regular compute, it performs similarly to `ADD`.
inline uint32_t clz(uint32_t x[8]) {
    if (x[7] != 0) return clz(x[7]);
    if (x[6] != 0) return 32 + clz(x[6]);
    if (x[5] != 0) return 64 + clz(x[5]);
    if (x[4] != 0) return 96 + clz(x[4]);
    if (x[3] != 0) return 128 + clz(x[3]);
    if (x[2] != 0) return 160 + clz(x[2]);
    if (x[1] != 0) return 192 + clz(x[1]);
    if (x[0] != 0) return 224 + clz(x[0]);
    return 256;
}
```

The cost of the opcode is 5, matching MUL (raised from 3 to avoid under-pricing DoS risk).

## Rationale

### The special 0 case

256 is the smallest number after 255. Returning a small number allows the result to be compared with minimal additional bytecode.

For byte scanning operations, one can get the number of bytes to be skipped for a zero word by simply computing `256 >> 3`, which gives 32.

### Preference over `CTZ` (count trailing zeros)

Computing the least significant bit can be easily implemented with `CLZ` by isolating the smallest bit via `x & -x`.

However, it is not possible to implement `CLZ` with `CTZ`.

### Gas cost

We have benchmarked the `CLZ` implementation against the `ADD` implementation in the intx library. `CLZ` uses approximately the same amount of compute cycles as `ADD`. 

The SP1 rv32im optimized variant uses less compute cycles than `ADD`, in the average and worst cases.

In SP1 rv32im, a 256-bit `CLZ` is cheaper to prove than `ADD`. 

## Backwards Compatibility

This is a new opcode not present prior.

## Test Cases

```
PUSH32 0x000000000000000000000000000000000000000000000000000000000000000
CLZ
---
0x0000000000000000000000000000000000000000000000000000000000000100
```

```
PUSH32 0x8000000000000000000000000000000000000000000000000000000000000000
CLZ
---
0x0000000000000000000000000000000000000000000000000000000000000000
```

```
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
CLZ
---
0x0000000000000000000000000000000000000000000000000000000000000000
```

```
PUSH32 0x4000000000000000000000000000000000000000000000000000000000000000
CLZ
---
0x0000000000000000000000000000000000000000000000000000000000000001
```

```
PUSH32 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
CLZ
---
0x0000000000000000000000000000000000000000000000000000000000000001
```

```
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000001
CLZ
---
0x00000000000000000000000000000000000000000000000000000000000000ff
```

## Security Considerations

`CLZ` is a stateless opcode that has a low worst-case constant cost in memory usage, compute and proving costs. It is therefore safe from being exploited for denial of service attacks.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
