const ERC4907Demo = artifacts.require("ERC4907Demo");

module.exports = function (deployer) {
  deployer.deploy(ERC4907Demo, "ERC4907Demo", "ERC4907Demo");
};
