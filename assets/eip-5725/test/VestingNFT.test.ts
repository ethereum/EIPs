import { ethers } from 'hardhat'
import { BigNumber, Signer } from 'ethers'
import { expect } from 'chai'
import { time } from '@nomicfoundation/hardhat-network-helpers'
// typechain
import { ERC20Mock, VestingNFT } from '../typechain-types'
import { IERC5725_InterfaceId } from '../src/erc5725'

const IERC721_InterfaceId = '0x80ac58cd'

const testValues = {
  payout: '1000000000',
  payoutDecimals: 18,
  lockTime: 60,
}

describe('VestingNFT', function () {
  let accounts: Signer[]
  let vestingNFT: VestingNFT
  let mockToken: ERC20Mock
  let receiverAccount: string
  let operatorAccount: string
  let transferToAccount: string
  let unlockTime: number
  let invalidTokenID = 1337

  beforeEach(async function () {
    const VestingNFT = await ethers.getContractFactory('VestingNFT')
    vestingNFT = await VestingNFT.deploy('VestingNFT', 'TLV')
    await vestingNFT.deployed()

    const ERC20Mock = await ethers.getContractFactory('ERC20Mock')
    mockToken = await ERC20Mock.deploy(
      '1000000000000000000000',
      testValues.payoutDecimals,
      'LockedToken',
      'LOCK'
    )
    await mockToken.deployed()
    await mockToken.approve(vestingNFT.address, '1000000000000000000000')

    accounts = await ethers.getSigners()
    receiverAccount = await accounts[1].getAddress()
    operatorAccount = await accounts[2].getAddress()
    transferToAccount = await accounts[3].getAddress()
    unlockTime = await createVestingNft(
      vestingNFT,
      receiverAccount,
      mockToken,
      5
    )
  })

  /**
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
   * // Solidity export interface id:
   * bytes4 public constant IID_TEST = type(IERC5725).interfaceId;
   * // Pull out the interfaceId in tests
   * const interfaceId = await vestingNFT.IID_TEST();
   */
  it('Supports ERC721 and IERC5725 interfaces', async function () {
    // IERC721
    expect(await vestingNFT.supportsInterface(IERC721_InterfaceId)).to.equal(
      true
    )
    // Vesting NFT Interface IERC5725
    expect(await vestingNFT.supportsInterface(IERC5725_InterfaceId)).to.equal(
      true
    )
  })

  it('Returns a valid vested payout', async function () {
    const totalPayout = await vestingNFT.vestedPayoutAtTime(0, unlockTime)
    expect(await vestingNFT.vestedPayout(0)).to.equal(0)
    await time.increase(testValues.lockTime)
    expect(await vestingNFT.vestedPayout(0)).to.equal(totalPayout)
  })

  it('Reverts with invalid ID', async function () {
    await expect(vestingNFT.vestedPayout(invalidTokenID)).to.revertedWith(
      'ERC5725: invalid token ID'
    )
    await expect(
      vestingNFT.vestedPayoutAtTime(invalidTokenID, unlockTime)
    ).to.revertedWith('ERC5725: invalid token ID')
    await expect(vestingNFT.vestingPayout(invalidTokenID)).to.revertedWith(
      'ERC5725: invalid token ID'
    )
    await expect(vestingNFT.claimablePayout(invalidTokenID)).to.revertedWith(
      'ERC5725: invalid token ID'
    )
    await expect(vestingNFT.vestingPeriod(invalidTokenID)).to.revertedWith(
      'ERC5725: invalid token ID'
    )
    await expect(vestingNFT.payoutToken(invalidTokenID)).to.revertedWith(
      'ERC5725: invalid token ID'
    )
    await expect(vestingNFT.claim(invalidTokenID)).to.revertedWith(
      'ERC5725: invalid token ID'
    )
  })

  it('Returns a valid pending payout', async function () {
    expect(await vestingNFT.vestingPayout(0)).to.equal(testValues.payout)
  })

  it('Returns a valid releasable payout', async function () {
    const totalPayout = await vestingNFT.vestedPayoutAtTime(0, unlockTime)
    expect(await vestingNFT.claimablePayout(0)).to.equal(0)
    await time.increase(testValues.lockTime)
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
    expect(await vestingNFT.claimedPayout(0)).to.equal(0)
    await time.increase(testValues.lockTime)
    const txReceipt = await connectedVestingNft.claim(0)
    await txReceipt.wait()
    expect(await mockToken.balanceOf(receiverAccount)).to.equal(
      testValues.payout
    )
    expect(await vestingNFT.claimedPayout(0)).to.equal(testValues.payout)
  })

  it('Reverts claim when payout is 0', async function () {
    const connectedVestingNft = vestingNFT.connect(accounts[1])
    await expect(connectedVestingNft.claim(0)).to.revertedWith(
      'ERC5725: No pending payout'
    )
  })

  it('Reverts claim when payout is not from owner or account with permission', async function () {
    const connectedVestingNft = vestingNFT.connect(accounts[2])
    await expect(connectedVestingNft.claim(0)).to.revertedWith(
      'ERC5725: not owner or operator'
    )
  })

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

  it('Revert when setting an setClaimApproval for a tokenId you do not own', async function () {
    // Account without permission tries to call setClaimApproval(self,tokenId)
    const connectedVestingNft = vestingNFT.connect(accounts[2])

    await expect(
      connectedVestingNft.setClaimApproval(operatorAccount, true, 1)
    ).to.revertedWith('ERC5725: not owner of tokenId')
  })

  it("Should allow a designated operator to manage specific tokenId's owned by the owner through _tokenIdApprovals, until such rights are revoked", async function () {
    // Give permission for SPECIFIC tokenId to be managed
    const ownersConnectedVestingNft = vestingNFT.connect(accounts[1])
    const operatorsConnectedVestingNft = vestingNFT.connect(accounts[2])
    let approveToken1 = ownersConnectedVestingNft.setClaimApproval(
      operatorAccount,
      true,
      1
    )
    await expect(approveToken1).to.be.fulfilled
    await expect(approveToken1)
      .to.emit(ownersConnectedVestingNft, 'ClaimApproval')
      .withArgs(receiverAccount, operatorAccount, 1, true)

    // Elapse time, operator can claim
    await time.increase(testValues.lockTime)
    await expect(operatorsConnectedVestingNft.claim(1)).to.be.fulfilled

    // Owner revokes permission for SPECIFIC tokenId
    let unapprovedToken1 = ownersConnectedVestingNft.setClaimApproval(
      operatorAccount,
      false,
      1
    )
    await expect(unapprovedToken1).to.be.fulfilled
    await expect(unapprovedToken1)
      .to.emit(ownersConnectedVestingNft, 'ClaimApproval')
      .withArgs(receiverAccount, operatorAccount, 1, false)

    // Elapse time, operator can't claim for that specific tokenId because no permissions
    await time.increase(testValues.lockTime)
    await expect(operatorsConnectedVestingNft.claim(0)).to.revertedWith(
      'ERC5725: not owner or operator'
    )
  })

  it("Should allow a designated operator to manage all tokenId's owned by the owner through _operatorApprovals, until such rights are revoked", async function () {
    // Give permission for ALL tokenId to be managed
    const ownersConnectedVestingNft = vestingNFT.connect(accounts[1])
    const operatorsConnectedVestingNft = vestingNFT.connect(accounts[2])
    let approveGlobalOperator =
      ownersConnectedVestingNft.setClaimApprovalForAll(operatorAccount, true)
    await expect(approveGlobalOperator).to.be.fulfilled
    await expect(approveGlobalOperator)
      .to.emit(ownersConnectedVestingNft, 'ClaimApprovalForAll')
      .withArgs(receiverAccount, operatorAccount, true)

    // Elapse time, operator can claim
    await time.increase(testValues.lockTime)
    await expect(operatorsConnectedVestingNft.claim(1)).to.be.fulfilled
    await expect(operatorsConnectedVestingNft.claim(2)).to.be.fulfilled
    await expect(operatorsConnectedVestingNft.claim(3)).to.be.fulfilled

    // Owner revokes permission for SPECIFIC tokenId
    let unapprovedGlobalOperator =
      ownersConnectedVestingNft.setClaimApprovalForAll(operatorAccount, false)
    await expect(unapprovedGlobalOperator).to.be.fulfilled
    await expect(unapprovedGlobalOperator)
      .to.emit(ownersConnectedVestingNft, 'ClaimApprovalForAll')
      .withArgs(receiverAccount, operatorAccount, false)

    // Elapse time, operator can't claim for that specific tokenId because no permissions
    await time.increase(testValues.lockTime)
    await expect(operatorsConnectedVestingNft.claim(1)).to.revertedWith(
      'ERC5725: not owner or operator'
    )
    await expect(operatorsConnectedVestingNft.claim(2)).to.revertedWith(
      'ERC5725: not owner or operator'
    )
    await expect(operatorsConnectedVestingNft.claim(3)).to.revertedWith(
      'ERC5725: not owner or operator'
    )
  })

  it("Should revoke an operator's management rights from _tokenIdApprovals for a specific tokenId when the token is transferred", async function () {
    // Give permission for SPECIFIC tokenId to be managed
    const ownersConnectedVestingNft = vestingNFT.connect(accounts[1])
    const operatorsConnectedVestingNft = vestingNFT.connect(accounts[2])
    let approveToken1 = ownersConnectedVestingNft.setClaimApproval(
      operatorAccount,
      true,
      1
    )
    await expect(approveToken1).to.be.fulfilled

    // permissions added
    expect(await ownersConnectedVestingNft.getClaimApproved(1)).to.equal(
      operatorAccount
    )

    // Transfer tokenId 1 to other address which removes the _tokenIdApprovals permission but we keep the global OP status
    const transferNft = ownersConnectedVestingNft.transferFrom(
      receiverAccount,
      transferToAccount,
      1
    )
    await expect(transferNft).to.be.fulfilled

    // permissions removed
    expect(await ownersConnectedVestingNft.getClaimApproved(1)).to.equal(
      '0x0000000000000000000000000000000000000000'
    )

    // Operator can't claim for tokenId 1 permissions removed
    await expect(operatorsConnectedVestingNft.claim(1)).to.revertedWith(
      'ERC5725: not owner or operator'
    )
  })

  it("Should keep an operator's management rights to _operatorApprovals for all tokenIds when one or more are transfered", async function () {
    // Give permission for ALL tokenId to be managed
    const ownersConnectedVestingNft = vestingNFT.connect(accounts[1])
    const operatorsConnectedVestingNft = vestingNFT.connect(accounts[2])
    let approveGlobalOperator =
      ownersConnectedVestingNft.setClaimApprovalForAll(operatorAccount, true)
    await expect(approveGlobalOperator).to.be.fulfilled

    // permissions added
    expect(
      await ownersConnectedVestingNft.isClaimApprovedForAll(
        receiverAccount,
        operatorAccount
      )
    ).to.equal(true)

    // Transfer tokenId 1 to other address which removes the _tokenIdApprovals permission but we keep the global OP status
    const transferNft = ownersConnectedVestingNft.transferFrom(
      receiverAccount,
      transferToAccount,
      1
    )
    await expect(transferNft).to.be.fulfilled

    // permissions kept
    expect(
      await ownersConnectedVestingNft.isClaimApprovedForAll(
        receiverAccount,
        operatorAccount
      )
    ).to.equal(true)

    // Operator can't claim for tokenId 1 they don't own it anymore
    await expect(operatorsConnectedVestingNft.claim(1)).to.revertedWith(
      'ERC5725: not owner or operator'
    )
    // Operator can claim for other tokenIds
    await time.increase(testValues.lockTime)
    await expect(operatorsConnectedVestingNft.claim(2)).to.be.fulfilled
    await expect(operatorsConnectedVestingNft.claim(3)).to.be.fulfilled
  })
})

async function createVestingNft(
  vestingNFT: VestingNFT,
  receiverAccount: string,
  mockToken: ERC20Mock,
  batchMintAmount: number = 1
) {
  const latestBlock = await ethers.provider.getBlock('latest')
  const unlockTime = latestBlock.timestamp + testValues.lockTime

  for (let i = 0; i <= batchMintAmount; i++) {
    const txReceipt = await vestingNFT.create(
      receiverAccount,
      testValues.payout,
      unlockTime,
      mockToken.address
    )
    await txReceipt.wait()
  }

  return unlockTime
}
