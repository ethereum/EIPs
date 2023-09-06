import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const NAME = "NAME";
const SYMBOL = "SYMBOL";
const TOKEN_ID = 1234;

const PARENT_1_COLLECTION = "0xDEAdBEEf00000000000000000123456789ABCdeF";
const PARENT_1_ID = 8888;
const PARENT_1_TOKEN = { collection: PARENT_1_COLLECTION, id: PARENT_1_ID };

const PARENT_2_COLLECTION = "0xBaDc0ffEe0000000000000000123456789aBCDef";
const PARENT_2_ID = 9999;
const PARENT_2_TOKEN = { collection: PARENT_2_COLLECTION, id: PARENT_2_ID };

describe("ERC7510", function () {

  async function deployContractFixture() {
    const [deployer, owner] = await ethers.getSigners();

    const contract = await ethers.deployContract("ERC7510", [NAME, SYMBOL], deployer);
    await contract.mint(owner, TOKEN_ID);

    return { contract, owner };
  }

  describe("Functions", function () {
    it("Should not set parent tokens if not owner or approved", async function () {
      const { contract } = await loadFixture(deployContractFixture);

      await expect(contract.setParentTokens(TOKEN_ID, [PARENT_1_TOKEN]))
        .to.be.revertedWith("ERC7510: caller is not owner or approved");
    });

    it("Should correctly query token without parents", async function () {
      const { contract } = await loadFixture(deployContractFixture);

      expect(await contract.parentTokensOf(TOKEN_ID)).to.have.lengthOf(0);

      expect(await contract.isParentToken(TOKEN_ID, PARENT_1_TOKEN)).to.equal(false);
    });

    it("Should set parent tokens and then update", async function () {
      const { contract, owner } = await loadFixture(deployContractFixture);

      await contract.connect(owner).setParentTokens(TOKEN_ID, [PARENT_1_TOKEN]);

      let parentTokens = await contract.parentTokensOf(TOKEN_ID);
      expect(parentTokens).to.have.lengthOf(1);
      expect(parentTokens[0].collection).to.equal(PARENT_1_COLLECTION);
      expect(parentTokens[0].id).to.equal(PARENT_1_ID);

      expect(await contract.isParentToken(TOKEN_ID, PARENT_1_TOKEN)).to.equal(true);
      expect(await contract.isParentToken(TOKEN_ID, PARENT_2_TOKEN)).to.equal(false);

      await contract.connect(owner).setParentTokens(TOKEN_ID, [PARENT_2_TOKEN]);

      parentTokens = await contract.parentTokensOf(TOKEN_ID);
      expect(parentTokens).to.have.lengthOf(1);
      expect(parentTokens[0].collection).to.equal(PARENT_2_COLLECTION);
      expect(parentTokens[0].id).to.equal(PARENT_2_ID);

      expect(await contract.isParentToken(TOKEN_ID, PARENT_1_TOKEN)).to.equal(false);
      expect(await contract.isParentToken(TOKEN_ID, PARENT_2_TOKEN)).to.equal(true);
    });

    it("Should burn and clear parent tokens", async function () {
      const { contract, owner } = await loadFixture(deployContractFixture);

      await contract.connect(owner).setParentTokens(TOKEN_ID, [PARENT_1_TOKEN, PARENT_2_TOKEN]);
      await contract.burn(TOKEN_ID);

      await expect(contract.parentTokensOf(TOKEN_ID)).to.be.revertedWith("ERC7510: query for nonexistent token");
      await expect(contract.isParentToken(TOKEN_ID, PARENT_1_TOKEN)).to.be.revertedWith("ERC7510: query for nonexistent token");
      await expect(contract.isParentToken(TOKEN_ID, PARENT_2_TOKEN)).to.be.revertedWith("ERC7510: query for nonexistent token");

      await contract.mint(owner, TOKEN_ID);

      expect(await contract.parentTokensOf(TOKEN_ID)).to.have.lengthOf(0);
      expect(await contract.isParentToken(TOKEN_ID, PARENT_1_TOKEN)).to.equal(false);
      expect(await contract.isParentToken(TOKEN_ID, PARENT_2_TOKEN)).to.equal(false);
    });
  });

  describe("Events", function () {
    it("Should emit event when set parent tokens", async function () {
      const { contract, owner } = await loadFixture(deployContractFixture);

      await expect(contract.connect(owner).setParentTokens(TOKEN_ID, [PARENT_1_TOKEN, PARENT_2_TOKEN]))
        .to.emit(contract, "UpdateParentTokens").withArgs(TOKEN_ID);
    });
  });

});
