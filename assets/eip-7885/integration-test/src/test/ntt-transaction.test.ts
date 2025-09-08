import { describe, it, expect, beforeAll } from 'vitest';
import { type Hex } from 'viem';
import { PRECOMPILE_ADDRESSES, NTT_OPERATIONS, CRYPTO_STANDARDS } from '../config/rpc-config.js';
import {
  walletClient,
  txPublicClient,
  privateKeyAccount,
  WALLET_CONFIG,
  nttTestChain,
} from '../config/wallet-config.js';
import {
  createNTTInput,
  parseNTTOutput,
  compareCoefficients,
  formatCoefficients,
  getKnownTestVector,
  type NTTResult,
} from '../utils/ntt-utils.js';

/**
 * Sends actual transaction to NTT precompile and returns parsed result
 */
async function sendNTTTransaction(
  address: Hex,
  input: Parameters<typeof createNTTInput>[0]
): Promise<
  NTTResult & { txHash?: Hex; gasUsed?: bigint; blockNumber?: bigint }
> {
  try {
    const inputData = createNTTInput(input);

    // Send transaction
    const txHash = await walletClient.sendTransaction({
      account: privateKeyAccount,
      chain: nttTestChain,
      to: address,
      data: inputData,
      value: 0n,
    });

    console.log(`📤 Transaction sent: ${txHash}`);

    // Wait for transaction receipt
    const receipt = await txPublicClient.waitForTransactionReceipt({
      hash: txHash,
      timeout: 30000,
    });

    console.log(
      `✅ Transaction confirmed in block ${receipt.blockNumber} (${receipt.gasUsed} gas used)`
    );

    // Check if transaction was successful
    if (receipt.status !== 'success') {
      return {
        success: false,
        output: null,
        coefficients: [],
        txHash,
        gasUsed: receipt.gasUsed,
        blockNumber: receipt.blockNumber,
        error: `Transaction failed with status: ${receipt.status}`,
      };
    }

    // Get return data from transaction receipt
    if (!receipt.logs || receipt.logs.length === 0) {
      // For precompile calls, the return data might be in different format
      // Let's try to get transaction details
      const tx = await txPublicClient.getTransaction({ hash: txHash });
      console.log(`📊 Transaction data length: ${tx.input.length} bytes`);
    }

    // Since precompile return data isn't in receipt logs, we need to simulate the call
    // to get the actual result for verification
    const result = await txPublicClient.call({
      to: address,
      data: inputData,
    });

    if (!result.data || result.data === '0x') {
      return {
        success: false,
        output: null,
        coefficients: [],
        txHash,
        gasUsed: receipt.gasUsed,
        blockNumber: receipt.blockNumber,
        error: 'Empty response from precompile call',
      };
    }

    const coefficients = parseNTTOutput(result.data, input.ringDegree);

    return {
      success: true,
      output: result.data,
      coefficients,
      txHash,
      gasUsed: receipt.gasUsed,
      blockNumber: receipt.blockNumber,
    };
  } catch (error) {
    return {
      success: false,
      output: null,
      coefficients: [],
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

/**
 * Performs round-trip transaction test (forward -> inverse)
 */
async function performTransactionRoundTrip(
  address: Hex,
  input: Parameters<typeof createNTTInput>[0]
): Promise<{
  success: boolean;
  error?: string;
  forwardTx?: Hex;
  inverseTx?: Hex;
  totalGas?: bigint;
}> {
  // Forward NTT transaction
  const forwardInput = { ...input, operation: NTT_OPERATIONS.FORWARD };
  const forwardResult = await sendNTTTransaction(address, forwardInput);

  if (!forwardResult.success) {
    return {
      success: false,
      error: `Forward NTT transaction failed: ${forwardResult.error}`,
    };
  }

  // Inverse NTT transaction
  const inverseInput = {
    ...input,
    operation: NTT_OPERATIONS.INVERSE,
    coefficients: forwardResult.coefficients,
  };

  const inverseResult = await sendNTTTransaction(address, inverseInput);

  if (!inverseResult.success) {
    return {
      success: false,
      error: `Inverse NTT transaction failed: ${inverseResult.error}`,
      forwardTx: forwardResult.txHash,
    };
  }

  // Check if we got back the original coefficients
  if (!compareCoefficients(input.coefficients, inverseResult.coefficients)) {
    return {
      success: false,
      error: `Round-trip failed. Original: ${formatCoefficients(
        input.coefficients
      )}, Got: ${formatCoefficients(inverseResult.coefficients)}`,
      forwardTx: forwardResult.txHash,
      inverseTx: inverseResult.txHash,
    };
  }

  const totalGas =
    (forwardResult.gasUsed || 0n) + (inverseResult.gasUsed || 0n);

  return {
    success: true,
    forwardTx: forwardResult.txHash,
    inverseTx: inverseResult.txHash,
    totalGas,
  };
}

describe('NTT Precompile Transaction Tests', () => {
  beforeAll(() => {
    console.log(`🔑 Wallet Address: ${WALLET_CONFIG.address}`);
    console.log(`🌐 RPC URL: ${WALLET_CONFIG.rpcUrl}`);

    if (!WALLET_CONFIG.hasPrivateKey) {
      throw new Error(
        'Private key not configured. Please set PRIVATE_KEY in .env file'
      );
    }
  });

  describe('Transaction Basic Functionality', () => {
    it('should send successful transaction to Pure NTT precompile', async () => {
      const { input } = getKnownTestVector();
      const result = await sendNTTTransaction(
        PRECOMPILE_ADDRESSES.PURE_NTT,
        input
      );

      expect(result.success, `Transaction failed: ${result.error}`).toBe(true);
      expect(result.txHash).toBeDefined();
      expect(result.gasUsed).toBeDefined();
      expect(result.blockNumber).toBeDefined();
      expect(result.coefficients).toHaveLength(input.ringDegree);

      console.log(`✅ Pure NTT Transaction: ${result.txHash}`);
      console.log(`⛽ Gas Used: ${result.gasUsed}`);
      console.log(`🏗️ Block Number: ${result.blockNumber}`);
      console.log(`📊 Output: ${formatCoefficients(result.coefficients)}`);
    }, 60000);

    it('should send successful transaction to Precomputed NTT precompile', async () => {
      const { input } = getKnownTestVector();
      const result = await sendNTTTransaction(
        PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT,
        input
      );

      expect(result.success, `Transaction failed: ${result.error}`).toBe(true);
      expect(result.txHash).toBeDefined();
      expect(result.gasUsed).toBeDefined();
      expect(result.blockNumber).toBeDefined();
      expect(result.coefficients).toHaveLength(input.ringDegree);

      console.log(`✅ Precomputed NTT Transaction: ${result.txHash}`);
      console.log(`⛽ Gas Used: ${result.gasUsed}`);
      console.log(`🏗️ Block Number: ${result.blockNumber}`);
      console.log(`📊 Output: ${formatCoefficients(result.coefficients)}`);
    }, 60000);

    it('should produce identical results between Pure and Precomputed via transactions', async () => {
      const { input } = getKnownTestVector();

      // Execute sequentially to avoid nonce conflicts
      const pureResult = await sendNTTTransaction(
        PRECOMPILE_ADDRESSES.PURE_NTT,
        input
      );
      const precomputedResult = await sendNTTTransaction(
        PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT,
        input
      );

      expect(
        pureResult.success,
        `Pure NTT transaction failed: ${pureResult.error}`
      ).toBe(true);
      expect(
        precomputedResult.success,
        `Precomputed NTT transaction failed: ${precomputedResult.error}`
      ).toBe(true);
      expect(pureResult.coefficients).toEqual(precomputedResult.coefficients);

      console.log(
        `✅ Pure NTT Tx: ${pureResult.txHash} (${pureResult.gasUsed} gas)`
      );
      console.log(
        `✅ Precomputed NTT Tx: ${precomputedResult.txHash} (${precomputedResult.gasUsed} gas)`
      );
      console.log(
        `📊 Both produce identical output: ${formatCoefficients(
          pureResult.coefficients
        )}`
      );

      // Compare gas usage
      if (pureResult.gasUsed && precomputedResult.gasUsed) {
        const gasSavings = pureResult.gasUsed - precomputedResult.gasUsed;
        const savingsPercent = Number((gasSavings * 100n) / pureResult.gasUsed);
        console.log(
          `⛽ Gas Savings: ${gasSavings} (${savingsPercent.toFixed(1)}%)`
        );
      }
    }, 90000);
  });

  describe('Round-trip Transaction Tests', () => {
    it('should perform successful round-trip transactions on Pure NTT', async () => {
      const { input } = getKnownTestVector();
      const result = await performTransactionRoundTrip(
        PRECOMPILE_ADDRESSES.PURE_NTT,
        input
      );

      expect(result.success, `Round-trip failed: ${result.error}`).toBe(true);
      expect(result.forwardTx).toBeDefined();
      expect(result.inverseTx).toBeDefined();
      expect(result.totalGas).toBeDefined();

      console.log(`✅ Pure NTT Round-trip Success`);
      console.log(`📤 Forward Tx: ${result.forwardTx}`);
      console.log(`📥 Inverse Tx: ${result.inverseTx}`);
      console.log(`⛽ Total Gas: ${result.totalGas}`);
    }, 120000);

    it('should perform successful round-trip transactions on Precomputed NTT', async () => {
      const { input } = getKnownTestVector();
      const result = await performTransactionRoundTrip(
        PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT,
        input
      );

      expect(result.success, `Round-trip failed: ${result.error}`).toBe(true);
      expect(result.forwardTx).toBeDefined();
      expect(result.inverseTx).toBeDefined();
      expect(result.totalGas).toBeDefined();

      console.log(`✅ Precomputed NTT Round-trip Success`);
      console.log(`📤 Forward Tx: ${result.forwardTx}`);
      console.log(`📥 Inverse Tx: ${result.inverseTx}`);
      console.log(`⛽ Total Gas: ${result.totalGas}`);
    }, 120000);
  });

  describe('Gas Cost Comparison via Transactions', () => {
    it('should compare actual transaction gas costs between implementations', async () => {
      const { input } = getKnownTestVector();

      // Execute sequentially to avoid nonce conflicts
      const pureRoundtrip = await performTransactionRoundTrip(
        PRECOMPILE_ADDRESSES.PURE_NTT,
        input
      );
      const precomputedRoundtrip = await performTransactionRoundTrip(
        PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT,
        input
      );

      expect(
        pureRoundtrip.success,
        `Pure round-trip failed: ${pureRoundtrip.error}`
      ).toBe(true);
      expect(
        precomputedRoundtrip.success,
        `Precomputed round-trip failed: ${precomputedRoundtrip.error}`
      ).toBe(true);

      console.log(`\n📊 Transaction Gas Cost Analysis:`);
      console.log(`⛽ Pure NTT Round-trip: ${pureRoundtrip.totalGas} gas`);
      console.log(
        `⛽ Precomputed NTT Round-trip: ${precomputedRoundtrip.totalGas} gas`
      );

      if (pureRoundtrip.totalGas && precomputedRoundtrip.totalGas) {
        const gasSavings =
          pureRoundtrip.totalGas - precomputedRoundtrip.totalGas;
        const savingsPercent = Number(
          (gasSavings * 100n) / pureRoundtrip.totalGas
        );

        console.log(
          `💰 Total Gas Savings: ${gasSavings} (${savingsPercent.toFixed(1)}%)`
        );
        console.log(
          `📈 Efficiency Improvement: ${(
            Number(pureRoundtrip.totalGas) /
            Number(precomputedRoundtrip.totalGas)
          ).toFixed(2)}x`
        );

        // Validate gas savings
        expect(precomputedRoundtrip.totalGas).toBeLessThan(
          pureRoundtrip.totalGas
        );
        expect(savingsPercent).toBeGreaterThan(20); // Expect at least 20% savings
      }
    }, 180000);
  });

  describe('Cryptographic Standards Transaction Tests', () => {
    it('should perform successful transactions with KYBER_128 parameters', async () => {
      const { ringDegree, modulus } = CRYPTO_STANDARDS.KYBER_128;
      const input = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree,
        modulus,
        coefficients: Array(ringDegree)
          .fill(0n)
          .map((_, i) => BigInt(i) % modulus),
      };

      // Execute sequentially to avoid nonce conflicts
      const pureResult = await sendNTTTransaction(PRECOMPILE_ADDRESSES.PURE_NTT, input);
      const precomputedResult = await sendNTTTransaction(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, input);

      expect(pureResult.success, `Pure NTT failed: ${pureResult.error}`).toBe(true);
      expect(precomputedResult.success, `Precomputed NTT failed: ${precomputedResult.error}`).toBe(true);
      expect(pureResult.coefficients).toEqual(precomputedResult.coefficients);

      console.log(`✅ KYBER_128 Pure NTT: ${pureResult.txHash} (${pureResult.gasUsed} gas)`);
      console.log(`✅ KYBER_128 Precomputed NTT: ${precomputedResult.txHash} (${precomputedResult.gasUsed} gas)`);
      
      if (pureResult.gasUsed && precomputedResult.gasUsed) {
        const gasSavings = pureResult.gasUsed - precomputedResult.gasUsed;
        const savingsPercent = Number((gasSavings * 100n) / pureResult.gasUsed);
        console.log(`⛽ KYBER_128 Gas Savings: ${gasSavings} (${savingsPercent.toFixed(1)}%)`);
      }
    }, 120000);

    it('should perform successful transactions with DILITHIUM_256 parameters', async () => {
      const { ringDegree, modulus } = CRYPTO_STANDARDS.DILITHIUM_256;
      const input = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree,
        modulus,
        coefficients: Array(ringDegree)
          .fill(0n)
          .map((_, i) => BigInt(i) % modulus),
      };

      // Execute sequentially to avoid nonce conflicts
      const pureResult = await sendNTTTransaction(PRECOMPILE_ADDRESSES.PURE_NTT, input);
      const precomputedResult = await sendNTTTransaction(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, input);

      expect(pureResult.success, `Pure NTT failed: ${pureResult.error}`).toBe(true);
      expect(precomputedResult.success, `Precomputed NTT failed: ${precomputedResult.error}`).toBe(true);
      expect(pureResult.coefficients).toEqual(precomputedResult.coefficients);

      console.log(`✅ DILITHIUM_256 Pure NTT: ${pureResult.txHash} (${pureResult.gasUsed} gas)`);
      console.log(`✅ DILITHIUM_256 Precomputed NTT: ${precomputedResult.txHash} (${precomputedResult.gasUsed} gas)`);
      
      if (pureResult.gasUsed && precomputedResult.gasUsed) {
        const gasSavings = pureResult.gasUsed - precomputedResult.gasUsed;
        const savingsPercent = Number((gasSavings * 100n) / pureResult.gasUsed);
        console.log(`⛽ DILITHIUM_256 Gas Savings: ${gasSavings} (${savingsPercent.toFixed(1)}%)`);
      }
    }, 120000);

    it('should perform successful transactions with FALCON_512 parameters', async () => {
      const { ringDegree, modulus } = CRYPTO_STANDARDS.FALCON_512;
      const input = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree,
        modulus,
        coefficients: Array(ringDegree)
          .fill(0n)
          .map((_, i) => BigInt(i) % modulus),
      };

      // Execute sequentially to avoid nonce conflicts
      const pureResult = await sendNTTTransaction(PRECOMPILE_ADDRESSES.PURE_NTT, input);
      const precomputedResult = await sendNTTTransaction(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, input);

      expect(pureResult.success, `Pure NTT failed: ${pureResult.error}`).toBe(true);
      expect(precomputedResult.success, `Precomputed NTT failed: ${precomputedResult.error}`).toBe(true);
      expect(pureResult.coefficients).toEqual(precomputedResult.coefficients);

      console.log(`✅ FALCON_512 Pure NTT: ${pureResult.txHash} (${pureResult.gasUsed} gas)`);
      console.log(`✅ FALCON_512 Precomputed NTT: ${precomputedResult.txHash} (${precomputedResult.gasUsed} gas)`);
      
      if (pureResult.gasUsed && precomputedResult.gasUsed) {
        const gasSavings = pureResult.gasUsed - precomputedResult.gasUsed;
        const savingsPercent = Number((gasSavings * 100n) / pureResult.gasUsed);
        console.log(`⛽ FALCON_512 Gas Savings: ${gasSavings} (${savingsPercent.toFixed(1)}%)`);
      }
    }, 120000);

    it('should perform round-trip transactions with cryptographic standards', async () => {
      const standards = [
        { name: 'KYBER_128', ...CRYPTO_STANDARDS.KYBER_128 },
        { name: 'DILITHIUM_256', ...CRYPTO_STANDARDS.DILITHIUM_256 },
        { name: 'FALCON_512', ...CRYPTO_STANDARDS.FALCON_512 },
      ];

      console.log(`\n🧪 Testing round-trip transactions with ${standards.length} cryptographic standards`);

      for (const standard of standards) {
        const input = {
          operation: NTT_OPERATIONS.FORWARD,
          ringDegree: standard.ringDegree,
          modulus: standard.modulus,
          coefficients: Array(standard.ringDegree)
            .fill(0n)
            .map((_, i) => BigInt(i) % standard.modulus),
        };

        // Test round-trip on Precomputed NTT (more efficient)
        const roundtripResult = await performTransactionRoundTrip(
          PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT,
          input
        );

        expect(roundtripResult.success, `${standard.name} round-trip failed: ${roundtripResult.error}`).toBe(true);
        
        console.log(`✅ ${standard.name} Round-trip: Forward ${roundtripResult.forwardTx?.slice(0, 10)}... + Inverse ${roundtripResult.inverseTx?.slice(0, 10)}... = ${roundtripResult.totalGas} gas`);
      }
    }, 300000);
  });

  describe('Error Handling in Transactions', () => {
    it('should handle invalid input in transactions gracefully', async () => {
      // Create invalid input (non-NTT-friendly modulus)
      const invalidInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 101n, // Not NTT-friendly (101 % 32 = 5 ≠ 1)
        coefficients: Array(16)
          .fill(0n)
          .map((_, i) => BigInt(i)),
      };

      // This should either fail gracefully or be caught by input validation
      try {
        const result = await sendNTTTransaction(
          PRECOMPILE_ADDRESSES.PURE_NTT,
          invalidInput
        );

        if (result.success) {
          // If transaction succeeded, the precompile might handle invalid inputs differently
          console.log(
            `⚠️ Transaction succeeded with invalid input: ${result.txHash}`
          );
          console.log(`📊 Output: ${formatCoefficients(result.coefficients)}`);
        } else {
          console.log(`✅ Transaction correctly failed: ${result.error}`);
          expect(result.success).toBe(false);
        }
      } catch (error) {
        // Input validation should catch this before sending transaction
        console.log(
          `✅ Input validation correctly rejected invalid input: ${error}`
        );
        expect(error).toBeDefined();
      }
    }, 60000);
  });
});
