import { JsonRpcSigner } from '@ethersproject/providers/src.ts/json-rpc-provider'
import { bytes } from '../../../solidityTypes'
import { ethers, web3 } from 'hardhat'
import { BountyContract, SignatureBountyWithPredeterminedLocks, SignatureBountyWithPredeterminedLocks__factory } from '../../../../typechain'
import { BigNumber, ContractTransaction } from 'ethers'
import BountyUtils, {
  getLatestSolvedGasCost,
  SolveAttemptResult,
  solveBountyReturningUserBalanceBeforeFinalSolution,
  submitSolution
} from '../../bounty-utils'
import { arrayify } from 'ethers/lib/utils'
import { Buffer } from 'buffer'

class SignatureBountyWithPredeterminedLocksUtils extends BountyUtils {
  private readonly numberOfLocks: number
  private readonly _publicKeys: bytes[][]
  private _signatures: string[]
  private readonly _signers: JsonRpcSigner[]

  constructor (numberOfLocks: number = 3) {
    super()
    this.numberOfLocks = numberOfLocks
    this._publicKeys = []
    this._signatures = []
    this._signers = []
  }

  public async deployBounty (): Promise<BountyContract> {
    const ethersSigner = ethers.provider.getSigner()
    const message = this.arbitraryMessage()
    return await new SignatureBountyWithPredeterminedLocks__factory(ethersSigner).deploy(await this.getLocks(), message)
  }

  public async getLocks (): Promise<bytes[][]> {
    if (this._publicKeys.length === 0) {
      for (const signer of this.signers) {
        this._publicKeys.push([Buffer.from(arrayify(await signer.getAddress()))])
      }
    }
    return this._publicKeys
  }

  public async solveBounty (bounty: SignatureBountyWithPredeterminedLocks, getUserBalance: () => Promise<BigNumber>): Promise<SolveAttemptResult> {
    const signatures = await this.getSignatures(this.arbitraryMessage())
    return solveBountyReturningUserBalanceBeforeFinalSolution(signatures, bounty, getUserBalance)
  }

  public async solveBountyPartially (bounty: SignatureBountyWithPredeterminedLocks): Promise<void> {
    const signatures = await this.getSignatures(this.arbitraryMessage())
    await submitSolution(0, signatures[0], bounty)
  }

  public async solveBountyIncorrectly (bounty: SignatureBountyWithPredeterminedLocks): Promise<ContractTransaction> {
    const signatures = await this.getSignatures(this.arbitraryMessage())
    return submitSolution(1, signatures[0], bounty)
  }

  private async getSignatures (message: string): Promise<string[]> {
    if (this._signatures.length === 0) {
      this._signatures = await Promise.all(this.signers.map(async (signer) =>
        await web3.eth.sign(message, await signer.getAddress())))
    }
    return this._signatures
  }

  private arbitraryMessage (): string {
    return web3.utils.sha3('arbitrary') as string
  }

  private get signers (): JsonRpcSigner[] {
    if (this._signers.length === 0) {
      for (let i = 0; i < this.numberOfLocks; i++) {
        this._signers.push(ethers.provider.getSigner(i))
      }
    }
    return this._signers
  }

  public async getLatestSolvedGasCost (): Promise<BigNumber> {
    return getLatestSolvedGasCost(this._signatures.length)
  }
}

export default SignatureBountyWithPredeterminedLocksUtils
