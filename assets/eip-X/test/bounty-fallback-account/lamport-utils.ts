import { randomBytes } from 'crypto'
import { arrayify } from 'ethers/lib/utils'
import { keccak256 as keccak256_buffer } from 'ethereumjs-util/dist/hash'
import { Buffer } from 'buffer'
import { getReversedBits } from './buffer-bit-utils'

// inspiration from https://zacharyratliff.org/Lamport-Signatures/

export function hashMessageWithEthHeader (message: string): Buffer {
  const labeledMessage = Buffer.concat([
    Buffer.from('\x19Ethereum Signed Message:\n32', 'ascii'),
    Buffer.from(arrayify(message))
  ])

  return keccak256_buffer(labeledMessage)
}

export class LamportKeys {
  public readonly secretKeys: Buffer[][]
  public readonly publicKeys: Buffer[][]

  constructor (secretKeys: Buffer[][], publicKeys: Buffer[][]) {
    this.secretKeys = secretKeys
    this.publicKeys = publicKeys
  }
}

export const DEFAULT_NUMBER_OF_TESTS_LAMPORT = 3
export const DEFAULT_TEST_SIZE_IN_BYTES_LAMPORT = 3

export function generateLamportKeys (
  numberOfTests: number = DEFAULT_NUMBER_OF_TESTS_LAMPORT,
  testSizeInBytes: number = DEFAULT_TEST_SIZE_IN_BYTES_LAMPORT
): LamportKeys {
  const secretKeys: Buffer[][] = [[], []]
  const publicKeys: Buffer[][] = [[], []]

  for (let i = 0; i < numberOfTests; i++) {
    const secretKey1 = randomBytes(testSizeInBytes)
    const secretKey2 = randomBytes(testSizeInBytes)
    secretKeys[0].push(secretKey1)
    secretKeys[1].push(secretKey2)

    publicKeys[0][i] = keccak256_buffer(secretKey1).slice(0, testSizeInBytes)
    publicKeys[1][i] = keccak256_buffer(secretKey2).slice(0, testSizeInBytes)
  }

  return new LamportKeys(secretKeys, publicKeys)
}

export function signMessageLamport (hashedMessage: Buffer, secretKeys: Buffer[][]): Buffer {
  const numberOfTests = secretKeys[0].length
  const bits = getReversedBits(hashedMessage, numberOfTests)

  const sig = []
  for (let i = 0; i < numberOfTests; i++) {
    sig[i] = secretKeys[bits[i]][i]
  }
  return Buffer.concat(sig)
}
