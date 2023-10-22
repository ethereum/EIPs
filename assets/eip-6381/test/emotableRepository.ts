import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC721Mock, EmotableRepository } from "../typechain-types";

function bn(x: number): BigNumber {
  return BigNumber.from(x);
}

async function tokenFixture() {
  const factory = await ethers.getContractFactory("ERC721Mock");
  const token = await factory.deploy("Chunky", "CHNK");
  await token.deployed();

  return token;
}

async function emotableRepositoryFixture() {
  const factory = await ethers.getContractFactory("EmotableRepository");
  const repository = await factory.deploy();
  await repository.deployed();

  return repository;
}

describe("RMRKEmotableRepositoryMock", async function () {
  let token: ERC721Mock;
  let repository: EmotableRepository;
  let owner: SignerWithAddress;
  let addrs: SignerWithAddress[];
  const tokenId = bn(1);
  const emoji1 = Buffer.from("😎");
  const emoji2 = Buffer.from("😁");

  beforeEach(async function () {
    [owner, ...addrs] = await ethers.getSigners();
    token = await loadFixture(tokenFixture);
    repository = await loadFixture(emotableRepositoryFixture);
  });

  it("can support IEmotableRepository", async function () {
    expect(await repository.supportsInterface("0x08eb97a6")).to.equal(true);
  });

  it("can support IERC165", async function () {
    expect(await repository.supportsInterface("0x01ffc9a7")).to.equal(true);
  });

  it("does not support other interfaces", async function () {
    expect(await repository.supportsInterface("0xffffffff")).to.equal(false);
  });

  describe("With minted tokens", async function () {
    beforeEach(async function () {
      await token.mint(owner.address, tokenId);
    });

    it("can emote", async function () {
      await expect(
        repository.connect(addrs[0]).emote(token.address, tokenId, emoji1, true)
      )
        .to.emit(repository, "Emoted")
        .withArgs(
          addrs[0].address,
          token.address,
          tokenId.toNumber(),
          emoji1,
          true
        );
      expect(
        await repository.emoteCountOf(token.address, tokenId, emoji1)
      ).to.equal(bn(1));
    });

    it("can undo emote", async function () {
      await repository.emote(token.address, tokenId, emoji1, true);

      await expect(repository.emote(token.address, tokenId, emoji1, false))
        .to.emit(repository, "Emoted")
        .withArgs(
          owner.address,
          token.address,
          tokenId.toNumber(),
          emoji1,
          false
        );
      expect(
        await repository.emoteCountOf(token.address, tokenId, emoji1)
      ).to.equal(bn(0));
    });

    it("can be emoted from different accounts", async function () {
      await repository
        .connect(addrs[0])
        .emote(token.address, tokenId, emoji1, true);
      await repository
        .connect(addrs[1])
        .emote(token.address, tokenId, emoji1, true);
      await repository
        .connect(addrs[2])
        .emote(token.address, tokenId, emoji2, true);
      expect(
        await repository.emoteCountOf(token.address, tokenId, emoji1)
      ).to.equal(bn(2));
      expect(
        await repository.emoteCountOf(token.address, tokenId, emoji2)
      ).to.equal(bn(1));
    });

    it("can add multiple emojis to same NFT", async function () {
      await repository.emote(token.address, tokenId, emoji1, true);
      await repository.emote(token.address, tokenId, emoji2, true);
      expect(
        await repository.emoteCountOf(token.address, tokenId, emoji1)
      ).to.equal(bn(1));
      expect(
        await repository.emoteCountOf(token.address, tokenId, emoji2)
      ).to.equal(bn(1));
    });

    it("does nothing if new state is the same as old state", async function () {
      await repository.emote(token.address, tokenId, emoji1, true);
      await repository.emote(token.address, tokenId, emoji1, true);
      expect(
        await repository.emoteCountOf(token.address, tokenId, emoji1)
      ).to.equal(bn(1));

      await repository.emote(token.address, tokenId, emoji2, false);
      expect(
        await repository.emoteCountOf(token.address, tokenId, emoji2)
      ).to.equal(bn(0));
    });
  });
});
