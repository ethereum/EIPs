# NTT Precompile Implementation for OP-Geth

This directory contains a Go implementation of the Number Theoretic Transform (NTT) precompile for [EIP-7885](../../../EIPS/eip-7885.md), integrated into OP-Geth (Optimism's Ethereum client).

## Overview

This implementation adds NTT support to the Ethereum Virtual Machine as a native precompiled contract, following the EIP-7885 specification with OP-Geth specific optimizations.

## Implementation Details

### Precompile Address

The NTT precompile is deployed at address `0x12` in the Optimism Isthmus hardfork.

### Gas Cost

Fixed gas cost: **70,000** gas per operation (both forward and inverse NTT).

### Dependencies

- **Lattigo v6**: High-performance lattice cryptography library for Go
- **OP-Geth**: Optimism's Ethereum client implementation

### Core Features

- **Forward NTT**: Transforms polynomial coefficients to evaluation domain
- **Inverse NTT**: Transforms evaluation points back to coefficient domain
- **Ring Support**: Configurable ring degree (power of 2, minimum 16)
- **Prime Fields**: Support for NTT-friendly prime moduli
- **Input Validation**: Comprehensive error checking and bounds validation

## Interface Specification

### Input Format

The precompile expects binary input with the following structure:

```
| Field        | Size    | Description                           |
|--------------|---------|---------------------------------------|
| operation    | 1 byte  | 0 = forward NTT, 1 = inverse NTT    |
| ring_degree  | 4 bytes | Ring degree (big-endian, power of 2) |
| modulus      | 8 bytes | Prime modulus (big-endian)           |
| coefficients | N*8     | N coefficients (8 bytes each)       |
```

**Total Input Size**: `13 + (ring_degree * 8)` bytes

### Constraints

1. **Ring Degree**: Must be a power of 2 and e 16
2. **Modulus**: Must be prime and satisfy `modulus a 1 (mod 2*ring_degree)`
3. **Coefficients**: Each coefficient must be `< modulus`
4. **Operation**: Must be 0 (forward) or 1 (inverse)

### Output Format

Returns `ring_degree * 8` bytes containing the transformed coefficients (8 bytes each, big-endian).

### Error Conditions

The precompile returns errors for:

- Input too short (< 13 bytes)
- Invalid operation code (not 0 or 1)
- Invalid ring degree (not power of 2 or < 16)
- Zero modulus
- Non NTT-friendly modulus
- Coefficient exceeding modulus
- Input length mismatch

## Usage Examples

### Forward NTT (Ring Degree 16)

```go
// Input: operation=0, ring_degree=16, modulus=97, coefficients=[1,2,3,...,16]
input := "00000000100000000000000061" +
         "0000000000000001" + "0000000000000002" + "0000000000000003" +
         // ... (16 coefficients total)
         "0000000000000010"

result, err := contract.Run(common.Hex2Bytes(input))
```

### Inverse NTT (Ring Degree 16)

```go
// Input: operation=1, ring_degree=16, modulus=97, coefficients=[NTT output]
input := "01000000100000000000000061" +
         "0000000000000045" + "0000000000000028" + "000000000000001d" +
         // ... (16 NTT coefficients)
         "0000000000000038"

result, err := contract.Run(common.Hex2Bytes(input))
// Should recover original [1,2,3,...,16]
```

## Testing

### Running Tests

```bash
# Run NTT precompile tests
go test ./core/vm -v -run TestPrecompiledNTT

# Run malformed input tests
go test ./core/vm -v -run TestPrecompileNTTMalformedInput
```

### Test Coverage

The test suite includes:

1. **Malformed Input Tests**: 8 different error conditions
2. **Valid Operation Tests**: Forward and inverse NTT with ring degree 16
3. **Cryptographic Standards**: Tests with real-world parameters

### Benchmark Tests

```bash
# Basic NTT benchmark
go test ./core/vm -bench BenchmarkPrecompiledNTT

# Crypto standards benchmarks (Falcon-512, Kyber-128, Dilithium-256)
go test ./core/vm -bench BenchmarkPrecompiledNTTCryptoStandards
```

### Hardfork Activation

The NTT precompile is activated in the **Optimism Isthmus** hardfork:

```go
var PrecompiledContractsIsthmus = map[common.Address]PrecompiledContract{
    // ... other precompiles
    common.BytesToAddress([]byte{0x12}): &NTT{},
}
```

### Contract Registration

```go
type NTT struct{}

func (c *NTT) RequiredGas(input []byte) uint64 {
    return 70000  // Fixed gas cost
}

func (c *NTT) Run(input []byte) ([]byte, error) {
    // Implementation using Lattigo library
}
```

## Security Considerations

### Input Validation

The implementation performs comprehensive input validation:

- Bounds checking on all parameters
- NTT-friendly modulus verification
- Coefficient range validation
- Ring degree power-of-2 requirement

### Side-Channel Resistance

The Lattigo library provides some protection against timing attacks through:

- Constant-time modular arithmetic
- Consistent memory access patterns
- Uniform execution paths

## Source Code

The complete implementation is available at: https://github.com/yhl125/op-geth/tree/feat/minimal-ntt-precompile

## References

- [EIP-7885: Number Theoretic Transform Precompile](../../../EIPS/eip-7885.md)
- [Lattigo Library](https://github.com/tuneinsight/lattigo/blob/main/ring/ntt.go)
- [OP-Geth Documentation](https://docs.optimism.io/)
