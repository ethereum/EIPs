import { ethers } from 'hardhat'
import { Signer } from 'ethers'
import { expect } from 'chai'
import { increaseTime } from './helpers/time'
// typechain
import { ERC20Mock, VestingNFT } from '../typechain-types'

const testValues = {
  payout: '1000000000',
  lockTime: 60,
}

describe('VestingNFT', function () {
  let accounts: Signer[]
  let vestingNFT: VestingNFT
  let mockToken: ERC20Mock
  let receiverAccount: string
  let unlockTime: number

  beforeEach(async function () {
    const VestingNFT = await ethers.getContractFactory('VestingNFT')
    vestingNFT = await VestingNFT.deploy('VestingNFT', 'TLV')
    await vestingNFT.deployed()

    const ERC20Mock = await ethers.getContractFactory('ERC20Mock')
    mockToken = await ERC20Mock.deploy(
      '1000000000000000000000',
      18,
      'LockedToken',
      'LOCK'
    )
    await mockToken.deployed()
    await mockToken.approve(vestingNFT.address, '1000000000000000000000')

    accounts = await ethers.getSigners()
    receiverAccount = await accounts[1].getAddress()
    unlockTime = await createVestingNft(vestingNFT, receiverAccount, mockToken)
  })

  it('Supports ERC721 and IERC5725 interfaces', async function () {
    expect(await vestingNFT.supportsInterface('0x80ac58cd')).to.equal(true)

    /**
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
     * // Solidity export interface id:
     * bytes4 public constant IID_ITEST = type(IERC5725).interfaceId;
     * // Pull out the interfaceId in tests
     * const interfaceId = await vestingNFT.IID_ITEST();
     */
    // Vesting NFT Interface ID
    expect(await vestingNFT.supportsInterface('0xf8600f8b')).to.equal(true)
  })

  it('Returns a valid vested payout', async function () {
    const totalPayout = await vestingNFT.vestedPayoutAtTime(0, unlockTime)
    expect(await vestingNFT.vestedPayout(0)).to.equal(0)
    await increaseTime(testValues.lockTime)
    expect(await vestingNFT.vestedPayout(0)).to.equal(totalPayout)
  })

  it('Reverts with invalid ID', async function () {
    await expect(vestingNFT.vestedPayout(1)).to.revertedWith(
      'VestingNFT: invalid token ID'
    )
    await expect(vestingNFT.vestedPayoutAtTime(1, unlockTime)).to.revertedWith(
      'VestingNFT: invalid token ID'
    )
    await expect(vestingNFT.vestingPayout(1)).to.revertedWith(
      'VestingNFT: invalid token ID'
    )
    await expect(vestingNFT.claimablePayout(1)).to.revertedWith(
      'VestingNFT: invalid token ID'
    )
    await expect(vestingNFT.vestingPeriod(1)).to.revertedWith(
      'VestingNFT: invalid token ID'
    )
    await expect(vestingNFT.payoutToken(1)).to.revertedWith(
      'VestingNFT: invalid token ID'
    )
    await expect(vestingNFT.claim(1)).to.revertedWith(
      'VestingNFT: invalid token ID'
    )
    // NOTE: Removed claimTo from spec
    // await expect(vestingNFT.claimTo(1, receiverAccount)).to.revertedWith(
    //   "VestingNFT: invalid token ID"
    // );
  })

  it('Returns a valid pending payout', async function () {
    expect(await vestingNFT.vestingPayout(0)).to.equal(testValues.payout)
  })

  it('Returns a valid releasable payout', async function () {
    const totalPayout = await vestingNFT.vestedPayoutAtTime(0, unlockTime)
    expect(await vestingNFT.claimablePayout(0)).to.equal(0)
    await increaseTime(testValues.lockTime)
    expect(await vestingNFT.claimablePayout(0)).to.equal(totalPayout)
  })

  it('Returns a valid vesting period', async function () {
    const vestingPeriod = await vestingNFT.vestingPeriod(0)
    expect(vestingPeriod.vestingEnd).to.equal(unlockTime)
  })

  it('Returns a valid payout token', async function () {
    expect(await vestingNFT.payoutToken(0)).to.equal(mockToken.address)
  })

  it('Is able to claim', async function () {
    const connectedVestingNft = vestingNFT.connect(accounts[1])
    await increaseTime(testValues.lockTime)
    const txReceipt = await connectedVestingNft.claim(0)
    await txReceipt.wait()
    expect(await mockToken.balanceOf(receiverAccount)).to.equal(
      testValues.payout
    )
  })

  it('Reverts claim when payout is 0', async function () {
    const connectedVestingNft = vestingNFT.connect(accounts[1])
    await expect(connectedVestingNft.claim(0)).to.revertedWith(
      'VestingNFT: No pending payout'
    )
  })

  it('Reverts claim when payout is not from owner', async function () {
    const connectedVestingNft = vestingNFT.connect(accounts[2])
    await expect(connectedVestingNft.claim(0)).to.revertedWith(
      'Not owner of NFT'
    )
  })

  // NOTE: Removed claimTo from spec
  // it("Is able to claim to other account", async function () {
  //   const connectedVestingNft = vestingNFT.connect(accounts[1]);
  //   const otherReceiverAddress = await accounts[2].getAddress();
  //   await increaseTime(testValues.lockTime);
  //   const txReceipt = await connectedVestingNft.claimTo(
  //     0,
  //     otherReceiverAddress
  //   );
  //   await txReceipt.wait();
  //   expect(await mockToken.balanceOf(otherReceiverAddress)).to.equal(
  //     testValues.payout
  //   );
  // });

  it('Reverts when creating to account 0', async function () {
    await expect(
      vestingNFT.create(
        '0x0000000000000000000000000000000000000000',
        testValues.payout,
        unlockTime,
        mockToken.address
      )
    ).to.revertedWith('to cannot be address 0')
  })
})

async function createVestingNft(
  vestingNFT: VestingNFT,
  receiverAccount: string,
  mockToken: ERC20Mock
) {
  const latestBlock = await ethers.provider.getBlock('latest')
  const unlockTime = latestBlock.timestamp + testValues.lockTime
  const txReceipt = await vestingNFT.create(
    receiverAccount,
    testValues.payout,
    unlockTime,
    mockToken.address
  )
  await txReceipt.wait()
  return unlockTime
}
