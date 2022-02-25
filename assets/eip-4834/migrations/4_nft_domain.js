const BasicNFTDomain = artifacts.require("BasicNFTDomain");

export default function(deployer) {
  deployer.deploy(BasicNFTDomain);
};