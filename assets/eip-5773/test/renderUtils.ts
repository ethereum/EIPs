import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { MultiAssetTokenMock, MultiAssetRenderUtils } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

function bn(x: number): BigNumber {
  return BigNumber.from(x);
}

async function assetsFixture() {
  const multiassetFactory = await ethers.getContractFactory(
    "MultiAssetTokenMock"
  );
  const renderUtilsFactory = await ethers.getContractFactory(
    "MultiAssetRenderUtils"
  );

  const multiasset = await multiassetFactory.deploy("Chunky", "CHNK");
  await multiasset.deployed();

  const renderUtils = await renderUtilsFactory.deploy();
  await renderUtils.deployed();

  return { multiasset, renderUtils };
}

describe("Render Utils", async function () {
  let owner: SignerWithAddress;
  let multiasset: MultiAssetTokenMock;
  let renderUtils: MultiAssetRenderUtils;
  let tokenId: number;

  const resId = bn(1);
  const resId2 = bn(2);
  const resId3 = bn(3);
  const resId4 = bn(4);

  before(async function () {
    ({ multiasset, renderUtils } = await loadFixture(assetsFixture));

    const signers = await ethers.getSigners();
    owner = signers[0];

    tokenId = 1;
    await multiasset.mint(owner.address, tokenId);
    await multiasset.addAssetEntry(resId, "ipfs://res1.jpg");
    await multiasset.addAssetEntry(resId2, "ipfs://res2.jpg");
    await multiasset.addAssetEntry(resId3, "ipfs://res3.jpg");
    await multiasset.addAssetEntry(resId4, "ipfs://res4.jpg");
    await multiasset.addAssetToToken(tokenId, resId, 0);
    await multiasset.addAssetToToken(tokenId, resId2, 0);
    await multiasset.addAssetToToken(tokenId, resId3, resId);
    await multiasset.addAssetToToken(tokenId, resId4, 0);

    await multiasset.acceptAsset(tokenId, 0, resId);
    await multiasset.acceptAsset(tokenId, 1, resId2);
    await multiasset.setPriority(tokenId, [10, 5]);
  });

  describe("Render Utils MultiAsset", async function () {
    it("can get active assets", async function () {
      expect(
        await renderUtils.getActiveAssets(multiasset.address, tokenId)
      ).to.eql([
        [resId, 10, "ipfs://res1.jpg"],
        [resId2, 5, "ipfs://res2.jpg"],
      ]);
    });
    it("can get pending assets", async function () {
      expect(
        await renderUtils.getPendingAssets(multiasset.address, tokenId)
      ).to.eql([
        [resId4, bn(0), bn(0), "ipfs://res4.jpg"],
        [resId3, bn(1), resId, "ipfs://res3.jpg"],
      ]);
    });

    it("can get top asset by priority", async function () {
      expect(
        await renderUtils.getTopAssetMetaForToken(multiasset.address, tokenId)
      ).to.eql("ipfs://res2.jpg");
    });

    it("cannot get top asset if token has no assets", async function () {
      const otherTokenId = 2;
      await multiasset.mint(owner.address, otherTokenId);
      await expect(
        renderUtils.getTopAssetMetaForToken(multiasset.address, otherTokenId)
      ).to.be.revertedWith("Token has no assets");
    });
  });
});
