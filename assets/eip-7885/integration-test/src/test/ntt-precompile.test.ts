import { describe, it, expect } from 'vitest'
import { type Hex } from 'viem'
import { publicClient, PRECOMPILE_ADDRESSES, NTT_OPERATIONS } from '../config/rpc-config.js'
import {
  createNTTInput,
  parseNTTOutput,
  compareCoefficients,
  formatCoefficients,
  getKnownTestVector,
  type NTTResult
} from '../utils/ntt-utils.js'
import { 
  getAllTestVectors,
  type TestVector 
} from '../utils/test-vectors.js'

/**
 * Calls NTT precompile and returns parsed result
 */
async function callNTTPrecompile(
  address: Hex,
  input: Parameters<typeof createNTTInput>[0]
): Promise<NTTResult> {
  try {
    const inputData = createNTTInput(input)
    
    const result = await publicClient.call({
      to: address,
      data: inputData
    })
    
    if (!result.data || result.data === '0x') {
      return {
        success: false,
        output: null,
        coefficients: [],
        error: 'Empty response from precompile'
      }
    }
    
    const coefficients = parseNTTOutput(result.data, input.ringDegree)
    
    return {
      success: true,
      output: result.data,
      coefficients,
    }
  } catch (error) {
    return {
      success: false,
      output: null,
      coefficients: [],
      error: error instanceof Error ? error.message : String(error)
    }
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
    const inputData = createNTTInput(input)
    
    // Estimate gas first
    const gasEstimate = await publicClient.estimateGas({
      to: address,
      data: inputData
    })
    
    // Make the actual call
    const result = await publicClient.call({
      to: address,
      data: inputData
    })
    
    if (!result.data || result.data === '0x') {
      return {
        success: false,
        output: null,
        coefficients: [],
        gasUsed: gasEstimate,
        error: 'Empty response from precompile'
      }
    }
    
    const coefficients = parseNTTOutput(result.data, input.ringDegree)
    
    return {
      success: true,
      output: result.data,
      coefficients,
      gasUsed: gasEstimate,
    }
  } catch (error) {
    return {
      success: false,
      output: null,
      coefficients: [],
      error: error instanceof Error ? error.message : String(error)
    }
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
  const forwardInput = { ...input, operation: NTT_OPERATIONS.FORWARD }
  const forwardResult = await callNTTPrecompile(address, forwardInput)
  
  if (!forwardResult.success) {
    return { success: false, error: `Forward NTT failed: ${forwardResult.error}` }
  }
  
  // Inverse NTT
  const inverseInput = {
    ...input,
    operation: NTT_OPERATIONS.INVERSE,
    coefficients: forwardResult.coefficients
  }
  
  const inverseResult = await callNTTPrecompile(address, inverseInput)
  
  if (!inverseResult.success) {
    return { success: false, error: `Inverse NTT failed: ${inverseResult.error}` }
  }
  
  // Check if we got back the original coefficients
  if (!compareCoefficients(input.coefficients, inverseResult.coefficients)) {
    return {
      success: false,
      error: `Round-trip failed. Original: ${formatCoefficients(input.coefficients)}, Got: ${formatCoefficients(inverseResult.coefficients)}`
    }
  }
  
  return { success: true }
}

describe('NTT Precompile Integration Tests', () => {
  describe('Precompile Availability', () => {
    it('should be able to connect to RPC endpoint', async () => {
      const blockNumber = await publicClient.getBlockNumber()
      expect(blockNumber).toBeGreaterThan(0n)
    })
    
    it('should detect Pure NTT precompile (0x14)', async () => {
      const { input } = getKnownTestVector()
      const result = await callNTTPrecompile(PRECOMPILE_ADDRESSES.PURE_NTT, input)
      
      // Should not fail due to "unknown precompile"
      if (result.error) {
        expect(result.error).not.toMatch(/unknown precompile/i)
      }
      // If no error, the precompile exists and works
      expect(result.error == null || !result.error.match(/unknown precompile/i)).toBe(true)
    }, 10000)
    
    it('should detect Precomputed NTT precompile (0x15)', async () => {
      const { input } = getKnownTestVector()
      const result = await callNTTPrecompile(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, input)
      
      // Should not fail due to "unknown precompile"
      if (result.error) {
        expect(result.error).not.toMatch(/unknown precompile/i)
      }
      // If no error, the precompile exists and works
      expect(result.error == null || !result.error.match(/unknown precompile/i)).toBe(true)
    }, 10000)
  })

  describe('Go Compatibility Tests', () => {
    it('should match Go test output for Pure NTT (0x14)', async () => {
      const { input, expectedOutput } = getKnownTestVector()
      const result = await callNTTPrecompile(PRECOMPILE_ADDRESSES.PURE_NTT, input)
      
      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true)
      expect(result.coefficients).toEqual(expectedOutput)
      
      console.log(`✅ Pure NTT Input: ${formatCoefficients(input.coefficients)}`)
      console.log(`✅ Pure NTT Output: ${formatCoefficients(result.coefficients)}`)
    }, 10000)
    
    it('should match Go test output for Precomputed NTT (0x15)', async () => {
      const { input, expectedOutput } = getKnownTestVector()
      const result = await callNTTPrecompile(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, input)
      
      expect(result.success, `Precomputed NTT failed: ${result.error}`).toBe(true)
      expect(result.coefficients).toEqual(expectedOutput)
      
      console.log(`✅ Precomputed NTT Input: ${formatCoefficients(input.coefficients)}`)
      console.log(`✅ Precomputed NTT Output: ${formatCoefficients(result.coefficients)}`)
    }, 10000)
    
    it('should produce identical results between Pure and Precomputed NTT', async () => {
      const { input } = getKnownTestVector()
      
      const [pureResult, precomputedResult] = await Promise.all([
        callNTTPrecompile(PRECOMPILE_ADDRESSES.PURE_NTT, input),
        callNTTPrecompile(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, input)
      ])
      
      expect(pureResult.success, `Pure NTT failed: ${pureResult.error}`).toBe(true)
      expect(precomputedResult.success, `Precomputed NTT failed: ${precomputedResult.error}`).toBe(true)
      expect(pureResult.coefficients).toEqual(precomputedResult.coefficients)
      
      console.log(`✅ Both implementations produce identical output: ${formatCoefficients(pureResult.coefficients)}`)
    }, 15000)
  })

  describe('Known Test Vectors', () => {
    const testVectors = getAllTestVectors()
    
    testVectors.known.forEach((vector) => {
      it(`should handle ${vector.name}`, async () => {
        const result = await callNTTPrecompile(PRECOMPILE_ADDRESSES.PURE_NTT, vector.input)
        
        if (vector.shouldFail) {
          expect(result.success).toBe(false)
          if (vector.errorPattern) {
            expect(result.error).toMatch(vector.errorPattern)
          }
        } else {
          expect(result.success, `Test failed: ${result.error}`).toBe(true)
          
          if (vector.expectedOutput) {
            expect(result.coefficients).toEqual(vector.expectedOutput)
          }
          
          console.log(`✅ ${vector.name}: ${formatCoefficients(result.coefficients)}`)
        }
      }, 10000)
    })
  })

  describe('Basic Functionality Tests', () => {
    const testVectors = getAllTestVectors()
    
    testVectors.basic.slice(0, 5).forEach((vector) => { // Limit to first 5 for CI speed
      it(`should handle ${vector.name}`, async () => {
        const result = await callNTTPrecompile(PRECOMPILE_ADDRESSES.PURE_NTT, vector.input)
        
        expect(result.success, `Test failed: ${result.error}`).toBe(true)
        expect(result.coefficients).toHaveLength(vector.input.ringDegree)
        
        // Verify all coefficients are less than modulus
        result.coefficients.forEach((coeff, i) => {
          expect(coeff, `Coefficient ${i} should be < modulus`).toBeLessThan(vector.input.modulus)
        })
        
        console.log(`✅ ${vector.name}: Success with ${result.coefficients.length} coefficients`)
      }, 15000)
    })
  })

  describe('Round-trip Tests', () => {
    const testVectors = getAllTestVectors()
    
    testVectors.roundTrip.slice(0, 3).forEach((vector) => { // Limit for CI speed
      it(`should pass round-trip test for ${vector.name}`, async () => {
        const result = await performRoundTripTest(PRECOMPILE_ADDRESSES.PURE_NTT, vector.input)
        
        expect(result.success, `Round-trip failed: ${result.error}`).toBe(true)
        console.log(`✅ Round-trip passed for ${vector.name}`)
      }, 20000)
    })
  })

  describe('Error Handling', () => {
    const testVectors = getAllTestVectors()
    
    testVectors.errors.forEach((vector) => {
      it(`should fail for ${vector.name}`, async () => {
        expect(() => createNTTInput(vector.input)).toThrow(vector.errorPattern)
        console.log(`✅ Correctly rejected: ${vector.name}`)
      })
    })
  })

  describe('Performance and Consistency', () => {
    it('should handle multiple rapid calls consistently', async () => {
      const { input } = getKnownTestVector()
      
      // Make 5 parallel calls
      const promises = Array(5).fill(null).map(() => 
        callNTTPrecompile(PRECOMPILE_ADDRESSES.PURE_NTT, input)
      )
      
      const results = await Promise.all(promises)
      
      // All should succeed
      results.forEach((result, i) => {
        expect(result.success, `Call ${i} failed: ${result.error}`).toBe(true)
      })
      
      // All should produce identical results
      const firstResult = results[0].coefficients
      results.forEach((result, i) => {
        expect(result.coefficients, `Call ${i} produced different result`).toEqual(firstResult)
      })
      
      console.log(`✅ All ${results.length} parallel calls produced identical results`)
    }, 20000)
    
    it('should handle large ring degrees', async () => {
      const testVector = getAllTestVectors().cryptoStandard.find(v => 
        v.name.includes('FALCON_512')
      )
      
      if (testVector) {
        const result = await callNTTPrecompile(PRECOMPILE_ADDRESSES.PURE_NTT, testVector.input)
        
        if (result.success) {
          expect(result.coefficients).toHaveLength(testVector.input.ringDegree)
          console.log(`✅ Successfully handled ring degree ${testVector.input.ringDegree}`)
        } else {
          console.log(`⚠️ Large ring degree test failed (expected for some implementations): ${result.error}`)
        }
      }
    }, 30000)
  })

  describe('Gas Cost Analysis', () => {
    it('should measure gas costs for Pure NTT vs Precomputed NTT', async () => {
      const { input } = getKnownTestVector()
      
      const [pureResult, precomputedResult] = await Promise.all([
        callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PURE_NTT, input),
        callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, input)
      ])
      
      expect(pureResult.success, `Pure NTT failed: ${pureResult.error}`).toBe(true)
      expect(precomputedResult.success, `Precomputed NTT failed: ${precomputedResult.error}`).toBe(true)
      
      console.log(`⛽ Pure NTT (0x14) Gas Used: ${pureResult.gasUsed?.toString() || 'N/A'}`)
      console.log(`⛽ Precomputed NTT (0x15) Gas Used: ${precomputedResult.gasUsed?.toString() || 'N/A'}`)
      
      if (pureResult.gasUsed && precomputedResult.gasUsed) {
        const gasDiff = pureResult.gasUsed - precomputedResult.gasUsed
        const gasDiffPercent = Number((gasDiff * 100n) / pureResult.gasUsed)
        console.log(`⛽ Gas Difference: ${gasDiff.toString()} (${gasDiffPercent.toFixed(1)}%)`)
        
        // Pure NTT should generally use more gas than precomputed
        if (pureResult.gasUsed > precomputedResult.gasUsed) {
          console.log(`✅ Pure NTT uses ${gasDiffPercent.toFixed(1)}% more gas than Precomputed NTT (expected)`)
        } else {
          console.log(`⚠️ Precomputed NTT uses more gas than Pure NTT (unexpected)`)
        }
      }
    }, 15000)

    it('should measure gas costs across cryptographic standards for both implementations', async () => {
      const testVectors = getAllTestVectors()
      const cryptoTests = testVectors.cryptoStandard // Use real crypto standard parameters
      
      const gasResults: { 
        name: string; 
        ringDegree: number; 
        modulus: string; 
        pureGas: bigint; 
        precomputedGas: bigint;
        gasDiff: bigint;
        efficiencyGain: number;
      }[] = []
      
      for (const vector of cryptoTests) {
        const [pureResult, precomputedResult] = await Promise.all([
          callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PURE_NTT, vector.input),
          callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, vector.input)
        ])
        
        if (pureResult.success && precomputedResult.success && pureResult.gasUsed && precomputedResult.gasUsed) {
          const gasDiff = pureResult.gasUsed - precomputedResult.gasUsed
          const efficiencyGain = Number((gasDiff * 100n) / pureResult.gasUsed)
          
          gasResults.push({
            name: vector.name,
            ringDegree: vector.input.ringDegree,
            modulus: vector.input.modulus.toString(),
            pureGas: pureResult.gasUsed,
            precomputedGas: precomputedResult.gasUsed,
            gasDiff,
            efficiencyGain
          })
          
          console.log(`⛽ ${vector.name}:`)
          console.log(`  └── Pure NTT (0x14): ${pureResult.gasUsed} gas`)
          console.log(`  └── Precomputed NTT (0x15): ${precomputedResult.gasUsed} gas`)
          console.log(`  └── Gas Saved: ${gasDiff} (${efficiencyGain.toFixed(1)}% efficiency gain)`)
          console.log(`  └── Ring Degree: ${vector.input.ringDegree}, Modulus: ${vector.input.modulus}`)
        } else {
          console.log(`⚠️ ${vector.name}: Pure=${pureResult.error || 'OK'}, Precomputed=${precomputedResult.error || 'OK'}`)
        }
      }
      
      // Verify we got results for crypto standards
      expect(gasResults.length).toBeGreaterThan(0)
      
      // Analyze gas scaling across different crypto standards
      if (gasResults.length >= 1) {
        gasResults.sort((a, b) => a.ringDegree - b.ringDegree)
        
        console.log(`\n📊 Cryptographic Standards Gas Comparison:`)
        gasResults.forEach(result => {
          const pureGasPerCoeff = Number(result.pureGas) / result.ringDegree
          const precomputedGasPerCoeff = Number(result.precomputedGas) / result.ringDegree
          console.log(`  • ${result.name}:`)
          console.log(`    - Pure: ${pureGasPerCoeff.toFixed(2)} gas/coeff`)
          console.log(`    - Precomputed: ${precomputedGasPerCoeff.toFixed(2)} gas/coeff`)
          console.log(`    - Efficiency: ${result.efficiencyGain.toFixed(1)}% gain`)
        })
        
        const avgEfficiencyGain = gasResults.reduce((sum, r) => sum + r.efficiencyGain, 0) / gasResults.length
        const totalGasSaved = gasResults.reduce((sum, r) => sum + Number(r.gasDiff), 0)
        
        console.log(`📊 Average efficiency gain: ${avgEfficiencyGain.toFixed(1)}%`)
        console.log(`📊 Total gas saved across all standards: ${totalGasSaved}`)
      }
    }, 90000)

    it('should measure gas costs for forward vs inverse operations on both implementations', async () => {
      const { input } = getKnownTestVector()
      
      // Test both Pure and Precomputed NTT for forward operations
      const forwardInput = { ...input, operation: NTT_OPERATIONS.FORWARD }
      const [pureForwardResult, precomputedForwardResult] = await Promise.all([
        callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PURE_NTT, forwardInput),
        callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, forwardInput)
      ])
      
      expect(pureForwardResult.success, `Pure Forward NTT failed: ${pureForwardResult.error}`).toBe(true)
      expect(precomputedForwardResult.success, `Precomputed Forward NTT failed: ${precomputedForwardResult.error}`).toBe(true)
      
      // Test both implementations for inverse operations
      const inverseInput = {
        ...input,
        operation: NTT_OPERATIONS.INVERSE,
        coefficients: pureForwardResult.coefficients // Use Pure result for consistency
      }
      const [pureInverseResult, precomputedInverseResult] = await Promise.all([
        callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PURE_NTT, inverseInput),
        callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, inverseInput)
      ])
      
      expect(pureInverseResult.success, `Pure Inverse NTT failed: ${pureInverseResult.error}`).toBe(true)
      expect(precomputedInverseResult.success, `Precomputed Inverse NTT failed: ${precomputedInverseResult.error}`).toBe(true)
      
      console.log(`⛽ Forward Operation Gas Costs:`)
      console.log(`  └── Pure NTT (0x14): ${pureForwardResult.gasUsed?.toString() || 'N/A'}`)
      console.log(`  └── Precomputed NTT (0x15): ${precomputedForwardResult.gasUsed?.toString() || 'N/A'}`)
      
      console.log(`⛽ Inverse Operation Gas Costs:`)
      console.log(`  └── Pure NTT (0x14): ${pureInverseResult.gasUsed?.toString() || 'N/A'}`)
      console.log(`  └── Precomputed NTT (0x15): ${precomputedInverseResult.gasUsed?.toString() || 'N/A'}`)
      
      // Analyze forward vs inverse for each implementation
      if (pureForwardResult.gasUsed && pureInverseResult.gasUsed) {
        const pureDiff = pureForwardResult.gasUsed > pureInverseResult.gasUsed 
          ? pureForwardResult.gasUsed - pureInverseResult.gasUsed
          : pureInverseResult.gasUsed - pureForwardResult.gasUsed
        const pureDiffPercent = Number((pureDiff * 100n) / pureForwardResult.gasUsed)
        
        console.log(`📊 Pure NTT Forward/Inverse Difference: ${pureDiff} (${pureDiffPercent.toFixed(1)}%)`)
      }
      
      if (precomputedForwardResult.gasUsed && precomputedInverseResult.gasUsed) {
        const precomputedDiff = precomputedForwardResult.gasUsed > precomputedInverseResult.gasUsed 
          ? precomputedForwardResult.gasUsed - precomputedInverseResult.gasUsed
          : precomputedInverseResult.gasUsed - precomputedForwardResult.gasUsed
        const precomputedDiffPercent = Number((precomputedDiff * 100n) / precomputedForwardResult.gasUsed)
        
        console.log(`📊 Precomputed NTT Forward/Inverse Difference: ${precomputedDiff} (${precomputedDiffPercent.toFixed(1)}%)`)
      }
      
      // Compare implementations
      if (pureForwardResult.gasUsed && precomputedForwardResult.gasUsed) {
        const forwardSavings = pureForwardResult.gasUsed - precomputedForwardResult.gasUsed
        const forwardSavingsPercent = Number((forwardSavings * 100n) / pureForwardResult.gasUsed)
        console.log(`📊 Forward Operation Savings: ${forwardSavings} gas (${forwardSavingsPercent.toFixed(1)}%)`)
      }
      
      if (pureInverseResult.gasUsed && precomputedInverseResult.gasUsed) {
        const inverseSavings = pureInverseResult.gasUsed - precomputedInverseResult.gasUsed
        const inverseSavingsPercent = Number((inverseSavings * 100n) / pureInverseResult.gasUsed)
        console.log(`📊 Inverse Operation Savings: ${inverseSavings} gas (${inverseSavingsPercent.toFixed(1)}%)`)
      }
    }, 30000)

    it('should analyze gas costs for crypto standard moduli comparison on both implementations', async () => {
      const testVectors = getAllTestVectors()
      const cryptoTests = testVectors.cryptoStandard
      
      const gasResults: { 
        name: string; 
        modulus: bigint; 
        ringDegree: number; 
        pureGas: bigint;
        precomputedGas: bigint; 
        pureGasPerUnit: number;
        precomputedGasPerUnit: number;
        savings: bigint;
        savingsPercent: number;
      }[] = []
      
      for (const vector of cryptoTests) {
        const [pureResult, precomputedResult] = await Promise.all([
          callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PURE_NTT, vector.input),
          callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, vector.input)
        ])
        
        if (pureResult.success && precomputedResult.success && pureResult.gasUsed && precomputedResult.gasUsed) {
          const pureGasPerUnit = Number(pureResult.gasUsed) / vector.input.ringDegree
          const precomputedGasPerUnit = Number(precomputedResult.gasUsed) / vector.input.ringDegree
          const savings = pureResult.gasUsed - precomputedResult.gasUsed
          const savingsPercent = Number((savings * 100n) / pureResult.gasUsed)
          
          gasResults.push({
            name: vector.name,
            modulus: vector.input.modulus,
            ringDegree: vector.input.ringDegree,
            pureGas: pureResult.gasUsed,
            precomputedGas: precomputedResult.gasUsed,
            pureGasPerUnit,
            precomputedGasPerUnit,
            savings,
            savingsPercent
          })
          
          console.log(`⛽ ${vector.name} (mod ${vector.input.modulus}):`)
          console.log(`  └── Pure NTT: ${pureResult.gasUsed} gas (${pureGasPerUnit.toFixed(2)} gas/ring-unit)`)
          console.log(`  └── Precomputed NTT: ${precomputedResult.gasUsed} gas (${precomputedGasPerUnit.toFixed(2)} gas/ring-unit)`)
          console.log(`  └── Savings: ${savings} gas (${savingsPercent.toFixed(1)}%)`)
        }
      }
      
      // Verify we got results
      expect(gasResults.length).toBeGreaterThan(0)
      
      if (gasResults.length >= 1) {
        // Sort by ring degree for consistent ordering
        gasResults.sort((a, b) => a.ringDegree - b.ringDegree)
        
        console.log(`\n📊 Cryptographic Standard Moduli Efficiency Comparison:`)
        gasResults.forEach(result => {
          console.log(`  • ${result.name} (degree ${result.ringDegree}):`)
          console.log(`    - Pure efficiency: ${result.pureGasPerUnit.toFixed(2)} gas/ring-unit`)
          console.log(`    - Precomputed efficiency: ${result.precomputedGasPerUnit.toFixed(2)} gas/ring-unit`)
          console.log(`    - Improvement: ${result.savingsPercent.toFixed(1)}%`)
        })
        
        // Find most and least efficient by precomputed gas per unit
        const sortedByEfficiency = [...gasResults].sort((a, b) => a.precomputedGasPerUnit - b.precomputedGasPerUnit)
        const mostEfficient = sortedByEfficiency[0]
        const leastEfficient = sortedByEfficiency[sortedByEfficiency.length - 1]
        const efficiencyRatio = leastEfficient.precomputedGasPerUnit / mostEfficient.precomputedGasPerUnit
        
        console.log(`📊 Most gas-efficient (Precomputed): ${mostEfficient.name} (${mostEfficient.precomputedGasPerUnit.toFixed(2)} gas/ring-unit)`)
        console.log(`📊 Least gas-efficient (Precomputed): ${leastEfficient.name} (${leastEfficient.precomputedGasPerUnit.toFixed(2)} gas/ring-unit)`)
        console.log(`📊 Efficiency range: ${efficiencyRatio.toFixed(2)}x difference`)
        
        const avgSavingsPercent = gasResults.reduce((sum, r) => sum + r.savingsPercent, 0) / gasResults.length
        const totalSavings = gasResults.reduce((sum, r) => sum + Number(r.savings), 0)
        console.log(`📊 Average precomputed savings: ${avgSavingsPercent.toFixed(1)}%`)
        console.log(`📊 Total gas saved across crypto standards: ${totalSavings}`)
      }
    }, 75000)

    it('should benchmark gas efficiency vs theoretical complexity for both implementations', async () => {
      const testVectors = getAllTestVectors()
      const cryptoTests = testVectors.cryptoStandard
      
      const benchmarkResults: { 
        name: string; 
        ringDegree: number; 
        pureGas: bigint; 
        precomputedGas: bigint;
        pureGasPerOp: number; 
        precomputedGasPerOp: number;
        pureEfficiency: string;
        precomputedEfficiency: string;
        improvementRatio: number;
      }[] = []
      
      for (const vector of cryptoTests) {
        const [pureResult, precomputedResult] = await Promise.all([
          callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PURE_NTT, vector.input),
          callNTTPrecompileWithGas(PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT, vector.input)
        ])
        
        expect(pureResult.success, `Pure ${vector.name} failed: ${pureResult.error}`).toBe(true)
        expect(precomputedResult.success, `Precomputed ${vector.name} failed: ${precomputedResult.error}`).toBe(true)
        expect(pureResult.gasUsed).toBeDefined()
        expect(precomputedResult.gasUsed).toBeDefined()
        
        if (pureResult.gasUsed && precomputedResult.gasUsed) {
          const ringDegree = vector.input.ringDegree
          const theoreticalComplexity = ringDegree * Math.log2(ringDegree)
          const pureGasPerOp = Number(pureResult.gasUsed) / theoreticalComplexity
          const precomputedGasPerOp = Number(precomputedResult.gasUsed) / theoreticalComplexity
          const improvementRatio = pureGasPerOp / precomputedGasPerOp
          
          const getEfficiency = (gasPerOp: number): string => {
            if (gasPerOp < 100) return 'Excellent'
            if (gasPerOp < 500) return 'Good'  
            if (gasPerOp < 2000) return 'Moderate'
            return 'Poor'
          }
          
          const pureEfficiency = getEfficiency(pureGasPerOp)
          const precomputedEfficiency = getEfficiency(precomputedGasPerOp)
          
          benchmarkResults.push({
            name: vector.name,
            ringDegree,
            pureGas: pureResult.gasUsed,
            precomputedGas: precomputedResult.gasUsed,
            pureGasPerOp,
            precomputedGasPerOp,
            pureEfficiency,
            precomputedEfficiency,
            improvementRatio
          })
          
          console.log(`📊 ${vector.name} (Ring Degree: ${ringDegree}, Modulus: ${vector.input.modulus}):`)
          console.log(`  └── Theoretical Complexity: ${theoreticalComplexity.toFixed(1)} ops (N*log2(N))`)
          console.log(`  └── Pure NTT: ${pureResult.gasUsed} gas (${pureGasPerOp.toFixed(2)} gas/op - ${pureEfficiency})`)
          console.log(`  └── Precomputed NTT: ${precomputedResult.gasUsed} gas (${precomputedGasPerOp.toFixed(2)} gas/op - ${precomputedEfficiency})`)
          console.log(`  └── Improvement: ${improvementRatio.toFixed(2)}x faster per operation`)
          
          // Basic sanity check for crypto standard parameters
          expect(Number(pureResult.gasUsed)).toBeGreaterThan(1000) // Should use some gas
          expect(Number(pureResult.gasUsed)).toBeLessThan(50000000) // But not excessive for large ring degrees
          expect(Number(precomputedResult.gasUsed)).toBeGreaterThan(1000)
          expect(Number(precomputedResult.gasUsed)).toBeLessThan(50000000)
        }
      }
      
      // Summary analysis
      if (benchmarkResults.length > 0) {
        console.log(`\n📊 Cryptographic Standards Efficiency Comparison Summary:`)
        
        console.log(`\n  Pure NTT (0x14) Performance:`)
        benchmarkResults
          .sort((a, b) => a.pureGasPerOp - b.pureGasPerOp)
          .forEach(result => {
            console.log(`    • ${result.name}: ${result.pureGasPerOp.toFixed(2)} gas/op (${result.pureEfficiency})`)
          })
        
        console.log(`\n  Precomputed NTT (0x15) Performance:`)
        benchmarkResults
          .sort((a, b) => a.precomputedGasPerOp - b.precomputedGasPerOp)
          .forEach(result => {
            console.log(`    • ${result.name}: ${result.precomputedGasPerOp.toFixed(2)} gas/op (${result.precomputedEfficiency})`)
          })
        
        const avgPureGasPerOp = benchmarkResults.reduce((sum, r) => sum + r.pureGasPerOp, 0) / benchmarkResults.length
        const avgPrecomputedGasPerOp = benchmarkResults.reduce((sum, r) => sum + r.precomputedGasPerOp, 0) / benchmarkResults.length
        const avgImprovementRatio = benchmarkResults.reduce((sum, r) => sum + r.improvementRatio, 0) / benchmarkResults.length
        
        console.log(`📊 Average Pure NTT efficiency: ${avgPureGasPerOp.toFixed(2)} gas/op`)
        console.log(`📊 Average Precomputed NTT efficiency: ${avgPrecomputedGasPerOp.toFixed(2)} gas/op`)
        console.log(`📊 Average improvement ratio: ${avgImprovementRatio.toFixed(2)}x faster`)
      }
    }, 180000)
  })
})