import {
  SignatureBountyWithLockGeneration__factory, SignatureBountyWithLockGeneration
} from '../../../../typechain'
import { ethers } from 'hardhat'
import { expect } from 'chai'

describe('SignatureBountyWithLockGeneration', () => {
  const ethersSigner = ethers.provider.getSigner()

  async function deployNewAccumulator (numberOfLocks: number): Promise<SignatureBountyWithLockGeneration> {
    const bounty = await new SignatureBountyWithLockGeneration__factory(ethersSigner).deploy(numberOfLocks)
    while (!(await bounty.callStatic.generationIsDone())) {
      await bounty.triggerLockAccumulation()
    }
    return bounty
  }

  it('should revert lock generation if already done', async () => {
    const numberOfLocks = 1
    const bounty = await deployNewAccumulator(numberOfLocks)
    const tx = bounty.triggerLockAccumulation()
    await expect(tx).to.be.revertedWith('Locks have already been generated')
  })

  it('should generate different locks on each deploy', async () => {
    const numberOfLocks = 1
    const SignatureBountyWithLockGenerations = await Promise.all(Array(2).fill(0)
      .map(async () => deployNewAccumulator(numberOfLocks)))
    const firstLock = (await SignatureBountyWithLockGenerations[0].getLock(0))[0]
    const secondLock = (await SignatureBountyWithLockGenerations[1].getLock(0))[0]
    expect(firstLock).to.not.be.eq(secondLock)
  })

  describe('correctly sized locks', () => {
    const publicKeyByteSize = 20
    const bytesPerMessage = 32
    const hexCharactersPerByte = 2
    const hexPrefixLength = 2

    let numberOfLocks: number
    let bounty: SignatureBountyWithLockGeneration

    async function expectCorrectSizes (): Promise<void> {
      await expectCorrectLockSizes()
      await expectCorrectMessageSize()
    }

    async function expectCorrectLockSizes (): Promise<void> {
      const expectedLockLength = hexCharactersPerByte * publicKeyByteSize + hexPrefixLength
      const locks = await Promise.all(new Array(numberOfLocks).fill(0)
        .map(async (_, i) => (await bounty.getLock(i))[0]))
      expect(locks.length).to.be.eq(numberOfLocks)
      expect(locks.every(lock => lock.length === expectedLockLength)).to.be.eq(true)
      expect(locks.slice(1).every(lock => lock !== locks[0])).to.be.eq(true)
    }

    async function expectCorrectMessageSize (): Promise<void> {
      const expectedMessageLength = hexCharactersPerByte * bytesPerMessage + hexPrefixLength
      const message = (await bounty.message())
      expect(message.length).to.eq(expectedMessageLength)
    }

    it('should correctly handle the trivial case', async () => {
      numberOfLocks = 1
      bounty = await deployNewAccumulator(numberOfLocks)
      await expectCorrectSizes()
    })

    it('should correctly handle a larger case', async () => {
      numberOfLocks = 7
      bounty = await deployNewAccumulator(numberOfLocks)
      await expectCorrectSizes()
    })
  })
})
