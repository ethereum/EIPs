const Ticket = artifacts.require("Ticket");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Ticket, accounts[0], "");
};
