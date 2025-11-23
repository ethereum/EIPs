# Optimism-geth with NTT Precompiles (liboqs Implementation)

Fork of `op-geth` with precompiled contracts for Number Theoretic Transform (NTT) operations using [liboqs](https://github.com/open-quantum-safe/liboqs) via CGO bindings, enabling efficient on-chain post-quantum cryptographic operations.

## Precompiled Contracts

| Address | Name | Description |
|---------|------|-------------|
| `0x12` | NTT_FW | Forward NTT using liboqs (Falcon-512/1024, ML-DSA) |
| `0x13` | NTT_INV | Inverse NTT using liboqs (same schemes as NTT_FW) |
| `0x14` | VECMULMOD | Element-wise modular multiplication: `result[i] = (a[i] * b[i]) mod q` |
| `0x15` | VECADDMOD | Element-wise modular addition: `result[i] = (a[i] + b[i]) mod q` |

### Supported Schemes

| Scheme | Ring Degree | Modulus | Element Size |
|--------|-------------|---------|--------------|
| Falcon-512 | 512 | 12289 | uint16 (2 bytes) |
| Falcon-1024 | 1024 | 12289 | uint16 (2 bytes) |
| ML-DSA | 256 | 8380417 | int32 (4 bytes) |

## Installation

### 1. Install liboqs with NTT CGO Bindings

```bash
# Clone and install dependencies
git clone -b feature/ntt-cgo-bindings https://github.com/yhl125/liboqs.git
sudo apt install astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml valgrind pkg-config

# Build liboqs and Go bindings
cd liboqs/bindings/go
make all
```

### 2. Configure Environment

```bash
# Set paths (adjust to your installation directory)
export PKG_CONFIG_PATH=/path/to/liboqs/bindings/go/.config:$PKG_CONFIG_PATH
export DYLD_LIBRARY_PATH=/path/to/liboqs/build/lib:$DYLD_LIBRARY_PATH  # macOS
export LD_LIBRARY_PATH=/path/to/liboqs/build/lib:$LD_LIBRARY_PATH      # Linux
```

### 3. Build op-geth

```bash
make geth
```

**Requirements:** Go 1.23+, pkg-config, CMake, Ninja

**Detailed instructions:** [liboqs Go bindings README](https://github.com/yhl125/liboqs/tree/feature/ntt-cgo-bindings/bindings/go)

## API Reference

### NTT_FW (0x12) - Forward Transform

Transforms coefficients into NTT domain using liboqs.

**Input:**
```
[0:4]   ring_degree (uint32, big-endian)
[4:12]  modulus (uint64, big-endian)
[12:*]  coefficients (Falcon: uint16×N, ML-DSA: int32×N, big-endian)
```

**Output:** NTT-transformed coefficients (same format as input)

**Gas Cost:**
- Falcon-512: 500 gas (~9.4μs, 53 mgas/s)
- Falcon-1024: 1,080 gas (~20.4μs, 53 mgas/s)
- ML-DSA: 256 gas (~4.8μs, 53 mgas/s)

### NTT_INV (0x13) - Inverse Transform

Transforms NTT domain coefficients back to standard representation.

**Input:** Same as NTT_FW (coefficients in NTT domain)

**Output:** Coefficients in standard representation

**Gas Cost:**
- Falcon-512: 500 gas (~9.4μs, 53 mgas/s)
- Falcon-1024: 1,080 gas (~20.3μs, 53 mgas/s)
- ML-DSA: 340 gas (~6.4μs, 53 mgas/s)

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
- Falcon-512: 164 gas (~2.9μs, 56 mgas/s)
- Falcon-1024: 328 gas (~6.0μs, 55 mgas/s)
- ML-DSA: 82 gas (~2.0μs, 42 mgas/s)

### VECADDMOD (0x15) - Vector Addition

Element-wise modular addition.

**Input:** Same as VECMULMOD

**Output:** Element-wise sum `(a[i] + b[i]) mod q`

**Gas Cost:** `ceil(0.3 × n)`
- Falcon-512: 154 gas (~2.8μs, 55 mgas/s)
- Falcon-1024: 308 gas (~5.8μs, 53 mgas/s)
- ML-DSA: 77 gas (~1.6μs, 47 mgas/s)

## Testing

```bash
cd core/vm

# All NTT tests
go test -v -run TestPrecompiled.*NTT

# Specific tests
go test -v -run TestPrecompiledNTT_FW
go test -v -run TestPrecompiledNTT_VECMULMOD

# Benchmarks
go test -bench=BenchmarkPrecompiledNTT -benchtime=5s
```

**Test Coverage:**
- Scheme detection (Falcon-512/1024, ML-DSA)
- Input validation (malformed inputs, invalid parameters)
- Round-trip verification (`INTT(NTT(x)) = x`)
- Cross-scheme isolation
- Performance benchmarks with crypto standards

### Benchmark Results

Benchmarks were run on an Intel(R) Xeon(R) CPU @ 2.20GHz. For detailed results, please see the files below:

- [Ecrecover Benchmark Test Results](./benchmark_results/BenchmarkPrecompiledEcrecover)
- [NTT & NTT Vector Operations Benchmark Test Results](./benchmark_results/BenchmarkPrecompiledNTT)
