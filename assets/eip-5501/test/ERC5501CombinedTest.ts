import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("ERC5501CombinedTest", function () {
  async function initialize() {
    // 7 * 24 * 60 * 60
    const week = 604800;

    const uint64MaxValue = BigNumber.from("18446744073709551615");

    const [owner, delegatee, borrower, rentalContractMock] =
      await ethers.getSigners();

    const contractFactory = await ethers.getContractFactory(
      "ERC5501CombinedTestCollection"
    );
    const contract = await contractFactory.deploy("Test Collection", "TEST");

    await contract.mint(owner.address, 1);

    return {
      contract,
      owner,
      delegatee,
      borrower,
      rentalContractMock,
      week,
      uint64MaxValue,
    };
  }

  it("Scenario", async function () {
    const {
      contract,
      owner,
      delegatee,
      borrower,
      rentalContractMock,
      week,
      uint64MaxValue,
    } = await loadFixture(initialize);

    // owner delegates NFT to hot wallet for security
    await expect(contract.setUser(1, delegatee.address, uint64MaxValue, false))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, delegatee.address, uint64MaxValue, false);
    expect(await contract.userBalanceOf(delegatee.address)).to.equal(1);
    expect(await contract.userOf(1)).to.equal(delegatee.address);
    expect(await contract.tokenOfUserByIndex(delegatee.address, 0)).to.equal(1);
    expect(await contract.userExpires(1)).to.equal(uint64MaxValue);
    expect(await contract.userIsBorrowed(1)).to.equal(false);

    // owner then decides to lend the NFT for one week
    await contract.setApprovalForAll(rentalContractMock.address, true);
    const oneWeekLater = (await time.latest()) + week;
    await expect(
      contract
        .connect(rentalContractMock)
        .setUser(1, borrower.address, oneWeekLater, true)
    )
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, oneWeekLater, true);
    expect(await contract.userBalanceOf(delegatee.address)).to.equal(0);
    expect(await contract.userBalanceOf(borrower.address)).to.equal(1);
    expect(await contract.tokenOfUserByIndex(borrower.address, 0)).to.equal(1);
    expect(await contract.userOf(1)).to.equal(borrower.address);
    expect(await contract.userExpires(1)).to.equal(oneWeekLater);
    expect(await contract.userIsBorrowed(1)).to.equal(true);

    // borrow expires
    await time.increaseTo((await time.latest()) + oneWeekLater + 1);

    // owner decides to lend the NFT again
    // this time, they accidentally set wrong time
    // the owner and borrower agree to terminate the loan under certain conditions
    await expect(
      contract
        .connect(rentalContractMock)
        .setUser(1, borrower.address, uint64MaxValue, true)
    )
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, uint64MaxValue, true);
    await expect(contract.connect(borrower).setBorrowTermination(1))
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, borrower.address, false);
    await expect(contract.setBorrowTermination(1))
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, owner.address, true);
    await expect(contract.terminateBorrow(1))
      .to.emit(contract, "TerminateBorrow")
      .withArgs(1, owner.address, borrower.address, owner.address)
      .to.emit(contract, "ResetTerminationAgreements")
      .withArgs(1);
  });

  it("Supports interface", async function () {
    const { contract } = await loadFixture(initialize);

    expect(await contract.supportsInterface("0xf808ec37")).to.equal(true);
    expect(await contract.supportsInterface("0x0cb22289")).to.equal(true);
    expect(await contract.supportsInterface("0x1d350ef8")).to.equal(true);
    expect(await contract.supportsInterface("0x6a26417e")).to.equal(true);
  });
});
