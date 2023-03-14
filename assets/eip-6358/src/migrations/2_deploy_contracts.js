const OmniverseProtocolHelper = artifacts.require("OmniverseProtocolHelper");
const ERC6358FungibleExample = artifacts.require("ERC6358FungibleExample");
const ERC6358NonFungibleExample = artifacts.require("ERC6358NonFungibleExample");
// const fs = require("fs");

const CHAIN_IDS = {
  GOERLI: 1,
  BSCTEST: 2,
  MOCK: 10000,
};

module.exports = async function (deployer, network) {
  // const contractAddressFile = './config/default.json';
  // let data = fs.readFileSync(contractAddressFile, 'utf8');
  // let jsonData = JSON.parse(data);
  if (network == 'development') {
    return;
  }
  // else if(!jsonData[network]) {
  //   console.error('There is no config for: ', network, ', please add.');
  //   return;
  // }

  await deployer.deploy(OmniverseProtocolHelper);
  await deployer.link(OmniverseProtocolHelper, ERC6358FungibleExample);
  await deployer.link(OmniverseProtocolHelper, ERC6358NonFungibleExample);
  await deployer.deploy(ERC6358FungibleExample, CHAIN_IDS[network], "X", "X");
  await deployer.deploy(ERC6358NonFungibleExample, CHAIN_IDS[network], "X", "X");

  // Update config
  if (network.indexOf('-fork') != -1 || network == 'test' || network == 'development') {
    return;
  }

  // jsonData[network].ERC6358FungibleExampleAddress = ERC6358FungibleExample.address;
  // jsonData[network].ERC6358NonFungibleExampleAddress = ERC6358NonFungibleExample.address;
  // fs.writeFileSync(contractAddressFile, JSON.stringify(jsonData, null, '\t'));
};
