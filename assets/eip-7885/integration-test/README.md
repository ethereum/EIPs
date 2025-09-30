# NTT Precompile Integration Tests

Pure NTT integration test suite for EIP-7885 NTT (Number Theoretic Transform) precompile using Viem and TypeScript.

## Overview

This test suite provides direct integration testing of the Pure NTT precompile by calling it through RPC, bypassing the limitations of Foundry's local EVM that doesn't include custom precompiles.

**Testing Environment**: Tests are executed against an op-geth client built from [yhl125/op-geth](https://github.com/yhl125/op-geth/tree/optimism) with integrated NTT precompile support.

This test suite is validated against a live OP-Stack testnet, which is also available for public use:

- **RPC**: http://34.29.49.47:8545
- **Network ID**: 788484
- **Deposit Address (Sepolia ETH)**: 0xaf17cee393b8cad73846a19e8ee718debbac6b9c

You can deposit Sepolia ETH to address `0xaf17cee393b8cad73846a19e8ee718debbac6b9c` to enable testing with real transactions on this testnet.

### Precompile Tested

- **Pure NTT (0x12)**: Standard NTT implementation with on-the-fly computation

## Features

- 🚀 **Direct RPC Testing**: Tests run against actual Pure NTT precompile implementation on remote node
- 🔬 **Go Compatibility**: Validates outputs match Go reference implementation exactly
- 📊 **Comprehensive Coverage**: Tests various ring degrees, moduli, and cryptographic standards
- ⚡ **Gas Cost Analysis**: Detailed gas consumption analysis and efficiency benchmarking
- 🏛️ **Cryptographic Standards**: Tests real-world parameters from Falcon, Dilithium, and Kyber
- 🔄 **Round-trip Validation**: Forward→Inverse NTT correctness verification
- 🛡️ **Error Handling**: Validates proper input validation and error responses

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
bun test ntt-precompile

# Run transaction tests (requires .env with PRIVATE_KEY)  
bun run test:tx
bun run test:tx-only
```

## Test Structure

### Core Test Files

- `src/test/ntt-precompile.test.ts` - Main integration tests with gas estimation
- `src/test/pure-ntt.test.ts` - Pure NTT specific tests  
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

### 3. Pure NTT Performance Tests
Validates Pure NTT performance characteristics across:
- Different moduli and ring degrees
- Forward and inverse operations
- Cryptographic standard parameters
- Edge cases and boundary conditions

### 4. Gas Cost Analysis Tests
Comprehensive gas estimation and efficiency analysis for Pure NTT:
- **Gas Estimation vs Actual**: Compares estimated vs real transaction gas costs
- **Cryptographic Standards**: Gas analysis for Falcon, Dilithium, and Kyber parameters
- **Operation Analysis**: Forward vs Inverse operation gas cost comparison
- **Performance Metrics**: Gas per coefficient and operation efficiency analysis

### 5. Performance Tests
- Operation timing analysis for Pure NTT
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
- **Real Transaction Execution**: Sends actual transactions to Pure NTT precompile
- **Transaction Receipt Analysis**: Gas usage, block confirmation, transaction hashes  
- **Round-trip Transactions**: Forward→Inverse transaction pairs
- **Cryptographic Standards**: KYBER_128, DILITHIUM_256, FALCON_512 real transaction tests
- **Actual Gas Cost Measurement**: Real transaction costs across all standards
- **Error Handling**: Transaction failures and invalid input handling

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

The test suite provides comprehensive gas cost analysis with both estimation and real transaction execution for Pure NTT:

### Real Transaction Gas Costs
Based on **actual transaction execution** on NTT precompile test network:

#### Basic NTT Operations (Ring Degree 16)
- **Pure NTT (0x12)**: 91,768 gas per transaction
- **Round-trip Cost**: 183,560 gas (91,768 + 91,792)

#### Cryptographic Standards Real Transaction Costs
1. **KYBER_128** (Ring Degree 128):
   - Pure NTT: 96,708 gas per transaction
   - Round-trip Cost: 194,832 gas
   - Gas per coefficient: 763.09

2. **DILITHIUM_256** (Ring Degree 256):
   - Pure NTT: 102,352 gas per transaction
   - Round-trip Cost: 210,788 gas
   - Gas per coefficient: 403.68

3. **FALCON_512** (Ring Degree 512):
   - Pure NTT: 116,664 gas per transaction
   - Round-trip Cost: 236,268 gas
   - Gas per coefficient: 229.90

### Gas Estimation vs Real Transaction Comparison

| Standard | Gas Estimation | Actual Transaction | Accuracy |
|----------|---------------|-------------------|----------|
| Basic (16) | 92,715 | 91,768 | 98.9% |
| KYBER_128 | 97,675 | 96,708 | 99.0% |
| DILITHIUM_256 | 103,341 | 102,352 | 99.0% |
| FALCON_512 | 117,710 | 116,664 | 99.1% |

**Estimation Accuracy**: 99.0% average accuracy between gas estimation and real transaction costs

### Performance Analysis
- **Forward vs Inverse Operations**: 0.0% difference (consistent performance)
- **Most Efficient**: FALCON_512 (229.90 gas per coefficient)
- **Least Efficient**: KYBER_128 (763.09 gas per coefficient)
- **Average Gas per Coefficient**: 465.55 across all cryptographic standards

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

**Gas Analysis Results (Pure NTT)**:
- **Basic Operations** (degree 16): 91,768 gas per transaction
- **KYBER_128** (degree 128): 96,708 gas per transaction
- **DILITHIUM_256** (degree 256): 102,352 gas per transaction  
- **FALCON_512** (degree 512): 116,664 gas per transaction

**Performance Characteristics**:
- **Most Efficient**: FALCON_512 (229.90 gas per coefficient)
- **Least Efficient**: KYBER_128 (763.09 gas per coefficient)
- **Average Efficiency**: 465.55 gas per coefficient

**Test Suite Performance**:
- **45 tests passed** (11 pure-ntt + 22 integration + 12 transaction tests) in ~86 seconds
- **99.0% estimation accuracy** confirmed by real blockchain execution
- **Total test coverage**: Pure NTT functionality across all cryptographic standards

## References

- [EIP-7885: Number Theoretic Transform Precompiles](https://github.com/ethereum/EIPs/pull/9374)
- [Viem Documentation](https://viem.sh/)
- [Vitest Documentation](https://vitest.dev/)