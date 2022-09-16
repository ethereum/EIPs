import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("ERC5501TerminableTest", function () {
  async function initialize() {
    // 365 * 24 * 60 * 60
    const fastForwardYear = 31536000;

    const expires = (await time.latest()) + fastForwardYear - 1;

    const uint64MaxValue = BigNumber.from("18446744073709551615");

    const [owner, delegatee, borrower] = await ethers.getSigners();

    const contractFactory = await ethers.getContractFactory(
      "ERC5501TerminableTestCollection"
    );
    const contract = await contractFactory.deploy("Test Collection", "TEST");

    await contract.mint(owner.address, 1);

    return {
      contract,
      owner,
      delegatee,
      borrower,
      uint64MaxValue,
      expires,
      fastForwardYear,
    };
  }

  it("Cannot terminate borrow without approval of both parties", async function () {
    const { contract, borrower, uint64MaxValue } = await loadFixture(
      initialize
    );

    await expect(contract.setUser(1, borrower.address, uint64MaxValue, true))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, uint64MaxValue, true);
    await expect(contract.terminateBorrow(1)).to.be.revertedWith(
      "ERC5501Terminable: not agreed"
    );
  });

  it("Cannot set borrow termination if borrow is not active", async function () {
    const { contract, delegatee, uint64MaxValue } = await loadFixture(
      initialize
    );

    await expect(contract.setUser(1, delegatee.address, uint64MaxValue, false))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, delegatee.address, uint64MaxValue, false);
    await expect(contract.setBorrowTermination(1)).to.be.revertedWith(
      "ERC5501Terminable: borrow not active"
    );
  });

  it("Can reset borrow if owner mistakenly borrowed token to own wallet and set a long duration", async function () {
    const { contract, owner, uint64MaxValue } = await loadFixture(initialize);

    await expect(contract.setUser(1, owner.address, uint64MaxValue, true))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, owner.address, uint64MaxValue, true);

    await expect(contract.setBorrowTermination(1))
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, owner.address, true)
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, owner.address, false);

    expect(await contract.getBorrowTermination(1)).to.have.ordered.members([
      true,
      true,
    ]);

    await expect(contract.terminateBorrow(1))
      .to.emit(contract, "TerminateBorrow")
      .withArgs(1, owner.address, owner.address, owner.address)
      .to.emit(contract, "ResetTerminationAgreements")
      .withArgs(1);

    expect(await contract.getBorrowTermination(1)).to.have.ordered.members([
      false,
      false,
    ]);
    expect(await contract.userIsBorrowed(1)).to.equal(false);
  });

  it("Can reset borrow and set a new user if both parties agree", async function () {
    const { contract, owner, delegatee, borrower, uint64MaxValue } =
      await loadFixture(initialize);

    await expect(contract.setUser(1, borrower.address, uint64MaxValue, true))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, uint64MaxValue, true);

    await expect(contract.setBorrowTermination(1))
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, owner.address, true);

    expect(await contract.getBorrowTermination(1)).to.have.ordered.members([
      true,
      false,
    ]);

    await expect(contract.connect(borrower).setBorrowTermination(1))
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, borrower.address, false);

    expect(await contract.getBorrowTermination(1)).to.have.ordered.members([
      true,
      true,
    ]);

    await expect(contract.terminateBorrow(1))
      .to.emit(contract, "TerminateBorrow")
      .withArgs(1, owner.address, borrower.address, owner.address)
      .to.emit(contract, "ResetTerminationAgreements")
      .withArgs(1);

    expect(await contract.getBorrowTermination(1)).to.have.ordered.members([
      false,
      false,
    ]);
    expect(await contract.userIsBorrowed(1)).to.equal(false);

    await expect(contract.setUser(1, delegatee.address, 0, false))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, delegatee.address, 0, false);
  });

  it("Agreed borrow terminations must be reset if userOf is changed", async function () {
    const { contract, owner, delegatee, borrower, expires, fastForwardYear } =
      await loadFixture(initialize);

    await expect(contract.setUser(1, borrower.address, expires, true))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, expires, true);

    await expect(contract.setBorrowTermination(1))
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, owner.address, true);
    await expect(contract.connect(borrower).setBorrowTermination(1))
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, borrower.address, false);

    expect(await contract.getBorrowTermination(1)).to.have.ordered.members([
      true,
      true,
    ]);

    await time.increaseTo((await time.latest()) + fastForwardYear);

    await expect(contract.setUser(1, delegatee.address, 0, false))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, delegatee.address, 0, false)
      .to.emit(contract, "ResetTerminationAgreements")
      .withArgs(1);

    expect(await contract.getBorrowTermination(1)).to.have.ordered.members([
      false,
      false,
    ]);
  });

  it("Reset termination agreements if token is transferred", async function () {
    const { contract, owner, delegatee, borrower, expires } = await loadFixture(
      initialize
    );

    await expect(contract.setUser(1, borrower.address, expires, true))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, expires, true);

    await expect(contract.setBorrowTermination(1))
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, owner.address, true);
    await expect(contract.connect(borrower).setBorrowTermination(1))
      .to.emit(contract, "AgreeToTerminateBorrow")
      .withArgs(1, borrower.address, false);

    expect(await contract.getBorrowTermination(1)).to.have.ordered.members([
      true,
      true,
    ]);

    await expect(
      contract["safeTransferFrom(address,address,uint256)"](
        owner.address,
        delegatee.address,
        1
      )
    )
      .to.emit(contract, "ResetTerminationAgreements")
      .withArgs(1);

    expect(await contract.getBorrowTermination(1)).to.have.ordered.members([
      false,
      false,
    ]);
  });

  it("Supports interface", async function () {
    const { contract } = await loadFixture(initialize);

    expect(await contract.supportsInterface("0x6a26417e")).to.equal(true);
  });
});
