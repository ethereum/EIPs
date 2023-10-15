import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { ACTION, CONTENT } from '../utils/constants';

import {
    getCopyValidationData,
    getEncodedValidationData,
    getNow
} from '../utils';

import { deploy } from '../scripts/deploy';
import { IContracts } from '../scripts/deploy.type';

describe('DISTRIBUTOR Contract', () => {
    
    let owner: SignerWithAddress;
    let addr1: SignerWithAddress;
    let addr2: SignerWithAddress;
    let addrs: SignerWithAddress[];

    let contracts: IContracts;

    before(async function () {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        contracts = await deploy();
    });

    describe('end-to-end tests', async () => {

        it('Parent token holder should be able to set up an edition for collectors to mint child tokens', async ()=> {

            // mint a token
            await contracts.mock.ERC721.connect(addr1).create(
                addr1.address,
                CONTENT
            );
            
            // get creator Id
            let balance = (await contracts.mock.ERC721.balanceOf(addr1.address)).toNumber();
            let creatorId = (await contracts.mock.ERC721.tokenOfOwnerByIndex(addr1.address, balance-1)).toString();

            let valInfo = getCopyValidationData({
                feeToken: contracts.mock.ERC20.address,
                mintAmount: 10000000000,
                limit: 3,
                start: getNow()-1000,
                time: 99999999999999
            });

            await expect(contracts.distributor.connect(addr1).setEdition(
                contracts.mock.ERC721.address,
                creatorId,
                contracts.validator.address,
                ACTION.TRANSFER + ACTION.UPDATE + ACTION.REVOKE, // actions
                getEncodedValidationData(valInfo) // data
            )).to.not.be.reverted;
            
            // original balance
            let walletBalance = await contracts.mock.ERC20.balanceOf(addr2.address);

            // copier go get some mockFT
            await contracts.mock.ERC20.connect(addr2).mint(addr2.address, 20000000000);

            // check balance
            expect((await contracts.mock.ERC20.balanceOf(addr2.address)).toNumber()).to.eq(walletBalance.add(20000000000));
            
            // set allowance
            await contracts.mock.ERC20.connect(addr2).approve(contracts.validator.address, 10000000000);
            
            // get the copyHash
            let copyHash = (await contracts.distributor.getEditionHashes(
                contracts.mock.ERC721.address,
                creatorId
            ))[0];

            // get a copy
            await contracts.distributor.connect(addr2).mint(addr2.address, copyHash);
            
            // get copy Id
            let copyBalance = (await contracts.distributor.balanceOf(addr2.address)).toNumber();
            expect(copyBalance).to.gt(0);
            let copyId = (await contracts.distributor.tokenByIndex(copyBalance-1)).toString();

            // check balance after transaction
            expect((await contracts.mock.ERC20.balanceOf(addr2.address)).toNumber()).to.eq(walletBalance.add(10000000000));
            
            // check copy NFT data
            expect(await contracts.distributor.tokenURI(copyId)).to.eq(CONTENT);

            // check update
            await contracts.distributor.connect(addr2).update(copyId);

            // check transfer
            await contracts.distributor.connect(addr2).transferFrom(addr2.address, addr1.address, copyId);

            // check revoke
            await contracts.distributor.connect(addr1).revoke(copyId);

        })

    })
})