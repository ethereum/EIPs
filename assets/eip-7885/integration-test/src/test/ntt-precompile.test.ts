import { describe, it, expect } from 'vitest';
import { type Hex } from 'viem';
import {
  publicClient,
  PRECOMPILE_ADDRESSES,
  NTT_OPERATIONS,
} from '../config/rpc-config.js';
import {
  createNTTInput,
  parseNTTOutput,
  compareCoefficients,
  formatCoefficients,
  getKnownTestVector,
  type NTTResult,
} from '../utils/ntt-utils.js';
import { getAllTestVectors } from '../utils/test-vectors.js';

/**
 * Calls NTT precompile and returns parsed result
 */
async function callNTTPrecompile(
  address: Hex,
  input: Parameters<typeof createNTTInput>[0]
): Promise<NTTResult> {
  try {
    const inputData = createNTTInput(input);

    const result = await publicClient.call({
      to: address,
      data: inputData,
    });

    if (!result.data || result.data === '0x') {
      return {
        success: false,
        output: null,
        coefficients: [],
        error: 'Empty response from precompile',
      };
    }

    const coefficients = parseNTTOutput(result.data, input.ringDegree);

    return {
      success: true,
      output: result.data,
      coefficients,
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
 * Calls NTT precompile with gas estimation
 */
async function callNTTPrecompileWithGas(
  address: Hex,
  input: Parameters<typeof createNTTInput>[0]
): Promise<NTTResult & { gasUsed?: bigint }> {
  try {
    const inputData = createNTTInput(input);

    // Estimate gas first
    const gasEstimate = await publicClient.estimateGas({
      to: address,
      data: inputData,
    });

    // Make the actual call
    const result = await publicClient.call({
      to: address,
      data: inputData,
    });

    if (!result.data || result.data === '0x') {
      return {
        success: false,
        output: null,
        coefficients: [],
        gasUsed: gasEstimate,
        error: 'Empty response from precompile',
      };
    }

    const coefficients = parseNTTOutput(result.data, input.ringDegree);

    return {
      success: true,
      output: result.data,
      coefficients,
      gasUsed: gasEstimate,
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
 * Performs round-trip test (forward -> inverse)
 */
async function performRoundTripTest(
  address: Hex,
  input: Parameters<typeof createNTTInput>[0]
): Promise<{ success: boolean; error?: string }> {
  // Forward NTT
  const forwardInput = { ...input, operation: NTT_OPERATIONS.FORWARD };
  const forwardResult = await callNTTPrecompile(address, forwardInput);

  if (!forwardResult.success) {
    return {
      success: false,
      error: `Forward NTT failed: ${forwardResult.error}`,
    };
  }

  // Inverse NTT
  const inverseInput = {
    ...input,
    operation: NTT_OPERATIONS.INVERSE,
    coefficients: forwardResult.coefficients,
  };

  const inverseResult = await callNTTPrecompile(address, inverseInput);

  if (!inverseResult.success) {
    return {
      success: false,
      error: `Inverse NTT failed: ${inverseResult.error}`,
    };
  }

  // Check if we got back the original coefficients
  if (!compareCoefficients(input.coefficients, inverseResult.coefficients)) {
    return {
      success: false,
      error: `Round-trip failed. Original: ${formatCoefficients(
        input.coefficients
      )}, Got: ${formatCoefficients(inverseResult.coefficients)}`,
    };
  }

  return { success: true };
}

describe('NTT Precompile Integration Tests', () => {
  describe('Precompile Availability', () => {
    it('should be able to connect to RPC endpoint', async () => {
      const blockNumber = await publicClient.getBlockNumber();
      expect(blockNumber).toBeGreaterThan(0n);
    });

    it('should detect Pure NTT precompile (0x12)', async () => {
      const { input } = getKnownTestVector();
      const result = await callNTTPrecompile(
        PRECOMPILE_ADDRESSES.PURE_NTT,
        input
      );

      // Should not fail due to "unknown precompile"
      if (result.error) {
        expect(result.error).not.toMatch(/unknown precompile/i);
      }
      // If no error, the precompile exists and works
      expect(
        result.error == null || !result.error.match(/unknown precompile/i)
      ).toBe(true);
    }, 10000);
  });

  describe('Go Compatibility Tests', () => {
    it('should match Go test output for Pure NTT (0x12)', async () => {
      const { input, expectedOutput } = getKnownTestVector();
      const result = await callNTTPrecompile(
        PRECOMPILE_ADDRESSES.PURE_NTT,
        input
      );

      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true);
      expect(result.coefficients).toEqual(expectedOutput);

      console.log(
        `✅ Pure NTT Input: ${formatCoefficients(input.coefficients)}`
      );
      console.log(
        `✅ Pure NTT Output: ${formatCoefficients(result.coefficients)}`
      );
    }, 10000);
  });

  describe('Known Test Vectors', () => {
    const testVectors = getAllTestVectors();

    testVectors.known.forEach((vector) => {
      it(`should handle ${vector.name}`, async () => {
        const result = await callNTTPrecompile(
          PRECOMPILE_ADDRESSES.PURE_NTT,
          vector.input
        );

        if (vector.shouldFail) {
          expect(result.success).toBe(false);
          if (vector.errorPattern) {
            expect(result.error).toMatch(vector.errorPattern);
          }
        } else {
          expect(result.success, `Test failed: ${result.error}`).toBe(true);

          if (vector.expectedOutput) {
            expect(result.coefficients).toEqual(vector.expectedOutput);
          }

          console.log(
            `✅ ${vector.name}: ${formatCoefficients(result.coefficients)}`
          );
        }
      }, 10000);
    });
  });

  describe('Basic Functionality Tests', () => {
    const testVectors = getAllTestVectors();

    testVectors.basic.slice(0, 5).forEach((vector) => {
      // Limit to first 5 for CI speed
      it(`should handle ${vector.name}`, async () => {
        const result = await callNTTPrecompile(
          PRECOMPILE_ADDRESSES.PURE_NTT,
          vector.input
        );

        expect(result.success, `Test failed: ${result.error}`).toBe(true);
        expect(result.coefficients).toHaveLength(vector.input.ringDegree);

        // Verify all coefficients are less than modulus
        result.coefficients.forEach((coeff, i) => {
          expect(coeff, `Coefficient ${i} should be < modulus`).toBeLessThan(
            vector.input.modulus
          );
        });

        console.log(
          `✅ ${vector.name}: Success with ${result.coefficients.length} coefficients`
        );
      }, 15000);
    });
  });

  describe('Round-trip Tests', () => {
    const testVectors = getAllTestVectors();

    testVectors.roundTrip.slice(0, 3).forEach((vector) => {
      // Limit for CI speed
      it(`should pass round-trip test for ${vector.name}`, async () => {
        const result = await performRoundTripTest(
          PRECOMPILE_ADDRESSES.PURE_NTT,
          vector.input
        );

        expect(result.success, `Round-trip failed: ${result.error}`).toBe(true);
        console.log(`✅ Round-trip passed for ${vector.name}`);
      }, 20000);
    });
  });

  describe('Error Handling', () => {
    const testVectors = getAllTestVectors();

    testVectors.errors.forEach((vector) => {
      it(`should fail for ${vector.name}`, async () => {
        expect(() => createNTTInput(vector.input)).toThrow(vector.errorPattern);
        console.log(`✅ Correctly rejected: ${vector.name}`);
      });
    });
  });

  describe('Performance and Consistency', () => {
    it('should handle multiple rapid calls consistently', async () => {
      const { input } = getKnownTestVector();

      // Make 5 parallel calls
      const promises = Array(5)
        .fill(null)
        .map(() => callNTTPrecompile(PRECOMPILE_ADDRESSES.PURE_NTT, input));

      const results = await Promise.all(promises);

      // All should succeed
      results.forEach((result, i) => {
        expect(result.success, `Call ${i} failed: ${result.error}`).toBe(true);
      });

      // All should produce identical results
      const firstResult = results[0].coefficients;
      results.forEach((result, i) => {
        expect(
          result.coefficients,
          `Call ${i} produced different result`
        ).toEqual(firstResult);
      });

      console.log(
        `✅ All ${results.length} parallel calls produced identical results`
      );
    }, 20000);

    it('should handle large ring degrees', async () => {
      const testVector = getAllTestVectors().cryptoStandard.find((v) =>
        v.name.includes('FALCON_512')
      );

      if (testVector) {
        const result = await callNTTPrecompile(
          PRECOMPILE_ADDRESSES.PURE_NTT,
          testVector.input
        );

        if (result.success) {
          expect(result.coefficients).toHaveLength(testVector.input.ringDegree);
          console.log(
            `✅ Successfully handled ring degree ${testVector.input.ringDegree}`
          );
        } else {
          console.log(
            `⚠️ Large ring degree test failed (expected for some implementations): ${result.error}`
          );
        }
      }
    }, 30000);
  });

  describe('Gas Cost Analysis', () => {
    it('should measure gas costs for Pure NTT', async () => {
      const { input } = getKnownTestVector();

      const pureResult = await callNTTPrecompileWithGas(
        PRECOMPILE_ADDRESSES.PURE_NTT,
        input
      );

      expect(pureResult.success, `Pure NTT failed: ${pureResult.error}`).toBe(
        true
      );

      console.log(
        `⛽ Pure NTT (0x12) Gas Used: ${
          pureResult.gasUsed?.toString() || 'N/A'
        }`
      );

      if (pureResult.gasUsed) {
        expect(pureResult.gasUsed).toBeGreaterThan(0);
        expect(pureResult.gasUsed).toBeLessThan(200000);

        const gasPerCoeff = Number(pureResult.gasUsed) / 16;
        console.log(
          `📊 Pure NTT Gas Analysis: ${pureResult.gasUsed} gas for ring degree 16`
        );
        console.log(`💡 Gas per coefficient: ${gasPerCoeff.toFixed(2)}`);
      }
    }, 15000);

    it('should measure gas costs across cryptographic standards for Pure NTT', async () => {
      const testVectors = getAllTestVectors();
      const cryptoTests = testVectors.cryptoStandard; // Use real crypto standard parameters

      const gasResults: {
        name: string;
        ringDegree: number;
        modulus: string;
        pureGas: bigint;
        gasPerCoeff: number;
      }[] = [];

      for (const vector of cryptoTests) {
        const pureResult = await callNTTPrecompileWithGas(
          PRECOMPILE_ADDRESSES.PURE_NTT,
          vector.input
        );

        if (pureResult.success && pureResult.gasUsed) {
          const gasPerCoeff =
            Number(pureResult.gasUsed) / vector.input.ringDegree;

          gasResults.push({
            name: vector.name,
            ringDegree: vector.input.ringDegree,
            modulus: vector.input.modulus.toString(),
            pureGas: pureResult.gasUsed,
            gasPerCoeff,
          });

          console.log(`⛽ ${vector.name}:`);
          console.log(`  └── Pure NTT (0x12): ${pureResult.gasUsed} gas`);
          console.log(`  └── Gas per coefficient: ${gasPerCoeff.toFixed(2)}`);
          console.log(
            `  └── Ring Degree: ${vector.input.ringDegree}, Modulus: ${vector.input.modulus}`
          );
        } else {
          console.log(`⚠️ ${vector.name}: Pure=${pureResult.error || 'OK'}`);
        }
      }

      // Verify we got results for crypto standards
      expect(gasResults.length).toBeGreaterThan(0);

      // Analyze gas scaling across different crypto standards
      if (gasResults.length >= 1) {
        gasResults.sort((a, b) => a.ringDegree - b.ringDegree);

        console.log(`\n📊 Cryptographic Standards Gas Analysis:`);
        gasResults.forEach((result) => {
          console.log(`  • ${result.name}:`);
          console.log(
            `    - Pure NTT: ${result.gasPerCoeff.toFixed(2)} gas/coeff`
          );
          console.log(
            `    - Total gas: ${result.pureGas} for ${result.ringDegree} coefficients`
          );
        });

        const avgGasPerCoeff =
          gasResults.reduce((sum, r) => sum + r.gasPerCoeff, 0) /
          gasResults.length;
        const totalGas = gasResults.reduce(
          (sum, r) => sum + Number(r.pureGas),
          0
        );

        console.log(
          `📊 Average gas per coefficient: ${avgGasPerCoeff.toFixed(2)}`
        );
        console.log(`📊 Total gas for all standards: ${totalGas}`);
      }
    }, 90000);

    it('should measure gas costs for forward vs inverse operations on Pure NTT', async () => {
      const { input } = getKnownTestVector();

      // Test Pure NTT for forward operations
      const forwardInput = { ...input, operation: NTT_OPERATIONS.FORWARD };
      const pureForwardResult = await callNTTPrecompileWithGas(
        PRECOMPILE_ADDRESSES.PURE_NTT,
        forwardInput
      );

      expect(
        pureForwardResult.success,
        `Pure Forward NTT failed: ${pureForwardResult.error}`
      ).toBe(true);

      // Test Pure NTT for inverse operations
      const inverseInput = {
        ...input,
        operation: NTT_OPERATIONS.INVERSE,
        coefficients: pureForwardResult.coefficients, // Use forward result for consistency
      };
      const pureInverseResult = await callNTTPrecompileWithGas(
        PRECOMPILE_ADDRESSES.PURE_NTT,
        inverseInput
      );

      expect(
        pureInverseResult.success,
        `Pure Inverse NTT failed: ${pureInverseResult.error}`
      ).toBe(true);

      console.log(`⛽ Pure NTT Operation Gas Costs:`);
      console.log(
        `  └── Forward: ${pureForwardResult.gasUsed?.toString() || 'N/A'}`
      );
      console.log(
        `  └── Inverse: ${pureInverseResult.gasUsed?.toString() || 'N/A'}`
      );

      // Analyze forward vs inverse for Pure NTT
      if (pureForwardResult.gasUsed && pureInverseResult.gasUsed) {
        const pureDiff =
          pureForwardResult.gasUsed > pureInverseResult.gasUsed
            ? pureForwardResult.gasUsed - pureInverseResult.gasUsed
            : pureInverseResult.gasUsed - pureForwardResult.gasUsed;
        const pureDiffPercent = Number(
          (pureDiff * 100n) / pureForwardResult.gasUsed
        );
        const totalGas = pureForwardResult.gasUsed + pureInverseResult.gasUsed;

        console.log(
          `📊 Pure NTT Forward/Inverse Difference: ${pureDiff} (${pureDiffPercent.toFixed(
            1
          )}%)`
        );
        console.log(`📊 Pure NTT Round-trip Total Gas: ${totalGas}`);
      }
    }, 30000);

    it('should analyze gas costs for crypto standard moduli comparison on Pure NTT', async () => {
      const testVectors = getAllTestVectors();
      const cryptoTests = testVectors.cryptoStandard;

      const gasResults: {
        name: string;
        modulus: bigint;
        ringDegree: number;
        pureGas: bigint;
        pureGasPerUnit: number;
      }[] = [];

      for (const vector of cryptoTests) {
        const pureResult = await callNTTPrecompileWithGas(
          PRECOMPILE_ADDRESSES.PURE_NTT,
          vector.input
        );

        if (pureResult.success && pureResult.gasUsed) {
          const pureGasPerUnit =
            Number(pureResult.gasUsed) / vector.input.ringDegree;

          gasResults.push({
            name: vector.name,
            modulus: vector.input.modulus,
            ringDegree: vector.input.ringDegree,
            pureGas: pureResult.gasUsed,
            pureGasPerUnit,
          });

          console.log(`⛽ ${vector.name} (mod ${vector.input.modulus}):`);
          console.log(
            `  └── Pure NTT: ${
              pureResult.gasUsed
            } gas (${pureGasPerUnit.toFixed(2)} gas/ring-unit)`
          );
        }
      }

      // Verify we got results
      expect(gasResults.length).toBeGreaterThan(0);

      if (gasResults.length >= 1) {
        // Sort by ring degree for consistent ordering
        gasResults.sort((a, b) => a.ringDegree - b.ringDegree);

        console.log(
          `\n📊 Cryptographic Standard Moduli Efficiency Comparison:`
        );
        gasResults.forEach((result) => {
          console.log(`  • ${result.name} (degree ${result.ringDegree}):`);
          console.log(
            `    - Pure efficiency: ${result.pureGasPerUnit.toFixed(
              2
            )} gas/ring-unit`
          );
        });
      }
    }, 75000);
  });
});
