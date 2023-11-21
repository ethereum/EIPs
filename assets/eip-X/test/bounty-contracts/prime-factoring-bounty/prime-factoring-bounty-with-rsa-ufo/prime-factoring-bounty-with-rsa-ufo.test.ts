import {
  PrimeFactoringBountyWithRsaUfo__factory, PrimeFactoringBountyWithRsaUfo
} from '../../../../typechain'
import { ethers } from 'hardhat'
import { expect } from 'chai'

describe('PrimeFactoringBountyWithRsaUfo', () => {
  const ethersSigner = ethers.provider.getSigner()

  async function deployNewRsaUfoAccumulator (numberOfLocks: number, bytesPerPrime: number): Promise<PrimeFactoringBountyWithRsaUfo> {
    const bounty = await new PrimeFactoringBountyWithRsaUfo__factory(ethersSigner).deploy(numberOfLocks, bytesPerPrime)
    while (!(await bounty.callStatic.generationIsDone())) {
      await bounty.triggerLockAccumulation()
    }
    return bounty
  }

  it('should revert lock generation if already done', async () => {
    const numberOfLocks = 1
    const bytesPerPrime = 1
    const bounty = await deployNewRsaUfoAccumulator(numberOfLocks, bytesPerPrime)
    const tx = bounty.triggerLockAccumulation()
    await expect(tx).to.be.revertedWith('Locks have already been generated')
  })

  it('should generate different locks on each deploy', async () => {
    const numberOfLocks = 1
    const bytesPerPrime = 1
    const primeFactoringBountyWithRsaUfos = await Promise.all(Array(2).fill(0)
      .map(async () => deployNewRsaUfoAccumulator(numberOfLocks, bytesPerPrime)))
    const firstLock = (await primeFactoringBountyWithRsaUfos[0].getLock(0))[0]
    const secondLock = (await primeFactoringBountyWithRsaUfos[1].getLock(0))[0]
    expect(firstLock).to.not.be.eq(secondLock)
  })

  describe('correctly sized locks', () => {
    let numberOfLocks: number
    let bytesPerPrime: number
    let primeFactoringBountyWithRsaUfo: PrimeFactoringBountyWithRsaUfo

    async function expectCorrectLockSizes (): Promise<void> {
      const hexCharactersPerByte = 2
      const lockBytesPerPrimeByte = 3
      const hexPrefixLength = 2
      const expectedLockLength = hexCharactersPerByte * lockBytesPerPrimeByte * bytesPerPrime + hexPrefixLength

      const locks = await Promise.all(new Array(numberOfLocks).fill(0)
        .map(async (_, i) => (await primeFactoringBountyWithRsaUfo.getLock(i))[0]))
      expect(locks.length).to.be.eq(numberOfLocks)
      expect(locks.every(lock => lock.length === expectedLockLength)).to.be.eq(true)
      expect(locks.slice(1).every(lock => lock !== locks[0])).to.be.eq(true)
    }

    it('should correctly handle the trivial case', async () => {
      numberOfLocks = 1
      bytesPerPrime = 1
      primeFactoringBountyWithRsaUfo = await deployNewRsaUfoAccumulator(numberOfLocks, bytesPerPrime)
      await expectCorrectLockSizes()
    })

    it('should correctly handle a larger case', async () => {
      numberOfLocks = 7
      bytesPerPrime = 8
      primeFactoringBountyWithRsaUfo = await deployNewRsaUfoAccumulator(numberOfLocks, bytesPerPrime)
      await expectCorrectLockSizes()
    })
  })
})
