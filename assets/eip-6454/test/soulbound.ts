import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC721SoulboundMock } from "../typechain-types";

async function soulboundTokenFixture(): Promise<ERC721SoulboundMock> {
  const factory = await ethers.getContractFactory("ERC721SoulboundMock");
  const token = await factory.deploy("Chunky", "CHNK");
  await token.deployed();

  return token;
}

describe("Soulbound", async function () {
  let soulbound: ERC721SoulboundMock;
  let owner: SignerWithAddress;
  let otherOwner: SignerWithAddress;
  const tokenId = 1;

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    otherOwner = signers[1];
    soulbound = await loadFixture(soulboundTokenFixture);

    await soulbound.mint(owner.address, 1);
  });

  it("can support IRMRKSoulbound", async function () {
    expect(await soulbound.supportsInterface("0x911ec470")).to.equal(true);
  });

  it("does not support other interfaces", async function () {
    expect(await soulbound.supportsInterface("0xffffffff")).to.equal(false);
  });

  it("cannot transfer", async function () {
    expect(
      soulbound
        .connect(owner)
        ["safeTransferFrom(address,address,uint256)"](
          owner.address,
          otherOwner.address,
          tokenId
        )
    ).to.be.revertedWithCustomError(soulbound, "CannotTransferSoulbound");
  });

  it("can burn", async function () {
    await soulbound.connect(owner).burn(tokenId);
    await expect(soulbound.ownerOf(tokenId)).to.be.revertedWith(
      "ERC721: invalid token ID"
    );
  });
});
