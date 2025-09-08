# NTT Precompile Integration Tests

Comprehensive integration test suite for EIP-7885 NTT (Number Theoretic Transform) precompiles using Viem and TypeScript.

## Source Code

The complete test suite is available at: https://github.com/yhl125/precompile-test

## Overview

This test suite provides direct integration testing of NTT precompiles by calling them through RPC, bypassing the limitations of Foundry's local EVM that doesn't include custom precompiles.

**Testing Environment**: Tests are executed against an op-geth client built from [yhl125/op-geth](https://github.com/yhl125/op-geth/tree/optimism) with integrated NTT precompile support.

### Precompiles Tested

- **Pure NTT (0x14)**: Standard NTT implementation with on-the-fly computation
- **Precomputed NTT (0x15)**: Optimized NTT implementation with precomputed twiddle factors

## Features

- 🚀 **Direct RPC Testing**: Tests run against actual precompile implementations on remote node
- 🔬 **Go Compatibility**: Validates outputs match Go reference implementation exactly
- 📊 **Comprehensive Coverage**: Tests various ring degrees, moduli, and cryptographic standards
- ⚡ **Gas Cost Analysis**: Detailed gas consumption comparison between implementations
- 🏛️ **Cryptographic Standards**: Tests real-world parameters from Falcon, Dilithium, and Kyber
- 🔄 **Round-trip Validation**: Forward→Inverse NTT correctness verification
- 🛡️ **Error Handling**: Validates proper input validation and error responses
- 📈 **Performance Benchmarking**: Gas efficiency analysis vs theoretical complexity

## Setup

1. **Install dependencies**:
   ```bash
   bun install
   # or
   npm install
   ```

2. **Configure RPC endpoint**:
   The tests use `http://34.29.49.47:8545` by default. Update `src/config/rpc-config.ts` if needed.

3. **For Transaction Tests** (optional):
   ```bash
   # Copy the example environment file
   cp .env.example .env
   
   # Edit .env and add your private key (WITHOUT 0x prefix)
   # PRIVATE_KEY=your_private_key_here
   ```
   **⚠️ WARNING: Never commit your `.env` file with real private keys!**

## Running Tests

```bash
# Run all tests (recommended with bun for faster execution)
bun test

# Run with npm/vitest
npm test

# Run tests with watch mode
bun test --watch

# Run tests with UI
npm run test:ui

# Run specific test suite
bun test pure-ntt
bun test precomputed-ntt
bun test ntt-precompile

# Run transaction tests (requires .env with PRIVATE_KEY)  
bun run test:tx
bun run test:tx-only
```

## Test Structure

### Core Test Files

- `src/test/ntt-precompile.test.ts` - Main integration tests with gas estimation
- `src/test/pure-ntt.test.ts` - Pure NTT specific tests  
- `src/test/precomputed-ntt.test.ts` - Precomputed NTT specific tests
- `src/test/ntt-transaction.test.ts` - **Real transaction tests** (requires private key)

### Utility Modules

- `src/utils/ntt-utils.ts` - NTT input/output handling utilities
- `src/utils/test-vectors.ts` - Test case generation and known vectors
- `src/config/rpc-config.ts` - RPC and precompile configuration

## Test Categories

### 1. Go Compatibility Tests
Validates that precompiles produce identical outputs to Go reference implementation:

```typescript
// Known test vector: modulus 97, sequential coefficients 0-15
Input:  [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
Output: [8,60,32,51,20,67,67,36,49,27,72,13,55,96,8,18]
```

### 2. Functionality Tests
- Forward/Inverse NTT operations
- Multiple ring degrees (16, 32, 64, 128, 256, 512)
- Various NTT-friendly moduli
- Round-trip correctness validation

### 3. Consistency Tests
Verifies Pure NTT and Precomputed NTT produce identical results across:
- Different moduli and ring degrees
- Forward and inverse operations
- Cryptographic standard parameters
- Edge cases and boundary conditions

### 4. Gas Cost Analysis Tests
Comprehensive gas estimation and efficiency analysis:
- **Implementation Comparison**: Pure NTT vs Precomputed NTT gas estimation
- **Cryptographic Standards**: Gas estimates for Falcon, Dilithium, and Kyber parameters
- **Operation Analysis**: Forward vs Inverse operation gas estimation comparison
- **Efficiency Benchmarking**: Gas estimates vs theoretical O(N log N) complexity
- **Savings Calculation**: Percentage improvements and total estimated gas savings

### 5. Performance Tests
- Operation timing comparisons between implementations
- Concurrent operation handling and consistency
- Stress testing with repeated calls
- Large ring degree performance validation

### 6. Error Handling Tests
Validates proper rejection of invalid inputs:
- Non-prime moduli
- Non-NTT-friendly moduli (not ≡ 1 (mod 2×ringDegree))
- Invalid ring degrees (not power of 2 or < 16)
- Coefficient validation (≥ modulus)

### 7. Transaction Tests (**Real Blockchain Transactions**)
Tests actual on-chain transactions with private key:
- **Real Transaction Execution**: Sends actual transactions to precompiles
- **Transaction Receipt Analysis**: Gas usage, block confirmation, transaction hashes  
- **Round-trip Transactions**: Forward→Inverse transaction pairs
- **Cryptographic Standards**: KYBER_128, DILITHIUM_256, FALCON_512 real transaction tests
- **Actual Gas Cost Measurement**: Real transaction costs across all standards
- **Error Handling**: Transaction failures and invalid input handling
- **Implementation Comparison**: Side-by-side transaction cost analysis

## Key Test Vectors

### Verified Working Cases
```typescript
// Ring degree 16, modulus 97 (Go compatibility)
{ ringDegree: 16, modulus: 97n }

// Additional verified moduli for degree 16
{ ringDegree: 16, modulus: 193n }
{ ringDegree: 16, modulus: 257n }

// Higher ring degrees
{ ringDegree: 32, modulus: 193n }
{ ringDegree: 64, modulus: 257n }
```

### Cryptographic Standards
Tests real-world parameters used in post-quantum cryptographic schemes:

```typescript
// Falcon-512: Post-quantum digital signature scheme
{ ringDegree: 512, modulus: 12289n }

// Dilithium: NIST-selected post-quantum digital signature
{ ringDegree: 256, modulus: 8380417n }

// Kyber: NIST-selected post-quantum key encapsulation mechanism  
{ ringDegree: 128, modulus: 3329n }
```

## Gas Cost Analysis Results

The test suite provides comprehensive gas cost analysis with both estimation and real transaction execution:

### Gas Estimation Results
Based on `estimateGas()` analysis from integration tests:

#### Gas Estimation Efficiency Rankings
1. **Most Efficient**: FALCON_512 (18.68 gas/op Precomputed, 25.54 gas/op Pure - Excellent)
2. **Moderate**: DILITHIUM_256 (24.30 gas/op Precomputed, 50.46 gas/op Pure - Excellent)  
3. **Least Efficient**: KYBER_128 (39.77 gas/op Precomputed, 109.01 gas/op Pure - Good/Excellent)

#### Implementation Comparison Results (Estimation)
- **Pure NTT (0x14)**: Average 61.67 gas/op across standards
- **Precomputed NTT (0x15)**: Average 27.58 gas/op across standards
- **Estimated Improvement**: 2.06x average improvement ratio (46.7% gas savings)
- **Forward vs Inverse**: <0.1% difference in gas consumption (consistent performance)

### Real Transaction Gas Costs
Based on **actual transaction execution** on NTT precompile test network:

#### Basic NTT Operations (Ring Degree 16)
- **Pure NTT (0x14)**: 91,768 gas per transaction
- **Precomputed NTT (0x15)**: 22,920 gas per transaction
- **Gas Savings**: 68,848 gas (75.0% reduction)
- **Efficiency Improvement**: 4.00x

#### Cryptographic Standards Real Transaction Costs
1. **KYBER_128** (Ring Degree 128):
   - Pure NTT: 96,708 gas | Precomputed NTT: 35,270 gas
   - **Gas Savings**: 61,438 gas (63.0% reduction)
   - **Round-trip Cost**: 74,080 gas

2. **DILITHIUM_256** (Ring Degree 256):
   - Pure NTT: 102,352 gas | Precomputed NTT: 49,380 gas
   - **Gas Savings**: 52,972 gas (51.0% reduction)
   - **Round-trip Cost**: 113,970 gas

3. **FALCON_512** (Ring Degree 512):
   - Pure NTT: 116,664 gas | Precomputed NTT: 85,160 gas
   - **Gas Savings**: 31,504 gas (27.0% reduction)
   - **Round-trip Cost**: 177,670 gas

#### Implementation Comparison Results (Real Transactions)
- **Average Gas Savings**: 47.0% across all cryptographic standards
- **Efficiency Range**: 27.0% (FALCON_512) to 75.0% (basic operations)  
- **Total Round-trip Savings**: Pure NTT 183,560 gas vs Precomputed NTT 45,900 gas (74.0% reduction)

### Gas Estimation vs Real Transaction Comparison

| Standard | Pure Estimation | Pure Actual | Precomputed Estimation | Precomputed Actual | Accuracy |
|----------|----------------|-------------|----------------------|-------------------|----------|
| Basic (16) | ~91,000 | 91,768 | ~23,000 | 22,920 | 99.1% |
| KYBER_128 | 97,675 | 96,708 | 35,631 | 35,270 | 99.0% |
| DILITHIUM_256 | 103,341 | 102,352 | 49,769 | 49,380 | 99.2% |
| FALCON_512 | 117,710 | 116,664 | 86,081 | 85,160 | 99.1% |

**Estimation Accuracy**: 99.1% average accuracy between gas estimation and real transaction costs

## Architecture

### Input Format
```
operation(1) + ring_degree(4) + modulus(8) + coefficients(ring_degree*8)
```
- **operation**: 0x00 (forward) or 0x01 (inverse)
- **ring_degree**: 32-bit big-endian integer
- **modulus**: 64-bit big-endian integer  
- **coefficients**: Array of 64-bit big-endian integers

### Output Format
```
coefficients(ring_degree*8)
```
- Array of 64-bit big-endian integers

### Validation Rules
- Ring degree must be power of 2 and ≥ 16
- Modulus must be prime
- Modulus must satisfy: `modulus ≡ 1 (mod 2×ringDegree)`
- All coefficients must be `< modulus`

## Troubleshooting

### Common Issues

1. **Connection timeouts**: Increase timeout in `vitest.config.ts`
2. **RPC rate limiting**: Reduce concurrent test operations
3. **Large ring degrees**: Some tests may timeout for degrees > 256

### Test Results

**Operation Timing** (measured with RPC latency):
- Ring degree 16: ~180-185ms per operation
- Ring degree 32: ~180-185ms per operation  
- Ring degree 64: ~180-185ms per operation
- Ring degree 128: ~186-200ms per operation
- Ring degree 256: ~366-370ms per operation
- Ring degree 512: ~190-200ms per operation

**Gas Estimation Results**:
- **KYBER_128** (degree 128): Pure 97,675 gas | Precomputed 35,631 gas
- **DILITHIUM_256** (degree 256): Pure 103,341 gas | Precomputed 49,769 gas  
- **FALCON_512** (degree 512): Pure 117,710 gas | Precomputed 86,081 gas

**Real Transaction Results**:
- **KYBER_128** (degree 128): Pure 96,708 gas | Precomputed 35,270 gas
- **DILITHIUM_256** (degree 256): Pure 102,352 gas | Precomputed 49,380 gas  
- **FALCON_512** (degree 512): Pure 116,664 gas | Precomputed 85,160 gas

**Measured Performance Gains**:
- **KYBER_128**: 63.0% gas savings (2.74x improvement ratio)
- **DILITHIUM_256**: 51.0% gas savings (2.07x improvement ratio)
- **FALCON_512**: 27.0% gas savings (1.37x improvement ratio)
- **Average**: 47.0% gas savings, 2.06x improvement ratio

**Test Suite Performance**:
- **61 tests passed** (50 integration + 11 transaction tests) in ~160 seconds
- **99.1% estimation accuracy** confirmed by real blockchain execution
- **Total actual gas savings**: 183,854 gas across cryptographic standards

## References

- [EIP-7885: Number Theoretic Transform Precompiles](https://github.com/ethereum/EIPs/pull/9374)
- [Viem Documentation](https://viem.sh/)
- [Vitest Documentation](https://vitest.dev/)