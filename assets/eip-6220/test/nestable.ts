import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, constants } from "ethers";
import { ethers } from "hardhat";
import { EquippableTokenMock } from "../typechain-types";

function bn(x: number): BigNumber {
  return BigNumber.from(x);
}

const ADDRESS_ZERO = constants.AddressZero;

async function parentChildFixture(): Promise<{
  parent: EquippableTokenMock;
  child: EquippableTokenMock;
}> {
  const factory = await ethers.getContractFactory("EquippableTokenMock");

  const parent = await factory.deploy();
  await parent.deployed();
  const child = await factory.deploy();
  await child.deployed();
  return { parent, child };
}

describe("NestableToken", function () {
  let parent: EquippableTokenMock;
  let child: EquippableTokenMock;
  let owner: SignerWithAddress;
  let tokenOwner: SignerWithAddress;
  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    [owner, tokenOwner, ...addrs] = await ethers.getSigners();
    ({ parent, child } = await loadFixture(parentChildFixture));
  });

  describe("Minting", async function () {
    it("cannot mint id 0", async function () {
      const tokenId1 = 0;
      await expect(
        child.mint(owner.address, tokenId1)
      ).to.be.revertedWithCustomError(child, "IdZeroForbidden");
    });

    it("cannot nest mint id 0", async function () {
      const parentId = 1;
      await child.mint(owner.address, parentId);
      const childId1 = 0;
      await expect(
        child.nestMint(parent.address, childId1, parentId)
      ).to.be.revertedWithCustomError(child, "IdZeroForbidden");
    });

    it("cannot mint already minted token", async function () {
      const tokenId1 = 1;
      await child.mint(owner.address, tokenId1);
      await expect(
        child.mint(owner.address, tokenId1)
      ).to.be.revertedWithCustomError(child, "ERC721TokenAlreadyMinted");
    });

    it("cannot nest mint already minted token", async function () {
      const parentId = 1;
      const childId1 = 99;
      await parent.mint(owner.address, parentId);
      await child.nestMint(parent.address, childId1, parentId);

      await expect(
        child.nestMint(parent.address, childId1, parentId)
      ).to.be.revertedWithCustomError(child, "ERC721TokenAlreadyMinted");
    });

    it("cannot nest mint already minted token", async function () {
      const parentId = 1;
      const childId1 = 99;
      await parent.mint(owner.address, parentId);
      await child.nestMint(parent.address, childId1, parentId);

      await expect(
        child.nestMint(parent.address, childId1, parentId)
      ).to.be.revertedWithCustomError(child, "ERC721TokenAlreadyMinted");
    });

    it("can mint with no destination", async function () {
      const tokenId1 = 1;
      await child.mint(tokenOwner.address, tokenId1);
      expect(await child.ownerOf(tokenId1)).to.equal(tokenOwner.address);
      expect(await child.directOwnerOf(tokenId1)).to.eql([
        tokenOwner.address,
        bn(0),
        false,
      ]);
    });

    it("has right owners", async function () {
      const otherOwner = addrs[2];
      const tokenId1 = 1;
      await parent.mint(tokenOwner.address, tokenId1);
      const tokenId2 = 2;
      await parent.mint(otherOwner.address, tokenId2);
      const tokenId3 = 3;
      await parent.mint(otherOwner.address, tokenId3);

      expect(await parent.ownerOf(tokenId1)).to.equal(tokenOwner.address);
      expect(await parent.ownerOf(tokenId2)).to.equal(otherOwner.address);
      expect(await parent.ownerOf(tokenId3)).to.equal(otherOwner.address);

      expect(await parent.balanceOf(tokenOwner.address)).to.equal(1);
      expect(await parent.balanceOf(otherOwner.address)).to.equal(2);

      await expect(parent.ownerOf(9999)).to.be.revertedWithCustomError(
        parent,
        "ERC721InvalidTokenId"
      );
    });

    it("cannot mint to zero address", async function () {
      await expect(child.mint(ADDRESS_ZERO, 1)).to.be.revertedWithCustomError(
        child,
        "ERC721MintToTheZeroAddress"
      );
    });

    it("cannot nest mint to a non-contract destination", async function () {
      await expect(
        child.nestMint(tokenOwner.address, 1, 1)
      ).to.be.revertedWithCustomError(child, "IsNotContract");
    });

    it("cannot nest mint to non nestable receiver", async function () {
      const ERC721 = await ethers.getContractFactory("ERC721Mock");
      const nonReceiver = await ERC721.deploy("Non receiver", "NR");
      await nonReceiver.deployed();

      await expect(
        child.nestMint(nonReceiver.address, 1, 1)
      ).to.be.revertedWithCustomError(child, "MintToNonNestableImplementer");
    });

    it("cannot nest mint to a non-existent token", async function () {
      await expect(
        child.nestMint(parent.address, 1, 1)
      ).to.be.revertedWithCustomError(child, "ERC721InvalidTokenId");
    });

    it("cannot nest mint to zero address", async function () {
      const parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
      await expect(
        child.nestMint(ADDRESS_ZERO, parentId, 1)
      ).to.be.revertedWithCustomError(child, "IsNotContract");
    });

    it("can mint to contract and owners are ok", async function () {
      const parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
      const childId1 = 99;
      await child.nestMint(parent.address, childId1, parentId);

      // owner is the same adress
      expect(await parent.ownerOf(parentId)).to.equal(tokenOwner.address);
      expect(await child.ownerOf(childId1)).to.equal(tokenOwner.address);

      expect(await parent.balanceOf(tokenOwner.address)).to.equal(1);
      expect(await child.balanceOf(parent.address)).to.equal(1);
    });

    it("can mint to contract and direct owners are ok", async function () {
      const parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
      const childId1 = 99;
      await child.nestMint(parent.address, childId1, parentId);

      // Direct owner is an address for the parent
      expect(await parent.directOwnerOf(parentId)).to.eql([
        tokenOwner.address,
        bn(0),
        false,
      ]);
      // Direct owner is a contract for the child
      expect(await child.directOwnerOf(childId1)).to.eql([
        parent.address,
        bn(parentId),
        true,
      ]);
    });

    it("can mint to contract and parent's children are ok", async function () {
      const parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
      const childId1 = 99;
      await child.nestMint(parent.address, childId1, parentId);

      const children = await parent.childrenOf(parentId);
      expect(children).to.eql([]);

      const pendingChildren = await parent.pendingChildrenOf(parentId);
      expect(pendingChildren).to.eql([[bn(childId1), child.address]]);
      expect(await parent.pendingChildOf(parentId, 0)).to.eql([
        bn(childId1),
        child.address,
      ]);
    });

    it("cannot get child out of index", async function () {
      const parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
      await expect(parent.childOf(parentId, 0)).to.be.revertedWithCustomError(
        parent,
        "ChildIndexOutOfRange"
      );
    });

    it("cannot get pending child out of index", async function () {
      const parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
      await expect(
        parent.pendingChildOf(parentId, 0)
      ).to.be.revertedWithCustomError(parent, "PendingChildIndexOutOfRange");
    });

    it("can mint multiple children", async function () {
      const parentId = 1;
      const childId1 = 99;
      const childId2 = 100;
      await parent.mint(tokenOwner.address, parentId);
      await child.nestMint(parent.address, childId1, parentId);
      await child.nestMint(parent.address, childId2, parentId);

      expect(await child.ownerOf(childId1)).to.equal(tokenOwner.address);
      expect(await child.ownerOf(childId2)).to.equal(tokenOwner.address);

      expect(await child.balanceOf(parent.address)).to.equal(2);

      const pendingChildren = await parent.pendingChildrenOf(parentId);
      expect(pendingChildren).to.eql([
        [bn(childId1), child.address],
        [bn(childId2), child.address],
      ]);
    });

    it("can mint child into child", async function () {
      const parentId = 1;
      const childId1 = 99;
      const granchildId = 999;
      await parent.mint(tokenOwner.address, parentId);
      await child.nestMint(parent.address, childId1, parentId);
      await child.nestMint(child.address, granchildId, childId1);

      // Check balances -- yes, technically the counted balance indicates `child` owns an instance of itself
      // and this is a little counterintuitive, but the root owner is the EOA.
      expect(await child.balanceOf(parent.address)).to.equal(1);
      expect(await child.balanceOf(child.address)).to.equal(1);

      const pendingChildrenOfChunky10 = await parent.pendingChildrenOf(
        parentId
      );
      const pendingChildrenOfMonkey1 = await child.pendingChildrenOf(childId1);

      expect(pendingChildrenOfChunky10).to.eql([[bn(childId1), child.address]]);
      expect(pendingChildrenOfMonkey1).to.eql([
        [bn(granchildId), child.address],
      ]);

      expect(await child.directOwnerOf(granchildId)).to.eql([
        child.address,
        bn(childId1),
        true,
      ]);

      expect(await child.ownerOf(granchildId)).to.eql(tokenOwner.address);
    });

    it("cannot have too many pending children", async () => {
      const parentId = 1;
      await parent.mint(tokenOwner.address, parentId);

      // First 128 should be fine.
      for (let i = 1; i <= 128; i++) {
        await child.nestMint(parent.address, i, parentId);
      }

      await expect(
        child.nestMint(parent.address, 129, parentId)
      ).to.be.revertedWithCustomError(child, "MaxPendingChildrenReached");
    });
  });

  describe("Interface support", async function () {
    it("can support IERC165", async function () {
      expect(await parent.supportsInterface("0x01ffc9a7")).to.equal(true);
    });

    it("can support IERC721", async function () {
      expect(await parent.supportsInterface("0x80ac58cd")).to.equal(true);
    });

    it("can support INestable", async function () {
      expect(await parent.supportsInterface("0x42b0e56f")).to.equal(true);
    });

    it("cannot support other interfaceId", async function () {
      expect(await parent.supportsInterface("0xffffffff")).to.equal(false);
    });
  });

  describe("Adding child", async function () {
    it("cannot add child from user address", async function () {
      const tokenOwner1 = addrs[0];
      const tokenOwner2 = addrs[1];
      const parentId = 1;
      await parent.mint(tokenOwner1.address, parentId);
      const childId1 = 99;
      await child.mint(tokenOwner2.address, childId1);
      await expect(
        parent.addChild(parentId, childId1, "0x")
      ).to.be.revertedWithCustomError(parent, "IsNotContract");
    });
  });

  describe("Accept child", async function () {
    let parentId: number;
    let childId1: number;

    beforeEach(async function () {
      parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
      childId1 = 99;
      await child.nestMint(parent.address, childId1, parentId);
    });

    it("can accept child", async function () {
      await expect(
        parent
          .connect(tokenOwner)
          .acceptChild(parentId, 0, child.address, childId1)
      )
        .to.emit(parent, "ChildAccepted")
        .withArgs(parentId, 0, child.address, childId1);
      await checkChildWasAccepted();
    });

    it("can accept child if approved", async function () {
      const approved = addrs[1];
      await parent.connect(tokenOwner).approve(approved.address, parentId);
      await parent
        .connect(approved)
        .acceptChild(parentId, 0, child.address, childId1);
      await checkChildWasAccepted();
    });

    it("can accept child if approved for all", async function () {
      const operator = addrs[2];
      await parent
        .connect(tokenOwner)
        .setApprovalForAll(operator.address, true);
      await parent
        .connect(operator)
        .acceptChild(parentId, 0, child.address, childId1);
      await checkChildWasAccepted();
    });

    it("cannot accept not owned child", async function () {
      const notOwner = addrs[3];
      await expect(
        parent
          .connect(notOwner)
          .acceptChild(parentId, 0, child.address, childId1)
      ).to.be.revertedWithCustomError(parent, "ERC721NotApprovedOrOwner");
    });

    it("cannot accept child if address or id do not match", async function () {
      const otherAddress = addrs[1].address;
      const otherChildId = 9999;
      await expect(
        parent
          .connect(tokenOwner)
          .acceptChild(parentId, 0, child.address, otherChildId)
      ).to.be.revertedWithCustomError(parent, "UnexpectedChildId");
      await expect(
        parent
          .connect(tokenOwner)
          .acceptChild(parentId, 0, otherAddress, childId1)
      ).to.be.revertedWithCustomError(parent, "UnexpectedChildId");
    });

    it("cannot accept children for non existing index", async () => {
      await expect(
        parent
          .connect(tokenOwner)
          .acceptChild(parentId, 1, child.address, childId1)
      ).to.be.revertedWithCustomError(parent, "PendingChildIndexOutOfRange");
    });

    async function checkChildWasAccepted() {
      expect(await parent.pendingChildrenOf(parentId)).to.eql([]);
      expect(await parent.childrenOf(parentId)).to.eql([
        [bn(childId1), child.address],
      ]);
    }
  });

  describe("Rejecting children", async function () {
    let parentId: number;

    beforeEach(async function () {
      parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
      await child.nestMint(parent.address, 99, parentId);
    });

    it("can reject all pending children", async function () {
      // Mint a couple of more children
      await child.nestMint(parent.address, 100, parentId);
      await child.nestMint(parent.address, 101, parentId);

      await expect(parent.connect(tokenOwner).rejectAllChildren(parentId, 3))
        .to.emit(parent, "AllChildrenRejected")
        .withArgs(parentId);
      await checkNoChildrenNorPending(parentId);

      // They are still on the child
      expect(await child.balanceOf(parent.address)).to.equal(3);
    });

    it("cannot reject all pending children if there are more than expected", async function () {
      // Mint a couple of more children
      await child.nestMint(parent.address, 100, parentId);
      await child.nestMint(parent.address, 101, parentId);

      await expect(
        parent.connect(tokenOwner).rejectAllChildren(parentId, 1)
      ).to.be.revertedWithCustomError(parent, "UnexpectedNumberOfChildren");
    });

    it("can reject all pending children if approved", async function () {
      // Mint a couple of more children
      await child.nestMint(parent.address, 100, parentId);
      await child.nestMint(parent.address, 101, parentId);

      const rejecter = addrs[1];
      await parent.connect(tokenOwner).approve(rejecter.address, parentId);
      await parent.connect(rejecter).rejectAllChildren(parentId, 3);
      await checkNoChildrenNorPending(parentId);
    });

    it("can reject all pending children if approved for all", async function () {
      // Mint a couple of more children
      await child.nestMint(parent.address, 100, parentId);
      await child.nestMint(parent.address, 101, parentId);

      const operator = addrs[2];
      await parent
        .connect(tokenOwner)
        .setApprovalForAll(operator.address, true);
      await parent.connect(operator).rejectAllChildren(parentId, 3);
      await checkNoChildrenNorPending(parentId);
    });

    it("cannot reject all pending children for not owned pending child", async function () {
      const notOwner = addrs[3];

      await expect(
        parent.connect(notOwner).rejectAllChildren(parentId, 2)
      ).to.be.revertedWithCustomError(parent, "ERC721NotApprovedOrOwner");
    });
  });

  describe("Burning", async function () {
    let parentId: number;

    beforeEach(async function () {
      parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
    });

    it("can burn token", async function () {
      expect(await parent.balanceOf(tokenOwner.address)).to.equal(1);
      await parent.connect(tokenOwner)["burn(uint256)"](parentId);
      await checkBurntParent();
    });

    it("can burn token if approved", async function () {
      const approved = addrs[1];
      await parent.connect(tokenOwner).approve(approved.address, parentId);
      await parent.connect(approved)["burn(uint256)"](parentId);
      await checkBurntParent();
    });

    it("can burn token if approved for all", async function () {
      const operator = addrs[2];
      await parent
        .connect(tokenOwner)
        .setApprovalForAll(operator.address, true);
      await parent.connect(operator)["burn(uint256)"](parentId);
      await checkBurntParent();
    });

    it("can recursively burn nested token", async function () {
      const childId1 = 99;
      const granchildId = 999;
      await child.nestMint(parent.address, childId1, parentId);
      await child.nestMint(child.address, granchildId, childId1);
      await parent
        .connect(tokenOwner)
        .acceptChild(parentId, 0, child.address, childId1);
      await child
        .connect(tokenOwner)
        .acceptChild(childId1, 0, child.address, granchildId);

      expect(await parent.balanceOf(tokenOwner.address)).to.equal(1);
      expect(await child.balanceOf(parent.address)).to.equal(1);
      expect(await child.balanceOf(child.address)).to.equal(1);

      expect(await parent.childrenOf(parentId)).to.eql([
        [bn(childId1), child.address],
      ]);
      expect(await child.childrenOf(childId1)).to.eql([
        [bn(granchildId), child.address],
      ]);
      expect(await child.directOwnerOf(granchildId)).to.eql([
        child.address,
        bn(childId1),
        true,
      ]);

      // Sets recursive burns to 2
      await parent.connect(tokenOwner)["burn(uint256,uint256)"](parentId, 2);

      expect(await parent.balanceOf(tokenOwner.address)).to.equal(0);
      expect(await child.balanceOf(parent.address)).to.equal(0);
      expect(await child.balanceOf(child.address)).to.equal(0);

      await expect(parent.ownerOf(parentId)).to.be.revertedWithCustomError(
        parent,
        "ERC721InvalidTokenId"
      );
      await expect(
        parent.directOwnerOf(parentId)
      ).to.be.revertedWithCustomError(parent, "ERC721InvalidTokenId");

      await expect(child.ownerOf(childId1)).to.be.revertedWithCustomError(
        child,
        "ERC721InvalidTokenId"
      );
      await expect(child.directOwnerOf(childId1)).to.be.revertedWithCustomError(
        child,
        "ERC721InvalidTokenId"
      );

      await expect(parent.ownerOf(granchildId)).to.be.revertedWithCustomError(
        parent,
        "ERC721InvalidTokenId"
      );
      await expect(
        parent.directOwnerOf(granchildId)
      ).to.be.revertedWithCustomError(parent, "ERC721InvalidTokenId");
    });

    it("can recursively burn nested token with the right number of recursive burns", async function () {
      // Parent
      // -> Child1
      //      -> GrandChild1
      //      -> GrandChild2
      //        -> GreatGrandChild1
      // -> Child2
      // Total tree 5 (4 recursive burns)
      const childId1 = 99;
      const childId2 = 100;
      const grandChild1 = 999;
      const grandChild2 = 1000;
      const greatGrandChild1 = 9999;
      await child.nestMint(parent.address, childId1, parentId);
      await child.nestMint(parent.address, childId2, parentId);
      await child.nestMint(child.address, grandChild1, childId1);
      await child.nestMint(child.address, grandChild2, childId1);
      await child.nestMint(child.address, greatGrandChild1, grandChild2);
      await parent
        .connect(tokenOwner)
        .acceptChild(parentId, 0, child.address, childId1);
      await parent
        .connect(tokenOwner)
        .acceptChild(parentId, 0, child.address, childId2);
      await child
        .connect(tokenOwner)
        .acceptChild(childId1, 0, child.address, grandChild1);
      await child
        .connect(tokenOwner)
        .acceptChild(childId1, 0, child.address, grandChild2);
      await child
        .connect(tokenOwner)
        .acceptChild(grandChild2, 0, child.address, greatGrandChild1);

      // 0 is not enough
      await expect(
        parent.connect(tokenOwner)["burn(uint256,uint256)"](parentId, 0)
      )
        .to.be.revertedWithCustomError(parent, "MaxRecursiveBurnsReached")
        .withArgs(child.address, childId1);
      // 1 is not enough
      await expect(
        parent.connect(tokenOwner)["burn(uint256,uint256)"](parentId, 1)
      )
        .to.be.revertedWithCustomError(parent, "MaxRecursiveBurnsReached")
        .withArgs(child.address, grandChild1);
      // 2 is not enough
      await expect(
        parent.connect(tokenOwner)["burn(uint256,uint256)"](parentId, 2)
      )
        .to.be.revertedWithCustomError(parent, "MaxRecursiveBurnsReached")
        .withArgs(child.address, grandChild2);
      // 3 is not enough
      await expect(
        parent.connect(tokenOwner)["burn(uint256,uint256)"](parentId, 3)
      )
        .to.be.revertedWithCustomError(parent, "MaxRecursiveBurnsReached")
        .withArgs(child.address, greatGrandChild1);
      // 4 is not enough
      await expect(
        parent.connect(tokenOwner)["burn(uint256,uint256)"](parentId, 4)
      )
        .to.be.revertedWithCustomError(parent, "MaxRecursiveBurnsReached")
        .withArgs(child.address, childId2);
      // 5 is just enough
      await parent.connect(tokenOwner)["burn(uint256,uint256)"](parentId, 5);
    });

    async function checkBurntParent() {
      expect(await parent.balanceOf(addrs[1].address)).to.equal(0);
      await expect(parent.ownerOf(parentId)).to.be.revertedWithCustomError(
        parent,
        "ERC721InvalidTokenId"
      );
    }
  });

  describe("Transferring Active Children", async function () {
    let parentId: number;
    let childId1: number;

    beforeEach(async function () {
      parentId = 1;
      childId1 = 99;
      await parent.mint(tokenOwner.address, parentId);
      await child.nestMint(parent.address, childId1, parentId);
      await parent
        .connect(tokenOwner)
        .acceptChild(parentId, 0, child.address, childId1);
    });

    it("can transfer child with to as root owner", async function () {
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            tokenOwner.address,
            0,
            0,
            child.address,
            childId1,
            false,
            "0x"
          )
      )
        .to.emit(parent, "ChildTransferred")
        .withArgs(parentId, 0, child.address, childId1, false);

      await checkChildMovedToRootOwner();
    });

    it("can transfer child to another address", async function () {
      const toOwnerAddress = addrs[2].address;
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            toOwnerAddress,
            0,
            0,
            child.address,
            childId1,
            false,
            "0x"
          )
      )
        .to.emit(parent, "ChildTransferred")
        .withArgs(parentId, 0, child.address, childId1, false);

      await checkChildMovedToRootOwner(toOwnerAddress);
    });

    it("can transfer child to another NFT", async function () {
      const newOwnerAddress = addrs[2].address;
      const newParentId = 2;
      await parent.mint(newOwnerAddress, newParentId);
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            parent.address,
            newParentId,
            0,
            child.address,
            childId1,
            false,
            "0x"
          )
      )
        .to.emit(parent, "ChildTransferred")
        .withArgs(parentId, 0, child.address, childId1, false);

      expect(await child.ownerOf(childId1)).to.eql(newOwnerAddress);
      expect(await child.directOwnerOf(childId1)).to.eql([
        parent.address,
        bn(newParentId),
        true,
      ]);
      expect(await parent.pendingChildrenOf(newParentId)).to.eql([
        [bn(childId1), child.address],
      ]);
    });

    it("cannot transfer child out of index", async function () {
      const toOwnerAddress = addrs[2].address;
      const badIndex = 2;
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            toOwnerAddress,
            0,
            badIndex,
            child.address,
            childId1,
            false,
            "0x"
          )
      ).to.be.revertedWithCustomError(parent, "ChildIndexOutOfRange");
    });

    it("cannot transfer child if address or id do not match", async function () {
      const otherAddress = addrs[1].address;
      const otherChildId = 9999;
      const toOwnerAddress = addrs[2].address;
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            toOwnerAddress,
            0,
            0,
            otherAddress,
            childId1,
            false,
            "0x"
          )
      ).to.be.revertedWithCustomError(parent, "UnexpectedChildId");
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            toOwnerAddress,
            0,
            0,
            child.address,
            otherChildId,
            false,
            "0x"
          )
      ).to.be.revertedWithCustomError(parent, "UnexpectedChildId");
    });

    it("can transfer child if approved", async function () {
      const transferer = addrs[1];
      const toOwner = tokenOwner.address;
      await parent.connect(tokenOwner).approve(transferer.address, parentId);

      await parent
        .connect(transferer)
        .transferChild(
          parentId,
          toOwner,
          0,
          0,
          child.address,
          childId1,
          false,
          "0x"
        );
      await checkChildMovedToRootOwner();
    });

    it("can transfer child if approved for all", async function () {
      const operator = addrs[2];
      const toOwner = tokenOwner.address;
      await parent
        .connect(tokenOwner)
        .setApprovalForAll(operator.address, true);

      await parent
        .connect(operator)
        .transferChild(
          parentId,
          toOwner,
          0,
          0,
          child.address,
          childId1,
          false,
          "0x"
        );
      await checkChildMovedToRootOwner();
    });

    it("can transfer child with grandchild and children are ok", async function () {
      const toOwner = tokenOwner.address;
      const grandchildId = 999;
      await child.nestMint(child.address, grandchildId, childId1);

      // Transfer child from parent.
      await parent
        .connect(tokenOwner)
        .transferChild(
          parentId,
          toOwner,
          0,
          0,
          child.address,
          childId1,
          false,
          "0x"
        );

      // New owner of child
      expect(await child.ownerOf(childId1)).to.eql(tokenOwner.address);
      expect(await child.directOwnerOf(childId1)).to.eql([
        tokenOwner.address,
        bn(0),
        false,
      ]);

      // Grandchild is still owned by child
      expect(await child.ownerOf(grandchildId)).to.eql(tokenOwner.address);
      expect(await child.directOwnerOf(grandchildId)).to.eql([
        child.address,
        bn(childId1),
        true,
      ]);
    });

    it("cannot transfer child if not child root owner", async function () {
      const toOwner = tokenOwner.address;
      const notOwner = addrs[3];
      await expect(
        parent
          .connect(notOwner)
          .transferChild(
            parentId,
            toOwner,
            0,
            0,
            child.address,
            childId1,
            false,
            "0x"
          )
      ).to.be.revertedWithCustomError(child, "ERC721NotApprovedOrOwner");
    });

    it("cannot transfer child from not existing parent", async function () {
      const badChildId = 99;
      const toOwner = tokenOwner.address;
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            badChildId,
            toOwner,
            0,
            0,
            child.address,
            childId1,
            false,
            "0x"
          )
      ).to.be.revertedWithCustomError(child, "ERC721InvalidTokenId");
    });

    async function checkChildMovedToRootOwner(rootOwnerAddress?: string) {
      if (rootOwnerAddress === undefined) {
        rootOwnerAddress = tokenOwner.address;
      }
      expect(await child.ownerOf(childId1)).to.eql(rootOwnerAddress);
      expect(await child.directOwnerOf(childId1)).to.eql([
        rootOwnerAddress,
        bn(0),
        false,
      ]);

      // Transferring updates balances downstream
      expect(await child.balanceOf(rootOwnerAddress)).to.equal(1);
      expect(await parent.balanceOf(tokenOwner.address)).to.equal(1);
    }
  });

  describe("Transferring Pending Children", async function () {
    let parentId: number;
    let childId1: number;

    beforeEach(async function () {
      parentId = 1;
      await parent.mint(tokenOwner.address, parentId);
      childId1 = 99;
      await child.nestMint(parent.address, childId1, parentId);
    });

    it("can transfer child with to as root owner", async function () {
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            tokenOwner.address,
            0,
            0,
            child.address,
            childId1,
            true,
            "0x"
          )
      )
        .to.emit(parent, "ChildTransferred")
        .withArgs(parentId, 0, child.address, childId1, true);

      await checkChildMovedToRootOwner();
    });

    it("can transfer child to another address", async function () {
      const toOwnerAddress = addrs[2].address;
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            toOwnerAddress,
            0,
            0,
            child.address,
            childId1,
            true,
            "0x"
          )
      )
        .to.emit(parent, "ChildTransferred")
        .withArgs(parentId, 0, child.address, childId1, true);

      await checkChildMovedToRootOwner(toOwnerAddress);
    });

    it("can transfer child to another NFT", async function () {
      const newOwnerAddress = addrs[2].address;
      const newParentId = 2;
      await parent.mint(newOwnerAddress, newParentId);
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            parent.address,
            newParentId,
            0,
            child.address,
            childId1,
            true,
            "0x"
          )
      )
        .to.emit(parent, "ChildTransferred")
        .withArgs(parentId, 0, child.address, childId1, true);

      expect(await child.ownerOf(childId1)).to.eql(newOwnerAddress);
      expect(await child.directOwnerOf(childId1)).to.eql([
        parent.address,
        bn(newParentId),
        true,
      ]);
      expect(await parent.pendingChildrenOf(newParentId)).to.eql([
        [bn(childId1), child.address],
      ]);
    });

    it("cannot transfer child out of index", async function () {
      const toOwnerAddress = addrs[2].address;
      const badIndex = 2;
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            toOwnerAddress,
            0,
            badIndex,
            child.address,
            childId1,
            true,
            "0x"
          )
      ).to.be.revertedWithCustomError(parent, "PendingChildIndexOutOfRange");
    });

    it("cannot transfer child if address or id do not match", async function () {
      const otherAddress = addrs[1].address;
      const otherChildId = 9999;
      const toOwnerAddress = addrs[2].address;
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            toOwnerAddress,
            0,
            0,
            otherAddress,
            childId1,
            true,
            "0x"
          )
      ).to.be.revertedWithCustomError(parent, "UnexpectedChildId");
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            parentId,
            toOwnerAddress,
            0,
            0,
            child.address,
            otherChildId,
            true,
            "0x"
          )
      ).to.be.revertedWithCustomError(parent, "UnexpectedChildId");
    });

    it("can transfer child if approved", async function () {
      const transferer = addrs[1];
      const toOwner = tokenOwner.address;
      await parent.connect(tokenOwner).approve(transferer.address, parentId);

      await parent
        .connect(transferer)
        .transferChild(
          parentId,
          toOwner,
          0,
          0,
          child.address,
          childId1,
          true,
          "0x"
        );
      await checkChildMovedToRootOwner();
    });

    it("can transfer child if approved for all", async function () {
      const operator = addrs[2];
      const toOwner = tokenOwner.address;
      await parent
        .connect(tokenOwner)
        .setApprovalForAll(operator.address, true);

      await parent
        .connect(operator)
        .transferChild(
          parentId,
          toOwner,
          0,
          0,
          child.address,
          childId1,
          true,
          "0x"
        );
      await checkChildMovedToRootOwner();
    });

    it("can transfer child with grandchild and children are ok", async function () {
      const toOwner = tokenOwner.address;
      const grandchildId = 999;
      await child.nestMint(child.address, grandchildId, childId1);

      // Transfer child from parent.
      await parent
        .connect(tokenOwner)
        .transferChild(
          parentId,
          toOwner,
          0,
          0,
          child.address,
          childId1,
          true,
          "0x"
        );

      // New owner of child
      expect(await child.ownerOf(childId1)).to.eql(tokenOwner.address);
      expect(await child.directOwnerOf(childId1)).to.eql([
        tokenOwner.address,
        bn(0),
        false,
      ]);

      // Grandchild is still owned by child
      expect(await child.ownerOf(grandchildId)).to.eql(tokenOwner.address);
      expect(await child.directOwnerOf(grandchildId)).to.eql([
        child.address,
        bn(childId1),
        true,
      ]);
    });

    it("cannot transfer child if not child root owner", async function () {
      const toOwner = tokenOwner.address;
      const notOwner = addrs[3];
      await expect(
        parent
          .connect(notOwner)
          .transferChild(
            parentId,
            toOwner,
            0,
            0,
            child.address,
            childId1,
            true,
            "0x"
          )
      ).to.be.revertedWithCustomError(child, "ERC721NotApprovedOrOwner");
    });

    it("cannot transfer child from not existing parent", async function () {
      const badChildId = 99;
      const toOwner = tokenOwner.address;
      await expect(
        parent
          .connect(tokenOwner)
          .transferChild(
            badChildId,
            toOwner,
            0,
            0,
            child.address,
            childId1,
            true,
            "0x"
          )
      ).to.be.revertedWithCustomError(child, "ERC721InvalidTokenId");
    });

    async function checkChildMovedToRootOwner(rootOwnerAddress?: string) {
      if (rootOwnerAddress === undefined) {
        rootOwnerAddress = tokenOwner.address;
      }
      expect(await child.ownerOf(childId1)).to.eql(rootOwnerAddress);
      expect(await child.directOwnerOf(childId1)).to.eql([
        rootOwnerAddress,
        bn(0),
        false,
      ]);

      // Transferring updates balances downstream
      expect(await child.balanceOf(rootOwnerAddress)).to.equal(1);
      expect(await parent.balanceOf(tokenOwner.address)).to.equal(1);
    }
  });

  describe("Transfer", async function () {
    it("can transfer token", async function () {
      const firstOwner = addrs[1];
      const newOwner = addrs[2];
      const tokenId1 = 1;
      await parent.mint(firstOwner.address, tokenId1);
      await parent.connect(firstOwner).transfer(newOwner.address, tokenId1);

      // Balances and ownership are updated
      expect(await parent.ownerOf(tokenId1)).to.eql(newOwner.address);
      expect(await parent.balanceOf(firstOwner.address)).to.equal(0);
      expect(await parent.balanceOf(newOwner.address)).to.equal(1);
    });

    it("cannot transfer not owned token", async function () {
      const firstOwner = addrs[1];
      const newOwner = addrs[2];
      const tokenId1 = 1;
      await parent.mint(firstOwner.address, tokenId1);
      await expect(
        parent.connect(newOwner).transfer(newOwner.address, tokenId1)
      ).to.be.revertedWithCustomError(child, "NotApprovedOrDirectOwner");
    });

    it("cannot transfer to address zero", async function () {
      const firstOwner = addrs[1];
      const tokenId1 = 1;
      await parent.mint(firstOwner.address, tokenId1);
      await expect(
        parent.connect(firstOwner).transfer(ADDRESS_ZERO, tokenId1)
      ).to.be.revertedWithCustomError(child, "ERC721TransferToTheZeroAddress");
    });

    it("can transfer token from approved address (not owner)", async function () {
      const firstOwner = addrs[1];
      const approved = addrs[2];
      const newOwner = addrs[3];
      const tokenId1 = 1;
      await parent.mint(firstOwner.address, tokenId1);

      await parent.connect(firstOwner).approve(approved.address, tokenId1);
      await parent.connect(firstOwner).transfer(newOwner.address, tokenId1);

      expect(await parent.ownerOf(tokenId1)).to.eql(newOwner.address);
    });

    it("can transfer not nested token with child to address and owners/children are ok", async function () {
      const firstOwner = addrs[1];
      const newOwner = addrs[2];
      const parentId = 1;
      await parent.mint(firstOwner.address, parentId);
      const childId1 = 99;
      await child.nestMint(parent.address, childId1, parentId);

      await parent.connect(firstOwner).transfer(newOwner.address, parentId);

      // Balances and ownership are updated
      expect(await parent.balanceOf(firstOwner.address)).to.equal(0);
      expect(await parent.balanceOf(newOwner.address)).to.equal(1);

      expect(await parent.ownerOf(parentId)).to.eql(newOwner.address);
      expect(await parent.directOwnerOf(parentId)).to.eql([
        newOwner.address,
        bn(0),
        false,
      ]);

      // New owner of child
      expect(await child.ownerOf(childId1)).to.eql(newOwner.address);
      expect(await child.directOwnerOf(childId1)).to.eql([
        parent.address,
        bn(parentId),
        true,
      ]);

      // Parent still has its children
      expect(await parent.pendingChildrenOf(parentId)).to.eql([
        [bn(childId1), child.address],
      ]);
    });

    it("cannot directly transfer nested child", async function () {
      const firstOwner = addrs[1];
      const newOwner = addrs[2];
      const parentId = 1;
      await parent.mint(firstOwner.address, parentId);
      const childId1 = 99;
      await child.nestMint(parent.address, childId1, parentId);

      await expect(
        child.connect(firstOwner).transfer(newOwner.address, childId1)
      ).to.be.revertedWithCustomError(child, "NotApprovedOrDirectOwner");
    });

    it("can transfer parent token to token with same owner, family tree is ok", async function () {
      const firstOwner = addrs[1];
      const grandParentId = 999;
      await parent.mint(firstOwner.address, grandParentId);
      const parentId = 1;
      await parent.mint(firstOwner.address, parentId);
      const childId1 = 99;
      await child.nestMint(parent.address, childId1, parentId);

      // Check balances
      expect(await parent.balanceOf(firstOwner.address)).to.equal(2);
      expect(await child.balanceOf(parent.address)).to.equal(1);

      // Transfers token parentId to (parent.address, token grandParentId)
      await parent
        .connect(firstOwner)
        .nestTransfer(parent.address, parentId, grandParentId);

      // Balances unchanged since root owner is the same
      expect(await parent.balanceOf(firstOwner.address)).to.equal(1);
      expect(await child.balanceOf(parent.address)).to.equal(1);
      expect(await parent.balanceOf(parent.address)).to.equal(1);

      // Parent is still owner of child
      let expected = [bn(childId1), child.address];
      checkAcceptedAndPendingChildren(parent, parentId, [expected], []);
      // Ownership: firstOwner > newGrandparent > parent > child
      expected = [bn(parentId), parent.address];
      checkAcceptedAndPendingChildren(parent, grandParentId, [], [expected]);
    });

    it("can transfer parent token to token with different owner, family tree is ok", async function () {
      const firstOwner = addrs[1];
      const otherOwner = addrs[2];
      const grandParentId = 999;
      await parent.mint(otherOwner.address, grandParentId);
      const parentId = 1;
      await parent.mint(firstOwner.address, parentId);
      const childId1 = 99;
      await child.nestMint(parent.address, childId1, parentId);

      // Check balances
      expect(await parent.balanceOf(otherOwner.address)).to.equal(1);
      expect(await parent.balanceOf(firstOwner.address)).to.equal(1);
      expect(await child.balanceOf(parent.address)).to.equal(1);

      // firstOwner calls parent to transfer parent token parent
      await parent
        .connect(firstOwner)
        .nestTransfer(parent.address, parentId, grandParentId);

      // Balances update
      expect(await parent.balanceOf(firstOwner.address)).to.equal(0);
      expect(await parent.balanceOf(parent.address)).to.equal(1);
      expect(await parent.balanceOf(otherOwner.address)).to.equal(1);
      expect(await child.balanceOf(parent.address)).to.equal(1);

      // Parent is still owner of child
      let expected = [bn(childId1), child.address];
      checkAcceptedAndPendingChildren(parent, parentId, [expected], []);
      // Ownership: firstOwner > newGrandparent > parent > child
      expected = [bn(parentId), parent.address];
      checkAcceptedAndPendingChildren(parent, grandParentId, [], [expected]);
    });
  });

  describe("Nest Transfer", async function () {
    let firstOwner: SignerWithAddress;
    let parentId: number;
    let childId1: number;

    beforeEach(async function () {
      firstOwner = addrs[1];
      parentId = 1;
      childId1 = 99;
      await parent.mint(firstOwner.address, parentId);
      await child.mint(firstOwner.address, childId1);
    });

    it("cannot nest tranfer from non immediate owner (owner of parent)", async function () {
      const otherParentId = 2;
      await parent.mint(firstOwner.address, otherParentId);
      // We send it to the parent first
      await child
        .connect(firstOwner)
        .nestTransfer(parent.address, childId1, parentId);
      // We can no longer nest transfer it, even if we are the root owner:
      await expect(
        child
          .connect(firstOwner)
          .nestTransfer(parent.address, childId1, otherParentId)
      ).to.be.revertedWithCustomError(child, "NotApprovedOrDirectOwner");
    });

    it("cannot nest tranfer to same NFT", async function () {
      // We can no longer nest transfer it, even if we are the root owner:
      await expect(
        child
          .connect(firstOwner)
          .nestTransfer(child.address, childId1, childId1)
      ).to.be.revertedWithCustomError(child, "NestableTransferToSelf");
    });

    it("cannot nest tranfer a descendant same NFT", async function () {
      // We can no longer nest transfer it, even if we are the root owner:
      await child
        .connect(firstOwner)
        .nestTransfer(parent.address, childId1, parentId);
      const grandChildId = 999;
      await child.nestMint(child.address, grandChildId, childId1);
      // Ownership is now parent->child->granChild
      // Cannot send parent to grandChild
      await expect(
        parent
          .connect(firstOwner)
          .nestTransfer(child.address, parentId, grandChildId)
      ).to.be.revertedWithCustomError(child, "NestableTransferToDescendant");
      // Cannot send parent to child
      await expect(
        parent
          .connect(firstOwner)
          .nestTransfer(child.address, parentId, childId1)
      ).to.be.revertedWithCustomError(child, "NestableTransferToDescendant");
    });

    it("cannot nest tranfer if ancestors tree is too deep", async function () {
      let lastId = childId1;
      for (let i = 101; i <= 200; i++) {
        await child.nestMint(child.address, i, lastId);
        lastId = i;
      }
      // Ownership is now parent->child->child->child->child...->lastChild
      // Cannot send parent to lastChild
      await expect(
        parent.connect(firstOwner).nestTransfer(child.address, parentId, lastId)
      ).to.be.revertedWithCustomError(child, "NestableTooDeep");
    });

    it("cannot nest tranfer if not owner", async function () {
      const notOwner = addrs[3];
      await expect(
        child.connect(notOwner).nestTransfer(parent.address, childId1, parentId)
      ).to.be.revertedWithCustomError(child, "NotApprovedOrDirectOwner");
    });

    it("cannot nest tranfer to address 0", async function () {
      await expect(
        child.connect(firstOwner).nestTransfer(ADDRESS_ZERO, childId1, parentId)
      ).to.be.revertedWithCustomError(child, "ERC721TransferToTheZeroAddress");
    });

    it("cannot nest tranfer to a non contract", async function () {
      const newOwner = addrs[2];
      await expect(
        child
          .connect(firstOwner)
          .nestTransfer(newOwner.address, childId1, parentId)
      ).to.be.revertedWithCustomError(child, "IsNotContract");
    });

    it("cannot nest tranfer to contract if it does implement INestable", async function () {
      const ERC721 = await ethers.getContractFactory("ERC721Mock");
      const nonNestable = await ERC721.deploy("Non receiver", "NR");
      await nonNestable.deployed();
      await expect(
        child
          .connect(firstOwner)
          .nestTransfer(nonNestable.address, childId1, parentId)
      ).to.be.revertedWithCustomError(
        child,
        "NestableTransferToNonNestableImplementer"
      );
    });

    it("can nest tranfer to INestable contract", async function () {
      await child
        .connect(firstOwner)
        .nestTransfer(parent.address, childId1, parentId);
      expect(await child.ownerOf(childId1)).to.eql(firstOwner.address);
      expect(await child.directOwnerOf(childId1)).to.eql([
        parent.address,
        bn(parentId),
        true,
      ]);
    });

    it("cannot nest tranfer to non existing parent token", async function () {
      const notExistingParentId = 9999;
      await expect(
        child
          .connect(firstOwner)
          .nestTransfer(parent.address, childId1, notExistingParentId)
      ).to.be.revertedWithCustomError(parent, "ERC721InvalidTokenId");
    });
  });

  async function checkNoChildrenNorPending(parentId: number): Promise<void> {
    expect(await parent.pendingChildrenOf(parentId)).to.eql([]);
    expect(await parent.childrenOf(parentId)).to.eql([]);
  }

  async function checkAcceptedAndPendingChildren(
    contract: EquippableTokenMock,
    tokenId1: number,
    expectedAccepted: any[],
    expectedPending: any[]
  ) {
    const accepted = await contract.childrenOf(tokenId1);
    expect(accepted).to.eql(expectedAccepted);

    const pending = await contract.pendingChildrenOf(tokenId1);
    expect(pending).to.eql(expectedPending);
  }
});
