import { BigNumber } from "ethers";
import { ERC3525BurnableUpgradeable } from "../../typechain";

export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
export const ZERO_TOKEN_ID = 0;

export interface TokenData {
  id: BigNumber;
  slot: BigNumber;
  balance: BigNumber;
  owner: string;
  erc3525: ERC3525BurnableUpgradeable;
}

export interface TransferEvent {
  from: string;
  to: string;
  tokenId: BigNumber;
}

export interface TransferValueEvent {
  fromTokenId: BigNumber;
  toTokenId: BigNumber;
  value: BigNumber;
}
