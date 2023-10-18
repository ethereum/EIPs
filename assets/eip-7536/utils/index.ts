import { BytesLike, ethers } from 'ethers';
import { BigNumberish } from 'ethers';

// export type MintTuple = [string, BigNumberish, string, boolean, boolean, boolean, boolean];
export type CopyValidationTuple = [string, BigNumberish, BigNumberish, BigNumberish, BigNumberish];

export interface NftDescriptor {
  contractAddress: string,
  tokenId: BigNumberish,
}

export interface MintData {
    validator: string,
    descriptor: NftDescriptor,
    creatorActions: BytesLike[],
    collectorActions: BytesLike[]
}

export interface CopyValidationData {
    feeToken: string;
    mintAmount: BigNumberish;
    limit: BigNumberish;
    start: BigNumberish;
    time: BigNumberish;
}

export const getEncodedValidationData = (validationInfo: CopyValidationTuple) => {
return ethers.utils.defaultAbiCoder.encode(
    ['tuple(address, uint256, uint256, uint64, uint64)'],
    [validationInfo]
    );
};

export const getCopyValidationData = (data: CopyValidationData): CopyValidationTuple => {
    return [
      data.feeToken,
      data.mintAmount,
      data.limit,
      data.start,
      data.time
    ];
};

export const getNow = (): number => {
  return Math.floor(new Date().getTime() / 1000);
}

export const getDeadline = (seconds: number) => {
  return getNow() + seconds;
};