const ERC5007Demo = artifacts.require("ERC5007Demo");

module.exports = function (deployer) {
  deployer.deploy(ERC5007Demo,'ERC5007Demo','ERC5007Demo');  
};

