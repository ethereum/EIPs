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
 * Calls Pure NTT precompile specifically
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

describe('Pure NTT Precompile (0x12)', () => {
  describe('Basic Forward NTT', () => {
    it('should compute forward NTT with modulus 97', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const result = await callPureNTT(input)
      
      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true)
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
      
      const result = await callPureNTT(input)
      
      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true)
      expect(result.coefficients).toHaveLength(16)
      
      // All output coefficients should be less than modulus
      result.coefficients.forEach((coeff, i) => {
        expect(coeff, `Coefficient ${i} should be < modulus`).toBeLessThan(193n)
        expect(coeff, `Coefficient ${i} should be >= 0`).toBeGreaterThanOrEqual(0n)
      })
      
      console.log(`Modulus 193 output: ${formatCoefficients(result.coefficients)}`)
    }, 10000)
    
    it('should compute forward NTT with modulus 257', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 257n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const result = await callPureNTT(input)
      
      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true)
      expect(result.coefficients).toHaveLength(16)
      
      console.log(`Modulus 257 output: ${formatCoefficients(result.coefficients)}`)
    }, 10000)
  })

  describe('Ring Degree Variations', () => {
    it('should handle ring degree 32', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 32,
        modulus: 193n, // 193 ≡ 1 (mod 64)
        coefficients: generateSequentialCoefficients(32)
      }
      
      const result = await callPureNTT(input)
      
      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true)
      expect(result.coefficients).toHaveLength(32)
      
      console.log(`Ring degree 32: First 8 coefficients = ${formatCoefficients(result.coefficients.slice(0, 8))}`)
    }, 15000)
    
    it('should handle ring degree 64', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 64,
        modulus: 257n, // 257 ≡ 1 (mod 128)
        coefficients: generateSequentialCoefficients(64)
      }
      
      const result = await callPureNTT(input)
      
      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true)
      expect(result.coefficients).toHaveLength(64)
      
      console.log(`Ring degree 64: First 8 coefficients = ${formatCoefficients(result.coefficients.slice(0, 8))}`)
    }, 20000)
  })

  describe('Inverse NTT', () => {
    it('should compute inverse NTT', async () => {
      // First compute forward NTT
      const forwardInput: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const forwardResult = await callPureNTT(forwardInput)
      expect(forwardResult.success).toBe(true)
      
      // Then compute inverse NTT
      const inverseInput: NTTInput = {
        operation: NTT_OPERATIONS.INVERSE,
        ringDegree: 16,
        modulus: 97n,
        coefficients: forwardResult.coefficients
      }
      
      const inverseResult = await callPureNTT(inverseInput)
      expect(inverseResult.success, `Inverse NTT failed: ${inverseResult.error}`).toBe(true)
      
      console.log(`Original: ${formatCoefficients(forwardInput.coefficients)}`)
      console.log(`Forward:  ${formatCoefficients(forwardResult.coefficients)}`)
      console.log(`Inverse:  ${formatCoefficients(inverseResult.coefficients)}`)
      
      // Should recover original coefficients
      expect(compareCoefficients(forwardInput.coefficients, inverseResult.coefficients)).toBe(true)
    }, 15000)
    
    it('should handle round-trip for different moduli', async () => {
      const moduli = [97n, 193n, 257n]
      
      for (const modulus of moduli) {
        const originalCoeffs = generateSequentialCoefficients(16)
        
        // Forward
        const forwardResult = await callPureNTT({
          operation: NTT_OPERATIONS.FORWARD,
          ringDegree: 16,
          modulus,
          coefficients: originalCoeffs
        })
        
        expect(forwardResult.success, `Forward failed for modulus ${modulus}`).toBe(true)
        
        // Inverse
        const inverseResult = await callPureNTT({
          operation: NTT_OPERATIONS.INVERSE,
          ringDegree: 16,
          modulus,
          coefficients: forwardResult.coefficients
        })
        
        expect(inverseResult.success, `Inverse failed for modulus ${modulus}`).toBe(true)
        expect(compareCoefficients(originalCoeffs, inverseResult.coefficients), 
               `Round-trip failed for modulus ${modulus}`).toBe(true)
        
        console.log(`✅ Round-trip passed for modulus ${modulus}`)
      }
    }, 25000)
  })

  describe('Edge Cases and Boundary Conditions', () => {
    it('should handle zero coefficients', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: Array(16).fill(0n)
      }
      
      const result = await callPureNTT(input)
      
      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true)
      
      console.log(`Zero input result: ${formatCoefficients(result.coefficients)}`)
    }, 10000)
    
    it('should handle maximum valid coefficients', async () => {
      const modulus = 97n
      const maxCoeff = modulus - 1n // 96
      
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus,
        coefficients: Array(16).fill(maxCoeff)
      }
      
      const result = await callPureNTT(input)
      
      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true)
      
      console.log(`Max coefficient input result: ${formatCoefficients(result.coefficients)}`)
    }, 10000)
    
    it('should handle mixed coefficient values', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: [0n, 1n, 96n, 50n, 25n, 75n, 10n, 87n, 
                      33n, 64n, 15n, 82n, 5n, 92n, 40n, 57n]
      }
      
      const result = await callPureNTT(input)
      
      expect(result.success, `Pure NTT failed: ${result.error}`).toBe(true)
      
      console.log(`Mixed input:  ${formatCoefficients(input.coefficients)}`)
      console.log(`Mixed output: ${formatCoefficients(result.coefficients)}`)
    }, 10000)
  })

  describe('Performance Tests', () => {
    it('should handle repeated operations efficiently', async () => {
      const input: NTTInput = {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: generateSequentialCoefficients(16)
      }
      
      const startTime = Date.now()
      const numOperations = 10
      
      const promises = Array(numOperations).fill(null).map(() => callPureNTT(input))
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
      
      console.log(`✅ ${numOperations} operations completed in ${totalTime}ms (avg: ${avgTime.toFixed(2)}ms)`)
      
      // Performance should be reasonable (< 2s per operation on average)
      expect(avgTime, 'Average operation time should be reasonable').toBeLessThan(2000)
    }, 30000)
  })
})