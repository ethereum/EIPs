import { UserOperation } from '../UserOperation'
import { getUserOpHash } from '../UserOp'
import { WalletLamport } from './wallet-lamport'

export function signUserOpLamport (op: UserOperation, signer: WalletLamport, entryPoint: string, chainId: number): UserOperation {
  const message = getUserOpHash(op, entryPoint, chainId)
  return {
    ...op,
    signature: signer.signMessageLamport(message)
  }
}
