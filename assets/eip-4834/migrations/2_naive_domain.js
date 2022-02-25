const NaiveDomain = artifacts.require("NaiveDomain");

export default function(deployer) {
  deployer.deploy(NaiveDomain);
};