import {
  OrderFindingBountyWithLockGeneration__factory, OrderFindingBountyWithLockGeneration
} from '../../../../typechain'
import { ethers } from 'hardhat'
import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { submitSolution } from '../../bounty-utils'

const MAX_GAS_LIMIT_OPTION = { gasLimit: BigNumber.from('0x1c9c380') }

describe('OrderFindingBountyWithLockGeneration', () => {
  const ethersSigner = ethers.provider.getSigner()

  async function deployNewAccumulator (numberOfLocks: number, byteSizeOfModulus: number): Promise<OrderFindingBountyWithLockGeneration> {
    const bounty = await new OrderFindingBountyWithLockGeneration__factory(ethersSigner).deploy(numberOfLocks, byteSizeOfModulus)
    while (!(await bounty.callStatic.generationIsDone())) {
      await bounty.triggerLockAccumulation(MAX_GAS_LIMIT_OPTION)
    }
    return bounty
  }

  it('should not allow a solution if generation is incomplete', async () => {
    const numberOfLocks = 1
    const byteSizeOfModulus = 1
    const bounty = await new OrderFindingBountyWithLockGeneration__factory(ethersSigner)
      .deploy(numberOfLocks, byteSizeOfModulus)
    const arbitrarySolution = '0x01'
    const tx = submitSolution(0, arbitrarySolution, bounty)
    await expect(tx).to.be.revertedWith('Lock has not been generated yet.')
  })

  it('should revert lock generation if already done', async () => {
    const numberOfLocks = 1
    const byteSizeOfModulus = 1
    const bounty = await deployNewAccumulator(numberOfLocks, byteSizeOfModulus)
    const tx = bounty.triggerLockAccumulation()
    await expect(tx).to.be.revertedWith('Locks have already been generated')
  })

  it('should generate different locks on each deploy', async () => {
    const numberOfLocks = 1
    const byteSizeOfModulus = 1
    const orderFindingBountyWithLockGenerations = await Promise.all(Array(2).fill(0)
      .map(async () => deployNewAccumulator(numberOfLocks, byteSizeOfModulus)))
    const lockComponents = (await Promise.all(Array(2).fill(0)
      .map(async (_, i) => Promise.all(Array(2).fill(0)
        .map(async (_, j) => (await orderFindingBountyWithLockGenerations[i].getLock(0))[j])))))
      .flat()
    expect((new Set(lockComponents)).size).to.be.eq(lockComponents.length)
  })

  describe('correctly sized locks', () => {
    let numberOfLocks: number
    let byteSizeOfModulus: number
    let orderFindingBountyWithLockGeneration: OrderFindingBountyWithLockGeneration

    async function expectCorrectLockSizes (): Promise<void> {
      const hexCharactersPerByte = 2
      const hexPrefixLength = 2
      const expectedLockLength = hexCharactersPerByte * byteSizeOfModulus + hexPrefixLength

      const locks = (await Promise.all(new Array(numberOfLocks).fill(0)
        .map(async (_, i) => Promise.all(new Array(2).fill(0)
          .map(async (_, j) => (await orderFindingBountyWithLockGeneration.getLock(i))[j])))))
        .flat()
      expect(locks.every(lock => lock.length === expectedLockLength)).to.be.eq(true)
      expect(locks.slice(1).every(lock => lock !== locks[0])).to.be.eq(true)
    }

    it('should correctly handle the trivial case', async () => {
      numberOfLocks = 1
      byteSizeOfModulus = 1
      orderFindingBountyWithLockGeneration = await deployNewAccumulator(numberOfLocks, byteSizeOfModulus)
      await expectCorrectLockSizes()
    })
  })
})
