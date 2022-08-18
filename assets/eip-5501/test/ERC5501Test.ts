import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC5501Test", function () {
  async function initialize() {
    // 365 * 24 * 60 * 60
    const fastForwardYear = 31536000;

    const expires = (await time.latest()) + fastForwardYear - 1;

    const [owner, delegatee, borrower, rentalContractMock] =
      await ethers.getSigners();

    const contractFactory = await ethers.getContractFactory(
      "ERC5501TestCollection"
    );
    const contract = await contractFactory.deploy("Test Collection", "TEST");

    await contract.mint(owner.address, 1);

    return {
      contract,
      owner,
      delegatee,
      borrower,
      rentalContractMock,
      expires,
      fastForwardYear,
    };
  }

  it("Operator is not owner or approved", async function () {
    const { contract, borrower } = await loadFixture(initialize);

    await expect(
      contract.connect(borrower).setUser(1, borrower.address, 0, false)
    ).to.be.revertedWith(
      "ERC5501: set user caller is not token owner or approved"
    );
  });

  it("User cannot be zero address", async function () {
    const { contract } = await loadFixture(initialize);

    await expect(
      contract.setUser(1, ethers.constants.AddressZero, 0, false)
    ).to.be.revertedWith("ERC5501: set user to zero address");
  });

  it("Revert userOf if not set or expired", async function () {
    const { contract } = await loadFixture(initialize);

    await expect(contract.userOf(1)).to.be.revertedWith(
      "ERC5501: user does not exist for this token"
    );
  });

  it("Cannot set user if NFT is borrowed", async function () {
    const { contract, delegatee, borrower, rentalContractMock, expires } =
      await loadFixture(initialize);

    await contract.setApprovalForAll(rentalContractMock.address, true);
    await expect(
      contract
        .connect(rentalContractMock)
        .setUser(1, borrower.address, expires, true)
    )
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, expires, true);
    await expect(
      contract.setUser(1, delegatee.address, 0, false)
    ).to.be.revertedWith("ERC5501: token is borrowed");
  });

  it("Can delegate and redelegate user", async function () {
    const { contract, owner, delegatee, expires } = await loadFixture(
      initialize
    );

    await expect(contract.setUser(1, owner.address, expires, false))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, owner.address, expires, false);
    await expect(contract.setUser(1, delegatee.address, expires, false))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, delegatee.address, expires, false);
  });

  it("Can set user after borrow expires", async function () {
    const { contract, delegatee, borrower, expires, fastForwardYear } =
      await loadFixture(initialize);

    await expect(contract.setUser(1, borrower.address, expires, true))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, expires, true);
    await time.increaseTo((await time.latest()) + fastForwardYear);
    await expect(contract.setUser(1, delegatee.address, 0, false))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, delegatee.address, 0, false);
  });

  it("User is reset if NFT is not borrowed and transferred", async function () {
    const { contract, owner, delegatee, expires } = await loadFixture(
      initialize
    );

    await expect(contract.setUser(1, delegatee.address, expires, false))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, delegatee.address, expires, false);
    await expect(
      contract["safeTransferFrom(address,address,uint256)"](
        owner.address,
        delegatee.address,
        1
      )
    )
      .to.emit(contract, "UpdateUser")
      .withArgs(1, ethers.constants.AddressZero, 0, false);

    await expect(contract.userOf(1)).to.be.revertedWith(
      "ERC5501: user does not exist for this token"
    );
    expect(await contract.userExpires(1)).to.equal(0);
    expect(await contract.userIsBorrowed(1)).to.equal(false);
  });

  it("User is not reset if NFT is borrowed and transferred", async function () {
    const { contract, owner, delegatee, borrower, expires } = await loadFixture(
      initialize
    );

    await expect(contract.setUser(1, borrower.address, expires, true))
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, expires, true);
    await contract["safeTransferFrom(address,address,uint256)"](
      owner.address,
      delegatee.address,
      1
    );

    expect(await contract.userOf(1)).to.equal(borrower.address);
    expect(await contract.userExpires(1)).to.equal(expires);
    expect(await contract.userIsBorrowed(1)).to.equal(true);
  });

  it("Rental contract can set user", async function () {
    const { contract, borrower, rentalContractMock, expires } =
      await loadFixture(initialize);

    await contract.setApprovalForAll(rentalContractMock.address, true);
    await expect(
      contract
        .connect(rentalContractMock)
        .setUser(1, borrower.address, expires, true)
    )
      .to.emit(contract, "UpdateUser")
      .withArgs(1, borrower.address, expires, true);

    expect(await contract.userOf(1)).to.equal(borrower.address);
    expect(await contract.userExpires(1)).to.equal(expires);
    expect(await contract.userIsBorrowed(1)).to.equal(true);
  });

  it("Supports interface", async function () {
    const { contract } = await loadFixture(initialize);

    expect(await contract.supportsInterface("0xf808ec37")).to.equal(true);
  });
});
