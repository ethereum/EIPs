import { describe, it, expect } from 'vitest'
import { publicClient, PRECOMPILE_ADDRESSES, NTT_OPERATIONS } from '../config/rpc-config.js'
import {
  createNTTInput,
  parseNTTOutput,
  generateSequentialCoefficients,
  compareCoefficients,
  formatCoefficients,
  type NTTInput,
  type NTTResult
} from '../utils/ntt-utils.js'

/**
 * Calls Precomputed NTT precompile specifically
 */
async function callPrecomputedNTT(input: NTTInput): Promise<NTTResult> {
  try {
    const inputData = createNTTInput(input)
    
    const result = await publicClient.call({
      to: PRECOMPILE_ADDRESSES.PRECOMPUTED_NTT,
      data: inputData
    })
    
    if (!result.data || result.data === '0x') {
      return {
        success: false,
        output: null,
        coefficients: [],
        error: 'Empty response from Precomputed NTT precompile'
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
 * Calls Pure NTT for comparison
 */
async function callPureNTT(input: NTTInput): Promise<NTTResult> {
  try {
    const inputData = createNTTInput(input)
    
    const result = await publicClient.call({
      to: PRECOMPILE_ADDRESSES.PURE_NTT,
      data: inputData
    })
    
    if (!result.data || result.data === '0x') {
      return {
        success: false,
        output: null,
        coefficients: [],
        error: 'Empty response from Pure NTT precompile'
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

describe('Precomputed NTT Precompile (0x15)', () => {
  describe('Basic Forward NTT', () => {
    it('should compute forward NTT with modulus 97', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const result = await callPrecomputedNTT(input)
      
      expect(result.success, `Precomputed NTT failed: ${result.error}`).toBe(true)
      expect(result.coefficients).toHaveLength(16)
      
      // Verify transformation occurred (output should be different from input)
      const inputChanged = !compareCoefficients(input.coefficients, result.coefficients)
      expect(inputChanged, 'NTT should transform coefficients').toBe(true)
      
      console.log(`Input:  ${formatCoefficients(input.coefficients)}`)
      console.log(`Output: ${formatCoefficients(result.coefficients)}`)
    }, 10000)
    
    it('should compute forward NTT with modulus 193', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 193n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const result = await callPrecomputedNTT(input)
      
      expect(result.success, `Precomputed NTT failed: ${result.error}`).toBe(true)
      expect(result.coefficients).toHaveLength(16)
      
      // All output coefficients should be less than modulus
      result.coefficients.forEach((coeff, i) => {
        expect(coeff, `Coefficient ${i} should be < modulus`).toBeLessThan(193n)
        expect(coeff, `Coefficient ${i} should be >= 0`).toBeGreaterThanOrEqual(0n)
      })
      
      console.log(`Modulus 193 output: ${formatCoefficients(result.coefficients)}`)
    }, 10000)
  })

  describe('Consistency with Pure NTT', () => {
    it('should produce identical results to Pure NTT with modulus 97', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const [pureResult, precomputedResult] = await Promise.all([
        callPureNTT(input),
        callPrecomputedNTT(input)
      ])
      
      expect(pureResult.success, `Pure NTT failed: ${pureResult.error}`).toBe(true)
      expect(precomputedResult.success, `Precomputed NTT failed: ${precomputedResult.error}`).toBe(true)
      
      expect(compareCoefficients(pureResult.coefficients, precomputedResult.coefficients),
             'Pure and Precomputed NTT should produce identical results').toBe(true)
      
      console.log(`✅ Both implementations produce: ${formatCoefficients(pureResult.coefficients)}`)
    }, 15000)
    
    it('should produce identical results to Pure NTT with different moduli', async () => {
      const moduli = [97n, 193n, 257n]
      
      for (const modulus of moduli) {
        const input: NTTInput = {
          operation: NTT_OPERATIONS.FORWARD,
          ringDegree: 16,
          modulus,
          coefficients: generateSequentialCoefficients(16)
        }
        
        const [pureResult, precomputedResult] = await Promise.all([
          callPureNTT(input),
          callPrecomputedNTT(input)
        ])
        
        expect(pureResult.success, `Pure NTT failed for modulus ${modulus}`).toBe(true)
        expect(precomputedResult.success, `Precomputed NTT failed for modulus ${modulus}`).toBe(true)
        
        expect(compareCoefficients(pureResult.coefficients, precomputedResult.coefficients),
               `Results should be identical for modulus ${modulus}`).toBe(true)
        
        console.log(`✅ Modulus ${modulus}: Identical results`)
      }
    }, 25000)
    
    it('should produce identical results for different ring degrees', async () => {
      const testCases = [
        { ringDegree: 16, modulus: 97n },
        { ringDegree: 32, modulus: 193n },
        { ringDegree: 64, modulus: 257n },
      ]
      
      for (const { ringDegree, modulus } of testCases) {
        const input: NTTInput = {
          operation: NTT_OPERATIONS.FORWARD,
          ringDegree,
          modulus,
          coefficients: generateSequentialCoefficients(ringDegree)
        }
        
        const [pureResult, precomputedResult] = await Promise.all([
          callPureNTT(input),
          callPrecomputedNTT(input)
        ])
        
        expect(pureResult.success, `Pure NTT failed for degree ${ringDegree}`).toBe(true)
        expect(precomputedResult.success, `Precomputed NTT failed for degree ${ringDegree}`).toBe(true)
        
        expect(compareCoefficients(pureResult.coefficients, precomputedResult.coefficients),
               `Results should be identical for degree ${ringDegree}`).toBe(true)
        
        console.log(`✅ Ring degree ${ringDegree}: Identical results`)
      }
    }, 30000)
  })

  describe('Inverse NTT', () => {
    it('should compute inverse NTT identically to Pure NTT', async () => {
      // First compute forward NTT
      const forwardInput: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const [pureForward, precomputedForward] = await Promise.all([
        callPureNTT(forwardInput),
        callPrecomputedNTT(forwardInput)
      ])
      
      expect(pureForward.success).toBe(true)
      expect(precomputedForward.success).toBe(true)
      expect(compareCoefficients(pureForward.coefficients, precomputedForward.coefficients)).toBe(true)
      
      // Then compute inverse NTT
      const inverseInput: NTTInput = {
        operation: NTT_OPERATIONS.INVERSE,
        ringDegree: 16,
        modulus: 97n,
        coefficients: pureForward.coefficients
      }
      
      const [pureInverse, precomputedInverse] = await Promise.all([
        callPureNTT(inverseInput),
        callPrecomputedNTT(inverseInput)
      ])
      
      expect(pureInverse.success, `Pure inverse failed: ${pureInverse.error}`).toBe(true)
      expect(precomputedInverse.success, `Precomputed inverse failed: ${precomputedInverse.error}`).toBe(true)
      
      // Both should recover original coefficients
      expect(compareCoefficients(forwardInput.coefficients, pureInverse.coefficients)).toBe(true)
      expect(compareCoefficients(forwardInput.coefficients, precomputedInverse.coefficients)).toBe(true)
      
      // And produce identical results
      expect(compareCoefficients(pureInverse.coefficients, precomputedInverse.coefficients)).toBe(true)
      
      console.log(`✅ Both implementations correctly computed inverse NTT`)
    }, 20000)
  })

  describe('Performance Comparison', () => {
    it('should compare performance with Pure NTT', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const numOperations = 5
      
      // Test Pure NTT performance
      const pureStartTime = Date.now()
      const purePromises = Array(numOperations).fill(null).map(() => callPureNTT(input))
      const pureResults = await Promise.all(purePromises)
      const pureEndTime = Date.now()
      const pureTime = pureEndTime - pureStartTime
      
      // Test Precomputed NTT performance
      const precomputedStartTime = Date.now()
      const precomputedPromises = Array(numOperations).fill(null).map(() => callPrecomputedNTT(input))
      const precomputedResults = await Promise.all(precomputedPromises)
      const precomputedEndTime = Date.now()
      const precomputedTime = precomputedEndTime - precomputedStartTime
      
      // All operations should succeed
      pureResults.forEach((result, i) => {
        expect(result.success, `Pure operation ${i} failed: ${result.error}`).toBe(true)
      })
      
      precomputedResults.forEach((result, i) => {
        expect(result.success, `Precomputed operation ${i} failed: ${result.error}`).toBe(true)
      })
      
      // Results should be consistent across calls
      const firstPureResult = pureResults[0].coefficients
      const firstPrecomputedResult = precomputedResults[0].coefficients
      
      expect(compareCoefficients(firstPureResult, firstPrecomputedResult)).toBe(true)
      
      console.log(`Performance comparison (${numOperations} operations):`)
      console.log(`  Pure NTT:       ${pureTime}ms (avg: ${(pureTime / numOperations).toFixed(2)}ms)`)
      console.log(`  Precomputed NTT: ${precomputedTime}ms (avg: ${(precomputedTime / numOperations).toFixed(2)}ms)`)
      
      if (precomputedTime < pureTime) {
        console.log(`  ✅ Precomputed NTT is ${((pureTime / precomputedTime - 1) * 100).toFixed(1)}% faster`)
      } else if (pureTime < precomputedTime) {
        console.log(`  ✅ Pure NTT is ${((precomputedTime / pureTime - 1) * 100).toFixed(1)}% faster`)
      } else {
        console.log(`  ✅ Both implementations have similar performance`)
      }
    }, 20000)
    
    it('should handle concurrent operations efficiently', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const startTime = Date.now()
      const numOperations = 10
      
      // Run multiple concurrent operations
      const promises = Array(numOperations).fill(null).map(() => callPrecomputedNTT(input))
      const results = await Promise.all(promises)
      
      const endTime = Date.now()
      const totalTime = endTime - startTime
      const avgTime = totalTime / numOperations
      
      // All operations should succeed
      results.forEach((result, i) => {
        expect(result.success, `Operation ${i} failed: ${result.error}`).toBe(true)
      })
      
      // All results should be identical
      const firstResult = results[0].coefficients
      results.forEach((result, i) => {
        expect(compareCoefficients(result.coefficients, firstResult), 
               `Operation ${i} produced different result`).toBe(true)
      })
      
      console.log(`✅ ${numOperations} concurrent operations completed in ${totalTime}ms (avg: ${avgTime.toFixed(2)}ms)`)
      
      // Performance should be reasonable
      expect(avgTime, 'Average operation time should be reasonable').toBeLessThan(2000)
    }, 25000)
  })

  describe('Edge Cases', () => {
    it('should handle edge cases identically to Pure NTT', async () => {
      const testCases = [
        {
          name: 'Zero coefficients',
          coefficients: Array(16).fill(0n)
        },
        {
          name: 'Maximum coefficients',
          coefficients: Array(16).fill(96n) // modulus - 1
        },
        {
          name: 'Single non-zero coefficient',
          coefficients: [1n, ...Array(15).fill(0n)]
        }
      ]
      
      for (const testCase of testCases) {
        const input: NTTInput = {
          operation: NTT_OPERATIONS.FORWARD,
          ringDegree: 16,
          modulus: 97n,
          coefficients: testCase.coefficients
        }
        
        const [pureResult, precomputedResult] = await Promise.all([
          callPureNTT(input),
          callPrecomputedNTT(input)
        ])
        
        expect(pureResult.success, `Pure NTT failed for ${testCase.name}`).toBe(true)
        expect(precomputedResult.success, `Precomputed NTT failed for ${testCase.name}`).toBe(true)
        
        expect(compareCoefficients(pureResult.coefficients, precomputedResult.coefficients),
               `Results should be identical for ${testCase.name}`).toBe(true)
        
        console.log(`✅ ${testCase.name}: Identical results`)
      }
    }, 15000)
  })
})