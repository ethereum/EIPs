import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC5501EnumerableTest", function () {
  async function initialize() {
    // 365 * 24 * 60 * 60
    const fastForwardYear = 31536000;
    // allows to set multiple tokens which will expire after fastForwardYear
    const expired = (await time.latest()) + fastForwardYear - 1;

    const expires = (await time.latest()) + fastForwardYear + fastForwardYear;

    const [owner, delegatee] = await ethers.getSigners();

    const contractFactory = await ethers.getContractFactory(
      "ERC5501EnumerableTestCollection"
    );
    const contract = await contractFactory.deploy("Test Collection", "TEST");

    await contract.mint(owner.address, 1);
    await contract.mint(owner.address, 2);
    await contract.mint(owner.address, 3);
    await contract.mint(owner.address, 4);
    await contract.mint(owner.address, 5);
    await contract.mint(owner.address, 6);
    await contract.mint(owner.address, 7);

    return { contract, owner, delegatee, expires, expired, fastForwardYear };
  }

  it("Return correct user tokens by index", async function () {
    const { contract, owner, delegatee, expires, expired, fastForwardYear } =
      await loadFixture(initialize);

    await contract.setUser(1, delegatee.address, expires, false);
    await contract.setUser(2, delegatee.address, expired, false);
    await contract.setUser(3, delegatee.address, expires, false);
    await contract.setUser(4, delegatee.address, expired, false);
    await contract.setUser(5, delegatee.address, expires, false);
    await contract.setUser(6, delegatee.address, expired, false);
    await contract.setUser(7, delegatee.address, expires, false);

    expect(await contract.tokenOfUserByIndex(delegatee.address, 0)).to.equal(1);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 1)).to.equal(2);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 2)).to.equal(3);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 3)).to.equal(4);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 4)).to.equal(5);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 5)).to.equal(6);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 6)).to.equal(7);

    // fast forward one year, token 2, 4, 6 expired for user
    // current balance: 1, 3, 5, 7
    await time.increaseTo((await time.latest()) + fastForwardYear);

    expect(await contract.tokenOfUserByIndex(delegatee.address, 0)).to.equal(1);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 1)).to.equal(3);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 2)).to.equal(5);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 3)).to.equal(7);
    await expect(
      contract.tokenOfUserByIndex(delegatee.address, 4)
    ).to.be.revertedWith("ERC5501Enumerable: owner index out of bounds");
  });

  it("Revert user token id by index query for zero address", async function () {
    const { contract } = await loadFixture(initialize);

    await expect(
      contract.tokenOfUserByIndex(ethers.constants.AddressZero, 0)
    ).to.be.revertedWith("ERC5501Enumerable: address zero is not a valid owner");
  });

  it("Revert user token id by index query for out of bounds index", async function () {
    const { contract, delegatee } = await loadFixture(initialize);

    await expect(
      contract.tokenOfUserByIndex(delegatee.address, 0)
    ).to.be.revertedWith("ERC5501Enumerable: owner index out of bounds");
  });

  it("Supports interface", async function () {
    const { contract } = await loadFixture(initialize);

    expect(await contract.supportsInterface("0x1d350ef8")).to.equal(true);
  });
});
