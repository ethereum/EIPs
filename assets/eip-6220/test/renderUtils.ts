import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import {
  EquippableTokenMock,
  EquipRenderUtils,
  MultiAssetRenderUtils,
} from "../typechain-types";

function bn(x: number): BigNumber {
  return BigNumber.from(x);
}

async function assetsFixture() {
  const equipFactory = await ethers.getContractFactory("EquippableTokenMock");
  const renderUtilsFactory = await ethers.getContractFactory(
    "MultiAssetRenderUtils"
  );
  const renderUtilsEquipFactory = await ethers.getContractFactory(
    "EquipRenderUtils"
  );

  const equip = <EquippableTokenMock>await equipFactory.deploy();
  await equip.deployed();

  const renderUtils = <MultiAssetRenderUtils>await renderUtilsFactory.deploy();
  await renderUtils.deployed();

  const renderUtilsEquip = <EquipRenderUtils>(
    await renderUtilsEquipFactory.deploy()
  );
  await renderUtilsEquip.deployed();

  return { equip, renderUtils, renderUtilsEquip };
}

describe("Render Utils", async function () {
  let owner: SignerWithAddress;
  let someCatalog: SignerWithAddress;
  let equip: EquippableTokenMock;
  let renderUtils: MultiAssetRenderUtils;
  let renderUtilsEquip: EquipRenderUtils;
  let tokenId: number;

  const resId = bn(1);
  const resId2 = bn(2);
  const resId3 = bn(3);
  const resId4 = bn(4);

  before(async function () {
    ({ equip, renderUtils, renderUtilsEquip } = await loadFixture(
      assetsFixture
    ));

    const signers = await ethers.getSigners();
    owner = signers[0];
    someCatalog = signers[1];
    tokenId = 1;

    await equip.mint(owner.address, tokenId);
    await equip.addEquippableAssetEntry(
      resId,
      0,
      ethers.constants.AddressZero,
      "ipfs://res1.jpg",
      []
    );
    await equip.addEquippableAssetEntry(
      resId2,
      1,
      someCatalog.address,
      "ipfs://res2.jpg",
      [1, 3, 4]
    );
    await equip.addEquippableAssetEntry(
      resId3,
      0,
      ethers.constants.AddressZero,
      "ipfs://res3.jpg",
      []
    );
    await equip.addEquippableAssetEntry(
      resId4,
      2,
      someCatalog.address,
      "ipfs://res4.jpg",
      [4]
    );
    await equip.addAssetToToken(tokenId, resId, 0);
    await equip.addAssetToToken(tokenId, resId2, 0);
    await equip.addAssetToToken(tokenId, resId3, resId);
    await equip.addAssetToToken(tokenId, resId4, 0);

    await equip.acceptAsset(tokenId, 0, resId);
    await equip.acceptAsset(tokenId, 1, resId2);
    await equip.setPriority(tokenId, [10, 5]);
  });

  describe("Render Utils MultiAsset", async function () {
    it("can get active assets", async function () {
      expect(await renderUtils.getActiveAssets(equip.address, tokenId)).to.eql([
        [resId, 10, "ipfs://res1.jpg"],
        [resId2, 5, "ipfs://res2.jpg"],
      ]);
    });

    it("can get assets by id", async function () {
      expect(
        await renderUtils.getAssetsById(equip.address, tokenId, [resId, resId2])
      ).to.eql(["ipfs://res1.jpg", "ipfs://res2.jpg"]);
    });

    it("can get pending assets", async function () {
      expect(await renderUtils.getPendingAssets(equip.address, tokenId)).to.eql(
        [
          [resId4, bn(0), bn(0), "ipfs://res4.jpg"],
          [resId3, bn(1), resId, "ipfs://res3.jpg"],
        ]
      );
    });

    it("can get top asset by priority", async function () {
      expect(
        await renderUtils.getTopAssetMetaForToken(equip.address, tokenId)
      ).to.eql("ipfs://res2.jpg");
    });

    it("cannot get top asset if token has no assets", async function () {
      const otherTokenId = 2;
      await equip.mint(owner.address, otherTokenId);
      await expect(
        renderUtils.getTopAssetMetaForToken(equip.address, otherTokenId)
      ).to.be.revertedWithCustomError(renderUtils, "TokenHasNoAssets");
    });
  });

  describe("Render Utils Equip", async function () {
    it("can get active assets", async function () {
      expect(
        await renderUtilsEquip.getExtendedActiveAssets(equip.address, tokenId)
      ).to.eql([
        [resId, bn(0), 10, ethers.constants.AddressZero, "ipfs://res1.jpg", []],
        [
          resId2,
          bn(1),
          5,
          someCatalog.address,
          "ipfs://res2.jpg",
          [bn(1), bn(3), bn(4)],
        ],
      ]);
    });

    it("can get pending assets", async function () {
      expect(
        await renderUtilsEquip.getExtendedPendingAssets(equip.address, tokenId)
      ).to.eql([
        [
          resId4,
          bn(2),
          bn(0),
          bn(0),
          someCatalog.address,
          "ipfs://res4.jpg",
          [bn(4)],
        ],
        [
          resId3,
          bn(0),
          bn(1),
          resId,
          ethers.constants.AddressZero,
          "ipfs://res3.jpg",
          [],
        ],
      ]);
    });
  });
});
