import { OrderFindingAccumulatorTestHelper, OrderFindingAccumulatorTestHelper__factory } from '../../../../typechain'
import { ethers } from 'hardhat'
import { arrayify } from 'ethers/lib/utils'
import { expect } from 'chai'
import { Buffer } from 'buffer'
import { BigNumber } from 'ethers'

const EMPTY_BYTES = '0x'

describe('OrderFindingAccumulator', () => {
  const ethersSigner = ethers.provider.getSigner()

  let testHelper: OrderFindingAccumulatorTestHelper

  async function accumulator (): Promise<any> {
    return await testHelper.accumulator()
  }

  async function deployNewAccumulator (
    numberOfLocks: number,
    bytesPerPrime: number,
    gcdIterationsPerCall: number = 1
  ): Promise<OrderFindingAccumulatorTestHelper> {
    return await new OrderFindingAccumulatorTestHelper__factory(ethersSigner).deploy(numberOfLocks, bytesPerPrime, gcdIterationsPerCall)
  }

  async function expectDone (expectedValue: boolean): Promise<void> {
    expect((await accumulator()).generationIsDone).to.be.eq(expectedValue)
  }

  async function expectLockParameter (lockNumber: number, lockParameterNumber: number, expectedValue: string): Promise<void> {
    expect((await accumulator()).locks.vals[lockNumber][lockParameterNumber]).to.be.eq(expectedValue)
  }

  async function expectLock (lockNumber: number, expectedValues: string[]): Promise<void> {
    for (let i = 0; i < (await accumulator()).parametersPerLock; i++) {
      await expectLockParameter(lockNumber, i, expectedValues[i])
    }
  }

  async function accumulateValues (hexStrings: string[]): Promise<void> {
    for (const hexString of hexStrings) {
      await accumulateValueWithoutWaitingForPrimeCheck(hexString)
      while ((await testHelper.callStatic.isCheckingPrime())) {
        await testHelper.triggerAccumulate([])
      }
    }
  }

  async function accumulateValueWithoutWaitingForPrimeCheck (hexString: string): Promise<void> {
    await testHelper.triggerAccumulate(Buffer.from(arrayify(hexString)))
  }

  describe('multiple gcd iterations', () => {
    const modulus = '0x81'
    const base = '0x02'

    async function deployNewAccumulatorWithSetGcdIterations (gcdIterationsPerCall: number): Promise<void> {
      const numberOfLocks = 1
      const bytesPerPrime = 1
      testHelper = await deployNewAccumulator(numberOfLocks, bytesPerPrime, gcdIterationsPerCall)
      await initializeByteValues()
    }

    async function initializeByteValues (): Promise<void> {
      const arbitraryValueToTriggerGcdProcess = EMPTY_BYTES
      for (const val of [modulus, base, arbitraryValueToTriggerGcdProcess]) {
        await accumulateValueWithoutWaitingForPrimeCheck(val)
      }
    }

    async function expectGcdProcessHasBegun (): Promise<void> {
      const currentA = BigNumber.from((await testHelper.accumulator())._a.val)
      expect(currentA.eq(modulus)).to.eq(false)
    }

    async function expectProperties (isCheckingPrime: boolean, expectedBase: string): Promise<void> {
      expect(await testHelper.callStatic.isCheckingPrime()).to.eq(isCheckingPrime)
      await expectLockParameter(0, 1, expectedBase)
    }

    it('should not finish with 1 gcd iteration', async () => {
      await deployNewAccumulatorWithSetGcdIterations(1)
      await expectGcdProcessHasBegun()
      await expectProperties(true, EMPTY_BYTES)
    })

    it('should finish with exactly enough gcd iteration', async () => {
      await deployNewAccumulatorWithSetGcdIterations(3)
      await expectProperties(false, base)
    })

    it('should finish with more than enough gcd iterations', async () => {
      await deployNewAccumulatorWithSetGcdIterations(4)
      await expectProperties(false, base)
    })
  })

  describe('modulus and base', () => {
    describe('single accumulations', () => {
      beforeEach(async () => {
        const numberOfLocks = 1
        const bytesPerPrime = 1
        testHelper = await deployNewAccumulator(numberOfLocks, bytesPerPrime)
      })

      describe('ensure the base is between 1 and -1', () => {
        beforeEach(async () => {
          await accumulateValues(['0x81'])
          await expectLockParameter(0, 0, '0x81')
        })

        it('should only accept a base that is coprime with the modulus', async () => {
          await accumulateValues(['0x06'])
          await expectLockParameter(0, 1, EMPTY_BYTES)
          await accumulateValues(['0x02'])
          await expectLockParameter(0, 1, '0x02')
        })

        it('should modulo the base if it is greater than the modulus', async () => {
          await accumulateValues(['0x83'])
          await expectLockParameter(0, 1, '0x02')
        })

        it('should not accept a base equal to -1', async () => {
          await accumulateValues(['0x80'])
          await expectLockParameter(0, 1, EMPTY_BYTES)
        })

        it('should not accept a base equal to 1', async () => {
          await accumulateValues(['0x01'])
          await expectLockParameter(0, 1, EMPTY_BYTES)
        })
      })

      describe('setting the first bit of the modulus', () => {
        it('should leave first bit of the modulus unchanged if already one', async () => {
          await accumulateValues(['0x81'])
          await expectLockParameter(0, 0, '0x81')
        })

        it('should set first bit of the modulus to one if zero', async () => {
          await accumulateValues(['0x02'])
          await expectLockParameter(0, 0, '0x82')
        })
      })

      it('should not set the first bit of the base', async () => {
        await accumulateValues(['0x81', '0x02'])
        await expectLockParameter(0, 1, '0x02')
      })
    })

    it('should not set the first bit of subsequent accumulations of the modulus', async () => {
      const numberOfLocks = 1
      const bytesPerPrime = 2
      testHelper = await deployNewAccumulator(numberOfLocks, bytesPerPrime)
      await accumulateValues(['0x81', '0x02'])
      await expectLockParameter(0, 0, '0x8102')
    })
  })

  describe('exact right size input', () => {
    beforeEach(async () => {
      const numberOfLocks = 1
      const bytesPerPrime = 1
      testHelper = await deployNewAccumulator(numberOfLocks, bytesPerPrime)
      await accumulateValues(['0xf5', '0x3d'])
    })

    it('should be marked as done', async () => {
      await expectDone(true)
    })

    it('should have a lock matching the input', async () => {
      await expectLock(0, ['0xf5', '0x3d'])
    })
  })

  describe('slicing off extra bytes', () => {
    beforeEach(async () => {
      const numberOfLocks = 1
      const bytesPerPrime = 1
      testHelper = await deployNewAccumulator(numberOfLocks, bytesPerPrime)
      await accumulateValues(['0xf5d4', '0x3d8c'])
    })

    it('should be marked as done', async () => {
      await expectDone(true)
    })

    it('should have a lock with only the necessary bytes', async () => {
      await expectLock(0, ['0xf5', '0x3d'])
    })
  })

  describe('multiple accumulations per lock', () => {
    beforeEach(async () => {
      const numberOfLocks = 1
      const bytesPerPrime = 2
      testHelper = await deployNewAccumulator(numberOfLocks, bytesPerPrime)
      await accumulateValues(['0xf5', '0x3d', '0x8c'])
    })

    describe('first accumulation', () => {
      it('should not be marked as done', async () => {
        await expectDone(false)
      })

      it('should have only the first parameter of the first lock', async () => {
        await expectLockParameter(0, 0, '0xf53d')
        await expectLockParameter(0, 1, EMPTY_BYTES)
      })
    })

    describe('second accumulation', () => {
      beforeEach(async () => {
        await accumulateValues(['0x00'])
      })

      it('should be marked as done', async () => {
        await expectDone(true)
      })

      it('should have a lock equal to both inputs', async () => {
        await expectLockParameter(0, 0, '0xf53d')
        await expectLockParameter(0, 1, '0x8c00')
      })
    })
  })

  describe('multiple locks', () => {
    beforeEach(async () => {
      const numberOfLocks = 2
      const bytesPerPrime = 1
      testHelper = await deployNewAccumulator(numberOfLocks, bytesPerPrime)
      await accumulateValues(['0xf5', '0x3d'])
    })

    describe('first accumulation', () => {
      it('should not be marked as done', async () => {
        await expectDone(false)
      })

      it('should have the first lock equal to the input', async () => {
        await expectLock(0, ['0xf5', '0x3d'])
      })

      it('should not have a second lock', async () => {
        expect((await accumulator()).locks.vals[1]).to.eql([])
      })
    })

    describe('second accumulation', () => {
      beforeEach(async () => {
        await accumulateValues(['0x8c', '0x03'])
      })

      it('should be marked as done', async () => {
        await expectDone(true)
      })

      it('should have the first lock equal to the first input', async () => {
        await expectLock(0, ['0xf5', '0x3d'])
      })

      it('should have the second lock equal to the second input', async () => {
        await expectLock(1, ['0x8c', '0x03'])
      })
    })
  })

  describe('already done', () => {
    beforeEach(async () => {
      const numberOfLocks = 1
      const bytesPerPrime = 1
      testHelper = await deployNewAccumulator(numberOfLocks, bytesPerPrime)
      await accumulateValues(['0xf5', '0x3d'])
    })

    describe('first accumulation', () => {
      it('should be marked as done', async () => {
        await expectDone(true)
      })

      it('should have the first lock equal to the input', async () => {
        await expectLock(0, ['0xf5', '0x3d'])
      })
    })

    describe('unnecessary, additional accumulation', () => {
      beforeEach(async () => {
        await accumulateValues(['0x8c', '0x00'])
      })

      it('should be marked as done', async () => {
        await expectDone(true)
      })

      it('should have the first lock equal to the first input', async () => {
        await expectLock(0, ['0xf5', '0x3d'])
      })
    })
  })
})
