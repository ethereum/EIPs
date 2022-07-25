const ERC5334Demo = artifacts.require("ERC5334Demo");

module.exports = function (deployer) {
  deployer.deploy(ERC5334Demo,'ERC5334Demo','ERC5334Demo');  
};

