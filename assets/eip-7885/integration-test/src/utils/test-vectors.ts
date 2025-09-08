import { type NTTInput, generateSequentialCoefficients, generateRandomCoefficients } from './ntt-utils.js'
import { NTT_OPERATIONS, NTT_FRIENDLY_MODULI, CRYPTO_STANDARDS } from '../config/rpc-config.js'

/**
 * Test vector with expected results
 */
export interface TestVector {
  name: string
  description: string
  input: NTTInput
  expectedOutput?: bigint[]
  shouldFail?: boolean
  errorPattern?: RegExp
}

/**
 * Known working test vectors based on verified cast call results
 */
export const KNOWN_TEST_VECTORS: TestVector[] = [
  {
    name: 'Go Compatibility - Sequential coefficients',
    description: 'Test vector matching Go test patterns with modulus 97 and sequential coefficients',
    input: {
      operation: NTT_OPERATIONS.FORWARD,
      ringDegree: 16,
      modulus: 97n,
      coefficients: generateSequentialCoefficients(16)
    },
    expectedOutput: [8n, 60n, 32n, 51n, 20n, 67n, 67n, 36n, 49n, 27n, 72n, 13n, 55n, 96n, 8n, 18n]
  },
  {
    name: 'Modulus 193 - Ring degree 16',
    description: 'Test with larger NTT-friendly prime modulus 193',
    input: {
      operation: NTT_OPERATIONS.FORWARD,
      ringDegree: 16,
      modulus: 193n,
      coefficients: generateSequentialCoefficients(16)
    }
  },
  {
    name: 'Modulus 257 - Ring degree 16',
    description: 'Test with NTT-friendly prime modulus 257',
    input: {
      operation: NTT_OPERATIONS.FORWARD,
      ringDegree: 16,
      modulus: 257n,
      coefficients: generateSequentialCoefficients(16)
    }
  }
]

/**
 * Generate test vectors for different ring degrees and moduli
 */
export function generateBasicTestVectors(): TestVector[] {
  const vectors: TestVector[] = []
  
  // Test different ring degrees with their corresponding moduli
  const testCases = [
    { ringDegree: 16, moduli: NTT_FRIENDLY_MODULI.DEGREE_16.slice(0, 3) },
    { ringDegree: 32, moduli: NTT_FRIENDLY_MODULI.DEGREE_32.slice(0, 2) },
    { ringDegree: 64, moduli: NTT_FRIENDLY_MODULI.DEGREE_64.slice(0, 2) },
  ]
  
  for (const { ringDegree, moduli } of testCases) {
    for (const modulus of moduli) {
      vectors.push({
        name: `Basic Forward NTT - Degree ${ringDegree}, Modulus ${modulus}`,
        description: `Forward NTT with ring degree ${ringDegree} and modulus ${modulus}`,
        input: {
          operation: NTT_OPERATIONS.FORWARD,
          ringDegree,
          modulus,
          coefficients: generateSequentialCoefficients(ringDegree)
        }
      })
    }
  }
  
  return vectors
}

/**
 * Generate round-trip test vectors (forward -> inverse should return original)
 */
export function generateRoundTripTestVectors(): TestVector[] {
  const vectors: TestVector[] = []
  
  const testCases = [
    { ringDegree: 16, modulus: 97n },
    { ringDegree: 16, modulus: 193n },
    { ringDegree: 32, modulus: 193n },
    { ringDegree: 64, modulus: 257n },
  ]
  
  for (const { ringDegree, modulus } of testCases) {
    vectors.push({
      name: `Round-trip test - Degree ${ringDegree}, Modulus ${modulus}`,
      description: `Test that forward->inverse NTT returns original coefficients`,
      input: {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree,
        modulus,
        coefficients: generateSequentialCoefficients(ringDegree)
      }
    })
  }
  
  return vectors
}

/**
 * Generate cryptographic standard test vectors
 */
export function generateCryptoStandardTestVectors(): TestVector[] {
  const vectors: TestVector[] = []
  
  for (const [name, params] of Object.entries(CRYPTO_STANDARDS)) {
    vectors.push({
      name: `${name} Parameters`,
      description: `NTT test with ${name} cryptographic standard parameters`,
      input: {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: params.ringDegree,
        modulus: params.modulus,
        coefficients: generateSequentialCoefficients(params.ringDegree)
      }
    })
  }
  
  return vectors
}

/**
 * Generate error case test vectors (should fail)
 */
export function generateErrorTestVectors(): TestVector[] {
  return [
    {
      name: 'Invalid Ring Degree - Not power of 2',
      description: 'Should fail with ring degree that is not a power of 2',
      input: {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 15, // Not power of 2
        modulus: 97n,
        coefficients: Array(15).fill(0n).map((_, i) => BigInt(i))
      },
      shouldFail: true,
      errorPattern: /Invalid ring degree/
    },
    {
      name: 'Invalid Ring Degree - Too small',
      description: 'Should fail with ring degree < 16',
      input: {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 8, // Too small
        modulus: 97n,
        coefficients: Array(8).fill(0n).map((_, i) => BigInt(i))
      },
      shouldFail: true,
      errorPattern: /Invalid ring degree/
    },
    {
      name: 'Non-prime Modulus',
      description: 'Should fail with composite modulus',
      input: {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 513n, // 513 = 3^3 × 19, not prime
        coefficients: generateSequentialCoefficients(16)
      },
      shouldFail: true,
      errorPattern: /not prime/
    },
    {
      name: 'Non-NTT-friendly Modulus',
      description: 'Should fail with prime modulus that is not NTT-friendly',
      input: {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 101n, // Prime but 101 % 32 = 5 ≠ 1
        coefficients: generateSequentialCoefficients(16)
      },
      shouldFail: true,
      errorPattern: /not NTT-friendly/
    },
    {
      name: 'Coefficient exceeds modulus',
      description: 'Should fail when coefficient >= modulus',
      input: {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: [98n, ...generateSequentialCoefficients(15)] // 98 >= 97
      },
      shouldFail: true,
      errorPattern: /less than modulus/
    },
    {
      name: 'Wrong coefficient count',
      description: 'Should fail when coefficient count != ring degree',
      input: {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: 16,
        modulus: 97n,
        coefficients: generateSequentialCoefficients(8) // Only 8 coefficients
      },
      shouldFail: true,
      errorPattern: /Expected 16 coefficients/
    }
  ]
}

/**
 * Generate random test vectors for stress testing
 */
export function generateRandomTestVectors(count: number = 5): TestVector[] {
  const vectors: TestVector[] = []
  
  const testCases = [
    { ringDegree: 16, moduli: [97n, 193n, 257n] },
    { ringDegree: 32, moduli: [193n, 257n] },
    { ringDegree: 64, moduli: [257n, 769n] },
  ]
  
  for (let i = 0; i < count; i++) {
    const testCase = testCases[i % testCases.length]
    const modulus = testCase.moduli[i % testCase.moduli.length]
    
    vectors.push({
      name: `Random coefficients ${i + 1} - Degree ${testCase.ringDegree}`,
      description: `Random coefficient test with degree ${testCase.ringDegree} and modulus ${modulus}`,
      input: {
        operation: NTT_OPERATIONS.FORWARD,
        ringDegree: testCase.ringDegree,
        modulus,
        coefficients: generateRandomCoefficients(testCase.ringDegree, modulus)
      }
    })
  }
  
  return vectors
}

/**
 * Get all test vectors
 */
export function getAllTestVectors(): {
  known: TestVector[]
  basic: TestVector[]
  roundTrip: TestVector[]
  cryptoStandard: TestVector[]
  errors: TestVector[]
  random: TestVector[]
} {
  return {
    known: KNOWN_TEST_VECTORS,
    basic: generateBasicTestVectors(),
    roundTrip: generateRoundTripTestVectors(),
    cryptoStandard: generateCryptoStandardTestVectors(),
    errors: generateErrorTestVectors(),
    random: generateRandomTestVectors()
  }
}