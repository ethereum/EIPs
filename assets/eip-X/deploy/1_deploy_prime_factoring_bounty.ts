import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { Create2Factory } from '../src/Create2Factory'
import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'

const MAX_GAS_LIMIT_OPTION = { gasLimit: BigNumber.from('0x1c9c380') }

const deployPrimeFactoringBounty: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const provider = ethers.provider
  const from = await provider.getSigner().getAddress()
  await new Create2Factory(ethers.provider).deployFactory()

  const numberOfLocks = 119
  const primeByteLength = 128
  let gasUsed = BigNumber.from(0)

  const deployResult = await hre.deployments.deploy(
    'PrimeFactoringBountyWithRsaUfo', {
      ...MAX_GAS_LIMIT_OPTION,
      from,
      args: [numberOfLocks, primeByteLength],
      gasLimit: 6e6,
      deterministicDeployment: true
    })
  console.log('==PrimeFactoringBounty addr=', deployResult.address)
  gasUsed = gasUsed.add(deployResult.receipt?.gasUsed)

  const bounty = await ethers.getContractAt('PrimeFactoringBountyWithRsaUfo', deployResult.address)
  while (!(await bounty.generationIsDone())) {
    const tx = await bounty.triggerLockAccumulation()
    const receipt = await tx.wait()
    gasUsed = gasUsed.add(receipt.gasUsed)
  }
  console.log('==PrimeFactoringBounty gasUsed=', gasUsed.toHexString())
}

module.exports = deployPrimeFactoringBounty
module.exports.tags = ['PrimeFactoringBounty']
