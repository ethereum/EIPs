const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("ERC6884", () => {
  let alice, bob, carl;
  let erc721, erc6884;

  const tokenId = 1;

  const blockTimestamp = async () => await time.latest();

  beforeEach(async () => {
    [deployer, alice, bob, carl] = await ethers.getSigners();

    const ERC721 = await ethers.getContractFactory("MockERC721");
    const ERC6884 = await ethers.getContractFactory("ERC6884");

    erc721 = await ERC721.deploy();
    erc6884 = await ERC6884.deploy(erc721.address);

    await erc721.mint(alice.address, tokenId);
  });

  it("correctly constructs an ERC6884", async () => {
    expect(await erc6884.origin()).to.equal(erc721.address);
    expect(await erc6884.balanceOf(alice.address)).to.equal(tokenId);
    expect(await erc6884.ownerOf(tokenId)).to.equal(alice.address);
    expect(await erc6884.userOf(tokenId)).to.equal(alice.address);
  });

  describe("approve", () => {
    it("sets token approval", async () => {
      await erc6884.connect(alice).approve(bob.address, tokenId);
      expect(await erc6884.getApproved(tokenId)).to.equal(bob.address);
    });

    it("sets token approval from operator", async () => {
      await erc6884.connect(alice).setApprovalForAll(bob.address, true);
      await erc6884.connect(bob).approve(carl.address, tokenId);
      expect(await erc6884.getApproved(tokenId)).to.equal(carl.address);
    });

    it("reverts if the sender is an unauthorized account", async () => {
      await expect(
        erc6884.connect(bob).approve(carl.address, tokenId)
      ).to.be.revertedWith("ERC6884: NOT_AUTHORIZED");
    });
  });

  describe("setApprovalForAll", () => {
    it("sets operator approval", async () => {
      await erc6884.connect(alice).setApprovalForAll(bob.address, true);
      expect(await erc6884.isApprovedForAll(alice.address, bob.address)).to.be
        .true;
    });
  });

  describe("delegate", () => {
    const duration = 86400;

    it("delegates token use right from the owner", async () => {
      await erc6884.connect(alice).delegate(bob.address, tokenId, duration);

      // The use right is changed.
      expect(await erc6884.userOf(tokenId)).to.equal(bob.address);
      expect(await erc6884.expiration(tokenId)).to.equal(
        (await blockTimestamp()) + duration
      );

      // But, the ownership is not changed.
      expect(await erc6884.ownerOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.balanceOf(alice.address)).to.equal(tokenId);
    });

    it("delegates token use right from the operator", async () => {
      await erc6884.connect(alice).setApprovalForAll(bob.address, true);
      await erc6884.connect(bob).delegate(carl.address, tokenId, duration);

      // The use right is changed.
      expect(await erc6884.userOf(tokenId)).to.equal(carl.address);
      expect(await erc6884.expiration(tokenId)).to.equal(
        (await blockTimestamp()) + duration
      );

      // But, the ownership is not changed.
      expect(await erc6884.ownerOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.balanceOf(alice.address)).to.equal(tokenId);
    });

    it("delegates token use right from the approved account", async () => {
      await erc6884.connect(alice).approve(bob.address, tokenId);
      await erc6884.connect(bob).delegate(carl.address, tokenId, duration);

      // The use right is changed.
      expect(await erc6884.userOf(tokenId)).to.equal(carl.address);
      expect(await erc6884.expiration(tokenId)).to.equal(
        (await blockTimestamp()) + duration
      );

      // But, the ownership is not changed.
      expect(await erc6884.ownerOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.balanceOf(alice.address)).to.equal(tokenId);
    });

    it("reverts if the origin token does not exist", async () => {
      const nonExistentTokenId = 2;
      await expect(
        erc6884
          .connect(alice)
          .delegate(bob.address, nonExistentTokenId, duration)
      ).to.be.reverted;
    });

    it("reverts if the sender is an unauthorized account", async () => {
      await expect(
        erc6884.connect(carl).delegate(bob.address, tokenId, duration)
      ).to.be.revertedWith("ERC6884: NOT_AUTHORIZED");
    });
  });

  describe("regain", () => {
    const duration = 86400;

    const makeBlockTimeAfterExpiration = async (duration) => {
      await time.increase(duration);
    };

    beforeEach(async () => {
      await erc6884.connect(alice).delegate(bob.address, tokenId, duration);
    });

    it("regains token use right after expiration by any account", async () => {
      await makeBlockTimeAfterExpiration(duration);
      await erc6884.connect(carl).regain(tokenId);

      // The use right is changed.
      expect(await erc6884.userOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.expiration(tokenId)).to.equal(0);

      // But, the ownership is not changed.
      expect(await erc6884.ownerOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.balanceOf(alice.address)).to.equal(tokenId);
    });

    it("reverts if the token has already been regained", async () => {
      await makeBlockTimeAfterExpiration(duration);
      await erc6884.connect(carl).regain(tokenId);
      await expect(erc6884.connect(carl).regain(tokenId)).to.be.revertedWith(
        "ERC6884: NOT_REGAINABLE"
      );
    });

    it("reverts if the token is not expired", async () => {
      await expect(erc6884.connect(carl).regain(tokenId)).to.be.revertedWith(
        "ERC6884: NOT_EXPIRED"
      );
    });
  });

  describe("restore", () => {
    const duration = 86400;

    beforeEach(async () => {
      await erc6884.connect(alice).delegate(bob.address, tokenId, duration);
    });

    it("restores token use right by the user", async () => {
      await erc6884.connect(bob).restore(tokenId);

      // The use right is changed.
      expect(await erc6884.userOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.expiration(tokenId)).to.equal(0);

      // But, the ownership is not changed.
      expect(await erc6884.ownerOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.balanceOf(alice.address)).to.equal(tokenId);
    });

    it("restores token use right by the operator", async () => {
      await erc6884.connect(bob).setApprovalForAll(carl.address, true);
      await erc6884.connect(carl).restore(tokenId);

      // The use right is changed.
      expect(await erc6884.userOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.expiration(tokenId)).to.equal(0);

      // But, the ownership is not changed.
      expect(await erc6884.ownerOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.balanceOf(alice.address)).to.equal(tokenId);
    });

    it("restores token use right by the approved account", async () => {
      await erc6884.connect(bob).approve(carl.address, tokenId);
      await erc6884.connect(carl).restore(tokenId);

      // The use right is changed.
      expect(await erc6884.userOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.expiration(tokenId)).to.equal(0);

      // But, the ownership is not changed.
      expect(await erc6884.ownerOf(tokenId)).to.equal(alice.address);
      expect(await erc6884.balanceOf(alice.address)).to.equal(tokenId);
    });

    it("reverts if the sender is an unauthorized account", async () => {
      await expect(erc6884.connect(carl).restore(tokenId)).to.be.revertedWith(
        "ERC6884: NOT_AUTHORIZED"
      );
    });
  });
});
