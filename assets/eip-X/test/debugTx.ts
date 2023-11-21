import { ethers } from 'hardhat'

export interface DebugLog {
  pc: number
  op: string
  gasCost: number
  depth: number
  stack: string[]
  memory: string[]
}

export interface DebugTransactionResult {
  gas: number
  failed: boolean
  returnValue: string
  structLogs: DebugLog[]
}

export async function debugTransaction (txHash: string, disableMemory = true, disableStorage = true): Promise<DebugTransactionResult> {
  const debugTx = async (hash: string): Promise<DebugTransactionResult> => await ethers.provider.send('debug_traceTransaction', [hash, {
    disableMemory,
    disableStorage
  }])

  return await debugTx(txHash)
}
