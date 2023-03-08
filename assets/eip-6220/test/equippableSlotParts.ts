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

const partIdForBody = 1;
const partIdForWeapon = 2;
const partIdForWeaponGem = 3;
const partIdForBackground = 4;

const uniqueSnakeSoldiers = 10;
const uniqueWeapons = 4;
// const uniqueWeaponGems = 2;
// const uniqueBackgrounds = 3;

const snakeSoldiersIds: number[] = [];
const weaponsIds: number[] = [];
const weaponGemsIds: number[] = [];
const backgroundsIds: number[] = [];

const soldierResId = 100;
const weaponAssetsFull = [1, 2, 3, 4]; // Must match the total of uniqueAssets
const weaponAssetsEquip = [5, 6, 7, 8]; // Must match the total of uniqueAssets
const weaponGemAssetFull = 101;
const weaponGemAssetEquip = 102;
const backgroundAssetId = 200;

enum ItemType {
  None,
  Slot,
  Fixed,
}

let addrs: SignerWithAddress[];

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

async function setupContextForSlots(
  catalog: CatalogMock,
  soldier: EquippableTokenMock,
  weapon: EquippableTokenMock,
  weaponGem: EquippableTokenMock,
  background: EquippableTokenMock
) {
  [, ...addrs] = await ethers.getSigners();

  await setupCatalog();

  await mintSnakeSoldiers();
  await mintWeapons();
  await mintWeaponGems();
  await mintBackgrounds();

  await addAssetsToSoldier();
  await addAssetsToWeapon();
  await addAssetsToWeaponGem();
  await addAssetsToBackground();

  return {
    catalog,
    soldier,
    weapon,
    background,
  };

  async function setupCatalog(): Promise<void> {
    const partForBody = {
      itemType: ItemType.Fixed,
      z: 1,
      equippable: [],
      metadataURI: "genericBody.png",
    };
    const partForWeapon = {
      itemType: ItemType.Slot,
      z: 2,
      equippable: [weapon.address],
      metadataURI: "",
    };
    const partForWeaponGem = {
      itemType: ItemType.Slot,
      z: 3,
      equippable: [weaponGem.address],
      metadataURI: "noGem.png",
    };
    const partForBackground = {
      itemType: ItemType.Slot,
      z: 0,
      equippable: [background.address],
      metadataURI: "noBackground.png",
    };

    await catalog.addPartList([
      { partId: partIdForBody, part: partForBody },
      { partId: partIdForWeapon, part: partForWeapon },
      { partId: partIdForWeaponGem, part: partForWeaponGem },
      { partId: partIdForBackground, part: partForBackground },
    ]);
  }

  async function mintSnakeSoldiers(): Promise<void> {
    // This array is reused, so we "empty" it before
    snakeSoldiersIds.length = 0;
    // Using only first 3 addresses to mint
    for (let i = 0; i < uniqueSnakeSoldiers; i++) {
      const newId = await mint(soldier, addrs[i % 3].address);
      snakeSoldiersIds.push(newId);
    }
  }

  async function mintWeapons(): Promise<void> {
    // This array is reused, so we "empty" it before
    weaponsIds.length = 0;
    // Mint one weapon to soldier
    for (let i = 0; i < uniqueSnakeSoldiers; i++) {
      const newId = await nestMint(
        weapon,
        soldier.address,
        snakeSoldiersIds[i]
      );
      weaponsIds.push(newId);
      await soldier
        .connect(addrs[i % 3])
        .acceptChild(snakeSoldiersIds[i], 0, weapon.address, newId);
    }
  }

  async function mintWeaponGems(): Promise<void> {
    // This array is reused, so we "empty" it before
    weaponGemsIds.length = 0;
    // Mint one weapon gem for each weapon on each soldier
    for (let i = 0; i < uniqueSnakeSoldiers; i++) {
      const newId = await nestMint(weaponGem, weapon.address, weaponsIds[i]);
      weaponGemsIds.push(newId);
      await weapon
        .connect(addrs[i % 3])
        .acceptChild(weaponsIds[i], 0, weaponGem.address, newId);
    }
  }

  async function mintBackgrounds(): Promise<void> {
    // This array is reused, so we "empty" it before
    backgroundsIds.length = 0;
    // Mint one background to soldier
    for (let i = 0; i < uniqueSnakeSoldiers; i++) {
      const newId = await nestMint(
        background,
        soldier.address,
        snakeSoldiersIds[i]
      );
      backgroundsIds.push(newId);
      await soldier
        .connect(addrs[i % 3])
        .acceptChild(snakeSoldiersIds[i], 0, background.address, newId);
    }
  }

  async function addAssetsToSoldier(): Promise<void> {
    await soldier.addEquippableAssetEntry(
      soldierResId,
      0,
      catalog.address,
      "ipfs:soldier/",
      [partIdForBody, partIdForWeapon, partIdForBackground]
    );
    for (let i = 0; i < uniqueSnakeSoldiers; i++) {
      await soldier.addAssetToToken(snakeSoldiersIds[i], soldierResId, 0);
      await soldier
        .connect(addrs[i % 3])
        .acceptAsset(snakeSoldiersIds[i], 0, soldierResId);
    }
  }

  async function addAssetsToWeapon(): Promise<void> {
    const equippableGroupId = 1; // Assets to equip will both use this

    for (let i = 0; i < weaponAssetsFull.length; i++) {
      await weapon.addEquippableAssetEntry(
        weaponAssetsFull[i],
        0, // Not meant to equip
        ethers.constants.AddressZero, // Not meant to equip
        `ipfs:weapon/full/${weaponAssetsFull[i]}`,
        []
      );
    }
    for (let i = 0; i < weaponAssetsEquip.length; i++) {
      await weapon.addEquippableAssetEntry(
        weaponAssetsEquip[i],
        equippableGroupId,
        catalog.address,
        `ipfs:weapon/equip/${weaponAssetsEquip[i]}`,
        [partIdForWeaponGem]
      );
    }

    // Can be equipped into snakeSoldiers
    await weapon.setValidParentForEquippableGroup(
      equippableGroupId,
      soldier.address,
      partIdForWeapon
    );

    // Add 2 assets to each weapon, one full, one for equip
    // There are 10 weapon tokens for 4 unique assets so we use %
    for (let i = 0; i < weaponsIds.length; i++) {
      await weapon.addAssetToToken(
        weaponsIds[i],
        weaponAssetsFull[i % uniqueWeapons],
        0
      );
      await weapon.addAssetToToken(
        weaponsIds[i],
        weaponAssetsEquip[i % uniqueWeapons],
        0
      );
      await weapon
        .connect(addrs[i % 3])
        .acceptAsset(weaponsIds[i], 0, weaponAssetsFull[i % uniqueWeapons]);
      await weapon
        .connect(addrs[i % 3])
        .acceptAsset(weaponsIds[i], 0, weaponAssetsEquip[i % uniqueWeapons]);
    }
  }

  async function addAssetsToWeaponGem(): Promise<void> {
    const equippableGroupId = 1; // Assets to equip will use this
    await weaponGem.addEquippableAssetEntry(
      weaponGemAssetFull,
      0, // Not meant to equip
      ethers.constants.AddressZero, // Not meant to equip
      "ipfs:weagponGem/full/",
      []
    );
    await weaponGem.addEquippableAssetEntry(
      weaponGemAssetEquip,
      equippableGroupId,
      catalog.address,
      "ipfs:weagponGem/equip/",
      []
    );
    await weaponGem.setValidParentForEquippableGroup(
      // Can be equipped into weapons
      equippableGroupId,
      weapon.address,
      partIdForWeaponGem
    );

    for (let i = 0; i < uniqueSnakeSoldiers; i++) {
      await weaponGem.addAssetToToken(weaponGemsIds[i], weaponGemAssetFull, 0);
      await weaponGem.addAssetToToken(weaponGemsIds[i], weaponGemAssetEquip, 0);
      await weaponGem
        .connect(addrs[i % 3])
        .acceptAsset(weaponGemsIds[i], 0, weaponGemAssetFull);
      await weaponGem
        .connect(addrs[i % 3])
        .acceptAsset(weaponGemsIds[i], 0, weaponGemAssetEquip);
    }
  }

  async function addAssetsToBackground(): Promise<void> {
    const equippableGroupId = 1; // Assets to equip will use this
    await background.addEquippableAssetEntry(
      backgroundAssetId,
      equippableGroupId,
      catalog.address,
      "ipfs:background/",
      []
    );
    // Can be equipped into snakeSoldiers
    await background.setValidParentForEquippableGroup(
      equippableGroupId,
      soldier.address,
      partIdForBackground
    );

    for (let i = 0; i < uniqueSnakeSoldiers; i++) {
      await background.addAssetToToken(backgroundsIds[i], backgroundAssetId, 0);
      await background
        .connect(addrs[i % 3])
        .acceptAsset(backgroundsIds[i], 0, backgroundAssetId);
    }
  }
}

async function slotsFixture() {
  const catalogSymbol = "SSB";
  const catalogType = "mixed";

  const catalogFactory = await ethers.getContractFactory("CatalogMock");
  const equipFactory = await ethers.getContractFactory("EquippableTokenMock");
  const viewFactory = await ethers.getContractFactory("EquipRenderUtils");

  // View
  const view = <EquipRenderUtils>await viewFactory.deploy();
  await view.deployed();

  // Catalog
  const catalog = <CatalogMock>(
    await catalogFactory.deploy(catalogSymbol, catalogType)
  );
  await catalog.deployed();

  // Soldier token
  const soldier = <EquippableTokenMock>await equipFactory.deploy();
  await soldier.deployed();

  // Weapon
  const weapon = <EquippableTokenMock>await equipFactory.deploy();
  await weapon.deployed();

  // Weapon Gem
  const weaponGem = <EquippableTokenMock>await equipFactory.deploy();
  await weaponGem.deployed();

  // Background
  const background = <EquippableTokenMock>await equipFactory.deploy();
  await background.deployed();

  await setupContextForSlots(catalog, soldier, weapon, weaponGem, background);

  return { catalog, soldier, weapon, weaponGem, background, view };
}

// The general idea is having these tokens: Soldier, Weapon, WeaponGem and Background.
// Weapon and Background can be equipped into Soldier. WeaponGem can be equipped into Weapon
// All use a single catalog.
// Soldier will use a single enumerated fixed asset for simplicity
// Weapon will have 2 assets per weapon, one for full view, one for equipping
// Background will have a single asset for each, it can be used as full view and to equip
// Weapon Gems will have 2 enumerated assets, one for full view, one for equipping.
describe("EquippableTokenMock with Slots", async () => {
  let catalog: CatalogMock;
  let soldier: EquippableTokenMock;
  let weapon: EquippableTokenMock;
  let weaponGem: EquippableTokenMock;
  let background: EquippableTokenMock;
  let view: EquipRenderUtils;

  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    [, ...addrs] = await ethers.getSigners();
    ({ catalog, soldier, weapon, weaponGem, background, view } =
      await loadFixture(slotsFixture));
  });

  it("can support IERC6220", async function () {
    expect(await soldier.supportsInterface("0x28bc9ae4")).to.equal(true);
  });

  describe("Validations", async function () {
    it("can validate equips of weapons into snakeSoldiers", async function () {
      // This asset is not equippable
      expect(
        await weapon.canTokenBeEquippedWithAssetIntoSlot(
          soldier.address,
          weaponsIds[0],
          weaponAssetsFull[0],
          partIdForWeapon
        )
      ).to.eql(false);

      // This asset is equippable into weapon part
      expect(
        await weapon.canTokenBeEquippedWithAssetIntoSlot(
          soldier.address,
          weaponsIds[0],
          weaponAssetsEquip[0],
          partIdForWeapon
        )
      ).to.eql(true);

      // This asset is NOT equippable into weapon gem part
      expect(
        await weapon.canTokenBeEquippedWithAssetIntoSlot(
          soldier.address,
          weaponsIds[0],
          weaponAssetsEquip[0],
          partIdForWeaponGem
        )
      ).to.eql(false);
    });

    it("can validate equips of weapon gems into weapons", async function () {
      // This asset is not equippable
      expect(
        await weaponGem.canTokenBeEquippedWithAssetIntoSlot(
          weapon.address,
          weaponGemsIds[0],
          weaponGemAssetFull,
          partIdForWeaponGem
        )
      ).to.eql(false);

      // This asset is equippable into weapon gem slot
      expect(
        await weaponGem.canTokenBeEquippedWithAssetIntoSlot(
          weapon.address,
          weaponGemsIds[0],
          weaponGemAssetEquip,
          partIdForWeaponGem
        )
      ).to.eql(true);

      // This asset is NOT equippable into background slot
      expect(
        await weaponGem.canTokenBeEquippedWithAssetIntoSlot(
          weapon.address,
          weaponGemsIds[0],
          weaponGemAssetEquip,
          partIdForBackground
        )
      ).to.eql(false);
    });

    it("can validate equips of backgrounds into snakeSoldiers", async function () {
      // This asset is equippable into background slot
      expect(
        await background.canTokenBeEquippedWithAssetIntoSlot(
          soldier.address,
          backgroundsIds[0],
          backgroundAssetId,
          partIdForBackground
        )
      ).to.eql(true);

      // This asset is NOT equippable into weapon slot
      expect(
        await background.canTokenBeEquippedWithAssetIntoSlot(
          soldier.address,
          backgroundsIds[0],
          backgroundAssetId,
          partIdForWeapon
        )
      ).to.eql(false);
    });
  });

  describe("Equip", async function () {
    it("can equip weapon", async function () {
      // Weapon is child on index 0, background on index 1
      const soldierOwner = addrs[0];
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await equipWeaponAndCheckFromAddress(
        soldierOwner,
        childIndex,
        weaponResId
      );
    });

    it("can equip weapon if approved", async function () {
      // Weapon is child on index 0, background on index 1
      const soldierOwner = addrs[0];
      const approved = addrs[1];
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await soldier
        .connect(soldierOwner)
        .approve(approved.address, snakeSoldiersIds[0]);
      await equipWeaponAndCheckFromAddress(approved, childIndex, weaponResId);
    });

    it("can equip weapon if approved for all", async function () {
      // Weapon is child on index 0, background on index 1
      const soldierOwner = addrs[0];
      const approved = addrs[1];
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await soldier
        .connect(soldierOwner)
        .setApprovalForAll(approved.address, true);
      await equipWeaponAndCheckFromAddress(approved, childIndex, weaponResId);
    });

    it("can equip weapon and background", async function () {
      // Weapon is child on index 0, background on index 1
      const weaponChildIndex = 0;
      const backgroundChildIndex = 1;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await soldier
        .connect(addrs[0])
        .equip([
          snakeSoldiersIds[0],
          weaponChildIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ]);
      await soldier
        .connect(addrs[0])
        .equip([
          snakeSoldiersIds[0],
          backgroundChildIndex,
          soldierResId,
          partIdForBackground,
          backgroundAssetId,
        ]);

      const expectedSlots = [bn(partIdForWeapon), bn(partIdForBackground)];
      const expectedEquips = [
        [bn(soldierResId), bn(weaponResId), bn(weaponsIds[0]), weapon.address],
        [
          bn(soldierResId),
          bn(backgroundAssetId),
          bn(backgroundsIds[0]),
          background.address,
        ],
      ];
      expect(
        await view.getEquipped(
          soldier.address,
          snakeSoldiersIds[0],
          soldierResId
        )
      ).to.eql([expectedSlots, expectedEquips]);

      // Children are marked as equipped:
      expect(
        await soldier.isChildEquipped(
          snakeSoldiersIds[0],
          weapon.address,
          weaponsIds[0]
        )
      ).to.eql(true);
      expect(
        await soldier.isChildEquipped(
          snakeSoldiersIds[0],
          background.address,
          backgroundsIds[0]
        )
      ).to.eql(true);
    });

    it("cannot equip non existing child in slot (weapon in background)", async function () {
      // Weapon is child on index 0, background on index 1
      const badChildIndex = 3;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await expect(
        soldier
          .connect(addrs[0])
          .equip([
            snakeSoldiersIds[0],
            badChildIndex,
            soldierResId,
            partIdForWeapon,
            weaponResId,
          ])
      ).to.be.reverted; // Bad index
    });

    it("cannot set a valid equippable group with id 0", async function () {
      const equippableGroupId = 0;
      // The malicious child indicates it can be equipped into soldier:
      await expect(
        weaponGem.setValidParentForEquippableGroup(
          equippableGroupId,
          soldier.address,
          partIdForWeaponGem
        )
      ).to.be.revertedWithCustomError(weaponGem, "IdZeroForbidden");
    });

    it("cannot set a valid equippable group with part id 0", async function () {
      const equippableGroupId = 1;
      const partId = 0;
      // The malicious child indicates it can be equipped into soldier:
      await expect(
        weaponGem.setValidParentForEquippableGroup(
          equippableGroupId,
          soldier.address,
          partId
        )
      ).to.be.revertedWithCustomError(weaponGem, "IdZeroForbidden");
    });

    it("cannot equip into a slot not set on the parent asset (gem into soldier)", async function () {
      const soldierOwner = addrs[0];
      const soldierId = snakeSoldiersIds[0];
      const childIndex = 2;

      const newWeaponGemId = await nestMint(
        weaponGem,
        soldier.address,
        soldierId
      );
      await soldier
        .connect(soldierOwner)
        .acceptChild(soldierId, 0, weaponGem.address, newWeaponGemId);

      // Add assets to weapon
      await weaponGem.addAssetToToken(newWeaponGemId, weaponGemAssetFull, 0);
      await weaponGem.addAssetToToken(newWeaponGemId, weaponGemAssetEquip, 0);
      await weaponGem
        .connect(soldierOwner)
        .acceptAsset(newWeaponGemId, 0, weaponGemAssetFull);
      await weaponGem
        .connect(soldierOwner)
        .acceptAsset(newWeaponGemId, 0, weaponGemAssetEquip);

      // The malicious child indicates it can be equipped into soldier:
      await weaponGem.setValidParentForEquippableGroup(
        1, // equippableGroupId for gems
        soldier.address,
        partIdForWeaponGem
      );

      // Weapon is child on index 0, background on index 1
      await expect(
        soldier
          .connect(addrs[0])
          .equip([
            soldierId,
            childIndex,
            soldierResId,
            partIdForWeaponGem,
            weaponGemAssetEquip,
          ])
      ).to.be.revertedWithCustomError(soldier, "TargetAssetCannotReceiveSlot");
    });

    it("cannot equip wrong child in slot (weapon in background)", async function () {
      // Weapon is child on index 0, background on index 1
      const backgroundChildIndex = 1;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await expect(
        soldier
          .connect(addrs[0])
          .equip([
            snakeSoldiersIds[0],
            backgroundChildIndex,
            soldierResId,
            partIdForWeapon,
            weaponResId,
          ])
      ).to.be.revertedWithCustomError(
        soldier,
        "TokenCannotBeEquippedWithAssetIntoSlot"
      );
    });

    it("cannot equip child in wrong slot (weapon in background)", async function () {
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await expect(
        soldier
          .connect(addrs[0])
          .equip([
            snakeSoldiersIds[0],
            childIndex,
            soldierResId,
            partIdForBackground,
            weaponResId,
          ])
      ).to.be.revertedWithCustomError(
        soldier,
        "TokenCannotBeEquippedWithAssetIntoSlot"
      );
    });

    it("cannot equip child with wrong asset (weapon in background)", async function () {
      const childIndex = 0;
      await expect(
        soldier
          .connect(addrs[0])
          .equip([
            snakeSoldiersIds[0],
            childIndex,
            soldierResId,
            partIdForWeapon,
            backgroundAssetId,
          ])
      ).to.be.revertedWithCustomError(
        soldier,
        "TokenCannotBeEquippedWithAssetIntoSlot"
      );
    });

    it("cannot equip if not owner", async function () {
      // Weapon is child on index 0, background on index 1
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await expect(
        soldier
          .connect(addrs[1]) // Owner is addrs[0]
          .equip([
            snakeSoldiersIds[0],
            childIndex,
            soldierResId,
            partIdForWeapon,
            weaponResId,
          ])
      ).to.be.revertedWithCustomError(soldier, "ERC721NotApprovedOrOwner");
    });

    it("cannot equip 2 children into the same slot", async function () {
      // Weapon is child on index 0, background on index 1
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await soldier
        .connect(addrs[0])
        .equip([
          snakeSoldiersIds[0],
          childIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ]);

      const weaponAssetIndex = 3;
      await mintWeaponToSoldier(
        addrs[0],
        snakeSoldiersIds[0],
        weaponAssetIndex
      );

      const newWeaponChildIndex = 2;
      const newWeaponResId = weaponAssetsEquip[weaponAssetIndex];
      await expect(
        soldier
          .connect(addrs[0])
          .equip([
            snakeSoldiersIds[0],
            newWeaponChildIndex,
            soldierResId,
            partIdForWeapon,
            newWeaponResId,
          ])
      ).to.be.revertedWithCustomError(soldier, "SlotAlreadyUsed");
    });

    it("cannot equip if not intented on catalog", async function () {
      // Weapon is child on index 0, background on index 1
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon

      // Remove equippable addresses for part.
      await catalog.resetEquippableAddresses(partIdForWeapon);
      await expect(
        soldier
          .connect(addrs[0]) // Owner is addrs[0]
          .equip([
            snakeSoldiersIds[0],
            childIndex,
            soldierResId,
            partIdForWeapon,
            weaponResId,
          ])
      ).to.be.revertedWithCustomError(
        soldier,
        "EquippableEquipNotAllowedByCatalog"
      );
    });
  });

  describe("Unequip", async function () {
    it("can unequip", async function () {
      // Weapon is child on index 0, background on index 1
      const soldierOwner = addrs[0];
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon

      await soldier
        .connect(soldierOwner)
        .equip([
          snakeSoldiersIds[0],
          childIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ]);

      await unequipWeaponAndCheckFromAddress(soldierOwner);
    });

    it("can unequip if approved", async function () {
      // Weapon is child on index 0, background on index 1
      const soldierOwner = addrs[0];
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      const approved = addrs[1];

      await soldier
        .connect(soldierOwner)
        .equip([
          snakeSoldiersIds[0],
          childIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ]);

      await soldier
        .connect(soldierOwner)
        .approve(approved.address, snakeSoldiersIds[0]);
      await unequipWeaponAndCheckFromAddress(approved);
    });

    it("can unequip if approved for all", async function () {
      // Weapon is child on index 0, background on index 1
      const soldierOwner = addrs[0];
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      const approved = addrs[1];

      await soldier
        .connect(soldierOwner)
        .equip([
          snakeSoldiersIds[0],
          childIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ]);

      await soldier
        .connect(soldierOwner)
        .setApprovalForAll(approved.address, true);
      await unequipWeaponAndCheckFromAddress(approved);
    });

    it("cannot unequip if not equipped", async function () {
      await expect(
        soldier
          .connect(addrs[0])
          .unequip(snakeSoldiersIds[0], soldierResId, partIdForWeapon)
      ).to.be.revertedWithCustomError(soldier, "NotEquipped");
    });

    it("cannot unequip if not owner", async function () {
      // Weapon is child on index 0, background on index 1
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await soldier
        .connect(addrs[0])
        .equip([
          snakeSoldiersIds[0],
          childIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ]);

      await expect(
        soldier
          .connect(addrs[1])
          .unequip(snakeSoldiersIds[0], soldierResId, partIdForWeapon)
      ).to.be.revertedWithCustomError(soldier, "ERC721NotApprovedOrOwner");
    });
  });

  describe("Transfer equipped", async function () {
    it("can unequip and transfer child", async function () {
      // Weapon is child on index 0, background on index 1
      const soldierOwner = addrs[0];
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon

      await soldier
        .connect(soldierOwner)
        .equip([
          snakeSoldiersIds[0],
          childIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ]);

      await unequipWeaponAndCheckFromAddress(soldierOwner);
      await soldier
        .connect(soldierOwner)
        .transferChild(
          snakeSoldiersIds[0],
          soldierOwner.address,
          0,
          childIndex,
          weapon.address,
          weaponsIds[0],
          false,
          "0x"
        );
    });

    it("child transfer fails if child is equipped", async function () {
      const soldierOwner = addrs[0];
      // Weapon is child on index 0
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await soldier
        .connect(addrs[0])
        .equip([
          snakeSoldiersIds[0],
          childIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ]);

      await expect(
        soldier
          .connect(soldierOwner)
          .transferChild(
            snakeSoldiersIds[0],
            soldierOwner.address,
            0,
            childIndex,
            weapon.address,
            weaponsIds[0],
            false,
            "0x"
          )
      ).to.be.revertedWithCustomError(weapon, "MustUnequipFirst");
    });
  });

  describe("Compose", async function () {
    it("can compose equippables for soldier", async function () {
      const childIndex = 0;
      const weaponResId = weaponAssetsEquip[0]; // This asset is assigned to weapon first weapon
      await soldier
        .connect(addrs[0])
        .equip([
          snakeSoldiersIds[0],
          childIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ]);

      const expectedFixedParts = [
        [
          bn(partIdForBody), // partId
          1, // z
          "genericBody.png", // metadataURI
        ],
      ];
      const expectedSlotParts = [
        [
          bn(partIdForWeapon), // partId
          bn(weaponAssetsEquip[0]), // childAssetId
          2, // z
          weapon.address, // childAddress
          bn(weaponsIds[0]), // childTokenId
          "ipfs:weapon/equip/5", // childAssetMetadata
          "", // partMetadata
        ],
        [
          // Nothing on equipped on background slot:
          bn(partIdForBackground), // partId
          bn(0), // childAssetId
          0, // z
          ethers.constants.AddressZero, // childAddress
          bn(0), // childTokenId
          "", // childAssetMetadata
          "noBackground.png", // partMetadata
        ],
      ];
      const allAssets = await view.composeEquippables(
        soldier.address,
        snakeSoldiersIds[0],
        soldierResId
      );
      expect(allAssets).to.eql([
        "ipfs:soldier/", // metadataURI
        bn(0), // equippableGroupId
        catalog.address, // catalogAddress
        expectedFixedParts,
        expectedSlotParts,
      ]);
    });

    it("can compose equippables for simple asset", async function () {
      const allAssets = await view.composeEquippables(
        background.address,
        backgroundsIds[0],
        backgroundAssetId
      );
      expect(allAssets).to.eql([
        "ipfs:background/", // metadataURI
        bn(1), // equippableGroupId
        catalog.address, // catalogAddress,
        [],
        [],
      ]);
    });

    it("cannot compose equippables for soldier with not associated asset", async function () {
      const wrongResId = weaponAssetsEquip[1];
      await expect(
        view.composeEquippables(weapon.address, weaponsIds[0], wrongResId)
      ).to.be.revertedWithCustomError(weapon, "TokenDoesNotHaveAsset");
    });
  });

  async function equipWeaponAndCheckFromAddress(
    from: SignerWithAddress,
    childIndex: number,
    weaponResId: number
  ): Promise<void> {
    await expect(
      soldier
        .connect(from)
        .equip([
          snakeSoldiersIds[0],
          childIndex,
          soldierResId,
          partIdForWeapon,
          weaponResId,
        ])
    )
      .to.emit(soldier, "ChildAssetEquipped")
      .withArgs(
        snakeSoldiersIds[0],
        soldierResId,
        partIdForWeapon,
        weaponsIds[0],
        weapon.address,
        weaponAssetsEquip[0]
      );
    // All part slots are included on the response:
    const expectedSlots = [bn(partIdForWeapon), bn(partIdForBackground)];
    // If a slot has nothing equipped, it returns an empty equip:
    const expectedEquips = [
      [bn(soldierResId), bn(weaponResId), bn(weaponsIds[0]), weapon.address],
      [bn(0), bn(0), bn(0), ethers.constants.AddressZero],
    ];
    expect(
      await view.getEquipped(soldier.address, snakeSoldiersIds[0], soldierResId)
    ).to.eql([expectedSlots, expectedEquips]);

    // Child is marked as equipped:
    expect(
      await soldier.isChildEquipped(
        snakeSoldiersIds[0],
        weapon.address,
        weaponsIds[0]
      )
    ).to.eql(true);
  }

  async function unequipWeaponAndCheckFromAddress(
    from: SignerWithAddress
  ): Promise<void> {
    await expect(
      soldier
        .connect(from)
        .unequip(snakeSoldiersIds[0], soldierResId, partIdForWeapon)
    )
      .to.emit(soldier, "ChildAssetUnequipped")
      .withArgs(
        snakeSoldiersIds[0],
        soldierResId,
        partIdForWeapon,
        weaponsIds[0],
        weapon.address,
        weaponAssetsEquip[0]
      );

    const expectedSlots = [bn(partIdForWeapon), bn(partIdForBackground)];
    // If a slot has nothing equipped, it returns an empty equip:
    const expectedEquips = [
      [bn(0), bn(0), bn(0), ethers.constants.AddressZero],
      [bn(0), bn(0), bn(0), ethers.constants.AddressZero],
    ];
    expect(
      await view.getEquipped(soldier.address, snakeSoldiersIds[0], soldierResId)
    ).to.eql([expectedSlots, expectedEquips]);

    // Child is marked as not equipped:
    expect(
      await soldier.isChildEquipped(
        snakeSoldiersIds[0],
        weapon.address,
        weaponsIds[0]
      )
    ).to.eql(false);
  }

  async function mintWeaponToSoldier(
    soldierOwner: SignerWithAddress,
    soldierId: number,
    assetIndex: number
  ): Promise<number> {
    // Mint another weapon to the soldier and accept it
    const newWeaponId = await nestMint(weapon, soldier.address, soldierId);
    await soldier
      .connect(soldierOwner)
      .acceptChild(soldierId, 0, weapon.address, newWeaponId);

    // Add assets to weapon
    await weapon.addAssetToToken(newWeaponId, weaponAssetsFull[assetIndex], 0);
    await weapon.addAssetToToken(newWeaponId, weaponAssetsEquip[assetIndex], 0);
    await weapon
      .connect(soldierOwner)
      .acceptAsset(newWeaponId, 0, weaponAssetsFull[assetIndex]);
    await weapon
      .connect(soldierOwner)
      .acceptAsset(newWeaponId, 0, weaponAssetsEquip[assetIndex]);

    return newWeaponId;
  }
});

function bn(x: number): BigNumber {
  return BigNumber.from(x);
}
