import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("ERC5501BalanceTest", function () {
  async function initialize() {
    // 365 * 24 * 60 * 60
    const fastForwardYear = 31536000;
    // Fri Jan 01 2021 00:00:00 GMT+0000
    const expired = 1609459200;

    const expires = (await time.latest()) + fastForwardYear - 1;

    const [owner, delegatee] = await ethers.getSigners();

    const contractFactory = await ethers.getContractFactory(
      "ERC5501BalanceTestCollection"
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

  it("Returns correct balance of user", async function () {
    const { contract, owner, delegatee, expires, expired, fastForwardYear } =
      await loadFixture(initialize);

    await contract.setUser(1, delegatee.address, expires, false);
    await contract.setUser(2, delegatee.address, expires, false);
    await contract.setUser(3, delegatee.address, expires, false);
    await contract.setUser(4, delegatee.address, expired, false);
    await contract.setUser(5, delegatee.address, expired, false);
    await contract.setUser(6, delegatee.address, expired, false);
    await contract.setUser(7, delegatee.address, expired, false);

    // flush function is called for user parameter - meaning flush does not happen for delegatee if user parameter is different address
    await contract.setUser(2, owner.address, expires, false);
    // delegatee is user of 1, 3
    // delegatee balances array is 1, 2, 3, 7

    expect(await contract.userBalanceOf(delegatee.address)).to.equal(2);
    expect(await contract.getUserBalances(delegatee.address)).to.deep.equal([
      BigNumber.from("1"),
      BigNumber.from("2"),
      BigNumber.from("3"),
      BigNumber.from("7"),
    ]);

    await time.increaseTo((await time.latest()) + fastForwardYear);
    await contract.setUser(
      1,
      delegatee.address,
      expires + fastForwardYear,
      false
    );

    expect(await contract.userBalanceOf(delegatee.address)).to.equal(1);
    expect(await contract.getUserBalances(delegatee.address)).to.deep.equal([
      BigNumber.from("1"),
    ]);

    await time.increaseTo((await time.latest()) + fastForwardYear);
    expect(await contract.userBalanceOf(delegatee.address)).to.equal(0);
  });

  it("Revert user balance query for zero address", async function () {
    const { contract } = await loadFixture(initialize);

    await expect(
      contract.userBalanceOf(ethers.constants.AddressZero)
    ).to.be.revertedWith("ERC5501Balance: address zero is not a valid owner");
  });

  it("Supports interface", async function () {
    const { contract } = await loadFixture(initialize);

    expect(await contract.supportsInterface("0x0cb22289")).to.equal(true);
  });
});
