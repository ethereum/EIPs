import { bytes } from '../../solidityTypes'
import {
  OrderFindingBountyWithPredeterminedLocks,
  OrderFindingBountyWithPredeterminedLocks__factory
} from '../../../typechain'
import { ethers } from 'hardhat'
import { submitSolution } from '../bounty-utils'
import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { randomBytes } from 'crypto'

const HEX_PREFIX = '0x'

describe('Test the cost of solving the order finding bounty', () => {
  let bounty: OrderFindingBountyWithPredeterminedLocks

  const locks = [
    [
      '0xccda5ed8b7b0a45eb02d23b07e62f088fbe14781ce0baf896605957519c2e0cdf8206066d6d1f7acaddeea0a5edc97277998024a093ee70358aabcf322c0b748ea4ac0cd884344c55564ab5a9d6d6ac7f89e67f488e84a0e19d0ced4c89bc818a35735f1b563234aea4da7c09fc150e7317a2efcf7f0b1741bd85671650e3e927d2eee89c5556a6a37ed619a36178a1b6b8790c0ffdc6c0438eac646f533c6252e6e6766501ba0392adde287e0e1f83360e590c9caa155b1285c6cd4563ed0d7456d22919fe118090b9fd00c3714daebfa21f5216a76b1ee6b46f135b9670b5465b7a089c9d7aad3acd3fbd65f98c5e625914744c19690ff1299685307458cb0504d1f8283872bdac22cc5bdbc39778fdd3dd57e87b58fe64bdcb547675ff8f85688cb807e913b584b0e4b5123da438acc793a1c7de8e9b42607e39750faec17f0a245bfaed21a0c4da06e419c9c36b876e8c207564e194920fa694754df4c6615c57bf984aa879d79c07b7ae4cb525936ddd6755690347c3e040454a2feb511',
      '0x4ac7e1bccd690ac694c718ce779dc5dadeeee6825286ea188c9c0dedaf86faaf772128237f019611cb2fbf0ed29aa4165d3e1ac39312f8a16408bd362ba25c8603cbd364cfc71d380b4be892a6f686e19fdda3603264698c31fd3bb3ef069973e11ca4c1d19c4ae768195ce25955f7e41f0dc294a7e6f237886b80b9d4fde770ce54368a439e57665e4128b038a2d475a751e2e21b7d8b966298ba25e61dfa4bd6caf99fbea486168704a9d34056c1d99bdcc5ad8b21dd28ded5245c815a90650c21f26def86b336eed19e012e46a1fcf858ea516e36dccba3a5983216dc43edd3afd6e9cf1ef8437f69cc654507c965ddbd8bcfb0de20c6dbfc3f986a5f276f1c9ac944c11904c0568ab1d8c8819e064d30789db0de11b7afb91ed8c6351c5afd9b17ec08270236cfcc00766a06312cfd1bcfd0478e613045f89892ff8d093f345e2eabeefae620e155e026fb50c4f4fa0097149f3996a5d2c808d53e3cc7500d001c979b8677920d50835dee1ded126a684e13fb38b12c7d609dfda9bf2177'
    ]
  ]

  async function deployBounty (locks: bytes[][]): Promise<OrderFindingBountyWithPredeterminedLocks> {
    const ethersSigner = ethers.provider.getSigner()
    const bounty = await new OrderFindingBountyWithPredeterminedLocks__factory(ethersSigner).deploy(locks.length)
    for (let i = 0; i < locks.length; i++) {
      await bounty.setLock(i, locks[i])
    }
    return bounty
  }

  beforeEach(async () => {
    bounty = await deployBounty(locks)
  })

  it('should find the gas cost to attempt a 3071-bit base, 3072-bit modulus with various sized exponents', async () => {
    const gasCosts: BigNumber[] = []

    const byteSizeOfModulus = locks[0][0].length - HEX_PREFIX.length
    const maxOrderByteSize = 2 * byteSizeOfModulus

    for (let i = 1; i <= maxOrderByteSize; i++) {
      const solution = randomBytes(i)
      solution[0] = solution[0] | (1 << 7)

      const tx = submitSolution(0, solution, bounty)
      await expect(tx, `Base ${locks[0][1]} worked with exponent 0x${solution.toString('hex')}`).to.be.reverted

      const latestBlock = await ethers.provider.getBlock('latest')
      const latestTransactionHash = latestBlock.transactions[latestBlock.transactions.length - 1]
      const latestReceipt = await ethers.provider.getTransactionReceipt(latestTransactionHash)

      const gasUsed = latestReceipt.gasUsed
      console.log(`Gas for ${i}-byte solution is ${gasUsed.toHexString()}`)
      gasCosts.push(gasUsed)
    }

    const maxGas = gasCosts.reduce((acc, curr) => curr.lt(acc) ? curr : acc)
    const minGas = gasCosts.reduce((acc, curr) => curr.gt(acc) ? curr : acc)
    const meanGas = gasCosts.reduce((acc, curr) => acc.add(curr)).div(gasCosts.length)

    const sortedGasCosts = gasCosts.sort((a, b) => a.lt(b) ? -1 : 1)
    const halfIndex = maxOrderByteSize / 2
    const medianGas = halfIndex % 1 === 0
      ? sortedGasCosts[halfIndex].add(sortedGasCosts[halfIndex + 1]).div(2)
      : sortedGasCosts[Math.ceil(halfIndex)]
    console.log(`Min gas: ${minGas.toHexString()}`)
    console.log(`Max gas: ${maxGas.toHexString()}`)
    console.log(`Mean gas: ${meanGas.toHexString()}`)
    console.log(`Median gas: ${medianGas.toHexString()}`)
  })
})
