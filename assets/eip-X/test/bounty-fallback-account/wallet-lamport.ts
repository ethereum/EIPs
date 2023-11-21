import { Wallet } from 'ethers'
import { generateLamportKeys, hashMessageWithEthHeader, LamportKeys, signMessageLamport } from './lamport-utils'
import { ecsign, toRpcSig } from 'ethereumjs-util'
import { arrayify } from 'ethers/lib/utils'

export class WalletLamport {
  public readonly baseWallet: Wallet
  public lamportKeys: LamportKeys
  public lamportKeysNext: LamportKeys

  private readonly _getNewLamportKeys: () => LamportKeys

  constructor (baseWallet: Wallet, numberOfTests: number, testSizeInBytes: number) {
    this.baseWallet = baseWallet

    this._getNewLamportKeys = () => generateLamportKeys(numberOfTests, testSizeInBytes)
    this.lamportKeysNext = this._getNewLamportKeys()
    this._updateLamportKeys()
  }

  public signMessageLamport (message: string): Buffer {
    const signature = this._getFullSignature(message)
    this._updateLamportKeys()
    return signature
  }

  private _getFullSignature (message: string): Buffer {
    const messageWithEthHeader = hashMessageWithEthHeader(message)
    const signatureLamport = signMessageLamport(messageWithEthHeader, this.lamportKeys.secretKeys)
    const signatureEcdsa = this._signMessageEcdsa(messageWithEthHeader)
    return Buffer.concat([
      Buffer.from(arrayify(signatureEcdsa)),
      signatureLamport,
      ...this.lamportKeysNext.publicKeys.flat()
    ])
  }

  private _signMessageEcdsa (message: Buffer): string {
    const sig = ecsign(message, Buffer.from(arrayify(this.baseWallet.privateKey)))
    return toRpcSig(sig.v, sig.r, sig.s)
  }

  private _updateLamportKeys (): void {
    this.lamportKeys = this.lamportKeysNext
    this.lamportKeysNext = this._getNewLamportKeys()
  }
}
