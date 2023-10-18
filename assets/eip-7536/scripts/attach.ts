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
import { IContracts, IContractAddresses } from './deploy.type';

let owner: SignerWithAddress;
let addrs: SignerWithAddress[];

export async function attach(): Promise<IContracts> {

    [owner, ...addrs] = await ethers.getSigners();

    if ( ! fs.existsSync(DEPLOY_CACHE)) {
        throw new Error('Contracts Not Deployed');
    }
    // saving the contract addresses
    let deployedContracts = JSON.parse(fs.readFileSync(DEPLOY_CACHE).toString());
    console.log(deployedContracts);

    let contractAddresses: IContractAddresses = deployedContracts[hre.network.name];
    let contracts = {
        distributor: (new Distributor__factory(owner)).attach(contractAddresses.distributor),
        validator: (new Validator__factory(owner)).attach(contractAddresses.validator),
        mock: {
            ERC20: (new MockERC20__factory(owner)).attach(contractAddresses.mock.ERC20),
            ERC721: (new MockERC721__factory(owner)).attach(contractAddresses.mock.ERC721)
        }
    }
    return contracts;
    }

    // We recommend this pattern to be able to use async/await everywhere
    // and properly handle errors.
    if (require.main === module){
        attach().catch((error) => {
            console.error(error);
            process.exitCode = 1;
    });
}
