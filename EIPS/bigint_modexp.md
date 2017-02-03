### Parameters

* `GQUADDIVISOR: 20`

### Specification

At address 0x00......05, add a precompile that expects input in the following format:

    <length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>
    
Where every length is a 32-byte left-padded integer representing the number of bytes to be taken up by the next value. Call data is assumed to be infinitely right-padded with zero bytes, and excess data is ignored. Consumes `floor(max(length_of_MODULUS, length_of_BASE) ** 2 * max(length_of_EXPONENT, 1) / GQUADDIVISOR)` gas, and if there is enough gas, returns an output `(BASE**EXPONENT) % MODULUS` as a byte array with the same length as the modulus.

For example, the input data:

    0000000000000000000000000000000000000000000000000000000000000001
    0000000000000000000000000000000000000000000000000000000000000020
    0000000000000000000000000000000000000000000000000000000000000020
    03
    fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2e
    fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
    
Represents the exponent `3**(2**256 - 2**32 - 978) % (2**256 - 2**32 - 977)`. By Fermat's little theorem, this equals 1, so the result is:

    0000000000000000000000000000000000000000000000000000000000000001
    
Returned as 32 bytes because the modulus length was 32 bytes. The gas cost would be `32**2 * 32 / 20 = 1638` gas (note that this roughly equals the cost of using the EXP opcode to compute a 32-byte exponent). A 4096-bit RSA exponentiation would cost `256**2 * 256 / 20 = 838860` gas in the worst case, though RSA verification in practice usually uses an exponent of 3 or 65537, which would reduce the gas consumption to 3276 or 6553, respectively.

This input data:

    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000020
    0000000000000000000000000000000000000000000000000000000000000020
    fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2e
    fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
    
Would be parsed as a base of 0, exponent of `2**256 - 2**32 - 978` and modulus of `2**256 - 2**32 - 978`, and so would return 0. Notice how if the length_of_BASE is 0, then it does not interpret _any_ data as the base, instead immediately interpreting the next 32 bytes as length_of_EXPONENT.

This input data:

    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000020
    ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
    fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd
    
Would parse a base length of 0, a modulus length of 32, and an exponent length of `2**256 - 1`, where the base is empty, the modulus is `2**256 - 2` and the exponent is `(2**256 - 3) * 256**(2**256 - 33)` (yes, that's a really big number). It would then immediately fail, as it's not possible to provide enough gas to make that computation.

This input data:

    0000000000000000000000000000000000000000000000000000000000000001
    0000000000000000000000000000000000000000000000000000000000000002
    0000000000000000000000000000000000000000000000000000000000000020
    03
    ffff
    8000000000000000000000000000000000000000000000000000000000000000
    07

Would parse as a base of 3, an exponent of 65535, and a modulus of `2**255`, and it would ignore the remaining 0x07 byte.

This input data:

    0000000000000000000000000000000000000000000000000000000000000001
    0000000000000000000000000000000000000000000000000000000000000002
    0000000000000000000000000000000000000000000000000000000000000020
    03
    ffff
    80
    
Would also parse as a base of 3, an exponent of 65535 and a modulus of `2**255`, as it attempts to grab 32 bytes for the modulus starting from 0x80, but then there is no further data so it right pads it with 31 zeroes.

### Rationale

This allows for efficient RSA verification inside of the EVM, as well as other forms of number theory-based cryptography. Note that adding precompiles for addition and subtraction is not required, as the in-EVM algorithm is efficient enough, and multiplication can be done through this precompile via `a * b = ((a + b)**2 - (a - b)**2) / 4`.

    
