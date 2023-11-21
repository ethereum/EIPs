import { bytes } from '../../../solidityTypes'
import { ethers } from 'hardhat'
import { BigNumber, ContractTransaction } from 'ethers'
import BountyUtils, {
  getLatestSolvedGasCost,
  SolveAttemptResult,
  solveBountyReturningUserBalanceBeforeFinalSolution,
  submitSolution
} from '../../bounty-utils'
import {
  BountyContract,
  OrderFindingBountyWithPredeterminedLocks,
  OrderFindingBountyWithPredeterminedLocks__factory
} from '../../../../typechain'
import { arrayify } from 'ethers/lib/utils'
import { Buffer } from 'buffer'

class OrderFindingBountyWithPredeterminedLocksUtils extends BountyUtils {
  private readonly locksAndKeys = [
    {
      lock: [15, 7],
      key: 4
    },
    {
      lock: [23, 17],
      key: 22
    }
  ]

  public async deployBounty (): Promise<OrderFindingBountyWithPredeterminedLocks> {
    const ethersSigner = ethers.provider.getSigner()
    const locks = await this.getLocks()
    const bounty = await new OrderFindingBountyWithPredeterminedLocks__factory(ethersSigner).deploy(locks.length)
    for (let i = 0; i < locks.length; i++) {
      await bounty.setLock(i, locks[i])
    }
    return bounty
  }

  public async getLocks (): Promise<bytes[][]> {
    return Promise.resolve(this.locksAndKeys.map(x => x.lock.map(y => Buffer.from(arrayify(y)))))
  }

  public async solveBounty (bounty: BountyContract, getUserBalance?: () => Promise<BigNumber>): Promise<SolveAttemptResult> {
    return solveBountyReturningUserBalanceBeforeFinalSolution(this._getKeys(), bounty, getUserBalance)
  }

  public async solveBountyPartially (bounty: BountyContract): Promise<void> {
    const primes = this._getKeys()
    await submitSolution(0, primes[0], bounty)
  }

  public async solveBountyIncorrectly (bounty: BountyContract): Promise<ContractTransaction> {
    const keys = this._getKeys()
    return await submitSolution(1, keys[0], bounty)
  }

  private _getKeys (): bytes[] {
    return this.locksAndKeys.map(lockAndKeys => Buffer.from(arrayify(lockAndKeys.key)))
  }

  public async getLatestSolvedGasCost (): Promise<BigNumber> {
    return getLatestSolvedGasCost(this.locksAndKeys.length)
  }
}

export default OrderFindingBountyWithPredeterminedLocksUtils
