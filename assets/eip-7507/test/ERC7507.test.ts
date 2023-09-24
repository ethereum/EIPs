import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const NAME = "NAME";
const SYMBOL = "SYMBOL";
const TOKEN_ID = 1234;
const EXPIRATION = 2000000000;
const YEAR = 31536000;

describe("ERC7507", function () {

  async function deployContractFixture() {
    const [deployer, owner, user1, user2] = await ethers.getSigners();

    const contract = await ethers.deployContract("ERC7507", [NAME, SYMBOL], deployer);
    await contract.mint(owner, TOKEN_ID);

    return { contract, owner, user1, user2 };
  }

  describe("Functions", function () {
    it("Should not set user if not owner or approved", async function () {
      const { contract, user1 } = await loadFixture(deployContractFixture);

      await expect(contract.setUser(TOKEN_ID, user1, EXPIRATION))
        .to.be.revertedWith("ERC7507: caller is not owner or approved");
    });

    it("Should return zero expiration for nonexistent user", async function () {
      const { contract, user1 } = await loadFixture(deployContractFixture);

      expect(await contract.userExpires(TOKEN_ID, user1)).to.equal(0);
    });

    it("Should set users and then update", async function () {
      const { contract, owner, user1, user2 } = await loadFixture(deployContractFixture);

      await contract.connect(owner).setUser(TOKEN_ID, user1, EXPIRATION);
      await contract.connect(owner).setUser(TOKEN_ID, user2, EXPIRATION);

      expect(await contract.userExpires(TOKEN_ID, user1)).to.equal(EXPIRATION);
      expect(await contract.userExpires(TOKEN_ID, user2)).to.equal(EXPIRATION);

      await contract.connect(owner).setUser(TOKEN_ID, user1, EXPIRATION + YEAR);
      await contract.connect(owner).setUser(TOKEN_ID, user2, 0);

      expect(await contract.userExpires(TOKEN_ID, user1)).to.equal(EXPIRATION + YEAR);
      expect(await contract.userExpires(TOKEN_ID, user2)).to.equal(0);
    });
  });

  describe("Events", function () {
    it("Should emit event when set user", async function () {
      const { contract, owner, user1 } = await loadFixture(deployContractFixture);

      await expect(contract.connect(owner).setUser(TOKEN_ID, user1, EXPIRATION))
        .to.emit(contract, "UpdateUser").withArgs(TOKEN_ID, user1.address, EXPIRATION);
    });
  });

});
