# Optimism-geth with Pure Go NTT Precompiles

Fork of `op-geth` with precompiled contracts for Number Theoretic Transform (NTT) operations implemented in pure Go, enabling efficient on-chain post-quantum cryptographic operations without external dependencies.

## Precompiled Contracts

| Address | Name      | Description                                                            |
| ------- | --------- | ---------------------------------------------------------------------- |
| `0x12`  | NTT_FW    | Forward NTT (Falcon-512/1024, ML-DSA)                                  |
| `0x13`  | NTT_INV   | Inverse NTT (Falcon-512/1024, ML-DSA)                                  |
| `0x14`  | VECMULMOD | Element-wise modular multiplication: `result[i] = (a[i] * b[i]) mod q` |
| `0x15`  | VECADDMOD | Element-wise modular addition: `result[i] = (a[i] + b[i]) mod q`       |

### Supported Schemes

| Scheme      | Ring Degree | Modulus | Element Size     |
| ----------- | ----------- | ------- | ---------------- |
| Falcon-512  | 512         | 12289   | uint16 (2 bytes) |
| Falcon-1024 | 1024        | 12289   | uint16 (2 bytes) |
| ML-DSA      | 256         | 8380417 | int32 (4 bytes)  |

## Implementation Details

This implementation uses **pure Go** for all NTT operations, located in `crypto/ntt/`:

- `falcon.go`: Falcon NTT with Montgomery arithmetic
- `falcon_tables.go`: Pre-computed twiddle factors for Falcon
- `dilithium.go`: ML-DSA/Dilithium NTT implementation
- `dilithium_tables.go`: Pre-computed zetas for ML-DSA

## API Reference

### NTT_FW (0x12) - Forward Transform

Transforms coefficients into NTT domain.

**Input:**

```
[0:4]   ring_degree (uint32, big-endian)
[4:12]  modulus (uint64, big-endian)
[12:*]  coefficients (Falcon: uint16×N, ML-DSA: int32×N, big-endian)
```

**Output:** NTT-transformed coefficients (same format as input)

**Gas Cost:**

- Falcon-512: 790 gas
- Falcon-1024: 1,750 gas
- ML-DSA: 220 gas

### NTT_INV (0x13) - Inverse Transform

Transforms NTT domain coefficients back to standard representation.

**Input:** Same as NTT_FW (coefficients in NTT domain)

**Output:** Coefficients in standard representation

**Gas Cost:**

- Falcon-512: 790 gas
- Falcon-1024: 1,750 gas
- ML-DSA: 270 gas

### VECMULMOD (0x14) - Vector Multiplication

Element-wise modular multiplication in NTT domain.

**Input:**

```
[0:4]   ring_degree (uint32, big-endian)
[4:12]  modulus (uint64, big-endian)
[12:12+n*size] vector_a
[12+n*size:*]  vector_b
```

**Output:** Element-wise product `(a[i] * b[i]) mod q`

**Gas Cost:** `ceil(0.32 × n)`

- Falcon-512: 164 gas
- Falcon-1024: 328 gas
- ML-DSA: 82 gas

### VECADDMOD (0x15) - Vector Addition

Element-wise modular addition.

**Input:** Same as VECMULMOD

**Output:** Element-wise sum `(a[i] + b[i]) mod q`

**Gas Cost:** `ceil(0.3 × n)`

- Falcon-512: 154 gas
- Falcon-1024: 308 gas
- ML-DSA: 77 gas

## Testing

```bash
cd core/vm

# All NTT tests
go test -v -run TestPrecompiled.*NTT
go test -v -run TestPrecompiledVectorOp

# Benchmarks
go test -bench=BenchmarkPrecompiledNTT
```

**Test Coverage:**

- Scheme detection (Falcon-512/1024, ML-DSA)
- Input validation (malformed inputs, invalid parameters)
- Round-trip verification (`INTT(NTT(x)) = x`)
- Cross-scheme isolation
- Performance benchmarks

### Benchmark Results

Benchmarks were run on an Intel(R) Xeon(R) CPU @ 2.20GHz. For detailed results, please see:

- [Ecrecover Benchmark Test Results](./benchmark_results/BenchmarkPrecompiledEcrecover)
- [NTT & NTT Vector Operations Benchmark Test Results](./benchmark_results/BenchmarkPrecompiledNTT)
