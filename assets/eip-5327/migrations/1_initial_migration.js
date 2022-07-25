const ERC5327Demo = artifacts.require("ERC5327Demo");

module.exports = function (deployer) {
  deployer.deploy(ERC5327Demo,'ERC5327Demo','ERC5327Demo');  
};

