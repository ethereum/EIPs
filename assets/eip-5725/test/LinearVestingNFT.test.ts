import { ethers } from 'hardhat'
import { Signer } from 'ethers'
import { expect } from 'chai'
import { time } from '@nomicfoundation/hardhat-network-helpers'
// typechain
import {
  ERC20Mock__factory,
  ERC20Mock,
  LinearVestingNFT__factory,
  LinearVestingNFT,
} from '../typechain-types'

const testValues = {
  payout: '1000000000',
  lockTime: 60,
  buffer: 10,
  totalLock: 70,
}

describe('LinearVestingNFT', function () {
  let accounts: Signer[]
  let linearVestingNFT: LinearVestingNFT
  let mockToken: ERC20Mock
  let receiverAccount: string
  let unlockTime: number

  beforeEach(async function () {
    const LinearVestingNFT = (await ethers.getContractFactory(
      'LinearVestingNFT'
    )) as LinearVestingNFT__factory
    linearVestingNFT = await LinearVestingNFT.deploy('LinearVestingNFT', 'TLV')
    await linearVestingNFT.deployed()

    const ERC20Mock = (await ethers.getContractFactory(
      'ERC20Mock'
    )) as ERC20Mock__factory
    mockToken = await ERC20Mock.deploy(
      '1000000000000000000000',
      18,
      'LockedToken',
      'LOCK'
    )
    await mockToken.deployed()
    await mockToken.approve(linearVestingNFT.address, '1000000000000000000000')

    accounts = await ethers.getSigners()
    receiverAccount = await accounts[1].getAddress()
    unlockTime = await createVestingNft(
      linearVestingNFT,
      receiverAccount,
      mockToken
    )
  })

  it('Returns a valid vested payout', async function () {
    // TODO: More extensive testing of linear vesting functionality
    const totalPayout = await linearVestingNFT.vestedPayoutAtTime(0, unlockTime)
    expect(await linearVestingNFT.vestedPayout(0)).to.equal(0)
    await time.increase(testValues.totalLock)
    expect(await linearVestingNFT.vestedPayout(0)).to.equal(totalPayout)
  })

  it('Reverts when creating to account 0', async function () {
    const latestBlock = await ethers.provider.getBlock('latest')
    await expect(
      linearVestingNFT.create(
        '0x0000000000000000000000000000000000000000',
        testValues.payout,
        latestBlock.timestamp + testValues.buffer,
        testValues.lockTime,
        0,
        mockToken.address
      )
    ).to.revertedWith('to cannot be address 0')
  })

  it('Reverts when creating to past start date 0', async function () {
    await expect(
      linearVestingNFT.create(
        receiverAccount,
        testValues.payout,
        0,
        testValues.lockTime,
        0,
        mockToken.address
      )
    ).to.revertedWith('startTime cannot be on the past')
  })

  it('Reverts when duration is less than cliff', async function () {
    const latestBlock = await ethers.provider.getBlock('latest')
    await expect(
      linearVestingNFT.create(
        receiverAccount,
        testValues.payout,
        latestBlock.timestamp + testValues.buffer,
        testValues.lockTime,
        100,
        mockToken.address
      )
    ).to.revertedWith('duration needs to be more than cliff')
  })
})

async function createVestingNft(
  linearVestingNFT: LinearVestingNFT,
  receiverAccount: string,
  mockToken: ERC20Mock
) {
  const latestBlock = await ethers.provider.getBlock('latest')
  const unlockTime =
    latestBlock.timestamp + testValues.lockTime + testValues.buffer
  const txReceipt = await linearVestingNFT.create(
    receiverAccount,
    testValues.payout,
    latestBlock.timestamp + testValues.buffer,
    testValues.lockTime,
    0,
    mockToken.address
  )
  await txReceipt.wait()
  return unlockTime
}
