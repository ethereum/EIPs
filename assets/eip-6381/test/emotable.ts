import { ethers } from 'hardhat';
import { expect } from 'chai';
import { BigNumber, Contract } from 'ethers';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ERC721EmotableMock } from '../typechain-types';

function bn(x: number): BigNumber {
  return BigNumber.from(x);
}

async function emotableTokenFixture() {
  const factory = await ethers.getContractFactory('ERC721EmotableMock');
  const token = await factory.deploy('Chunky', 'CHNK');
  await token.deployed();

  return token;
}

describe('RMRKMultiAssetEmotableMock', async function () {
  let token: ERC721EmotableMock;
  let owner: SignerWithAddress;
  let addrs: SignerWithAddress[];
  const tokenId = bn(1);
  const emoji1 = Buffer.from('😎');
  const emoji2 = Buffer.from('😁');

  beforeEach(async function () {
    [owner, ...addrs] = await ethers.getSigners();
    token = await loadFixture(emotableTokenFixture);
  });

  it('can support IEmotable', async function () {
    expect(await token.supportsInterface('0x580d1840')).to.equal(true);
  });

  it('can support IERC721', async function () {
    expect(await token.supportsInterface('0x80ac58cd')).to.equal(true);
  });

  it('does not support other interfaces', async function () {
    expect(await token.supportsInterface('0xffffffff')).to.equal(false);
  });

  describe('With minted tokens', async function () {
    beforeEach(async function () {
      await token.mint(owner.address, tokenId);
    });

    it('can emote', async function () {
      await expect(token.emote(tokenId, emoji1, true))
        .to.emit(token, 'Emoted')
        .withArgs(owner.address, tokenId.toNumber(), emoji1, true);
      expect(await token.emoteCountOf(tokenId, emoji1)).to.equal(bn(1));
    });

    it('can undo emote', async function () {
      await token.emote(tokenId, emoji1, true);

      await expect(token.emote(tokenId, emoji1, false))
        .to.emit(token, 'Emoted')
        .withArgs(owner.address, tokenId.toNumber(), emoji1, false);
      expect(await token.emoteCountOf(tokenId, emoji1)).to.equal(bn(0));
    });

    it('can be emoted from different accounts', async function () {
      await token.connect(addrs[0]).emote(tokenId, emoji1, true);
      await token.connect(addrs[1]).emote(tokenId, emoji1, true);
      await token.connect(addrs[2]).emote(tokenId, emoji2, true);
      expect(await token.emoteCountOf(tokenId, emoji1)).to.equal(bn(2));
      expect(await token.emoteCountOf(tokenId, emoji2)).to.equal(bn(1));
    });

    it('can add multiple emojis to same NFT', async function () {
      await token.emote(tokenId, emoji1, true);
      await token.emote(tokenId, emoji2, true);
      expect(await token.emoteCountOf(tokenId, emoji1)).to.equal(bn(1));
      expect(await token.emoteCountOf(tokenId, emoji2)).to.equal(bn(1));
    });

    it('does nothing if new state is the same as old state', async function () {
      await token.emote(tokenId, emoji1, true);
      await token.emote(tokenId, emoji1, true);
      expect(await token.emoteCountOf(tokenId, emoji1)).to.equal(bn(1));

      await token.emote(tokenId, emoji2, false);
      expect(await token.emoteCountOf(tokenId, emoji2)).to.equal(bn(0));
    });
  });
});

