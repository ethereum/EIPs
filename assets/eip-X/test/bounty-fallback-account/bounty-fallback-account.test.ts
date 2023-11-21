import { ethers } from 'hardhat'
import { expect } from 'chai'
import {
  BountyFallbackAccount, BountyFallbackAccountFactory,
  BountyFallbackAccountFactory__factory, SignatureBounty,
  TestUtil,
  TestUtil__factory
} from '../../typechain'
import {
  createAddress,
  getBalance,
  isDeployed,
  ONE_ETH,
  HashZero
} from '../testutils'
import { fillUserOpDefaults, getUserOpHash, packUserOp } from '../UserOp'
import { arrayify, parseEther } from 'ethers/lib/utils'
import { UserOperation } from '../UserOperation'
import {
  createAccountLamport,
  createAccountOwnerLamport
} from './testutils-lamport'
import { signUserOpLamport } from './UserOpLamport'
import { WalletLamport } from './wallet-lamport'
import { generateLamportKeys } from './lamport-utils'
import SignatureBountyUtils from '../bounty-contracts/signature-bounty/signature-bounty-with-predetermined-locks/signature-bounty-with-predetermined-locks-utils'
import { BigNumber } from 'ethers'

const EDCSA_LENGTH = 65

describe('BountyFallbackAccount', function () {
  const entryPoint = '0x'.padEnd(42, '2')
  let accounts: string[]
  let testUtil: TestUtil
  let accountOwner: WalletLamport
  const ethersSigner = ethers.provider.getSigner()

  const bountyUtils = new SignatureBountyUtils()
  let bounty: SignatureBounty

  beforeEach(async function () {
    bounty = await bountyUtils.deployBounty()

    accounts = await ethers.provider.listAccounts()
    // ignore in geth.. this is just a sanity test. should be refactored to use a single-account mode..
    if (accounts.length < 2) this.skip()
    testUtil = await new TestUtil__factory(ethersSigner).deploy()
    accountOwner = createAccountOwnerLamport()
  })

  async function createFirstAccountLamport (): Promise<{
    proxy: BountyFallbackAccount
    accountFactory: BountyFallbackAccountFactory
    implementation: string
  }> {
    const keysLamport = generateLamportKeys()
    return await createAccountLamport(ethers.provider.getSigner(), accounts[0], keysLamport.publicKeys, bounty.address, entryPoint)
  }

  it('owner should be able to call transfer', async () => {
    const { proxy: account } = await createFirstAccountLamport()
    await ethersSigner.sendTransaction({ from: accounts[0], to: account.address, value: parseEther('2') })
    await account.execute(accounts[2], ONE_ETH, '0x')
  })

  it('other account should not be able to call transfer', async () => {
    const { proxy: account } = await createFirstAccountLamport()
    await expect(account.connect(ethers.provider.getSigner(1)).execute(accounts[2], ONE_ETH, '0x'))
      .to.be.revertedWith('account: not Owner or EntryPoint')
  })

  it('should pack in js the same as solidity', async () => {
    const op = await fillUserOpDefaults({ sender: accounts[0] })
    const packed = packUserOp(op)
    expect(await testUtil.packUserOp(op)).to.equal(packed)
  })

  describe('#validateUserOp', () => {
    let account: BountyFallbackAccount
    let userOpHash: string
    let preBalance: number
    let expectedPay: number

    const actualGasPrice = 1e9

    let nonceTracker: number

    let getUserOpLamport: () => UserOperation
    let userOpLamportInitial: UserOperation
    let userOpNoLamport: UserOperation

    beforeEach(async () => {
      nonceTracker = 0

      // that's the account of ethersSigner
      const entryPoint = accounts[2];
      ({ proxy: account } = await createAccountLamport(
        await ethers.getSigner(entryPoint),
        accountOwner.baseWallet.address,
        accountOwner.lamportKeys.publicKeys,
        bounty.address,
        entryPoint))
      await ethersSigner.sendTransaction({ from: accounts[0], to: account.address, value: parseEther('0.2') })
      const callGasLimit = 200000
      const verificationGasLimit = 100000
      const maxFeePerGas = 3e9
      const chainId = await ethers.provider.getNetwork().then(net => net.chainId)

      getUserOpLamport = () => signUserOpLamport(fillUserOpDefaults({
        sender: account.address,
        callGasLimit,
        verificationGasLimit,
        maxFeePerGas
      }), accountOwner, entryPoint, chainId)

      userOpLamportInitial = getUserOpLamport()
      userOpHash = await getUserOpHash(userOpLamportInitial, entryPoint, chainId)

      userOpNoLamport = {
        ...userOpLamportInitial,
        signature: Buffer.concat([
          Buffer.from(arrayify(userOpLamportInitial.signature)).slice(0, EDCSA_LENGTH),
          Buffer.from(new Array(userOpLamportInitial.signature.length - EDCSA_LENGTH).fill(0))
        ])
      }

      expectedPay = actualGasPrice * (callGasLimit + verificationGasLimit)
      preBalance = await getBalance(account.address)
    })

    describe('before bounty is solved', function () {
      beforeEach(async () => {
        const ret = await account.validateUserOp(userOpNoLamport, userOpHash, expectedPay, { gasPrice: actualGasPrice })
        await ret.wait()
        ++nonceTracker
      })

      it('should pay', async () => {
        const postBalance = await getBalance(account.address)
        expect(preBalance - postBalance).to.eql(expectedPay)
      })

      it('should increment nonce', async () => {
        expect(await account.nonce()).to.equal(1)
      })

      it('should reject same TX on nonce error', async () => {
        await expect(account.validateUserOp(userOpNoLamport, userOpHash, 0)).to.revertedWith('invalid nonce')
      })

      it('should return NO_SIG_VALIDATION on wrong ECDSA signature', async () => {
        const deadline = await account.callStatic.validateUserOp({ ...userOpNoLamport, nonce: nonceTracker }, HashZero, 0)
        expect(deadline).to.eq(1)
      })

      it('should return 0 on correct ECDSA signature but incorrect Lamport signature', async () => {
        const deadline = await account.callStatic.validateUserOp({ ...userOpNoLamport, nonce: nonceTracker }, userOpHash, 0)
        expect(deadline).to.eq(0)
      })
    })

    describe('after bounty is solved', () => {
      beforeEach(async () => {
        await bountyUtils.solveBounty(bounty)
      })

      it('should return NO_SIG_VALIDATION on wrong lamport signature', async () => {
        const deadline = await account.callStatic.validateUserOp({ ...userOpNoLamport, nonce: nonceTracker }, userOpHash, 0)
        expect(deadline).to.eq(1)
      })

      it('should return 0 on correct lamport signature', async () => {
        const deadline = await account.callStatic.validateUserOp({ ...userOpLamportInitial, nonce: nonceTracker }, userOpHash, 0)
        expect(deadline).to.eq(0)
      })
    })

    describe('lamport signature is updated', () => {
      async function updateSignature (userOpLamport: UserOperation): Promise<void> {
        const txUsingFirstSignature = await account.validateUserOp({ ...userOpLamport, nonce: nonceTracker }, userOpHash, 0)
        await txUsingFirstSignature.wait()
        ++nonceTracker
      }

      async function testSignature (userOpLamport: UserOperation): Promise<BigNumber> {
        return await account.callStatic.validateUserOp({ ...userOpLamport, nonce: nonceTracker }, userOpHash, 0)
      }

      beforeEach(async () => {
        await updateSignature(userOpLamportInitial)
        await bountyUtils.solveBounty(bounty)
      })

      it('should not allow same lamport signature twice', async () => {
        const txUsingFirstSignatureAgain = await testSignature(userOpLamportInitial)
        expect(txUsingFirstSignatureAgain).to.eq(1)
      })

      it('should require updated lamport signature on subsequent transaction', async () => {
        const txUsingUpdatedSignature = await testSignature(getUserOpLamport())
        expect(txUsingUpdatedSignature).to.eq(0)
      })

      it('should also update the lamport key after bounty is solved', async () => {
        await updateSignature(getUserOpLamport())
        const txUsingUpdatedSignature = await testSignature(getUserOpLamport())
        expect(txUsingUpdatedSignature).to.eq(0)
      })
    })
  })

  context('BountyFallbackWalletFactory', () => {
    it('sanity: check deployer', async () => {
      const ownerAddr = createAddress()
      const lamportKeys = generateLamportKeys()
      const deployer = await new BountyFallbackAccountFactory__factory(ethersSigner).deploy(entryPoint)
      const target = await deployer.callStatic.createAccount(ownerAddr, 1234, lamportKeys.publicKeys, bounty.address)
      expect(await isDeployed(target)).to.eq(false)
      await deployer.createAccount(ownerAddr, 1234, lamportKeys.publicKeys, bounty.address)
      expect(await isDeployed(target)).to.eq(true)
    })
  })
})
