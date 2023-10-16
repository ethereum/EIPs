import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC721TransferableMock } from "../typechain-types";

async function transferableTokenFixture(): Promise<ERC721TransferableMock> {
  const factory = await ethers.getContractFactory("ERC721TransferableMock");
  const token = await factory.deploy("Chunky", "CHNK");
  await token.deployed();

  return token;
}

describe("Transferable", async function () {
  let nonTransferable: ERC721TransferableMock;
  let owner: SignerWithAddress;
  let otherOwner: SignerWithAddress;
  const tokenId = 1;

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    otherOwner = signers[1];
    nonTransferable = await loadFixture(transferableTokenFixture);

    await nonTransferable.mint(owner.address, 1);
    await nonTransferable.mint(otherOwner.address, 2);
  });

  it("can support IRMRKNonTransferable", async function () {
    expect(await nonTransferable.supportsInterface("0x91a6262f")).to.equal(true);
  });

  it("does not support other interfaces", async function () {
    expect(await nonTransferable.supportsInterface("0xffffffff")).to.equal(false);
  });

  it("cannot transfer", async function () {
    expect(
      nonTransferable
        .connect(owner)
        ["safeTransferFrom(address,address,uint256)"](
          owner.address,
          otherOwner.address,
          tokenId + 1
        )
    ).to.be.revertedWithCustomError(nonTransferable, "CannotTransferNonTransferable");
  });

  it("returns the expected transferability state", async function () {
    expect(await nonTransferable['isTransferable(uint256,address,address)'](tokenId, ethers.constants.AddressZero, ethers.constants.AddressZero)).to.equal(false);
    expect(await nonTransferable['isTransferable(uint256,address,address)'](tokenId, ethers.constants.AddressZero, otherOwner.address)).to.equal(true);
  })

  it("reverts if token does not exist", async function () {
    await expect(nonTransferable['isTransferable(uint256,address,address)'](10, owner.address, otherOwner.address)).to.be.revertedWith("ERC721: invalid token ID");
  });

  it("can burn", async function () {
    await nonTransferable.connect(owner).burn(tokenId);
    await expect(nonTransferable.ownerOf(tokenId)).to.be.revertedWith(
      "ERC721: invalid token ID"
    );
  });
});
