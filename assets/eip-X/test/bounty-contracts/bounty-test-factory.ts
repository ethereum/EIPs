import { BigNumber } from 'ethers'
import { JsonRpcSigner } from '@ethersproject/providers/src.ts/json-rpc-provider'
import { ethers } from 'hardhat'
import { expect } from 'chai'
import BountyUtils, { submitSolution } from './bounty-utils'
import { BountyContract } from '../../typechain'
import { arrayify } from 'ethers/lib/utils'
import { Buffer } from 'buffer'
import { bytes } from '../solidityTypes'
import { time } from '@nomicfoundation/hardhat-network-helpers'

const ONE_MINUTE_IN_SECONDS = 60

function getBountyTest (bountyUtils: BountyUtils) {
  return () => {
    let bounty: BountyContract

    beforeEach(async () => {
      bounty = await bountyUtils.deployBounty()
    })

    describe('Withdraw', () => {
      const arbitraryBountyAmount = BigNumber.from(100)
      let arbitraryUser: JsonRpcSigner
      let previousBalance: BigNumber

      async function getBalance (): Promise<BigNumber> {
        return await arbitraryUser.getBalance()
      }

      before(async () => {
        arbitraryUser = ethers.provider.getSigner(1)
      })

      beforeEach(async () => {
        await bounty.addToBounty({ value: arbitraryBountyAmount })
      })

      describe('Correct Solutions', () => {
        beforeEach(async () => {
          const result = await bountyUtils.solveBounty(bounty, getBalance)
          previousBalance = result.userBalanceBeforeFinalTransaction
        })

        it('should have a bounty of zero afterwards', async () => {
          expect(await bounty.bounty()).to.equal(0)
        })

        it('should send the bounty to the user', async () => {
          const gasUsed = await bountyUtils.getLatestSolvedGasCost()
          const newBalance = await arbitraryUser.getBalance()
          const expectedBalance = previousBalance.sub(gasUsed).add(arbitraryBountyAmount)
          expect(newBalance).to.equal(expectedBalance)
        })

        it('should set the bounty as solved', async () => {
          expect(await bounty.solved()).to.equal(true)
        })

        it('should revert deposits if already solved', async () => {
          const tx = bounty.addToBounty({ value: arbitraryBountyAmount })
          await expect(tx).to.be.revertedWith('Already solved')
        })

        it('should not allow further solve attempts if already solved', async () => {
          const tx = submitSolution(0, Buffer.from(''), bounty)
          await expect(tx).to.be.revertedWith('Already solved')
        })
      })

      describe('Incorrect Solutions', () => {
        beforeEach(async () => {
          previousBalance = await getBalance()
          const tx = bountyUtils.solveBountyIncorrectly(bounty)
          await expect(tx).to.be.revertedWith('Invalid solution')
        })

        it('should have full bounty afterwards', async () => {
          expect(await bounty.bounty()).equal(arbitraryBountyAmount)
        })

        it('should not send the bounty to the user', async () => {
          const latestTXGasCosts = await bountyUtils.getLatestSolvedGasCost()
          const newBalance = await arbitraryUser.getBalance()
          expect(newBalance).equal(previousBalance.sub(latestTXGasCosts))
        })

        it('should keep the bounty as unsolved', async () => {
          expect(await bounty.solved()).equal(false)
        })
      })
    })

    describe('Lock generation', () => {
      it('should set locks as publicly available', async () => {
        const locks = await bountyUtils.getLocks(bounty)
        for (let i = 0; i < locks.length; i++) {
          const expectedLock = locks[i]
          for (let j = 0; j < expectedLock.length; j++) {
            const bountyLock = Buffer.from(arrayify((await bounty.getLock(i))[j]))
            expect(bountyLock).deep.equal(expectedLock[j])
          }
        }
      })
    })

    describe('Add to bounty', () => {
      const amountToAdd = 100
      const otherUser = ethers.provider.getSigner(1)

      async function testAddToBounty (func: () => Promise<void>): Promise<void> {
        expect(await bounty.bounty()).to.equal(0)
        await func()
        expect(await bounty.bounty()).to.equal(amountToAdd)
      }

      it('should allow adding to the bounty', async () => {
        await testAddToBounty(async () => {
          await bounty.connect(otherUser).addToBounty({ value: amountToAdd })
        })
      })

      it('should allow adding to the bounty by sending funds to address using receive', async () => {
        await testAddToBounty(async () => {
          await otherUser.sendTransaction({ to: bounty.address, value: amountToAdd })
        })
      })

      it('should allow adding to the bounty by sending funds to address using fallback', async () => {
        await testAddToBounty(async () => {
          const arbitrary_data = '0x54'
          await otherUser.sendTransaction({ to: bounty.address, value: amountToAdd, data: arbitrary_data })
        })
      })
    })

    describe('Commit reveal', () => {
      const arbitraryLockNumber = 0
      const arbitrarySolutionHash = '0x0000000000000000000000000000000000000000000000000000000000000001'
      const arbitrarySolutionHashBuffer = Buffer.from(arrayify(arbitrarySolutionHash))

      it('should be able to retrieve commit info', async () => {
        await bounty.commitSolution(arbitraryLockNumber, arbitrarySolutionHashBuffer)
        const [hash, timestamp] = await bounty.callStatic.getMyCommit(arbitraryLockNumber)
        expect(hash).to.be.eq(arbitrarySolutionHash)

        const blockNumBefore = await ethers.provider.getBlockNumber()
        const blockBefore = await ethers.provider.getBlock(blockNumBefore)
        const timestampBefore = blockBefore.timestamp
        expect(timestamp).to.eq(timestampBefore)
      })

      it('should be able to override a commit', async () => {
        const arbitrarySolutionHash2 = '0x0000000000000000000000000000000000000000000000000000000000000002'
        await bounty.commitSolution(arbitraryLockNumber, arbitrarySolutionHashBuffer)
        await bounty.commitSolution(arbitraryLockNumber, Buffer.from(arrayify(arbitrarySolutionHash2)))
        const [hash] = await bounty.callStatic.getMyCommit(arbitraryLockNumber)
        expect(hash).to.be.eq(arbitrarySolutionHash2)
      })

      it('should revert getting my commit if no commit was made', async () => {
        const tx = bounty.getMyCommit(arbitraryLockNumber)
        await expect(tx).to.be.revertedWith('Not committed yet')
      })

      it('should not allow commits if already solved', async () => {
        await bountyUtils.solveBounty(bounty)
        const tx = bounty.commitSolution(arbitraryLockNumber, arbitrarySolutionHashBuffer)
        await expect(tx).to.be.revertedWith('Already solved')
      })

      it('should not allow a reveal without a commit', async () => {
        const arbitrarySolution: bytes = '0x'
        const tx = bounty.solve(arbitraryLockNumber, arbitrarySolution)
        await expect(tx).to.be.revertedWith('Not committed yet')
      })

      it('should not allow a reveal within a day of the commit', async () => {
        const arbitrarySolutions: bytes = '0x'
        await bounty.commitSolution(arbitraryLockNumber, arbitrarySolutionHashBuffer)

        const justBeforeADay = bountyUtils.ONE_DAY_IN_SECONDS - ONE_MINUTE_IN_SECONDS
        await time.increase(justBeforeADay)
        const txReveal = bounty.solve(arbitraryLockNumber, arbitrarySolutions)
        await expect(txReveal).to.be.revertedWith('Cannot reveal within a day of the commit')
      })
    })

    describe('Track individual lock status', () => {
      const arbitraryBountyAmount = 1

      beforeEach(async () => {
        await bounty.addToBounty({ value: arbitraryBountyAmount })
        await bountyUtils.solveBountyPartially(bounty)
      })

      it('should not set the bounty as solved', async () => {
        expect(await bounty.solved()).to.eq(false)
      })

      it('should not send the bounty funds', async () => {
        expect(await bounty.bounty()).to.eq(arbitraryBountyAmount)
      })
    })
  }
}

export default getBountyTest
