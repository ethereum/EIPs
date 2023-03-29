import { ethers } from "hardhat";
import { expect } from "chai";
import {
  ERC721ReceiverMock,
  MultiAssetReceiverMock,
  MultiAssetTokenMock,
  NonReceiverMock,
  MultiAssetRenderUtils,
} from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";

describe("MultiAsset", async () => {
  let token: MultiAssetTokenMock;
  let renderUtils: MultiAssetRenderUtils;
  let nonReceiver: NonReceiverMock;
  let receiver721: ERC721ReceiverMock;

  let owner: SignerWithAddress;
  let addrs: SignerWithAddress[];

  const name = "RmrkTest";
  const symbol = "RMRKTST";

  const metaURIDefault = "metaURI";

  beforeEach(async () => {
    const [signersOwner, ...signersAddr] = await ethers.getSigners();
    owner = signersOwner;
    addrs = signersAddr;

    const multiassetFactory = await ethers.getContractFactory(
      "MultiAssetTokenMock"
    );
    token = await multiassetFactory.deploy(name, symbol);
    await token.deployed();

    const renderFactory = await ethers.getContractFactory(
      "MultiAssetRenderUtils"
    );
    renderUtils = await renderFactory.deploy();
    await renderUtils.deployed();
  });

  describe("Init", async function () {
    it("Name", async function () {
      expect(await token.name()).to.equal(name);
    });

    it("Symbol", async function () {
      expect(await token.symbol()).to.equal(symbol);
    });
  });

  describe("ERC165 check", async function () {
    it("can support IERC165", async function () {
      expect(await token.supportsInterface("0x01ffc9a7")).to.equal(true);
    });

    it("can support IERC721", async function () {
      expect(await token.supportsInterface("0x80ac58cd")).to.equal(true);
    });

    it("can support IERC5773", async function () {
      expect(await token.supportsInterface("0x06b4329a")).to.equal(true);
    });

    it("cannot support other interfaceId", async function () {
      expect(await token.supportsInterface("0xffffffff")).to.equal(false);
    });
  });

  describe("Check OnReceived ERC721 and Multiasset", async function () {
    it("Revert on transfer to non onERC721/onMultiasset implementer", async function () {
      const tokenId = 1;
      await token.mint(owner.address, tokenId);

      const NonReceiver = await ethers.getContractFactory("NonReceiverMock");
      nonReceiver = await NonReceiver.deploy();
      await nonReceiver.deployed();

      await expect(
        token
          .connect(owner)
          ["safeTransferFrom(address,address,uint256)"](
            owner.address,
            nonReceiver.address,
            1
          )
      ).to.be.revertedWith(
        "MultiAsset: transfer to non ERC721 Receiver implementer"
      );
    });

    it("onERC721Received callback on transfer", async function () {
      const tokenId = 1;
      await token.mint(owner.address, tokenId);

      const ERC721Receiver = await ethers.getContractFactory(
        "ERC721ReceiverMock"
      );
      receiver721 = await ERC721Receiver.deploy();
      await receiver721.deployed();

      await token
        .connect(owner)
        ["safeTransferFrom(address,address,uint256)"](
          owner.address,
          receiver721.address,
          1
        );
      expect(await token.ownerOf(1)).to.equal(receiver721.address);
    });
  });

  describe("Asset storage", async function () {
    it("can add asset", async function () {
      const id = 10;

      await expect(token.addAssetEntry(id, metaURIDefault))
        .to.emit(token, "AssetSet")
        .withArgs(id);
    });

    it("cannot get non existing asset", async function () {
      const tokenId = 1;
      const resId = 10;
      await token.mint(owner.address, tokenId);
      await expect(token.getAssetMetadata(tokenId, resId)).to.be.revertedWith(
        "MultiAsset: Token does not have asset"
      );
    });

    it("cannot add asset entry if not issuer", async function () {
      const id = 10;
      await expect(
        token.connect(addrs[1]).addAssetEntry(id, metaURIDefault)
      ).to.be.revertedWith("RMRK: Only issuer");
    });

    it("can set and get issuer", async function () {
      const newIssuerAddr = addrs[1].address;
      expect(await token.getIssuer()).to.equal(owner.address);

      await token.setIssuer(newIssuerAddr);
      expect(await token.getIssuer()).to.equal(newIssuerAddr);
    });

    it("cannot set issuer if not issuer", async function () {
      const newIssuer = addrs[1];
      await expect(
        token.connect(newIssuer).setIssuer(newIssuer.address)
      ).to.be.revertedWith("RMRK: Only issuer");
    });

    it("cannot overwrite asset", async function () {
      const id = 10;

      await token.addAssetEntry(id, metaURIDefault);
      await expect(token.addAssetEntry(id, metaURIDefault)).to.be.revertedWith(
        "RMRK: asset already exists"
      );
    });

    it("cannot add asset with id 0", async function () {
      const id = ethers.utils.hexZeroPad("0x0", 8);

      await expect(token.addAssetEntry(id, metaURIDefault)).to.be.revertedWith(
        "RMRK: Write to zero"
      );
    });

    it("cannot add same asset twice", async function () {
      const id = 10;

      await expect(token.addAssetEntry(id, metaURIDefault))
        .to.emit(token, "AssetSet")
        .withArgs(id);

      await expect(token.addAssetEntry(id, metaURIDefault)).to.be.revertedWith(
        "RMRK: asset already exists"
      );
    });
  });

  describe("Adding assets", async function () {
    it("can add asset to token", async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId, resId2]);
      await expect(token.addAssetToToken(tokenId, resId, 0)).to.emit(
        token,
        "AssetAddedToTokens"
      );
      await expect(token.addAssetToToken(tokenId, resId2, 0)).to.emit(
        token,
        "AssetAddedToTokens"
      );

      const pendingIds = await token.getPendingAssets(tokenId);
      expect(
        await renderUtils.getAssetsById(token.address, tokenId, pendingIds)
      ).to.be.eql([metaURIDefault, metaURIDefault]);
    });

    it("cannot add non existing asset to token", async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await expect(token.addAssetToToken(tokenId, resId, 0)).to.be.revertedWith(
        "MultiAsset: Asset not found in storage"
      );
    });

    it("can add asset to non existing token and it is pending when minted", async function () {
      const resId = 1;
      const tokenId = 1;
      await addAssets([resId]);

      await token.addAssetToToken(tokenId, resId, 0);
      await token.mint(owner.address, tokenId);
      expect(await token.getPendingAssets(tokenId)).to.eql([
        ethers.BigNumber.from(resId),
      ]);
    });

    it("cannot add asset twice to the same token", async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId]);
      await token.addAssetToToken(tokenId, resId, 0);
      await expect(
        token.addAssetToToken(tokenId, ethers.BigNumber.from(resId), 0)
      ).to.be.revertedWith("MultiAsset: Asset already exists on token");
    });

    it("cannot add too many assets to the same token", async function () {
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      for (let i = 1; i <= 128; i++) {
        await addAssets([i]);
        await token.addAssetToToken(tokenId, i, 0);
      }

      // Now it's full, next should fail
      const resId = 129;
      await addAssets([resId]);
      await expect(token.addAssetToToken(tokenId, resId, 0)).to.be.revertedWith(
        "MultiAsset: Max pending assets reached"
      );
    });

    it("can add same asset to 2 different tokens", async function () {
      const resId = 1;
      const tokenId1 = 1;
      const tokenId2 = 2;

      await token.mint(owner.address, tokenId1);
      await token.mint(owner.address, tokenId2);
      await addAssets([resId]);
      await token.addAssetToToken(tokenId1, resId, 0);
      await token.addAssetToToken(tokenId2, resId, 0);
    });
  });

  describe("Accepting assets", async function () {
    it("can accept asset if owner", async function () {
      const { tokenOwner, tokenId } = await mintSampleToken();
      const approved = tokenOwner;

      await checkAcceptFromAddress(approved, tokenId);
    });

    it("can accept asset if approved for assets", async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[1];

      await token.approveForAssets(approved.address, tokenId);
      await checkAcceptFromAddress(approved, tokenId);
    });

    it("can accept asset if approved for assets for all", async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[2];

      await token.setApprovalForAllForAssets(approved.address, true);
      await checkAcceptFromAddress(approved, tokenId);
    });

    it("can accept multiple assets", async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId, resId2]);
      await token.addAssetToToken(tokenId, resId, 0);
      await token.addAssetToToken(tokenId, resId2, 0);
      await expect(token.acceptAsset(tokenId, 1, resId2))
        .to.emit(token, "AssetAccepted")
        .withArgs(tokenId, resId2, 0);
      await expect(token.acceptAsset(tokenId, 0, resId))
        .to.emit(token, "AssetAccepted")
        .withArgs(tokenId, resId, 0);

      expect(await token.getPendingAssets(tokenId)).to.be.eql([]);

      const activeIds = await token.getActiveAssets(tokenId);
      expect(
        await renderUtils.getAssetsById(token.address, tokenId, activeIds)
      ).to.eql([metaURIDefault, metaURIDefault]);
    });

    it("cannot accept asset twice", async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId]);
      await token.addAssetToToken(tokenId, resId, 0);
      await token.acceptAsset(tokenId, 0, resId);
    });

    it("cannot accept asset if not owner", async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId]);
      await token.addAssetToToken(tokenId, resId, 0);
      await expect(
        token.connect(addrs[1]).acceptAsset(tokenId, 0, resId)
      ).to.be.revertedWith("MultiAsset: not owner or approved");
    });

    it("cannot accept non existing asset", async function () {
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await expect(token.acceptAsset(tokenId, 0, 1)).to.be.revertedWith(
        "MultiAsset: index out of bounds"
      );
    });
  });

  describe("Overwriting assets", async function () {
    it("can add asset to token overwritting an existing one", async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId, resId2]);
      await token.addAssetToToken(tokenId, resId, 0);
      await token.acceptAsset(tokenId, 0, resId);

      // Add new asset to overwrite the first, and accept
      const activeAssets = await token.getActiveAssets(tokenId);
      await expect(token.addAssetToToken(tokenId, resId2, activeAssets[0]))
        .to.emit(token, "AssetAddedToTokens")
        .withArgs([tokenId], resId2, resId);
      const pendingAssets = await token.getPendingAssets(tokenId);

      expect(
        await token.getAssetReplacements(tokenId, pendingAssets[0])
      ).to.eql(activeAssets[0]);
      await expect(token.acceptAsset(tokenId, 0, resId2))
        .to.emit(token, "AssetAccepted")
        .withArgs(tokenId, resId2, resId);

      const activeIds = await token.getActiveAssets(tokenId);
      expect(
        await renderUtils.getAssetsById(token.address, tokenId, activeIds)
      ).to.eql([metaURIDefault]);
      // Overwrite should be gone
      expect(
        await token.getAssetReplacements(tokenId, pendingAssets[0])
      ).to.eql(ethers.BigNumber.from(0));
    });

    it("can overwrite non existing asset to token, it could have been deleted", async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId]);
      await token.addAssetToToken(
        tokenId,
        resId,
        ethers.utils.hexZeroPad("0x1", 8)
      );
      await token.acceptAsset(tokenId, 0, resId);

      const activeIds = await token.getActiveAssets(tokenId);
      expect(
        await renderUtils.getAssetsById(token.address, tokenId, activeIds)
      ).to.eql([metaURIDefault]);
    });

    it("can overwrite an existing asset after 3 have been added and 1 accepted", async function () {
      const resId = 1;
      const resId2 = 2;
      const resId3 = 3;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId, resId2, resId3]);
      await expect(token.addAssetToToken(tokenId, resId, 0)).to.emit(
        token,
        "AssetAddedToTokens"
      );
      await expect(token.addAssetToToken(tokenId, resId2, 0)).to.emit(
        token,
        "AssetAddedToTokens"
      );
      await expect(token.addAssetToToken(tokenId, resId3, resId2))
        .to.emit(token, "AssetAddedToTokens")
        .withArgs([tokenId], resId3, resId2);

      const pendingIds = await token.getPendingAssets(tokenId);

      expect(
        await renderUtils.getAssetsById(token.address, tokenId, pendingIds)
      ).to.be.eql([metaURIDefault, metaURIDefault, metaURIDefault]);

      await expect(token.acceptAsset(tokenId, 1, resId2))
        .to.emit(token, "AssetAccepted")
        .withArgs(tokenId, resId2, 0);

      await expect(token.acceptAsset(tokenId, 1, resId3))
        .to.emit(token, "AssetAccepted")
        .withArgs(tokenId, resId3, 2);
    });
  });

  describe("Rejecting assets", async function () {
    it("can reject asset if owner", async function () {
      const { tokenOwner, tokenId } = await mintSampleToken();
      const approved = tokenOwner;

      await checkRejectFromAddress(approved, tokenId);
    });

    it("can reject asset if approved for assets", async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[1];

      await token.approveForAssets(approved.address, tokenId);
      await checkRejectFromAddress(approved, tokenId);
    });

    it("can reject asset if approved for assets for all", async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[2];

      await token.setApprovalForAllForAssets(approved.address, true);
      await checkRejectFromAddress(approved, tokenId);
    });

    it("can reject all assets if owner", async function () {
      const { tokenOwner, tokenId } = await mintSampleToken();
      const approved = tokenOwner;

      await checkRejectAllFromAddress(approved, tokenId);
    });

    it("can reject all assets if approved for assets", async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[1];

      await token.approveForAssets(approved.address, tokenId);
      await checkRejectAllFromAddress(approved, tokenId);
    });

    it("can reject all assets if approved for assets for all", async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[2];

      await token.setApprovalForAllForAssets(approved.address, true);
      await checkRejectAllFromAddress(approved, tokenId);
    });

    it("can reject asset and overwrites are cleared", async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId, resId2]);
      await token.addAssetToToken(tokenId, resId, 0);
      await token.acceptAsset(tokenId, 0, resId);

      // Will try to overwrite but we reject it
      await token.addAssetToToken(tokenId, resId2, resId);
      await token.rejectAsset(tokenId, 0, resId2);

      expect(await token.getAssetReplacements(tokenId, resId2)).to.eql(
        ethers.BigNumber.from(0)
      );
    });

    it("can reject all assets and overwrites are cleared", async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId, resId2]);
      await token.addAssetToToken(tokenId, resId, 0);
      await token.acceptAsset(tokenId, 0, resId);

      // Will try to overwrite but we reject all
      await token.addAssetToToken(tokenId, resId2, resId);
      await token.rejectAllAssets(tokenId, 1);

      expect(await token.getAssetReplacements(tokenId, resId2)).to.eql(
        ethers.BigNumber.from(0)
      );
    });

    it("can reject all pending assets at max capacity", async function () {
      const tokenId = 1;
      const resArr = [];

      for (let i = 1; i < 128; i++) {
        resArr.push(i);
      }

      await token.mint(owner.address, tokenId);
      await addAssets(resArr);

      for (let i = 1; i < 128; i++) {
        await token.addAssetToToken(tokenId, i, 1);
      }
      await token.rejectAllAssets(tokenId, 128);

      expect(await token.getAssetReplacements(1, 2)).to.eql(
        ethers.BigNumber.from(0)
      );
    });

    it("cannot reject asset twice", async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId]);
      await token.addAssetToToken(tokenId, resId, 0);
      await token.rejectAsset(tokenId, 0, resId);
    });

    it("cannot reject asset nor reject all if not owner", async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addAssets([resId]);
      await token.addAssetToToken(tokenId, resId, 0);

      await expect(
        token.connect(addrs[1]).rejectAsset(tokenId, 0, resId)
      ).to.be.revertedWith("MultiAsset: not owner or approved");
      await expect(
        token.connect(addrs[1]).rejectAllAssets(tokenId, 1)
      ).to.be.revertedWith("MultiAsset: not owner or approved");
    });

    it("cannot reject non existing asset", async function () {
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await expect(token.rejectAsset(tokenId, 0, 1)).to.be.revertedWith(
        "MultiAsset: index out of bounds"
      );
    });
  });

  describe("Priorities", async function () {
    it("can set and get priorities", async function () {
      const tokenId = 1;
      await addAssetsToToken(tokenId);

      expect(await token.getActiveAssetPriorities(tokenId)).to.be.eql([BigNumber.from(0), BigNumber.from(1)]);
      await expect(token.setPriority(tokenId, [2, 1]))
        .to.emit(token, "AssetPrioritySet")
        .withArgs(tokenId);
      expect(await token.getActiveAssetPriorities(tokenId)).to.be.eql([BigNumber.from(2), BigNumber.from(1)]);
    });

    it("cannot set priorities for non owned token", async function () {
      const tokenId = 1;
      await addAssetsToToken(tokenId);
      await expect(
        token.connect(addrs[1]).setPriority(tokenId, [2, 1])
      ).to.be.revertedWith("MultiAsset: not owner or approved");
    });

    it("cannot set different number of priorities", async function () {
      const tokenId = 1;
      await addAssetsToToken(tokenId);
      await expect(
        token.connect(addrs[1]).setPriority(tokenId, [1])
      ).to.be.revertedWith("MultiAsset: Bad priority list length");
      await expect(
        token.connect(addrs[1]).setPriority(tokenId, [2, 1, 3])
      ).to.be.revertedWith("MultiAsset: Bad priority list length");
    });

    it("cannot set priorities for non existing token", async function () {
      const tokenId = 1;
      await expect(
        token.connect(addrs[1]).setPriority(tokenId, [])
      ).to.be.revertedWith("MultiAsset: approved query for nonexistent token");
    });
  });

  describe("Approval Cleaning", async function () {
    it("cleans token and assets approvals on transfer", async function () {
      const tokenId = 1;
      const tokenOwner = addrs[1];
      const newOwner = addrs[2];
      const approved = addrs[3];
      await token.mint(tokenOwner.address, tokenId);
      await token.connect(tokenOwner).approve(approved.address, tokenId);
      await token
        .connect(tokenOwner)
        .approveForAssets(approved.address, tokenId);

      expect(await token.getApproved(tokenId)).to.eql(approved.address);
      expect(await token.getApprovedForAssets(tokenId)).to.eql(
        approved.address
      );

      await token.connect(tokenOwner).transfer(newOwner.address, tokenId);

      expect(await token.getApproved(tokenId)).to.eql(
        ethers.constants.AddressZero
      );
      expect(await token.getApprovedForAssets(tokenId)).to.eql(
        ethers.constants.AddressZero
      );
    });

    it("cleans token and assets approvals on burn", async function () {
      const tokenId = 1;
      const tokenOwner = addrs[1];
      const approved = addrs[3];
      await token.mint(tokenOwner.address, tokenId);
      await token.connect(tokenOwner).approve(approved.address, tokenId);
      await token
        .connect(tokenOwner)
        .approveForAssets(approved.address, tokenId);

      expect(await token.getApproved(tokenId)).to.eql(approved.address);
      expect(await token.getApprovedForAssets(tokenId)).to.eql(
        approved.address
      );

      await token.connect(tokenOwner).burn(tokenId);

      await expect(token.getApproved(tokenId)).to.be.revertedWith(
        "MultiAsset: approved query for nonexistent token"
      );
      await expect(token.getApprovedForAssets(tokenId)).to.be.revertedWith(
        "MultiAsset: approved query for nonexistent token"
      );
    });
  });

  async function mintSampleToken(): Promise<{
    tokenOwner: SignerWithAddress;
    tokenId: number;
  }> {
    const tokenOwner = owner;
    const tokenId = 1;
    await token.mint(tokenOwner.address, tokenId);

    return { tokenOwner, tokenId };
  }

  async function addAssets(ids: number[]): Promise<void> {
    ids.forEach(async (resId) => {
      await token.addAssetEntry(resId, metaURIDefault);
    });
  }

  async function addAssetsToToken(tokenId: number): Promise<void> {
    const resId = 1;
    const resId2 = 2;
    await token.mint(owner.address, tokenId);
    await addAssets([resId, resId2]);
    await token.addAssetToToken(tokenId, resId, 0);
    await token.addAssetToToken(tokenId, resId2, 0);
    await token.acceptAsset(tokenId, 0, resId);
    await token.acceptAsset(tokenId, 0, resId2);
  }

  async function checkAcceptFromAddress(
    accepter: SignerWithAddress,
    tokenId: number
  ): Promise<void> {
    const resId = 1;

    await addAssets([resId]);
    await token.addAssetToToken(tokenId, resId, 0);
    await expect(token.connect(accepter).acceptAsset(tokenId, 0, resId))
      .to.emit(token, "AssetAccepted")
      .withArgs(tokenId, resId, 0);

    expect(await token.getPendingAssets(tokenId)).to.be.eql([]);

    const activeIds = await token.getActiveAssets(tokenId);
    expect(
      await renderUtils.getAssetsById(token.address, tokenId, activeIds)
    ).to.eql([metaURIDefault]);
  }

  async function checkRejectFromAddress(
    rejecter: SignerWithAddress,
    tokenId: number
  ): Promise<void> {
    const resId = 1;

    await addAssets([resId]);
    await token.addAssetToToken(tokenId, resId, 0);

    await expect(
      token.connect(rejecter).rejectAsset(tokenId, 0, resId)
    ).to.emit(token, "AssetRejected");

    expect(await token.getPendingAssets(tokenId)).to.be.eql([]);
    expect(await token.getActiveAssets(tokenId)).to.be.eql([]);
  }

  async function checkRejectAllFromAddress(
    rejecter: SignerWithAddress,
    tokenId: number
  ): Promise<void> {
    const resId = 1;
    const resId2 = 2;

    await addAssets([resId, resId2]);
    await token.addAssetToToken(tokenId, resId, 0);
    await token.addAssetToToken(tokenId, resId2, 0);

    await expect(token.connect(rejecter).rejectAllAssets(tokenId, 2)).to.emit(
      token,
      "AssetRejected"
    );

    expect(await token.getPendingAssets(tokenId)).to.be.eql([]);
    expect(await token.getActiveAssets(tokenId)).to.be.eql([]);
  }
});
