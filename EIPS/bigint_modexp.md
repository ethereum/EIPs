### Parameters

* `GQUADDIVISOR: 20`

### Specification

At address 0x00......05, add a precompile that expects input in the following format:

    <length of BASE> <BASE> <length of EXPONENT> <EXPONENT> <length of MODULUS> <MODULUS>
    
Where every length is a 32-byte left-padded integer representing the number of bytes to be taken up by the next value. Consumes `floor(length(MODULUS)**2 * length(EXPONENT) / GQUADDIVISOR)` gas. If there is enough gas, returns an output as a byte array with the same length as the modulus.

Example:

    000000000000000000000000000000000000000000000000000000000000000103
    0000000000000000000000000000000000000000000000000000000000000020fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2e
    0000000000000000000000000000000000000000000000000000000000000020fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
    
Represents the exponent 3**(2**256 - 2**32 - 978) % (2**256 - 2**32 - 977). By Fermat's little theorem, this equals 1, so the result is:

    0000000000000000000000000000000000000000000000000000000000000001
    
Returned as 32 bytes because the modulus length was 32 bytes. The gas cost would be 32**2 * 32 / 20 = 1638 gas (note that this roughly equals the cost of using the EXP opcode to compute a 32-byte exponent). A 4096-bit RSA exponentiation would cost 256**2 * 256 / 20 = 838860 gas in the worst case, though RSA verification in practice usually uses an exponent of 3 or 65537, which would reduce the gas consumption to 3276 or 6553, respectively.

### Rationale

This allows for efficient RSA verification inside of the EVM, as well as other forms of number theory-based cryptography. Note that adding precompiles for addition and subtraction is not required, as the in-EVM algorithm is efficient enough, and multiplication can be done through this precompile via `a * b = ((a + b)**2 - (a - b)**2) / 4`.

    
