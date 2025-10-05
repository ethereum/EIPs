import { type Hex, concat, toHex, fromHex } from 'viem'
import { NTT_OPERATIONS } from '../config/rpc-config.js'

/**
 * NTT operation type
 */
export type NTTOperation = (typeof NTT_OPERATIONS)[keyof typeof NTT_OPERATIONS]

/**
 * NTT input parameters
 */
export interface NTTInput {
  operation: NTTOperation
  ringDegree: number
  modulus: bigint
  coefficients: bigint[]
}

/**
 * NTT test result
 */
export interface NTTResult {
  success: boolean
  output: Hex | null
  coefficients: bigint[]
  error?: string
}

/**
 * Validates that a number is prime
 */
export function isPrime(n: bigint): boolean {
  if (n < 2n) return false
  if (n === 2n) return true
  if (n % 2n === 0n) return false
  
  for (let i = 3n; i * i <= n; i += 2n) {
    if (n % i === 0n) return false
  }
  return true
}

/**
 * Validates that a modulus is NTT-friendly for a given ring degree
 * Checks: modulus ≡ 1 (mod 2*ringDegree)
 */
export function isNTTFriendly(modulus: bigint, ringDegree: number): boolean {
  return modulus % (2n * BigInt(ringDegree)) === 1n
}

/**
 * Validates ring degree is a power of 2 and >= 16
 */
export function isValidRingDegree(ringDegree: number): boolean {
  return ringDegree >= 16 && (ringDegree & (ringDegree - 1)) === 0
}

/**
 * Validates all coefficients are less than modulus
 */
export function validateCoefficients(coefficients: bigint[], modulus: bigint): boolean {
  return coefficients.every(coeff => coeff < modulus && coeff >= 0n)
}

/**
 * Creates NTT input data in the format expected by precompiles
 * Format: operation(1) + ring_degree(4) + modulus(8) + coefficients(ring_degree*8)
 */
export function createNTTInput({ operation, ringDegree, modulus, coefficients }: NTTInput): Hex {
  // Validate inputs
  if (!isValidRingDegree(ringDegree)) {
    throw new Error(`Invalid ring degree: ${ringDegree}. Must be power of 2 and >= 16`)
  }
  
  if (!isPrime(modulus)) {
    throw new Error(`Modulus ${modulus} is not prime`)
  }
  
  if (!isNTTFriendly(modulus, ringDegree)) {
    throw new Error(`Modulus ${modulus} is not NTT-friendly for ring degree ${ringDegree}. Must satisfy: modulus ≡ 1 (mod ${2 * ringDegree})`)
  }
  
  if (coefficients.length !== ringDegree) {
    throw new Error(`Expected ${ringDegree} coefficients, got ${coefficients.length}`)
  }
  
  if (!validateCoefficients(coefficients, modulus)) {
    throw new Error('All coefficients must be non-negative and less than modulus')
  }
  
  // Pack input data
  const parts: Hex[] = []
  
  // Operation (1 byte)
  parts.push(toHex(operation, { size: 1 }))
  
  // Ring degree (4 bytes, big endian)
  parts.push(toHex(ringDegree, { size: 4 }))
  
  // Modulus (8 bytes, big endian)
  parts.push(toHex(modulus, { size: 8 }))
  
  // Coefficients (ring_degree * 8 bytes each, big endian)
  for (const coeff of coefficients) {
    parts.push(toHex(coeff, { size: 8 }))
  }
  
  return concat(parts)
}

/**
 * Parses NTT output data into coefficients array
 * Output format: ring_degree * 8 bytes (each coefficient as 8-byte big endian)
 */
export function parseNTTOutput(output: Hex, ringDegree: number): bigint[] {
  if (output === '0x') {
    throw new Error('Empty output from precompile')
  }
  
  const expectedLength = ringDegree * 8 * 2 + 2 // *2 for hex chars, +2 for '0x'
  if (output.length !== expectedLength) {
    throw new Error(`Expected output length ${expectedLength}, got ${output.length}`)
  }
  
  const coefficients: bigint[] = []
  const bytes = fromHex(output, 'bytes')
  
  for (let i = 0; i < ringDegree; i++) {
    const start = i * 8
    const end = start + 8
    const coeffBytes = bytes.slice(start, end)
    
    // Convert 8 bytes to big endian bigint
    let value = 0n
    for (let j = 0; j < 8; j++) {
      value = (value << 8n) + BigInt(coeffBytes[j])
    }
    
    coefficients.push(value)
  }
  
  return coefficients
}

/**
 * Generates sequential coefficients for testing (0, 1, 2, ..., n-1)
 */
export function generateSequentialCoefficients(ringDegree: number): bigint[] {
  return Array.from({ length: ringDegree }, (_, i) => BigInt(i))
}

/**
 * Generates random coefficients less than modulus
 */
export function generateRandomCoefficients(ringDegree: number, modulus: bigint): bigint[] {
  const coefficients: bigint[] = []
  
  for (let i = 0; i < ringDegree; i++) {
    // Generate random coefficient in range [0, modulus)
    const randomBytes = crypto.getRandomValues(new Uint8Array(8))
    let value = 0n
    for (let j = 0; j < 8; j++) {
      value = (value << 8n) + BigInt(randomBytes[j])
    }
    coefficients.push(value % modulus)
  }
  
  return coefficients
}

/**
 * Compares two coefficient arrays for equality
 */
export function compareCoefficients(a: bigint[], b: bigint[]): boolean {
  if (a.length !== b.length) return false
  return a.every((coeff, i) => coeff === b[i])
}

/**
 * Formats coefficients for readable output
 */
export function formatCoefficients(coefficients: bigint[]): string {
  return `[${coefficients.join(', ')}]`
}

/**
 * Gets the expected output for the known test case
 * Input: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15] with modulus 97, ring degree 16
 * Output: [8,60,32,51,20,67,67,36,49,27,72,13,55,96,8,18]
 */
export function getKnownTestVector(): { input: NTTInput; expectedOutput: bigint[] } {
  return {
    input: {
      operation: NTT_OPERATIONS.FORWARD,
      ringDegree: 16,
      modulus: 97n,
      coefficients: generateSequentialCoefficients(16)
    },
    expectedOutput: [8n, 60n, 32n, 51n, 20n, 67n, 67n, 36n, 49n, 27n, 72n, 13n, 55n, 96n, 8n, 18n]
  }
}