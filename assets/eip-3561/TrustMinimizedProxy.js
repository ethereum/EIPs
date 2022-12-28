const { loadFixture, mine } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { deployTrustMinimizedProxyFixture, trustMinimizedProxyWithMockLogicFixture } = require('./fixtures.js')

const ADMIN_SLOT = '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103'
const LOGIC_SLOT = '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc'
const NEXT_LOGIC_SLOT = '0x19e3fabe07b65998b604369d85524946766191ac9434b39e27c424c976493685'
const NEXT_LOGIC_BLOCK_SLOT = '0xe3228ec3416340815a9ca41bfee1103c47feb764b4f0f4412f5d92df539fe0ee'
const PROPOSE_BLOCK_SLOT = '0x4b50776e56454fad8a52805daac1d9fd77ef59e4f1a053c342aaae5568af1388'
const ZERO_TRUST_PERIOD_SLOT = '0x7913203adedf5aca5386654362047f05edbd30729ae4b0351441c46289146720'

let owner = {}
let otherAccount = {}
let trustMinimizedProxy = {}
let mockLogic = {}
let trustMinimizedProxyWithLogic = {}

describe('TrustMinimizedProxy', () => {
  beforeEach('deploy fixture', async () => {
    //prettier-ignore
    [trustMinimizedProxy, owner, otherAccount, mockLogic] = await loadFixture(deployTrustMinimizedProxyFixture)
  })
  describe('Initialization', () => {
    it('Slot addresses to call are valid', async () => {
      const tuples = [
        { _: ADMIN_SLOT, __: 'eip1967.proxy.admin' },
        { _: LOGIC_SLOT, __: 'eip1967.proxy.implementation' },
        { _: NEXT_LOGIC_SLOT, __: 'eip3561.proxy.next.logic' },
        { _: NEXT_LOGIC_BLOCK_SLOT, __: 'eip3561.proxy.next.logic.block' },
        { _: PROPOSE_BLOCK_SLOT, __: 'eip3561.proxy.propose.block' },
        { _: ZERO_TRUST_PERIOD_SLOT, __: 'eip3561.proxy.zero.trust.period' },
      ]
      for (let n = 0; n < tuples.length; n++) {
        let slot = await ethers.BigNumber.from(ethers.utils.keccak256(ethers.utils.toUtf8Bytes(tuples[n].__)))
          .sub(ethers.BigNumber.from(1))
          .toHexString()
        expect(slot).to.equal(tuples[n]._)
      }
    })
    it('Initial ADMIN_SLOT, LOGIC_SLOT, NEXT_LOGIC_SLOT, NEXT_LOGIC_BLOCK_SLOT, PROPOSE_BLOCK_SLOT, ZERO_TRUST_PERIOD_SLOT initial values', async () => {
      const adminAddress = ethers.utils.getAddress(ethers.utils.hexStripZeros(await ethers.provider.getStorageAt(trustMinimizedProxy.address, ADMIN_SLOT)))
      expect(adminAddress).to.equal(owner.address)
      const slotAddresses = [LOGIC_SLOT, NEXT_LOGIC_SLOT, NEXT_LOGIC_BLOCK_SLOT, PROPOSE_BLOCK_SLOT, ZERO_TRUST_PERIOD_SLOT]
      for (let n = 0; n < slotAddresses.length; n++) {
        let slotVal = await ethers.provider.getStorageAt(trustMinimizedProxy.address, slotAddresses[n])
        expect(slotVal).to.equal(ethers.constants.HashZero)
      }
    })
  })

  describe('changeAdmin(address newAdm)', () => {
    it('changes admin if called by admin', async () => {
      await expect(await trustMinimizedProxy.changeAdmin(otherAccount.address))
        .to.emit(trustMinimizedProxy, 'AdminChanged')
        .withArgs(owner.address, otherAccount.address)
      const adminAddress = ethers.utils.getAddress(ethers.utils.hexStripZeros(await ethers.provider.getStorageAt(trustMinimizedProxy.address, ADMIN_SLOT)))
      expect(adminAddress).to.equal(otherAccount.address)
    })
    it('fallbacks to proxy logic execution if called by not an admin', async () => {
      const tx = await trustMinimizedProxy.connect(otherAccount)['changeAdmin'](otherAccount.address)
      await expect(tx).not.to.be.reverted
      await expect(tx).to.not.emit(trustMinimizedProxy, 'AdminChanged')
    })
  })

  describe('upgrade(bytes calldata data)', () => {
    it('upgrades logic slot to next logic slot if called by admin', async () => {
      await trustMinimizedProxy.proposeTo(otherAccount.address, '0x')
      await trustMinimizedProxy.proposeTo(owner.address, '0x')
      await expect(await trustMinimizedProxy.upgrade('0x')).to.emit(trustMinimizedProxy, 'Upgraded')
      const logic = await ethers.provider.getStorageAt(trustMinimizedProxy.address, LOGIC_SLOT)
      const nextLogic = await ethers.provider.getStorageAt(trustMinimizedProxy.address, NEXT_LOGIC_SLOT)
      expect(logic).to.equal(nextLogic)
    })
    it('fallbacks to proxy logic execution if called by not an admin', async () => {
      const tx = await trustMinimizedProxy.connect(otherAccount).upgrade('0x')
      await expect(tx).not.to.be.reverted
      await expect(tx).to.not.emit(trustMinimizedProxy, 'Upgraded')
    })
    it('fails if zerotrustperiod was set and nextLogicBlock wasnt reached', async () => {
      await trustMinimizedProxy.proposeTo(owner.address, '0x')
      await trustMinimizedProxy.setZeroTrustPeriod(3)
      await expect(trustMinimizedProxy.upgrade('0x')).to.be.reverted
    })
    it('upgrades if zerotrustperiod was set and nextLogicBlock was reached', async () => {
      await trustMinimizedProxy.proposeTo(owner.address, '0x')
      await trustMinimizedProxy.setZeroTrustPeriod(3)
      await mine(3)
      await expect(trustMinimizedProxy.upgrade('0x')).not.to.be.reverted
    })
  })

  describe('cancelUpgrade()', () => {
    it('cancels upgrade if called by admin', async () => {
      await trustMinimizedProxy.proposeTo(otherAccount.address, '0x')
      await trustMinimizedProxy.proposeTo(owner.address, '0x')
      await expect(await trustMinimizedProxy.cancelUpgrade()).to.emit(trustMinimizedProxy, 'NextLogicCanceled')
      const logic = await ethers.provider.getStorageAt(trustMinimizedProxy.address, LOGIC_SLOT)
      const nextLogic = await ethers.provider.getStorageAt(trustMinimizedProxy.address, NEXT_LOGIC_SLOT)
      expect(logic).to.equal(nextLogic)
    })
    it('fallbacks to proxy logic execution if called by not an admin', async () => {
      const tx = await trustMinimizedProxy.connect(otherAccount).cancelUpgrade()
      await expect(tx).not.to.be.reverted
      await expect(tx).to.not.emit(trustMinimizedProxy, 'NextLogicCanceled')
    })
  })

  describe('prolongLock(uint b)', () => {
    it('increases PROPOSE_BLOCK_SLOT value if called by admin', async () => {
      const proposeBlockInitial = await ethers.provider.getStorageAt(trustMinimizedProxy.address, PROPOSE_BLOCK_SLOT)
      const arg = 1
      await expect(await trustMinimizedProxy.prolongLock(arg)).to.emit(trustMinimizedProxy, 'ProposingUpgradesRestrictedUntil')
      const proposeBlock = await ethers.provider.getStorageAt(trustMinimizedProxy.address, PROPOSE_BLOCK_SLOT)
      expect(ethers.BigNumber.from(proposeBlockInitial).add(ethers.BigNumber.from(arg))).to.equal(proposeBlock)
    })
    it('increases PROPOSE_BLOCK_SLOT value to max uint256 if called by admin', async () => {
      const proposeBlockInitial = await ethers.provider.getStorageAt(trustMinimizedProxy.address, PROPOSE_BLOCK_SLOT)
      const arg = ethers.constants.MaxUint256
      await expect(await trustMinimizedProxy.prolongLock(arg)).to.emit(trustMinimizedProxy, 'ProposingUpgradesRestrictedUntil')
      const proposeBlock = await ethers.provider.getStorageAt(trustMinimizedProxy.address, PROPOSE_BLOCK_SLOT)
      expect(ethers.BigNumber.from(proposeBlockInitial).add(ethers.BigNumber.from(arg))).to.equal(proposeBlock)
    })
    it('fallbacks to proxy logic execution if called by not an admin', async () => {
      const tx = await trustMinimizedProxy.connect(otherAccount).prolongLock(5)
      await expect(tx).not.to.be.reverted
      await expect(tx).to.not.emit(trustMinimizedProxy, 'ProposingUpgradesRestrictedUntil')
    })
    it('fails to increase to max uint256 after ZERO_TRUST_PERIOD was set', async () => {
      await trustMinimizedProxy.setZeroTrustPeriod(3)
      const arg = ethers.constants.MaxUint256
      await expect(trustMinimizedProxy.prolongLock(arg)).to.be.reverted
    })
  })

  describe('setZeroTrustPeriod(uint blocks)', () => {
    it('sets ZERO_TRUST_PERIOD_SLOT value', async () => {
      const valInitial = await ethers.provider.getStorageAt(trustMinimizedProxy.address, ZERO_TRUST_PERIOD_SLOT)
      const arg = 1
      await expect(await trustMinimizedProxy.setZeroTrustPeriod(arg)).to.emit(trustMinimizedProxy, 'ZeroTrustPeriodSet')
      const val = await ethers.provider.getStorageAt(trustMinimizedProxy.address, ZERO_TRUST_PERIOD_SLOT)
      expect(ethers.BigNumber.from(valInitial).add(ethers.BigNumber.from(arg))).to.equal(val)
    })
    it('fails to set ZERO_TRUST_PERIOD_SLOT value to max uint256', async () => {
      const valInitial = await ethers.provider.getStorageAt(trustMinimizedProxy.address, ZERO_TRUST_PERIOD_SLOT)
      const arg = ethers.constants.MaxUint256
      await expect(trustMinimizedProxy.setZeroTrustPeriod(arg)).to.be.reverted
      const val = await ethers.provider.getStorageAt(trustMinimizedProxy.address, ZERO_TRUST_PERIOD_SLOT)
      expect(valInitial).to.equal(val)
    })
    it('fallbacks to proxy logic execution if called by not an admin', async () => {
      const tx = await trustMinimizedProxy.connect(otherAccount).setZeroTrustPeriod(1)
      await expect(tx).not.to.be.reverted
      await expect(tx).to.not.emit(trustMinimizedProxy, 'ZeroTrustPeriodSet')
    })
    it('after ZEROTRUSTPERIOD was already set, sets ZERO_TRUST_PERIOD_SLOT value and if argument value is higher than previous', async () => {
      const arg = 3
      await expect(await trustMinimizedProxy.setZeroTrustPeriod(arg)).to.emit(trustMinimizedProxy, 'ZeroTrustPeriodSet')
      await expect(await trustMinimizedProxy.setZeroTrustPeriod(arg + 1)).to.emit(trustMinimizedProxy, 'ZeroTrustPeriodSet')
      const val = await ethers.provider.getStorageAt(trustMinimizedProxy.address, ZERO_TRUST_PERIOD_SLOT)
      expect(arg + 1).to.equal(parseInt(ethers.utils.hexStripZeros(val)))
    })
    it('after ZEROTRUSTPERIOD was set, fails to set if arg value is not above previous', async () => {
      await trustMinimizedProxy.setZeroTrustPeriod(3)
      const valInitial = await ethers.provider.getStorageAt(trustMinimizedProxy.address, ZERO_TRUST_PERIOD_SLOT)
      const arg = 1
      await expect(trustMinimizedProxy.setZeroTrustPeriod(arg)).to.be.reverted
    })
  })

  describe('proposeTo(address newLogic, bytes calldata data)', () => {
    it('upgrades if current logic is address 0', async () => {
      await expect(await trustMinimizedProxy.proposeTo(otherAccount.address, '0x')).to.emit(trustMinimizedProxy, 'Upgraded') //.withArgs(otherAccount.address)
      const logic = ethers.utils.getAddress(ethers.utils.hexStripZeros(await ethers.provider.getStorageAt(trustMinimizedProxy.address, LOGIC_SLOT)))
      expect(logic).to.equal(otherAccount.address)
    })
    it('fallbacks to proxy logic execution if called by not admin', async () => {
      const logicInit = await ethers.provider.getStorageAt(trustMinimizedProxy.address, LOGIC_SLOT)
      const tx = await trustMinimizedProxy.connect(otherAccount).proposeTo(owner.address, '0x')
      await expect(tx).not.to.be.reverted
      await expect(tx).to.not.emit(trustMinimizedProxy, 'NextLogicDefined')
      await expect(tx).to.not.emit(trustMinimizedProxy, 'Upgraded')
      const logic = await ethers.provider.getStorageAt(trustMinimizedProxy.address, LOGIC_SLOT)
      expect(logic).to.equal(logicInit)
    })
    it('fails to instantly upgrade if zero trust period is set and next logic block wasnt reached. Sets next logic instead', async () => {
      await trustMinimizedProxy.proposeTo(otherAccount.address, '0x')
      await trustMinimizedProxy.setZeroTrustPeriod(3)
      const logicSlotInitial = await ethers.provider.getStorageAt(trustMinimizedProxy.address, LOGIC_SLOT)
      const nextLogicSlotInitial = await ethers.provider.getStorageAt(trustMinimizedProxy.address, NEXT_LOGIC_SLOT)
      const tx = await trustMinimizedProxy.proposeTo(otherAccount.address, '0x')
      await expect(tx).to.emit(trustMinimizedProxy, 'NextLogicDefined')
      const logicSlotCurrent = await ethers.provider.getStorageAt(trustMinimizedProxy.address, LOGIC_SLOT)
      const nextLogicSlotCurrent = await ethers.provider.getStorageAt(trustMinimizedProxy.address, NEXT_LOGIC_SLOT)
      expect(logicSlotCurrent).to.equal(logicSlotInitial)
      expect(nextLogicSlotCurrent).to.not.equal(nextLogicSlotInitial)
    })
    it('sets next logic if zero trust period is set and next logic block was reached', async () => {
      await trustMinimizedProxy.proposeTo(otherAccount.address, '0x')
      await trustMinimizedProxy.setZeroTrustPeriod(3)
      await mine(3)
      await expect(await trustMinimizedProxy.proposeTo(otherAccount.address, '0x')).to.emit(trustMinimizedProxy, 'NextLogicDefined')
      const logic = ethers.utils.getAddress(ethers.utils.hexStripZeros(await ethers.provider.getStorageAt(trustMinimizedProxy.address, NEXT_LOGIC_SLOT)))
      expect(logic).to.equal(otherAccount.address)
    })
  })
})

describe('MockLogic', () => {
  beforeEach('deploy fixture', async () => {
    ;[trustMinimizedProxy, trustMinimizedProxyWithLogic, owner, otherAccount] = await loadFixture(trustMinimizedProxyWithMockLogicFixture)
    trustMinimizedProxyWithLogic = trustMinimizedProxyWithLogic.connect(otherAccount)
    trustMinimizedProxy = trustMinimizedProxy.connect(otherAccount)
  })
  describe('init(address _governance)', () => {
    it('initializes correct governance and sets ini to true, state stays 0', async () => {
      expect(await trustMinimizedProxyWithLogic.governance()).to.equal(otherAccount.address)
      expect(await trustMinimizedProxyWithLogic.ini()).to.equal(true)
      expect(await trustMinimizedProxyWithLogic.state()).to.equal(0)
    })
    it('cant be initialized twice', async () => {
      await expect(trustMinimizedProxyWithLogic.init(otherAccount.address)).to.be.reverted
    })
  })
  describe('changeMockLogicState(uint _state)', () => {
    it('reverts if called by admin', async () => {
      trustMinimizedProxyWithLogic = trustMinimizedProxyWithLogic.connect(owner)
      await expect(trustMinimizedProxyWithLogic.changeState(6)).to.be.reverted
    })
    it('changes state', async () => {
      expect(await trustMinimizedProxyWithLogic.changeState(6)).not.to.be.reverted
      expect(await trustMinimizedProxyWithLogic.state()).to.equal(6)
    })
  })
  describe('fallback()', () => {
    it('fallbacks if not admin calls proxy functions', async () => {
      const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('FallbackTriggered(address)'))
      const lowerCaseAddress = otherAccount.address.toLowerCase()
      const fnNames = ['cancelUpgrade', 'changeAdmin', 'upgrade', 'prolongLock', 'setZeroTrustPeriod', 'proposeTo']
      const args = [null, [otherAccount.address], ['0x'], [5], [5], [otherAccount.address, '0x']]
      let tx
      for (let n = 0; n < fnNames.length; n++) {
        args[n] == null ? (tx = await trustMinimizedProxy[fnNames[n]]()) : (tx = await trustMinimizedProxy[fnNames[n]](...args[n]))
        let receipt = await tx.wait()
        expect(receipt.logs[0].topics[0]).to.equal(hash)
        expect(ethers.utils.hexStripZeros(receipt.logs[0].topics[1])).to.equal(lowerCaseAddress)
      }
    })
  })
})
