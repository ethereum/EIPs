import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC721NonTransferrableMock } from "../typechain-types";

async function nonTransferrableTokenFixture(): Promise<ERC721NonTransferrableMock> {
  const factory = await ethers.getContractFactory("ERC721NonTransferrableMock");
  const token = await factory.deploy("Chunky", "CHNK");
  await token.deployed();

  return token;
}

describe("NonTransferrable", async function () {
  let nonTransferrable: ERC721NonTransferrableMock;
  let owner: SignerWithAddress;
  let otherOwner: SignerWithAddress;
  const tokenId = 1;

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    otherOwner = signers[1];
    nonTransferrable = await loadFixture(nonTransferrableTokenFixture);

    await nonTransferrable.mint(owner.address, 1);
  });

  it("can support IRMRKNonTransferrable", async function () {
    expect(await nonTransferrable.supportsInterface("0x0083fc9d")).to.equal(true);
  });

  it("does not support other interfaces", async function () {
    expect(await nonTransferrable.supportsInterface("0xffffffff")).to.equal(false);
  });

  it("cannot transfer", async function () {
    expect(
      nonTransferrable
        .connect(owner)
        ["safeTransferFrom(address,address,uint256)"](
          owner.address,
          otherOwner.address,
          tokenId
        )
    ).to.be.revertedWithCustomError(nonTransferrable, "CannotTransferNonTransferrable");
  });

  it("can burn", async function () {
    await nonTransferrable.connect(owner).burn(tokenId);
    await expect(nonTransferrable.ownerOf(tokenId)).to.be.revertedWith(
      "ERC721: invalid token ID"
    );
  });
});
