const OmniverseProtocolHelper = artifacts.require("OmniverseProtocolHelper");
const SkywalkerFungible = artifacts.require("SkywalkerFungible");
const SkywalkerNonFungible = artifacts.require("SkywalkerNonFungible");
const fs = require("fs");

const CHAIN_IDS = {
  BSCTEST: 0,
  MOCK: 10000,
};

module.exports = async function (deployer, network) {
  const contractAddressFile = './config/default.json';
  let data = fs.readFileSync(contractAddressFile, 'utf8');
  let jsonData = JSON.parse(data);
  if (!jsonData[network]) {
    console.error('There is no config for: ', network, ', please add.');
    return;
  }

  await deployer.deploy(OmniverseProtocolHelper);
  await deployer.link(OmniverseProtocolHelper, SkywalkerFungible);
  await deployer.link(OmniverseProtocolHelper, SkywalkerNonFungible);
  await deployer.deploy(SkywalkerFungible, CHAIN_IDS[network], "X", "X");
  await deployer.deploy(SkywalkerNonFungible, CHAIN_IDS[network], "X", "X");

  // Update config
  if (network.indexOf('-fork') != -1 || network == 'test' || network == 'development') {
    return;
  }

  jsonData[network].skywalkerFungibleAddress = SkywalkerFungible.address;
  jsonData[network].skywalkerNonFungibleAddress = SkywalkerNonFungible.address;
  fs.writeFileSync(contractAddressFile, JSON.stringify(jsonData, null, '\t'));
};
