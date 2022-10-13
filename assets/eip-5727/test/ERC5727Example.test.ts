import { expect } from 'chai'
import { ethers } from 'hardhat'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { ERC5727Example, ERC5727Example__factory } from '../typechain'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

interface Fixture {
  ERC5727ExampleFactory: ERC5727Example__factory
  ERC5727ExampleContract: ERC5727Example
  owner: SignerWithAddress
  tokenOwnerSoul1: SignerWithAddress
  tokenOwnerSoul2: SignerWithAddress
  voterSoul1: SignerWithAddress
  voterSoul2: SignerWithAddress
  delegateSoul1: SignerWithAddress
  delegateSoul2: SignerWithAddress
}

describe('ERC5727Test', function () {
  async function deployTokenFixture(): Promise<Fixture> {
    const ERC5727ExampleFactory = await ethers.getContractFactory('ERC5727Example')
    const [
      owner,
      tokenOwnerSoul1,
      tokenOwnerSoul2,
      voterSoul1,
      voterSoul2,
      delegateSoul1,
      delegateSoul2,
    ] = await ethers.getSigners()
    const ERC5727ExampleContract = await ERC5727ExampleFactory.deploy(
      'Soularis',
      'SOUL',
      [voterSoul1.address, voterSoul2.address],
      'https://soularis-demo.s3.ap-northeast-1.amazonaws.com/perk/',
    )
    await ERC5727ExampleContract.deployed()
    return {
      ERC5727ExampleFactory,
      ERC5727ExampleContract,
      owner,
      tokenOwnerSoul1,
      tokenOwnerSoul2,
      voterSoul1,
      voterSoul2,
      delegateSoul1,
      delegateSoul2,
    }
  }

  describe('ERC5727Example', function () {
    it('Only contract owner can mint with mint', async function () {
      const { ERC5727ExampleContract, owner, tokenOwnerSoul1, voterSoul1 } = await loadFixture(
        deployTokenFixture,
      )
      expect(await ERC5727ExampleContract.owner()).equal(owner.address)

      await ERC5727ExampleContract.connect(owner).mint(
        tokenOwnerSoul1.address,
        1,
        1,
        2664539263,
        false,
      )

      await expect(
        ERC5727ExampleContract.connect(voterSoul1).mint(
          tokenOwnerSoul1.address,
          1,
          2,
          2664539263,
          false,
        ),
      ).be.reverted
    })

    it('Only contract owner can revoke with revoke', async function () {
      const { ERC5727ExampleContract, owner, tokenOwnerSoul1, voterSoul1 } = await loadFixture(
        deployTokenFixture,
      )
      expect(await ERC5727ExampleContract.owner()).equal(owner.address)

      await ERC5727ExampleContract.connect(owner).mint(
        tokenOwnerSoul1.address,
        1,
        1,
        2664539263,
        false,
      )

      await ERC5727ExampleContract.connect(owner).revoke(0)

      await expect(ERC5727ExampleContract.connect(voterSoul1).revoke(0)).be.reverted
    })

    it('Balance of souls will increase when tokens are minted to them', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )

      expect(await ERC5727ExampleContract.balanceOf(tokenOwnerSoul1.address)).equal(3)

      expect(await ERC5727ExampleContract.balanceOf(tokenOwnerSoul2.address)).equal(1)
    })

    it('Token will be invalid if it is revoked', async function () {
      const { ERC5727ExampleContract, owner, tokenOwnerSoul1 } = await loadFixture(
        deployTokenFixture,
      )
      expect(await ERC5727ExampleContract.owner()).equal(owner.address)

      await ERC5727ExampleContract.connect(owner).mint(
        tokenOwnerSoul1.address,
        1,
        1,
        2664539263,
        false,
      )

      await ERC5727ExampleContract.connect(owner).revoke(0)

      expect(await ERC5727ExampleContract.isValid(0)).equal(false)
    })

    it('Revert if a token not exist is revoked', async function () {
      const { ERC5727ExampleContract } = await loadFixture(deployTokenFixture)
      await expect(ERC5727ExampleContract.revoke(100)).be.reverted
    })

    it('Support Interface', async function () {
      const { ERC5727ExampleContract } = await loadFixture(deployTokenFixture)
      expect(await ERC5727ExampleContract.supportsInterface('0x35f61d8a')).to.equal(true)
      expect(await ERC5727ExampleContract.supportsInterface('0x3da384b4')).to.equal(true)
      expect(await ERC5727ExampleContract.supportsInterface('0x211ec300')).to.equal(true)
      expect(await ERC5727ExampleContract.supportsInterface('0x2a8cf5aa')).to.equal(true)
      expect(await ERC5727ExampleContract.supportsInterface('0x3ba738d1')).to.equal(true)
      expect(await ERC5727ExampleContract.supportsInterface('0xba3e1a9d')).to.equal(true)
      expect(await ERC5727ExampleContract.supportsInterface('0x379f4e66')).to.equal(true)
      expect(await ERC5727ExampleContract.supportsInterface('0x3475cd68')).to.equal(true)
      expect(await ERC5727ExampleContract.supportsInterface('0x3b741b9e')).to.equal(true)
    })
  })

  describe('ERC5727', function () {
    it('The information of a token can be correctly queried', async function () {
      const { ERC5727ExampleContract, owner, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )

      expect(await ERC5727ExampleContract.slotOf(0)).equal(1)
      expect(await ERC5727ExampleContract.soulOf(0)).equal(tokenOwnerSoul1.address)
      expect(await ERC5727ExampleContract.issuerOf(0)).equal(owner.address)
      expect(await ERC5727ExampleContract.isValid(0)).equal(true)
    })

    it('The information of the contract is correct', async function () {
      const { ERC5727ExampleContract } = await loadFixture(deployTokenFixture)
      expect(await ERC5727ExampleContract.name()).equal('Soularis')
      expect(await ERC5727ExampleContract.symbol()).equal('SOUL')
    })
  })

  describe('ERC5727Delegate', function () {
    it('Only contract owner can create or delete delegate request', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, voterSoul1 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul1.address, 1, 1)
      await expect(
        ERC5727ExampleContract.connect(voterSoul1).createDelegateRequest(
          tokenOwnerSoul1.address,
          1,
          1,
        ),
      ).be.reverted
      await expect(ERC5727ExampleContract.connect(voterSoul1).removeDelegateRequest(0)).be.reverted
      await ERC5727ExampleContract.removeDelegateRequest(0)
    })

    it('Only contract owner or delegate can delegate', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, delegateSoul1, delegateSoul2 } =
        await loadFixture(deployTokenFixture)
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul1.address, 1, 1)
      await ERC5727ExampleContract.mintDelegate(delegateSoul1.address, 0)
      await ERC5727ExampleContract.connect(delegateSoul1).mintDelegate(delegateSoul2.address, 0)
      await expect(
        ERC5727ExampleContract.connect(delegateSoul1).mintDelegate(delegateSoul2.address, 0),
      ).be.reverted

      await ERC5727ExampleContract.revokeDelegate(delegateSoul1.address, 0)
      await ERC5727ExampleContract.connect(delegateSoul1).revokeDelegate(delegateSoul2.address, 0)
      await expect(
        ERC5727ExampleContract.connect(delegateSoul1).revokeDelegate(delegateSoul2.address, 0),
      ).be.reverted
    })

    it('Only contract owner or delegate can mint or revoke', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, delegateSoul1 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul1.address, 1, 1)
      await ERC5727ExampleContract.mintDelegate(delegateSoul1.address, 0)
      await ERC5727ExampleContract.delegateMint(0)
      await ERC5727ExampleContract.delegateMint(0)
      await ERC5727ExampleContract.connect(delegateSoul1).delegateMint(0)
      await expect(ERC5727ExampleContract.connect(delegateSoul1).delegateMint(0)).be.reverted

      await ERC5727ExampleContract.revokeDelegate(delegateSoul1.address, 1)
      await ERC5727ExampleContract.delegateRevoke(0)
      await ERC5727ExampleContract.connect(delegateSoul1).delegateRevoke(1)
      await expect(ERC5727ExampleContract.connect(delegateSoul1).delegateRevoke(2)).be.reverted
    })

    it('Batch operations', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2, delegateSoul1 } =
        await loadFixture(deployTokenFixture)
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul1.address, 1, 1)
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul2.address, 1, 1)
      await ERC5727ExampleContract.mintDelegateBatch(
        [delegateSoul1.address, delegateSoul1.address],
        [0, 1],
      )
      await ERC5727ExampleContract.connect(delegateSoul1).delegateMintBatch([0, 1])
      await ERC5727ExampleContract.delegateRevokeBatch([0, 1])
    })

    it('Query of information of delegate request', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1 } = await loadFixture(deployTokenFixture)
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul1.address, 1, 1)
      expect(await ERC5727ExampleContract.soulOfDelegateRequest(0)).to.equal(
        tokenOwnerSoul1.address,
      )
      expect(await ERC5727ExampleContract.valueOfDelegateRequest(0)).to.equal(1)
      expect(await ERC5727ExampleContract.slotOfDelegateRequest(0)).to.equal(1)
    })

    it('Query for delegated requests or token of an operator', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2, delegateSoul1 } =
        await loadFixture(deployTokenFixture)
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul1.address, 1, 1)
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul2.address, 1, 1)
      await ERC5727ExampleContract.mintDelegateBatch(
        [delegateSoul1.address, delegateSoul1.address],
        [0, 1],
      )
      expect(await ERC5727ExampleContract.delegatedRequestsOf(delegateSoul1.address)).to.eql([
        ethers.BigNumber.from(0),
        ethers.BigNumber.from(1),
      ])
      await ERC5727ExampleContract.delegateMintBatch([0, 1])
      await ERC5727ExampleContract.revokeDelegateBatch(
        [delegateSoul1.address, delegateSoul1.address],
        [0, 1],
      )
      expect(await ERC5727ExampleContract.delegatedTokensOf(delegateSoul1.address)).to.eql([
        ethers.BigNumber.from(0),
        ethers.BigNumber.from(1),
      ])
    })
  })

  describe('ERC5727Enumerable', function () {
    it('EmittedCount, soulsCount, balance of a soul can be correctly queried', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )
      expect(await ERC5727ExampleContract.emittedCount()).equal(4)
      expect(await ERC5727ExampleContract.soulsCount()).equal(2)
      expect(await ERC5727ExampleContract.balanceOf(tokenOwnerSoul1.address)).equal(3)
      expect(await ERC5727ExampleContract.balanceOf(tokenOwnerSoul2.address)).equal(1)
    })

    it('Can correctly query if a soul holds valid tokens', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )
      await ERC5727ExampleContract.revoke(0)
      await ERC5727ExampleContract.revoke(3)
      expect(await ERC5727ExampleContract.hasValid(tokenOwnerSoul1.address)).equal(true)
      expect(await ERC5727ExampleContract.hasValid(tokenOwnerSoul2.address)).equal(false)
    })

    it('Can correctly query a token of a soul by index', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )
      expect(await ERC5727ExampleContract.tokenOfSoulByIndex(tokenOwnerSoul1.address, 0)).equal(0)
      expect(await ERC5727ExampleContract.tokenOfSoulByIndex(tokenOwnerSoul2.address, 0)).equal(3)
    })

    it('Revert when index overflows', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )
      await expect(ERC5727ExampleContract.tokenOfSoulByIndex(tokenOwnerSoul1.address, 3)).be
        .reverted
      await expect(ERC5727ExampleContract.tokenOfSoulByIndex(tokenOwnerSoul2.address, 1)).be
        .reverted
    })
  })

  describe('ERC5727Expirable', function () {
    it('Query expiry date of a token and revert if the date is not set', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )
      expect(await ERC5727ExampleContract.expiryDate(0)).equal(2664539263)
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul1.address, 1, 1)
      await ERC5727ExampleContract.delegateMint(0)
      await expect(ERC5727ExampleContract.expiryDate(4)).be.reverted
    })

    it('Query if a token is expired and revert if the date is not set', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )
      expect(await ERC5727ExampleContract.isExpired(0)).equal(false)
      await ERC5727ExampleContract.createDelegateRequest(tokenOwnerSoul1.address, 1, 1)
      await ERC5727ExampleContract.delegateMint(0)
      await expect(ERC5727ExampleContract.isExpired(4)).be.reverted
    })

    it('Revert when setting wrong expiry date', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )
      await expect(ERC5727ExampleContract.setExpiryDate(0, 100000)).be.reverted
      await expect(ERC5727ExampleContract.setExpiryDate(0, 2664539262)).be.reverted
    })
  })

  describe('ERC5727Governance', function () {
    it('Approve to mint a token and approve to revoke the token', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, voterSoul1, voterSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.createApprovalRequest(1, 1)
      await ERC5727ExampleContract.connect(voterSoul1).approveMint(tokenOwnerSoul1.address, 0)
      await expect(ERC5727ExampleContract.soulOf(0)).be.reverted
      await ERC5727ExampleContract.connect(voterSoul2).approveMint(tokenOwnerSoul1.address, 0)
      expect(await ERC5727ExampleContract.soulOf(0)).equal(tokenOwnerSoul1.address)
      expect(await ERC5727ExampleContract.isValid(0)).equal(true)
      await ERC5727ExampleContract.connect(voterSoul1).approveRevoke(0)
      await ERC5727ExampleContract.connect(voterSoul2).approveRevoke(0)
      expect(await ERC5727ExampleContract.isValid(0)).equal(false)
    })

    it('Revert when approving an approved request', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, voterSoul1 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.createApprovalRequest(1, 1)
      await ERC5727ExampleContract.connect(voterSoul1).approveMint(tokenOwnerSoul1.address, 0)
      await expect(
        ERC5727ExampleContract.connect(voterSoul1).approveMint(tokenOwnerSoul1.address, 0),
      ).be.reverted
      await ERC5727ExampleContract.connect(voterSoul1).approveRevoke(0)
      await expect(ERC5727ExampleContract.connect(voterSoul1).approveRevoke(0)).be.reverted
    })

    it('Revert when a soul other than the creator try to remove an approval request', async function () {
      const { ERC5727ExampleContract, voterSoul1 } = await loadFixture(deployTokenFixture)
      await ERC5727ExampleContract.connect(voterSoul1).createApprovalRequest(1, 1)
      await expect(ERC5727ExampleContract.removeApprovalRequest(0)).be.reverted
      await ERC5727ExampleContract.connect(voterSoul1).removeApprovalRequest(0)
    })

    it('Revert when trying to remove a non voter', async function () {
      const { ERC5727ExampleContract, delegateSoul1 } = await loadFixture(deployTokenFixture)
      await expect(ERC5727ExampleContract.removeVoter(delegateSoul1.address)).be.reverted
    })

    it('Revert when trying to add a current voter', async function () {
      const { ERC5727ExampleContract, voterSoul1 } = await loadFixture(deployTokenFixture)
      await expect(ERC5727ExampleContract.addVoter(voterSoul1.address)).be.reverted
    })

    it('Only contract owner can add or remove voters', async function () {
      const { ERC5727ExampleContract, voterSoul1 } = await loadFixture(deployTokenFixture)
      await expect(ERC5727ExampleContract.connect(voterSoul1).removeVoter(voterSoul1.address)).be
        .reverted
      await ERC5727ExampleContract.removeVoter(voterSoul1.address)
      await expect(ERC5727ExampleContract.connect(voterSoul1).addVoter(voterSoul1.address)).be
        .reverted
      await ERC5727ExampleContract.addVoter(voterSoul1.address)
    })

    it('Correctly get voters', async function () {
      const { ERC5727ExampleContract, voterSoul1, voterSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      expect(await ERC5727ExampleContract.voters()).eql([voterSoul1.address, voterSoul2.address])
    })
  })

  describe('ERC5727Shadow', function () {
    it('Only manager can shadow or reveal a token', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )
      await expect(ERC5727ExampleContract.connect(tokenOwnerSoul2).shadow(0)).be.reverted
      await ERC5727ExampleContract.connect(tokenOwnerSoul2).shadow(3)
      await ERC5727ExampleContract.shadow(0)
      await expect(ERC5727ExampleContract.connect(tokenOwnerSoul1).reveal(3)).be.reverted
      await ERC5727ExampleContract.connect(tokenOwnerSoul1).reveal(0)
      await ERC5727ExampleContract.reveal(3)
    })

    it('Only manager can query the shadowed information of a shadowed token', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        true,
      )
      await expect(ERC5727ExampleContract.connect(tokenOwnerSoul2).soulOf(0)).be.reverted
      await ERC5727ExampleContract.valueOf(3)
      await ERC5727ExampleContract.connect(tokenOwnerSoul2).valueOf(3)
      await ERC5727ExampleContract.slotOf(3)
      await ERC5727ExampleContract.connect(tokenOwnerSoul2).slotOf(3)
      await ERC5727ExampleContract.isShadowed(3)
      await ERC5727ExampleContract.connect(tokenOwnerSoul2).isShadowed(3)
    })
  })

  describe('ERC5727Recovery', function () {
    it('Successful recovery', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )

      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )

      const signature = await tokenOwnerSoul1.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.solidityPack(
              ['address', 'address'],
              [tokenOwnerSoul1.address, tokenOwnerSoul2.address],
            ),
          ),
        ),
      )

      await ERC5727ExampleContract.connect(tokenOwnerSoul2).recover(
        tokenOwnerSoul1.address,
        signature,
      )

      expect(await ERC5727ExampleContract.balanceOf(tokenOwnerSoul2.address)).to.equal(4)
    })

    it('Revert when the signature is invalid', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )

      await ERC5727ExampleContract.mintBatch(
        [
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul1.address,
          tokenOwnerSoul2.address,
        ],
        1,
        1,
        2664539263,
        false,
      )

      const signature = await tokenOwnerSoul1.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.solidityPack(
              ['address', 'address'],
              [tokenOwnerSoul1.address, tokenOwnerSoul2.address],
            ),
          ),
        ),
      )

      await expect(ERC5727ExampleContract.recover(tokenOwnerSoul1.address, signature)).to.be
        .reverted
    })

    it('Revert when no token can be recover', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )

      const signature = await tokenOwnerSoul1.signMessage(
        ethers.utils.arrayify(
          ethers.utils.keccak256(
            ethers.utils.solidityPack(
              ['address', 'address'],
              [tokenOwnerSoul1.address, tokenOwnerSoul2.address],
            ),
          ),
        ),
      )

      await expect(
        ERC5727ExampleContract.connect(tokenOwnerSoul2).recover(tokenOwnerSoul1.address, signature),
      ).to.be.reverted
    })
  })

  describe('ERC5727SlotEnumerable', function () {
    it('Query for slot information', async function () {
      const { ERC5727ExampleContract, tokenOwnerSoul1, tokenOwnerSoul2 } = await loadFixture(
        deployTokenFixture,
      )
      await ERC5727ExampleContract.mintBatch(
        [tokenOwnerSoul1.address, tokenOwnerSoul2.address],
        1,
        1,
        2664539263,
        false,
      )
      await ERC5727ExampleContract.mintBatch(
        [tokenOwnerSoul1.address, tokenOwnerSoul1.address, tokenOwnerSoul2.address],
        1,
        2,
        2664539263,
        false,
      )
      expect(await ERC5727ExampleContract.tokenSupplyInSlot(1)).to.equal(2)
      expect(await ERC5727ExampleContract.slotCount()).to.equal(2)
      expect(await ERC5727ExampleContract.slotByIndex(1)).to.equal(2)
      expect(await ERC5727ExampleContract.tokenInSlotByIndex(2, 2)).to.equal(4)
    })

    it('Revert when index overflows', async function () {
      const { ERC5727ExampleContract } = await loadFixture(deployTokenFixture)
      await expect(ERC5727ExampleContract.tokenInSlotByIndex(2, 3)).to.be.reverted
      await expect(ERC5727ExampleContract.slotByIndex(2)).to.be.reverted
    })
  })

  /*
  describe('ERC5727Model', function () {
    it('', async function (){
      const { ERC5727ExampleFactory, ERC5727ExampleContract, owner, tokenOwnerSoul1, tokenOwnerSoul2, voterSoul1, voterSoul2, delegateSoul1, delegateSoul2 } = await loadFixture(deployTokenFixture)
    })
  })
  */
})
