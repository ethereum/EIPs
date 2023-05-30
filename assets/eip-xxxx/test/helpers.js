const {assert} = require("chai");

const Helpers = {
  initEthers(ethers) {
    this.ethers = ethers;
  },

  async assertThrowsMessage(promise, message) {
    try {
      await promise;
      console.log("It did not throw :-(");
      assert.isTrue(false);
    } catch (e) {
      const shouldBeTrue = e.message.indexOf(message) > -1;
      if (!shouldBeTrue) {
        console.error("Expected:", message);
        console.error("Returned:", e.message);
        // console.log(e)
      }
      assert.isTrue(shouldBeTrue);
    }
  },

  async deployContractBy(contractName, owner, ...args) {
    const Contract = await this.ethers.getContractFactory(contractName);
    const contract = await Contract.connect(owner).deploy(...args);
    await contract.deployed();
    return contract;
  },

  async deployContract(contractName, ...args) {
    const Contract = await this.ethers.getContractFactory(contractName);
    const contract = await Contract.deploy(...args);
    await contract.deployed();
    return contract;
  },

  async deployContractUpgradeable(contractName, args = []) {
    const Contract = await this.ethers.getContractFactory(contractName);
    const contract = await upgrades.deployProxy(Contract, args);
    await contract.deployed();
    return contract;
  },

  async signPackedData(
    hash,
    // hardhat account #4, starting from #0
    privateKey = "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
  ) {
    const signingKey = new this.ethers.utils.SigningKey(privateKey);
    const signedDigest = signingKey.signDigest(hash);
    return this.ethers.utils.joinSignature(signedDigest);
  },

  async getTimestamp() {
    return (await this.ethers.provider.getBlock()).timestamp;
  },

  addr0: "0x0000000000000000000000000000000000000000",

  async increaseBlockTimestampBy(offset) {
    await this.ethers.provider.send("evm_increaseTime", [offset]);
    await this.ethers.provider.send("evm_mine");
  },
};

module.exports = Helpers;
