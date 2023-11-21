import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { Create2Factory } from '../src/Create2Factory'
import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'
import * as fs from 'fs'

const MAX_GAS_LIMIT_OPTION = { gasLimit: BigNumber.from('0x1c9c380') }

const deployOrderFindingBounty: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const provider = ethers.provider
  const from = await provider.getSigner().getAddress()
  await new Create2Factory(ethers.provider).deployFactory()

  const numberOfLocks = 119
  const byteSizeOfModulus = 128 * 3
  const gcdIterationsPerCall = 2 ** 11
  let gasUsed = BigNumber.from(0)
  let maxGas = BigNumber.from(0)
  let numberOfAccumulations = 0

  const deployResult = await hre.deployments.deploy(
    'OrderFindingBountyWithLockGeneration', {
      ...MAX_GAS_LIMIT_OPTION,
      from,
      args: [numberOfLocks, byteSizeOfModulus, gcdIterationsPerCall],
      gasLimit: 6e6,
      deterministicDeployment: true
    })
  console.log('==OrderFindingBounty addr=', deployResult.address)
  gasUsed = gasUsed.add(deployResult.receipt?.gasUsed)

  const bounty = await ethers.getContractAt('OrderFindingBountyWithLockGeneration', deployResult.address)
  while (!(await bounty.callStatic.generationIsDone())) {
    ++numberOfAccumulations
    const tx = await bounty.triggerLockAccumulation(MAX_GAS_LIMIT_OPTION)
    const receipt = await tx.wait()
    gasUsed = gasUsed.add(receipt.gasUsed)
    if (receipt.gasUsed.gt(maxGas)) maxGas = receipt.gasUsed

    if (await bounty.callStatic.isCheckingPrime()) console.log('_b: ', (await bounty.currentPrimeCheck()))
  }

  console.log('==OrderFindingBounty gasUsed=', gasUsed.toHexString())
  console.log('==OrderFindingBounty maxGas=', maxGas.toHexString())
  const [modulus, base] = await bounty.getLock(0)
  console.log('Modulus: ', modulus)
  console.log('Base: ', base)
  console.log(`Number of accumulations: ${numberOfAccumulations}`)

  fs.writeFile(
    'Output.txt',
    `gasUsed: ${gasUsed.toHexString()};\n\nMax Gas: ${maxGas.toHexString()};\n\nModulus: ${modulus as string};\n\nBase: ${base as string};\n\nNumber of Accumulations: ${numberOfAccumulations}`,
    (err) => {
      if (err != null) throw err
    })
}

module.exports = deployOrderFindingBounty
module.exports.tags = ['OrderFindingBounty']
