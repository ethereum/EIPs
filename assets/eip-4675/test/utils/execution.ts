import { Contract, Wallet, utils, BigNumber, BigNumberish, Signer, PopulatedTransaction } from "ethers"
import { TypedDataSigner } from "@ethersproject/abstract-signer";
import { AddressZero } from "@ethersproject/constants";

interface transOption {
    from: string;
    gas: BigInteger
}

export const addToken = async (MFNFT: Contract, token: string, tokenId: BigNumberish, totalSupply: BigNumberish, options: any = {}): Promise<any> => {
    const tAddr = token || AddressZero;
    const tId = tokenId || 1;
    const tSupply = totalSupply || 1000;

    options.from == null ? options = null : (MFNFT = MFNFT.connect(options.from), options = null);

    return MFNFT.setParentNFT(tAddr, tId, tSupply, options);
}


export const safeTransferFrom = async (NFT: Contract, from: string, to: string, tokenId: BigNumberish) => {
    return await NFT["safeTransferFrom(address,address,uint256)"](from, to, tokenId)
}

export const transfer = async (MFNFT: Contract, to: string, _id: BigNumberish, value: BigNumberish, options: any = {}) => {
    options.from == null ? options = null : (MFNFT = MFNFT.connect(options.from), options = null);
    
    return await MFNFT.transfer(to, _id, value)
}

export const transferFrom = async (MFNFT: Contract, from: string, to: string, _id: BigNumberish, value: BigNumberish, options: any = {}) => {
    options.from == null ? options = null : (MFNFT = MFNFT.connect(options.from), options = null);
    
    return await MFNFT.transferFrom(from, to, _id, value)
}

export const balanceOf = async (MFNFT: Contract, owner: string, _id: BigNumberish) => {
    return await MFNFT.balanceOf(owner, _id)
}

export const approve = async (MFNFT: Contract, spender: string, tokenId: BigNumberish, value: BigNumberish) => {
    return await MFNFT.approve(spender, tokenId, value)
}

export const increaseAllowance = async (MFNFT: Contract, spender: string, tokenId: BigNumberish, value: BigNumberish) => {
    return await MFNFT.increaseAllowance(spender, tokenId, value)
}

export const decreaseAllowance = async (MFNFT: Contract, spender: string, tokenId: BigNumberish, value: BigNumberish) => {
    return await MFNFT.decreaseAllowance(spender, tokenId, value)
}