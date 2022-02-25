const OwnableDomain = artifacts.require("OwnableDomain");

export default function(deployer) {
  deployer.deploy(OwnableDomain);
};