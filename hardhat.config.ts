import '@nomiclabs/hardhat-waffle';
import 'hardhat-abi-exporter';
import 'hardhat-typechain';


module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.11",
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: 'hardhat',
  abiExporter: {
    only: ['IERC721Consumable', 'ERC721Consumable'],
    clear: true,
    flat: true,
  },
};
