import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { MultiResourceTokenMock, MultiResourceRenderUtils } from '../typechain-types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

function bn(x: number): BigNumber {
  return BigNumber.from(x);
}

async function resourcesFixture() {
  const multiresourceFactory = await ethers.getContractFactory('MultiResourceTokenMock');
  const renderUtilsFactory = await ethers.getContractFactory('MultiResourceRenderUtils');

  const multiresource = await multiresourceFactory.deploy('Chunky', 'CHNK');
  await multiresource.deployed();

  const renderUtils = await renderUtilsFactory.deploy();
  await renderUtils.deployed();

  return { multiresource, renderUtils };
}

describe('Render Utils', async function () {
  let owner: SignerWithAddress;
  let multiresource: MultiResourceTokenMock;
  let renderUtils: MultiResourceRenderUtils;
  let tokenId: number;

  const resId = bn(1);
  const resId2 = bn(2);
  const resId3 = bn(3);
  const resId4 = bn(4);

  before(async function () {
    ({ multiresource, renderUtils } = await loadFixture(resourcesFixture));

    const signers = await ethers.getSigners();
    owner = signers[0];

    tokenId = 1;
    await multiresource.mint(owner.address, tokenId);
    await multiresource.addResourceEntry(resId, 'ipfs://res1.jpg');
    await multiresource.addResourceEntry(resId2, 'ipfs://res2.jpg');
    await multiresource.addResourceEntry(resId3, 'ipfs://res3.jpg');
    await multiresource.addResourceEntry(resId4, 'ipfs://res4.jpg');
    await multiresource.addResourceToToken(tokenId, resId, 0);
    await multiresource.addResourceToToken(tokenId, resId2, 0);
    await multiresource.addResourceToToken(tokenId, resId3, resId);
    await multiresource.addResourceToToken(tokenId, resId4, 0);

    await multiresource.acceptResource(tokenId, 0, resId);
    await multiresource.acceptResource(tokenId, 1, resId2);
    await multiresource.setPriority(tokenId, [10, 5]);
  });

  describe('Render Utils MultiResource', async function () {
    it('can get active resources', async function () {
      expect(await renderUtils.getActiveResources(multiresource.address, tokenId)).to.eql([
        [resId, 10, 'ipfs://res1.jpg'],
        [resId2, 5, 'ipfs://res2.jpg'],
      ]);
    });
    it('can get pending resources', async function () {
      expect(await renderUtils.getPendingResources(multiresource.address, tokenId)).to.eql([
        [resId4, bn(0), bn(0), 'ipfs://res4.jpg'],
        [resId3, bn(1), resId, 'ipfs://res3.jpg'],
      ]);
    });

    it('can get top resource by priority', async function () {
      expect(await renderUtils.getTopResourceMetaForToken(multiresource.address, tokenId)).to.eql(
        'ipfs://res2.jpg',
      );
    });

    it('cannot get top resource if token has no resources', async function () {
      const otherTokenId = 2;
      await multiresource.mint(owner.address, otherTokenId);
      await expect(
        renderUtils.getTopResourceMetaForToken(multiresource.address, otherTokenId),
      ).to.be.revertedWith('Token has no resources');
    });
  });
});