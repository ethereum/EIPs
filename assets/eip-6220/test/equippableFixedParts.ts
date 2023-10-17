import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import {
  CatalogMock,
  EquippableTokenMock,
  EquipRenderUtils,
} from "../typechain-types";

let addrs: SignerWithAddress[];

const partIdForHead1 = 1;
const partIdForHead2 = 2;
const partIdForHead3 = 3;
const partIdForBody1 = 4;
const partIdForBody2 = 5;
const partIdForHair1 = 6;
const partIdForHair2 = 7;
const partIdForHair3 = 8;
const partIdForMaskCatalog1 = 9;
const partIdForMaskCatalog2 = 10;
const partIdForMaskCatalog3 = 11;
const partIdForEars1 = 12;
const partIdForEars2 = 13;
const partIdForHorns1 = 14;
const partIdForHorns2 = 15;
const partIdForHorns3 = 16;
const partIdForMaskCatalogEquipped1 = 17;
const partIdForMaskCatalogEquipped2 = 18;
const partIdForMaskCatalogEquipped3 = 19;
const partIdForEarsEquipped1 = 20;
const partIdForEarsEquipped2 = 21;
const partIdForHornsEquipped1 = 22;
const partIdForHornsEquipped2 = 23;
const partIdForHornsEquipped3 = 24;
const partIdForMask = 25;

const uniqueNeons = 10;
const uniqueMasks = 4;
// Ids could be the same since they are different collections, but to avoid log problems we have them unique
const neons: number[] = [];
const masks: number[] = [];

const neonResIds = [100, 101, 102, 103, 104];
const maskAssetsFull = [1, 2, 3, 4]; // Must match the total of uniqueAssets
const maskAssetsEquip = [5, 6, 7, 8]; // Must match the total of uniqueAssets
const maskpableGroupId = 1; // Assets to equip will all use this

enum ItemType {
  None,
  Slot,
  Fixed,
}

let nextTokenId = 1;
let nextChildTokenId = 100;

async function mint(token: EquippableTokenMock, to: string): Promise<number> {
  const tokenId = nextTokenId;
  nextTokenId++;
  await token["mint(address,uint256)"](to, tokenId);
  return tokenId;
}

async function nestMint(
  token: EquippableTokenMock,
  to: string,
  parentId: number
): Promise<number> {
  const childTokenId = nextChildTokenId;
  nextChildTokenId++;
  await token["nestMint(address,uint256,uint256)"](to, childTokenId, parentId);
  return childTokenId;
}

async function setupContextForParts(
  catalog: CatalogMock,
  neon: EquippableTokenMock,
  mask: EquippableTokenMock
) {
  [, ...addrs] = await ethers.getSigners();
  await setupCatalog();

  await mintNeons();
  await mintMasks();

  await addAssetsToNeon();
  await addAssetsToMask();

  async function setupCatalog(): Promise<void> {
    const partForHead1 = {
      itemType: ItemType.Fixed,
      z: 1,
      equippable: [],
      metadataURI: "ipfs://head1.png",
    };
    const partForHead2 = {
      itemType: ItemType.Fixed,
      z: 1,
      equippable: [],
      metadataURI: "ipfs://head2.png",
    };
    const partForHead3 = {
      itemType: ItemType.Fixed,
      z: 1,
      equippable: [],
      metadataURI: "ipfs://head3.png",
    };
    const partForBody1 = {
      itemType: ItemType.Fixed,
      z: 1,
      equippable: [],
      metadataURI: "ipfs://body1.png",
    };
    const partForBody2 = {
      itemType: ItemType.Fixed,
      z: 1,
      equippable: [],
      metadataURI: "ipfs://body2.png",
    };
    const partForHair1 = {
      itemType: ItemType.Fixed,
      z: 2,
      equippable: [],
      metadataURI: "ipfs://hair1.png",
    };
    const partForHair2 = {
      itemType: ItemType.Fixed,
      z: 2,
      equippable: [],
      metadataURI: "ipfs://hair2.png",
    };
    const partForHair3 = {
      itemType: ItemType.Fixed,
      z: 2,
      equippable: [],
      metadataURI: "ipfs://hair3.png",
    };
    const partForMaskCatalog1 = {
      itemType: ItemType.Fixed,
      z: 3,
      equippable: [],
      metadataURI: "ipfs://maskCatalog1.png",
    };
    const partForMaskCatalog2 = {
      itemType: ItemType.Fixed,
      z: 3,
      equippable: [],
      metadataURI: "ipfs://maskCatalog2.png",
    };
    const partForMaskCatalog3 = {
      itemType: ItemType.Fixed,
      z: 3,
      equippable: [],
      metadataURI: "ipfs://maskCatalog3.png",
    };
    const partForEars1 = {
      itemType: ItemType.Fixed,
      z: 4,
      equippable: [],
      metadataURI: "ipfs://ears1.png",
    };
    const partForEars2 = {
      itemType: ItemType.Fixed,
      z: 4,
      equippable: [],
      metadataURI: "ipfs://ears2.png",
    };
    const partForHorns1 = {
      itemType: ItemType.Fixed,
      z: 5,
      equippable: [],
      metadataURI: "ipfs://horn1.png",
    };
    const partForHorns2 = {
      itemType: ItemType.Fixed,
      z: 5,
      equippable: [],
      metadataURI: "ipfs://horn2.png",
    };
    const partForHorns3 = {
      itemType: ItemType.Fixed,
      z: 5,
      equippable: [],
      metadataURI: "ipfs://horn3.png",
    };
    const partForMaskCatalogEquipped1 = {
      itemType: ItemType.Fixed,
      z: 3,
      equippable: [],
      metadataURI: "ipfs://maskCatalogEquipped1.png",
    };
    const partForMaskCatalogEquipped2 = {
      itemType: ItemType.Fixed,
      z: 3,
      equippable: [],
      metadataURI: "ipfs://maskCatalogEquipped2.png",
    };
    const partForMaskCatalogEquipped3 = {
      itemType: ItemType.Fixed,
      z: 3,
      equippable: [],
      metadataURI: "ipfs://maskCatalogEquipped3.png",
    };
    const partForEarsEquipped1 = {
      itemType: ItemType.Fixed,
      z: 4,
      equippable: [],
      metadataURI: "ipfs://earsEquipped1.png",
    };
    const partForEarsEquipped2 = {
      itemType: ItemType.Fixed,
      z: 4,
      equippable: [],
      metadataURI: "ipfs://earsEquipped2.png",
    };
    const partForHornsEquipped1 = {
      itemType: ItemType.Fixed,
      z: 5,
      equippable: [],
      metadataURI: "ipfs://hornEquipped1.png",
    };
    const partForHornsEquipped2 = {
      itemType: ItemType.Fixed,
      z: 5,
      equippable: [],
      metadataURI: "ipfs://hornEquipped2.png",
    };
    const partForHornsEquipped3 = {
      itemType: ItemType.Fixed,
      z: 5,
      equippable: [],
      metadataURI: "ipfs://hornEquipped3.png",
    };
    const partForMask = {
      itemType: ItemType.Slot,
      z: 2,
      equippable: [mask.address],
      metadataURI: "",
    };

    await catalog.addPartList([
      { partId: partIdForHead1, part: partForHead1 },
      { partId: partIdForHead2, part: partForHead2 },
      { partId: partIdForHead3, part: partForHead3 },
      { partId: partIdForBody1, part: partForBody1 },
      { partId: partIdForBody2, part: partForBody2 },
      { partId: partIdForHair1, part: partForHair1 },
      { partId: partIdForHair2, part: partForHair2 },
      { partId: partIdForHair3, part: partForHair3 },
      { partId: partIdForMaskCatalog1, part: partForMaskCatalog1 },
      { partId: partIdForMaskCatalog2, part: partForMaskCatalog2 },
      { partId: partIdForMaskCatalog3, part: partForMaskCatalog3 },
      { partId: partIdForEars1, part: partForEars1 },
      { partId: partIdForEars2, part: partForEars2 },
      { partId: partIdForHorns1, part: partForHorns1 },
      { partId: partIdForHorns2, part: partForHorns2 },
      { partId: partIdForHorns3, part: partForHorns3 },
      {
        partId: partIdForMaskCatalogEquipped1,
        part: partForMaskCatalogEquipped1,
      },
      {
        partId: partIdForMaskCatalogEquipped2,
        part: partForMaskCatalogEquipped2,
      },
      {
        partId: partIdForMaskCatalogEquipped3,
        part: partForMaskCatalogEquipped3,
      },
      { partId: partIdForEarsEquipped1, part: partForEarsEquipped1 },
      { partId: partIdForEarsEquipped2, part: partForEarsEquipped2 },
      { partId: partIdForHornsEquipped1, part: partForHornsEquipped1 },
      { partId: partIdForHornsEquipped2, part: partForHornsEquipped2 },
      { partId: partIdForHornsEquipped3, part: partForHornsEquipped3 },
      { partId: partIdForMask, part: partForMask },
    ]);
  }

  async function mintNeons(): Promise<void> {
    // This array is reused, so we "empty" it before
    neons.length = 0;
    // Using only first 3 addresses to mint
    for (let i = 0; i < uniqueNeons; i++) {
      const newId = await mint(neon, addrs[i % 3].address);
      neons.push(newId);
    }
  }

  async function mintMasks(): Promise<void> {
    // This array is reused, so we "empty" it before
    masks.length = 0;
    // Mint one weapon to neon
    for (let i = 0; i < uniqueNeons; i++) {
      const newId = await nestMint(mask, neon.address, neons[i]);
      masks.push(newId);
      await neon
        .connect(addrs[i % 3])
        .acceptChild(neons[i], 0, mask.address, newId);
    }
  }

  async function addAssetsToNeon(): Promise<void> {
    await neon.addEquippableAssetEntry(
      neonResIds[0],
      0,
      catalog.address,
      "ipfs:neonRes/1",
      [partIdForHead1, partIdForBody1, partIdForHair1, partIdForMask]
    );
    await neon.addEquippableAssetEntry(
      neonResIds[1],
      0,
      catalog.address,
      "ipfs:neonRes/2",
      [partIdForHead2, partIdForBody2, partIdForHair2, partIdForMask]
    );
    await neon.addEquippableAssetEntry(
      neonResIds[2],
      0,
      catalog.address,
      "ipfs:neonRes/3",
      [partIdForHead3, partIdForBody1, partIdForHair3, partIdForMask]
    );
    await neon.addEquippableAssetEntry(
      neonResIds[3],
      0,
      catalog.address,
      "ipfs:neonRes/4",
      [partIdForHead1, partIdForBody2, partIdForHair2, partIdForMask]
    );
    await neon.addEquippableAssetEntry(
      neonResIds[4],
      0,
      catalog.address,
      "ipfs:neonRes/1",
      [partIdForHead2, partIdForBody1, partIdForHair1, partIdForMask]
    );

    for (let i = 0; i < uniqueNeons; i++) {
      await neon.addAssetToToken(
        neons[i],
        neonResIds[i % neonResIds.length],
        0
      );
      await neon
        .connect(addrs[i % 3])
        .acceptAsset(neons[i], 0, neonResIds[i % neonResIds.length]);
    }
  }

  async function addAssetsToMask(): Promise<void> {
    // Assets for full view, composed with fixed parts
    await mask.addEquippableAssetEntry(
      maskAssetsFull[0],
      0, // Not meant to equip
      catalog.address, // Not meant to equip, but catalog needed for parts
      `ipfs:weapon/full/${maskAssetsFull[0]}`,
      [partIdForMaskCatalog1, partIdForHorns1, partIdForEars1]
    );
    await mask.addEquippableAssetEntry(
      maskAssetsFull[1],
      0, // Not meant to equip
      catalog.address, // Not meant to equip, but catalog needed for parts
      `ipfs:weapon/full/${maskAssetsFull[1]}`,
      [partIdForMaskCatalog2, partIdForHorns2, partIdForEars2]
    );
    await mask.addEquippableAssetEntry(
      maskAssetsFull[2],
      0, // Not meant to equip
      catalog.address, // Not meant to equip, but catalog needed for parts
      `ipfs:weapon/full/${maskAssetsFull[2]}`,
      [partIdForMaskCatalog3, partIdForHorns1, partIdForEars2]
    );
    await mask.addEquippableAssetEntry(
      maskAssetsFull[3],
      0, // Not meant to equip
      catalog.address, // Not meant to equip, but catalog needed for parts
      `ipfs:weapon/full/${maskAssetsFull[3]}`,
      [partIdForMaskCatalog2, partIdForHorns2, partIdForEars1]
    );

    // Assets for equipping view, also composed with fixed parts
    await mask.addEquippableAssetEntry(
      maskAssetsEquip[0],
      maskpableGroupId,
      catalog.address,
      `ipfs:weapon/equip/${maskAssetsEquip[0]}`,
      [partIdForMaskCatalog1, partIdForHorns1, partIdForEars1]
    );

    // Assets for equipping view, also composed with fixed parts
    await mask.addEquippableAssetEntry(
      maskAssetsEquip[1],
      maskpableGroupId,
      catalog.address,
      `ipfs:weapon/equip/${maskAssetsEquip[1]}`,
      [partIdForMaskCatalog2, partIdForHorns2, partIdForEars2]
    );

    // Assets for equipping view, also composed with fixed parts
    await mask.addEquippableAssetEntry(
      maskAssetsEquip[2],
      maskpableGroupId,
      catalog.address,
      `ipfs:weapon/equip/${maskAssetsEquip[2]}`,
      [partIdForMaskCatalog3, partIdForHorns1, partIdForEars2]
    );

    // Assets for equipping view, also composed with fixed parts
    await mask.addEquippableAssetEntry(
      maskAssetsEquip[3],
      maskpableGroupId,
      catalog.address,
      `ipfs:weapon/equip/${maskAssetsEquip[3]}`,
      [partIdForMaskCatalog2, partIdForHorns2, partIdForEars1]
    );

    // Can be equipped into neons
    await mask.setValidParentForEquippableGroup(
      maskpableGroupId,
      neon.address,
      partIdForMask
    );

    // Add 2 assets to each weapon, one full, one for equip
    // There are 10 weapon tokens for 4 unique assets so we use %
    for (let i = 0; i < masks.length; i++) {
      await mask.addAssetToToken(masks[i], maskAssetsFull[i % uniqueMasks], 0);
      await mask.addAssetToToken(masks[i], maskAssetsEquip[i % uniqueMasks], 0);
      await mask
        .connect(addrs[i % 3])
        .acceptAsset(masks[i], 0, maskAssetsFull[i % uniqueMasks]);
      await mask
        .connect(addrs[i % 3])
        .acceptAsset(masks[i], 0, maskAssetsEquip[i % uniqueMasks]);
    }
  }
}

async function partsFixture() {
  const baseSymbol = "NCB";
  const baseType = "mixed";

  const baseFactory = await ethers.getContractFactory("CatalogMock");
  const equipFactory = await ethers.getContractFactory("EquippableTokenMock");
  const viewFactory = await ethers.getContractFactory("EquipRenderUtils");

  // Catalog
  const catalog = <CatalogMock>await baseFactory.deploy(baseSymbol, baseType);
  await catalog.deployed();

  // Neon token
  const neon = <EquippableTokenMock>await equipFactory.deploy();
  await neon.deployed();

  // Weapon
  const mask = <EquippableTokenMock>await equipFactory.deploy();
  await mask.deployed();

  // View
  const view = <EquipRenderUtils>await viewFactory.deploy();
  await view.deployed();

  await setupContextForParts(catalog, neon, mask);
  return { catalog, neon, mask, view };
}

// The general idea is having these tokens: Neon and Mask
// Masks can be equipped into Neons.
// All use a single catalog.
// Neon will use an asset per token, which uses fixed parts to compose the body
// Mask will have 2 assets per weapon, one for full view, one for equipping. Both are composed using fixed parts
describe("EquippableTokenMock with Parts", async () => {
  let catalog: CatalogMock;
  let neon: EquippableTokenMock;
  let mask: EquippableTokenMock;
  let view: EquipRenderUtils;
  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    [, ...addrs] = await ethers.getSigners();
    ({ catalog, neon, mask, view } = await loadFixture(partsFixture));
  });

  describe("Equip", async function () {
    it("can equip weapon", async function () {
      // Weapon is child on index 0, background on index 1
      const childIndex = 0;
      const weaponResId = maskAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await expect(
        neon
          .connect(addrs[0])
          .equip([
            neons[0],
            childIndex,
            neonResIds[0],
            partIdForMask,
            weaponResId,
          ])
      )
        .to.emit(neon, "ChildAssetEquipped")
        .withArgs(
          neons[0],
          neonResIds[0],
          partIdForMask,
          masks[0],
          mask.address,
          weaponResId
        );

      // All part slots are included on the response:
      const expectedSlots = [bn(partIdForMask)];
      const expectedEquips = [
        [bn(neonResIds[0]), bn(weaponResId), bn(masks[0]), mask.address],
      ];
      expect(
        await view.getEquipped(neon.address, neons[0], neonResIds[0])
      ).to.eql([expectedSlots, expectedEquips]);

      // Child is marked as equipped:
      expect(
        await neon.isChildEquipped(neons[0], mask.address, masks[0])
      ).to.eql(true);
    });

    it("cannot equip non existing child in slot", async function () {
      // Weapon is child on index 0
      const badChildIndex = 3;
      const weaponResId = maskAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await expect(
        neon
          .connect(addrs[0])
          .equip([
            neons[0],
            badChildIndex,
            neonResIds[0],
            partIdForMask,
            weaponResId,
          ])
      ).to.be.reverted; // Bad index
    });
  });

  describe("Compose", async function () {
    it("can compose all parts for neon", async function () {
      const childIndex = 0;
      const weaponResId = maskAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await neon
        .connect(addrs[0])
        .equip([
          neons[0],
          childIndex,
          neonResIds[0],
          partIdForMask,
          weaponResId,
        ]);

      const expectedFixedParts = [
        [
          bn(partIdForHead1), // partId
          1, // z
          "ipfs://head1.png", // metadataURI
        ],
        [
          bn(partIdForBody1), // partId
          1, // z
          "ipfs://body1.png", // metadataURI
        ],
        [
          bn(partIdForHair1), // partId
          2, // z
          "ipfs://hair1.png", // metadataURI
        ],
      ];
      const expectedSlotParts = [
        [
          bn(partIdForMask), // partId
          bn(maskAssetsEquip[0]), // childAssetId
          2, // z
          mask.address, // childAddress
          bn(masks[0]), // childTokenId
          "ipfs:weapon/equip/5", // childAssetMetadata
          "", // partMetadata
        ],
      ];
      const allAssets = await view.composeEquippables(
        neon.address,
        neons[0],
        neonResIds[0]
      );
      expect(allAssets).to.eql([
        "ipfs:neonRes/1", // metadataURI
        bn(0), // equippableGroupId
        catalog.address, // baseAddress,
        expectedFixedParts,
        expectedSlotParts,
      ]);
    });

    it("can compose all parts for mask", async function () {
      const expectedFixedParts = [
        [
          bn(partIdForMaskCatalog1), // partId
          3, // z
          "ipfs://maskCatalog1.png", // metadataURI
        ],
        [
          bn(partIdForHorns1), // partId
          5, // z
          "ipfs://horn1.png", // metadataURI
        ],
        [
          bn(partIdForEars1), // partId
          4, // z
          "ipfs://ears1.png", // metadataURI
        ],
      ];
      const allAssets = await view.composeEquippables(
        mask.address,
        masks[0],
        maskAssetsEquip[0]
      );
      expect(allAssets).to.eql([
        `ipfs:weapon/equip/${maskAssetsEquip[0]}`, // metadataURI
        bn(maskpableGroupId), // equippableGroupId
        catalog.address, // baseAddress
        expectedFixedParts,
        [],
      ]);
    });

    it("cannot compose equippables for neon with not associated asset", async function () {
      const wrongResId = maskAssetsEquip[1];
      await expect(
        view.composeEquippables(mask.address, masks[0], wrongResId)
      ).to.be.revertedWithCustomError(mask, "TokenDoesNotHaveAsset");
    });

    it("cannot compose equippables for mask for asset with no catalog", async function () {
      const noCatalogAssetId = 99;
      await mask.addEquippableAssetEntry(
        noCatalogAssetId,
        0, // Not meant to equip
        ethers.constants.AddressZero, // Not meant to equip
        `ipfs:weapon/full/customAsset.png`,
        []
      );
      await mask.addAssetToToken(masks[0], noCatalogAssetId, 0);
      await mask.connect(addrs[0]).acceptAsset(masks[0], 0, noCatalogAssetId);
      await expect(
        view.composeEquippables(mask.address, masks[0], noCatalogAssetId)
      ).to.be.revertedWithCustomError(view, "NotComposableAsset");
    });
  });
});

function bn(x: number): BigNumber {
  return BigNumber.from(x);
}
