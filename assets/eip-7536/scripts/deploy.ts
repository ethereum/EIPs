import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from "hardhat";
import hre from 'hardhat'
import fs from 'fs';
import {
  Validator__factory,
  Distributor__factory,
  MockERC20__factory,
  MockERC721__factory
} from "../typechain-types";

import { DEPLOY_CACHE } from '../utils/constants';
import { IContracts } from './deploy.type';

let owner: SignerWithAddress;
let addrs: SignerWithAddress[];

export async function deploy(isMain=false): Promise<IContracts> {

  [owner, ...addrs] = await ethers.getSigners();
  
  // deploy copy contract
  let distributorContract = await new Distributor__factory(owner).deploy("Collection", "COL");

  // deploy validator
  let validatorContract = await new Validator__factory(owner).deploy(distributorContract.address);

  // deploy test contracts
  let mockFT = await new MockERC20__factory(owner).deploy("MOCK_USDT", "MUSDT");
  let mockNFT = await new MockERC721__factory(owner).deploy("MOCK_NFT", "MNFT");

  let contracts = {
    distributor: distributorContract,
    validator: validatorContract,
    mock: {
      ERC20: mockFT,
      ERC721: mockNFT
    }
  }
  
  let contractAddresses = {
    distributor: distributorContract.address,
    validator: validatorContract.address,
    test: {
      mockFT: mockFT.address,
      mockNFT: mockNFT.address
    }
  }

  // saving the contract addresses
  let deployedContracts: Record<string, any> = {};
  if (fs.existsSync(DEPLOY_CACHE)) {
    deployedContracts = JSON.parse(fs.readFileSync(DEPLOY_CACHE).toString());
    deployedContracts[hre.network.name] = contractAddresses;
  } else {
    deployedContracts = {
      [hre.network.name]: contractAddresses
    }
  }
  fs.writeFileSync(DEPLOY_CACHE, JSON.stringify(deployedContracts));
  if (isMain) console.log(deployedContracts);

  return contracts; 
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module){
  deploy(true).catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
