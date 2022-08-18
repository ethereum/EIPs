const ERC721PDemo = artifacts.require("ERC721PDemo");
const ERC721PCloneableDemo = artifacts.require("ERC721PCloneableDemo");

module.exports = function (deployer) {
  deployer.deploy(ERC721PDemo,'ERC721PDemo','EPD');  
  deployer.deploy(ERC721PCloneableDemo,'ERC721PCDemo','EPCD');  
};

