import { createPublicClient, http } from 'viem'

/**
 * RPC configuration for NTT precompile testing
 * Uses the remote node that has NTT precompiles deployed
 */
export const RPC_URL = process.env.RPC_URL || 'http://34.29.49.47:8545'

/**
 * Create a public client for interacting with the precompile-enabled node
 */
export const publicClient = createPublicClient({
  transport: http(RPC_URL, {
    timeout: 30000, // 30s timeout for precompile operations
    retryCount: 3,
    retryDelay: 1000,
  })
})

/**
 * Precompile addresses as defined in EIP-7885 (Pure NTT only)
 */
export const PRECOMPILE_ADDRESSES = {
  PURE_NTT: '0x0000000000000000000000000000000000000012' as const,
} as const

/**
 * NTT operation types
 */
export const NTT_OPERATIONS = {
  FORWARD: 0x00,
  INVERSE: 0x01,
} as const

/**
 * Common NTT-friendly moduli for testing
 * These are prime numbers that satisfy: modulus ≡ 1 (mod 2*ringDegree)
 */
export const NTT_FRIENDLY_MODULI = {
  // For ring degree 16: modulus ≡ 1 (mod 32)
  DEGREE_16: [97n, 193n, 257n, 353n, 449n, 577n, 641n, 769n],
  // For ring degree 32: modulus ≡ 1 (mod 64)  
  DEGREE_32: [193n, 257n, 449n, 577n, 641n, 769n, 1153n, 1217n],
  // For ring degree 64: modulus ≡ 1 (mod 128)
  DEGREE_64: [257n, 769n, 1153n, 1409n, 1537n, 2689n, 2817n, 3329n],
} as const

/**
 * Cryptographic standard parameters for testing
 */
export const CRYPTO_STANDARDS = {
  FALCON_512: {
    ringDegree: 512,
    modulus: 12289n, // Falcon parameters: q = 12289, degree 512
  },
  DILITHIUM_256: {
    ringDegree: 256,
    modulus: 8380417n, // Dilithium parameters: q = 8380417, degree 256
  },
  KYBER_128: {
    ringDegree: 128,
    modulus: 3329n, // Kyber parameters: q = 3329, degree 128 (2^7 = 128)
  },
} as const