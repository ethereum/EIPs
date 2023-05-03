const FirstKBT = artifacts.require("MyFirstKBT");

module.exports = function (deployer) {
  deployer.deploy(FirstKBT);
};
