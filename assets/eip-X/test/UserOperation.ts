import * as typ from './solidityTypes'

export interface UserOperation {

  sender: typ.address
  nonce: typ.uint256
  initCode: typ.bytes
  callData: typ.bytes
  callGasLimit: typ.uint256
  verificationGasLimit: typ.uint256
  preVerificationGas: typ.uint256
  maxFeePerGas: typ.uint256
  maxPriorityFeePerGas: typ.uint256
  paymasterAndData: typ.bytes
  signature: typ.bytes
}
