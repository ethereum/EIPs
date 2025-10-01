# Optimism-geth with NTT Precompiles

This is a fork of `op-geth` that implements [EIP-7885](../../../EIPS/eip-7885.md) precompiled contracts for Number Theoretic Transform (NTT) operations and vectorized modular arithmetic.

## Precompiled Contracts

Three precompiled contracts are added at addresses `0x12`, `0x13`, and `0x14` in the **Optimism Isthmus** hardfork:

- **`0x12`: NTT**: Number Theoretic Transform operations using the Lattigo library. Supports both forward and inverse NTT transformations.
- **`0x13`: VECMULMOD**: Vectorized element-wise modular multiplication in the NTT domain using Barrett reduction.
- **`0x14`: VECADDMOD**: Vectorized element-wise modular addition in the NTT domain.

## Implementation Details

### NTT Precompile (0x12)

The NTT precompile accepts input in the following format:

- `operation` (1 byte): `0x00` for forward NTT, `0x01` for inverse NTT
- `ring_degree` (4 bytes): Power of 2, minimum 16
- `modulus` (8 bytes): NTT-friendly prime where `q ≡ 1 (mod 2N)`
- `coefficients` (8\*N bytes): Ring coefficients as 64-bit integers

**Gas Costing**: A fixed gas cost of 70,000 is applied, targeting approximately 50 mgas/s performance to maintain consistency with existing precompiles like `ecrecover`.

### VECMULMOD Precompile (0x13)

Performs element-wise modular multiplication of two vectors in the NTT domain: `result[i] = (a[i] * b[i]) mod q`

Input format:

- `ring_degree` (4 bytes): Power of 2, minimum 16
- `modulus` (8 bytes): NTT-friendly prime where `q ≡ 1 (mod 2N)`
- `vector_a` (8\*N bytes): First vector coefficients
- `vector_b` (8\*N bytes): Second vector coefficients

**Gas Costing**: Uses a memory-aware formula reflecting the dominant overhead of memory allocation, targeting approximately 50 mgas/s performance:

```
Gas = BASE_COST + (COMPUTE_COST_PER_ELEMENT × N)
    = 72,000 + (7 × N)
```

Where:

- `BASE_COST` (72,000 gas): Memory allocation overhead
- `COMPUTE_COST_PER_ELEMENT` (7 gas): Barrett reduction multiplication per element

### VECADDMOD Precompile (0x14)

Performs element-wise modular addition of two vectors: `result[i] = (a[i] + b[i]) mod q`

Input format: Same as VECMULMOD (0x13)

**Gas Costing**: Uses the same memory-aware formula with cheaper compute cost, targeting approximately 50 mgas/s performance:

```
Gas = BASE_COST + (COMPUTE_COST_PER_ELEMENT × N)
    = 72,000 + (5 × N)
```

## Tests and Benchmarks

Comprehensive tests and benchmarks are implemented in `core/vm/contracts_test.go`, including:

### NTT Tests (0x12)

- **Malformed Input Tests**: 8 test cases covering invalid operations, ring degrees, moduli, and coefficients
- **Forward/Inverse NTT Tests**: Round-trip validation ensuring `INTT(NTT(x)) = x`
- **Crypto Standards Benchmarks**: Performance testing with real-world parameters from Falcon-512, Kyber-128, and Dilithium-256

### Vector Operations Tests (0x13, 0x14)

- **Unified Malformed Input Tests**: 7 test cases covering invalid ring degrees, moduli, and input lengths for both VECMULMOD and VECADDMOD
- **Functional Tests**: Validates correct element-wise operations with small test vectors
- **Crypto Standards Benchmarks**: Performance testing with Falcon-512, Kyber-128, and Dilithium-256 parameters

### Benchmark Results

Benchmarks were run on an Intel(R) Xeon(R) CPU @ 2.20GHz. For detailed results, please see the files below:

- [Ecrecover Benchmark Test Results](./benchmark_results/BenchmarkPrecompiledEcrecover)
- [NTT Benchmark Test Results](./benchmark_results/BenchmarkPrecompiledNTTCryptoStandards)
- [Vector Operations Benchmark Test Results](./benchmark_results/BenchmarkPrecompiledNTTVecOpsCryptoStandards)

## Running Tests

### Unit Tests

```bash
# Run all NTT-related tests
go test ./core/vm -v -run TestPrecompiledNTT

# Run malformed input tests
go test ./core/vm -v -run TestPrecompileNTTMalformedInput

# Run vector operations tests
go test ./core/vm -v -run TestPrecompiledNTTVecOps

# Run unified malformed input tests for vector operations
go test ./core/vm -v -run TestPrecompileNTTVecOpsMalformedInput
```

### Benchmark Tests

```bash
# Run NTT benchmarks
go test ./core/vm -bench BenchmarkPrecompiledNTTCryptoStandards

# Run vector operations benchmarks
go test ./core/vm -bench BenchmarkPrecompiledNTTVecOpsCryptoStandards
```

## Source Code

The complete implementation is available at: https://github.com/yhl125/op-geth/tree/feat/minimal-ntt-precompile

### Key Files

- **contracts.go**: Implementation of NTT, VECMULMOD, and VECADDMOD precompiles
- **contracts_test.go**: Comprehensive test suite including unit tests and benchmarks
- **benchmark_results/**: Detailed benchmark outputs for performance analysis

## Dependencies

- **Lattigo v6**: High-performance lattice cryptography library for Go
- **OP-Geth**: Optimism's Ethereum client implementation based on go-ethereum

## Integration with Optimism Isthmus

The precompiles are activated in the Optimism Isthmus hardfork:

```go
var PrecompiledContractsIsthmus = map[common.Address]PrecompiledContract{
    // ... existing precompiles
    common.BytesToAddress([]byte{0x12}): &NTT{},
    common.BytesToAddress([]byte{0x13}): &nttVecMulMod{},
    common.BytesToAddress([]byte{0x14}): &nttVecAddMod{},
}
```

## References

- [EIP-7885: Number Theoretic Transform Precompile](../../../EIPS/eip-7885.md)
- [Lattigo Library](https://github.com/tuneinsight/lattigo)
- [OP-Geth Documentation](https://docs.optimism.io/)
