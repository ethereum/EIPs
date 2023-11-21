import { Signer } from 'ethers'
import {
  BountyFallbackAccount,
  BountyFallbackAccount__factory,
  BountyFallbackAccountFactory,
  BountyFallbackAccountFactory__factory
} from '../../typechain'
import { WalletLamport } from './wallet-lamport'
import { createAccountOwner } from '../testutils'
import { DEFAULT_NUMBER_OF_TESTS_LAMPORT, DEFAULT_TEST_SIZE_IN_BYTES_LAMPORT } from './lamport-utils'
import { address } from '../solidityTypes'
import { ethers } from 'hardhat'

// create non-random account, so gas calculations are deterministic
export function createAccountOwnerLamport (numberOfTests: number = DEFAULT_NUMBER_OF_TESTS_LAMPORT, testSizeInBytes: number = DEFAULT_TEST_SIZE_IN_BYTES_LAMPORT, privateKey?: string): WalletLamport {
  const wallet = privateKey == null ? createAccountOwner() : new ethers.Wallet(privateKey, ethers.provider)
  return new WalletLamport(wallet, numberOfTests, testSizeInBytes)
}

// Deploys an implementation and a proxy pointing to this implementation
export async function createAccountLamport (
  ethersSigner: Signer,
  accountOwner: string,
  lamportKey: Buffer[][],
  bountyContractAddress: address,
  entryPoint: string,
  _factory?: BountyFallbackAccountFactory
):
  Promise<{
    proxy: BountyFallbackAccount
    accountFactory: BountyFallbackAccountFactory
    implementation: string
  }> {
  const accountFactory = _factory ?? await new BountyFallbackAccountFactory__factory(ethersSigner).deploy(entryPoint)
  const implementation = await accountFactory.accountImplementation()
  await accountFactory.createAccount(accountOwner, 0, lamportKey, bountyContractAddress)
  const accountAddress = await accountFactory.getAddress(accountOwner, 0, lamportKey, bountyContractAddress)
  const proxy = BountyFallbackAccount__factory.connect(accountAddress, ethersSigner)
  return {
    implementation,
    accountFactory,
    proxy
  }
}
